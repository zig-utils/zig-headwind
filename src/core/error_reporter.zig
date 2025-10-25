const std = @import("std");

/// ANSI color codes for terminal output
pub const Color = enum {
    reset,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bold,
    dim,

    pub fn code(self: Color) []const u8 {
        return switch (self) {
            .reset => "\x1b[0m",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37m",
            .bold => "\x1b[1m",
            .dim => "\x1b[2m",
        };
    }
};

/// Error reporter with colored output and suggestions
pub const ErrorReporter = struct {
    allocator: std.mem.Allocator,
    colors_enabled: bool,

    pub fn init(allocator: std.mem.Allocator) ErrorReporter {
        return .{
            .allocator = allocator,
            .colors_enabled = !std.process.hasEnvVarConstant("NO_COLOR"),
        };
    }

    /// Print an error message with optional suggestions
    pub fn reportError(
        self: *const ErrorReporter,
        comptime fmt: []const u8,
        args: anytype,
    ) void {
        if (self.colors_enabled) {
            std.debug.print("{s}error:{s} ", .{ Color.red.code(), Color.reset.code() });
        } else {
            std.debug.print("error: ", .{});
        }
        std.debug.print(fmt ++ "\n", args);
    }

    /// Print a warning message
    pub fn reportWarning(
        self: *const ErrorReporter,
        comptime fmt: []const u8,
        args: anytype,
    ) void {
        if (self.colors_enabled) {
            std.debug.print("{s}warning:{s} ", .{ Color.yellow.code(), Color.reset.code() });
        } else {
            std.debug.print("warning: ", .{});
        }
        std.debug.print(fmt ++ "\n", args);
    }

    /// Print an info message
    pub fn reportInfo(
        self: *const ErrorReporter,
        comptime fmt: []const u8,
        args: anytype,
    ) void {
        if (self.colors_enabled) {
            std.debug.print("{s}info:{s} ", .{ Color.cyan.code(), Color.reset.code() });
        } else {
            std.debug.print("info: ", .{});
        }
        std.debug.print(fmt ++ "\n", args);
    }

    /// Report unknown utility with suggestions
    pub fn reportUnknownUtility(
        self: *const ErrorReporter,
        utility_name: []const u8,
        file_path: ?[]const u8,
        line: ?usize,
    ) !void {
        // Print error location if available
        if (file_path) |path| {
            if (self.colors_enabled) {
                std.debug.print("{s}{s}:{s}", .{ Color.bold.code(), path, Color.reset.code() });
            } else {
                std.debug.print("{s}:", .{path});
            }

            if (line) |l| {
                if (self.colors_enabled) {
                    std.debug.print("{s}{d}:{s} ", .{ Color.bold.code(), l, Color.reset.code() });
                } else {
                    std.debug.print("{d}: ", .{l});
                }
            }
        }

        // Print error
        self.reportError("Unknown utility '{s}'", .{utility_name});

        // Try to find suggestions
        const suggestions = try self.findSimilarUtilities(utility_name);
        defer self.allocator.free(suggestions);

        if (suggestions.len > 0) {
            if (self.colors_enabled) {
                std.debug.print("  {s}Did you mean:{s}\n", .{ Color.cyan.code(), Color.reset.code() });
            } else {
                std.debug.print("  Did you mean:\n", .{});
            }

            for (suggestions) |suggestion| {
                if (self.colors_enabled) {
                    std.debug.print("    {s}{s}{s}\n", .{ Color.green.code(), suggestion, Color.reset.code() });
                } else {
                    std.debug.print("    {s}\n", .{suggestion});
                }
            }
        }

        // Print helpful hint
        self.printHint(utility_name);
    }

    /// Find similar utilities using Levenshtein distance
    fn findSimilarUtilities(self: *const ErrorReporter, utility_name: []const u8) ![][]const u8 {
        const common_utilities = [_][]const u8{
            // Layout
            "flex",
            "flex-row",
            "flex-col",
            "grid",
            "block",
            "inline",
            "hidden",
            // Spacing
            "m-0",
            "m-4",
            "p-4",
            "gap-4",
            // Alignment
            "items-center",
            "justify-center",
            "items-start",
            "justify-start",
            "items-end",
            "justify-end",
            // Sizing
            "w-full",
            "h-full",
            "w-screen",
            "h-screen",
            // Typography
            "text-sm",
            "text-base",
            "text-lg",
            "text-xl",
            "font-bold",
            "text-center",
            // Colors
            "bg-white",
            "bg-black",
            "text-white",
            "text-black",
            "bg-blue-500",
            "text-blue-500",
            // Borders
            "border",
            "rounded",
            "rounded-lg",
            // Effects
            "shadow",
            "shadow-lg",
            "opacity-50",
        };

        var suggestions = std.ArrayList([]const u8).init(self.allocator);
        errdefer suggestions.deinit();

        for (common_utilities) |util| {
            const distance = levenshteinDistance(utility_name, util);
            // Suggest if distance is small (typo) or if starts with same prefix
            if (distance <= 2 or std.mem.startsWith(u8, util, utility_name)) {
                try suggestions.append(util);
                if (suggestions.items.len >= 3) break; // Max 3 suggestions
            }
        }

        return suggestions.toOwnedSlice();
    }

    /// Print helpful hint based on utility pattern
    fn printHint(self: *const ErrorReporter, utility_name: []const u8) void {
        const hint: ?[]const u8 = blk: {
            if (std.mem.indexOf(u8, utility_name, "center")) |_| {
                break :blk "To center items, use: 'flex items-center justify-center'";
            } else if (std.mem.startsWith(u8, utility_name, "color-")) {
                break :blk "Use 'text-{color}' for text color or 'bg-{color}' for background";
            } else if (std.mem.startsWith(u8, utility_name, "padding-") or std.mem.startsWith(u8, utility_name, "margin-")) {
                break :blk "Use shorthand: 'p-4' for padding, 'm-4' for margin";
            }
            break :blk null;
        };

        if (hint) |h| {
            if (self.colors_enabled) {
                std.debug.print("  {s}hint:{s} {s}\n", .{ Color.cyan.code(), Color.reset.code(), h });
            } else {
                std.debug.print("  hint: {s}\n", .{h});
            }
        }
    }
};

