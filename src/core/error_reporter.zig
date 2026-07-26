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

    /// Find similar utilities using Levenshtein distance and pattern matching
    fn findSimilarUtilities(self: *const ErrorReporter, utility_name: []const u8) ![][]const u8 {
        const common_utilities = [_][]const u8{
            // Layout
            "flex",             "flex-row",          "flex-col",        "flex-wrap",       "flex-nowrap",
            "grid",             "grid-cols-1",       "grid-cols-2",     "grid-cols-3",     "grid-rows-1",
            "block",            "inline",            "inline-block",    "inline-flex",     "inline-grid",
            "hidden",           "visible",           "invisible",       "static",          "fixed",
            "absolute",         "relative",          "sticky",
            // Spacing
                     "m-0",             "m-1",
            "m-2",              "m-4",               "m-8",             "m-auto",          "mx-auto",
            "my-auto",          "mt-4",              "mb-4",            "ml-4",            "mr-4",
            "p-0",              "p-1",               "p-2",             "p-4",             "p-8",
            "px-4",             "py-4",              "pt-4",            "pb-4",            "pl-4",
            "pr-4",             "gap-0",             "gap-2",           "gap-4",           "gap-8",
            "space-x-4",        "space-y-4",
            // Alignment
                    "items-start",     "items-center",    "items-end",
            "items-baseline",   "items-stretch",     "justify-start",   "justify-center",  "justify-end",
            "justify-between",  "justify-around",    "content-start",   "content-center",  "content-end",
            "self-auto",        "self-start",        "self-center",     "self-end",
            // Sizing
                   "w-0",
            "w-full",           "w-screen",          "w-auto",          "w-1/2",           "w-1/3",
            "w-2/3",            "h-0",               "h-full",          "h-screen",        "h-auto",
            "h-1/2",            "min-w-0",           "min-w-full",      "max-w-xs",        "max-w-sm",
            "max-w-md",         "max-w-lg",          "min-h-0",         "min-h-full",      "max-h-screen",
            // Typography
            "text-xs",          "text-sm",           "text-base",       "text-lg",         "text-xl",
            "text-2xl",         "font-thin",         "font-normal",     "font-medium",     "font-semibold",
            "font-bold",        "text-left",         "text-center",     "text-right",      "text-justify",
            "leading-none",     "leading-tight",     "leading-normal",  "leading-loose",   "tracking-tighter",
            "tracking-tight",   "tracking-normal",   "tracking-wide",   "uppercase",       "lowercase",
            "capitalize",       "normal-case",       "underline",       "line-through",    "no-underline",
            // Colors
            "text-transparent", "text-current",      "text-black",      "text-white",      "text-gray-50",
            "text-gray-500",    "text-gray-900",     "text-red-500",    "text-blue-500",   "text-green-500",
            "text-yellow-500",  "bg-transparent",    "bg-current",      "bg-black",        "bg-white",
            "bg-gray-50",       "bg-gray-500",       "bg-gray-900",     "bg-red-500",      "bg-blue-500",
            "bg-green-500",     "bg-yellow-500",
            // Borders
                "border",          "border-0",        "border-2",
            "border-4",         "border-t",          "border-b",        "border-l",        "border-r",
            "rounded",          "rounded-sm",        "rounded-md",      "rounded-lg",      "rounded-full",
            "rounded-t",        "rounded-b",         "rounded-l",       "rounded-r",       "border-solid",
            "border-dashed",    "border-dotted",     "border-gray-200", "border-gray-500",
            // Effects
            "shadow",
            "shadow-sm",        "shadow-md",         "shadow-lg",       "shadow-xl",       "shadow-none",
            "opacity-0",        "opacity-50",        "opacity-100",     "blur",            "blur-sm",
            "blur-md",          "blur-lg",
            // Transitions
                      "transition",      "transition-all",  "transition-colors",
            "duration-100",     "duration-200",      "duration-300",    "duration-500",    "ease-in",
            "ease-out",         "ease-in-out",
            // Transforms
                  "transform",       "scale-100",       "scale-110",
            "rotate-45",        "translate-x-4",
            // Display
                "overflow-hidden", "overflow-auto",   "overflow-scroll",
            "truncate",         "whitespace-nowrap", "break-words",
            // Z-index
                "z-0",             "z-10",
            "z-20",             "z-50",              "z-auto",
        };

        var suggestions = std.ArrayList([]const u8).init(self.allocator);
        errdefer suggestions.deinit();

        // First pass: exact prefix matches
        for (common_utilities) |util| {
            if (std.mem.startsWith(u8, util, utility_name) and utility_name.len > 2) {
                try suggestions.append(util);
                if (suggestions.items.len >= 5) break;
            }
        }

        // Second pass: Levenshtein distance for typos
        if (suggestions.items.len < 3) {
            for (common_utilities) |util| {
                const distance = levenshteinDistance(utility_name, util);
                if (distance <= 2 and distance > 0) {
                    // Check if not already added
                    var already_added = false;
                    for (suggestions.items) |s| {
                        if (std.mem.eql(u8, s, util)) {
                            already_added = true;
                            break;
                        }
                    }
                    if (!already_added) {
                        try suggestions.append(util);
                        if (suggestions.items.len >= 5) break;
                    }
                }
            }
        }

        return suggestions.toOwnedSlice();
    }

    /// Print helpful hint based on utility pattern
    fn printHint(self: *const ErrorReporter, utility_name: []const u8) void {
        const hint: ?[]const u8 = blk: {
            // Centering
            if (std.mem.indexOf(u8, utility_name, "center")) |_| {
                break :blk "To center items, use: 'flex items-center justify-center'";
            }
            // Color patterns
            else if (std.mem.startsWith(u8, utility_name, "color-")) {
                break :blk "Use 'text-{color}' for text color or 'bg-{color}' for background";
            }
            // Spacing patterns
            else if (std.mem.startsWith(u8, utility_name, "padding-") or std.mem.startsWith(u8, utility_name, "margin-")) {
                break :blk "Use shorthand: 'p-4' for padding, 'm-4' for margin";
            }
            // Width/Height
            else if (std.mem.startsWith(u8, utility_name, "width-") or std.mem.startsWith(u8, utility_name, "height-")) {
                break :blk "Use shorthand: 'w-{size}' for width, 'h-{size}' for height";
            }
            // Font size
            else if (std.mem.startsWith(u8, utility_name, "font-size-")) {
                break :blk "Use 'text-{size}' (e.g., text-sm, text-lg, text-xl)";
            }
            // Background
            else if (std.mem.startsWith(u8, utility_name, "background-")) {
                break :blk "Use 'bg-{color}' for background color";
            }
            // Display
            else if (std.mem.eql(u8, utility_name, "display-flex")) {
                break :blk "Use 'flex' instead of 'display-flex'";
            } else if (std.mem.eql(u8, utility_name, "display-grid")) {
                break :blk "Use 'grid' instead of 'display-grid'";
            }
            // Arbitrary values
            else if (std.mem.indexOf(u8, utility_name, "(") != null or std.mem.indexOf(u8, utility_name, ")") != null) {
                break :blk "For arbitrary values, use square brackets: 'w-[100px]' or 'bg-[#ff5733]'";
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

    /// Report arbitrary value syntax error
    pub fn reportArbitraryValueError(
        self: *const ErrorReporter,
        class_name: []const u8,
        error_msg: []const u8,
    ) void {
        self.reportError("Invalid arbitrary value in '{s}': {s}", .{ class_name, error_msg });

        // Provide examples
        if (self.colors_enabled) {
            std.debug.print("  {s}Examples of valid arbitrary values:{s}\n", .{ Color.cyan.code(), Color.reset.code() });
            std.debug.print("    {s}w-[100px]{s}          - Width with pixels\n", .{ Color.green.code(), Color.reset.code() });
            std.debug.print("    {s}h-[calc(100vh-64px)]{s} - Height with calc\n", .{ Color.green.code(), Color.reset.code() });
            std.debug.print("    {s}bg-[#ff5733]{s}      - Background with hex color\n", .{ Color.green.code(), Color.reset.code() });
            std.debug.print("    {s}text-[14px]{s}       - Font size\n", .{ Color.green.code(), Color.reset.code() });
        } else {
            std.debug.print("  Examples of valid arbitrary values:\n", .{});
            std.debug.print("    w-[100px]          - Width with pixels\n", .{});
            std.debug.print("    h-[calc(100vh-64px)] - Height with calc\n", .{});
            std.debug.print("    bg-[#ff5733]      - Background with hex color\n", .{});
            std.debug.print("    text-[14px]       - Font size\n", .{});
        }
    }

    /// Report variant error with suggestions
    pub fn reportVariantError(
        self: *const ErrorReporter,
        variant: []const u8,
        class_name: []const u8,
    ) void {
        self.reportError("Unknown variant '{s}' in '{s}'", .{ variant, class_name });

        const common_variants = [_][]const u8{
            "hover", "focus", "active", "disabled",
            "md", "lg", "xl", "2xl", // Breakpoints
            "dark",         "light", // Dark mode
            "group-hover",  "peer-hover",
            "first",        "last",
            "odd",          "even",
            "focus-within", "focus-visible",
        };

        // Find similar variants
        var found_suggestion = false;
        for (common_variants) |v| {
            const distance = levenshteinDistance(variant, v);
            if (distance <= 2) {
                if (!found_suggestion) {
                    if (self.colors_enabled) {
                        std.debug.print("  {s}Did you mean:{s} {s}{s}{s}\n", .{
                            Color.cyan.code(),
                            Color.reset.code(),
                            Color.green.code(),
                            v,
                            Color.reset.code(),
                        });
                    } else {
                        std.debug.print("  Did you mean: {s}\n", .{v});
                    }
                    found_suggestion = true;
                    break;
                }
            }
        }

        if (!found_suggestion) {
            if (self.colors_enabled) {
                std.debug.print("  {s}Common variants:{s} hover, focus, active, md, lg, dark\n", .{
                    Color.cyan.code(),
                    Color.reset.code(),
                });
            } else {
                std.debug.print("  Common variants: hover, focus, active, md, lg, dark\n", .{});
            }
        }
    }

    /// Report file not found with helpful suggestions
    pub fn reportFileNotFound(
        self: *const ErrorReporter,
        file_path: []const u8,
    ) void {
        self.reportError("File not found: {s}", .{file_path});

        if (self.colors_enabled) {
            std.debug.print("  {s}Check that:{s}\n", .{ Color.cyan.code(), Color.reset.code() });
        } else {
            std.debug.print("  Check that:\n", .{});
        }

        std.debug.print("    - The file path is correct\n", .{});
        std.debug.print("    - The file exists in your project\n", .{});
        std.debug.print("    - You have read permissions\n", .{});
        std.debug.print("    - The file is included in your content configuration\n", .{});
    }

    /// Report performance warning
    pub fn reportPerformanceWarning(
        self: *const ErrorReporter,
        message: []const u8,
        suggestion: []const u8,
    ) void {
        self.reportWarning("{s}", .{message});

        if (self.colors_enabled) {
            std.debug.print("  {s}suggestion:{s} {s}\n", .{
                Color.cyan.code(),
                Color.reset.code(),
                suggestion,
            });
        } else {
            std.debug.print("  suggestion: {s}\n", .{suggestion});
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