/// Calculate Levenshtein distance between two strings
fn levenshteinDistance(s1: []const u8, s2: []const u8) usize {
    const len1 = s1.len;
    const len2 = s2.len;

    if (len1 == 0) return len2;
    if (len2 == 0) return len1;

    // For small strings, use simple algorithm
    if (len1 > 50 or len2 > 50) return std.math.maxInt(usize);

    var costs: [51]usize = undefined;

    var i: usize = 0;
    while (i <= len2) : (i += 1) {
        costs[i] = i;
    }

    i = 1;
    while (i <= len1) : (i += 1) {
        var corner = costs[0];
        costs[0] = i;

        var j: usize = 1;
        while (j <= len2) : (j += 1) {
            const upper = costs[j];
            const cost: usize = if (s1[i - 1] == s2[j - 1]) 0 else 1;

            costs[j] = @min(
                @min(costs[j - 1] + 1, costs[j] + 1),
                corner + cost,
            );

            corner = upper;
        }
    }

    return costs[len2];
}

test "levenshtein distance" {
    try std.testing.expectEqual(@as(usize, 0), levenshteinDistance("flex", "flex"));
    try std.testing.expectEqual(@as(usize, 1), levenshteinDistance("flex", "fle"));
    try std.testing.expectEqual(@as(usize, 1), levenshteinDistance("flex", "flox"));
    try std.testing.expectEqual(@as(usize, 3), levenshteinDistance("flex", "grid"));
}

test "color codes" {
    try std.testing.expect(Color.red.code().len > 0);
    try std.testing.expect(Color.reset.code().len > 0);
}
