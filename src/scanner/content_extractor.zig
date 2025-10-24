const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");

/// Extract CSS class names from various file formats
pub const ContentExtractor = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ContentExtractor {
        return .{ .allocator = allocator };
    }

    /// Extract class names from a file
    pub fn extractFromFile(self: *ContentExtractor, file_path: []const u8) ![][]const u8 {
        // Read file content
        const content = try std.fs.cwd().readFileAlloc(
            self.allocator,
            file_path,
            10 * 1024 * 1024, // 10MB max
        );
        defer self.allocator.free(content);

        // Detect file type and extract accordingly
        const ext = getFileExtension(file_path);

        if (std.mem.eql(u8, ext, ".html") or std.mem.eql(u8, ext, ".htm")) {
            return try self.extractFromHTML(content);
        } else if (std.mem.eql(u8, ext, ".jsx") or std.mem.eql(u8, ext, ".tsx")) {
            return try self.extractFromJSX(content);
        } else if (std.mem.eql(u8, ext, ".vue")) {
            return try self.extractFromVue(content);
        } else if (std.mem.eql(u8, ext, ".svelte")) {
            return try self.extractFromSvelte(content);
        } else if (std.mem.eql(u8, ext, ".js") or std.mem.eql(u8, ext, ".ts")) {
            return try self.extractFromJS(content);
        }

        // Default: try to find className patterns
        return try self.extractFromJSX(content);
    }

    /// Extract from HTML (class="..." and class='...')
    fn extractFromHTML(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        var classes: std.ArrayList([]const u8) = .{};
        errdefer classes.deinit(self.allocator);

        var i: usize = 0;
        while (i < content.len) {
            // Look for class="..." or class='...'
            if (i + 6 < content.len and std.mem.eql(u8, content[i .. i + 6], "class=")) {
                i += 6;

                // Skip whitespace
                while (i < content.len and std.ascii.isWhitespace(content[i])) {
                    i += 1;
                }

                if (i >= content.len) break;

                const quote = content[i];
                if (quote != '"' and quote != '\'') {
                    continue;
                }

                i += 1; // Skip opening quote
                const start = i;

                // Find closing quote
                while (i < content.len and content[i] != quote) {
                    i += 1;
                }

                if (i > start) {
                    const class_string = content[start..i];
                    try self.splitClasses(class_string, &classes);
                }
            }
            i += 1;
        }

        return classes.toOwnedSlice(self.allocator);
    }

    /// Extract from JSX/TSX (className="..." and className={...})
    fn extractFromJSX(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        var classes: std.ArrayList([]const u8) = .{};
        errdefer classes.deinit(self.allocator);

        var i: usize = 0;
        while (i < content.len) {
            // Look for className="..." or className='...'
            if (i + 9 < content.len and std.mem.eql(u8, content[i .. i + 9], "className")) {
                i += 9;

                // Skip whitespace and =
                while (i < content.len and (std.ascii.isWhitespace(content[i]) or content[i] == '=')) {
                    i += 1;
                }

                if (i >= content.len) break;

                if (content[i] == '"' or content[i] == '\'') {
                    // String literal
                    const quote = content[i];
                    i += 1;
                    const start = i;

                    while (i < content.len and content[i] != quote) {
                        i += 1;
                    }

                    if (i > start) {
                        const class_string = content[start..i];
                        try self.splitClasses(class_string, &classes);
                    }
                } else if (content[i] == '{') {
                    // Template expression - basic support for simple cases
                    i += 1;
                    const start = i;
                    var brace_count: usize = 1;

                    while (i < content.len and brace_count > 0) {
                        if (content[i] == '{') brace_count += 1;
                        if (content[i] == '}') brace_count -= 1;
                        i += 1;
                    }

                    // Try to extract string literals from the expression
                    const expr = content[start .. i - 1];
                    try self.extractFromExpression(expr, &classes);
                }
            }

            // Also look for class="..." (in JSX)
            if (i + 6 < content.len and std.mem.eql(u8, content[i .. i + 6], "class=")) {
                i += 6;

                while (i < content.len and (std.ascii.isWhitespace(content[i]) or content[i] == '=')) {
                    i += 1;
                }

                if (i < content.len and (content[i] == '"' or content[i] == '\'')) {
                    const quote = content[i];
                    i += 1;
                    const start = i;

                    while (i < content.len and content[i] != quote) {
                        i += 1;
                    }

                    if (i > start) {
                        const class_string = content[start..i];
                        try self.splitClasses(class_string, &classes);
                    }
                }
            }

            i += 1;
        }

        return classes.toOwnedSlice(self.allocator);
    }

    /// Extract from Vue templates
    fn extractFromVue(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        // For Vue, we need to extract from <template> section
        // This is a simplified version - look for class and :class
        var classes: std.ArrayList([]const u8) = .{};
        errdefer classes.deinit(self.allocator);

        var i: usize = 0;
        while (i < content.len) {
            // Look for class="..." or :class="..."
            const has_colon = i + 1 < content.len and content[i] == ':';
            const offset: usize = if (has_colon) 7 else 6;

            if (i + offset < content.len) {
                const check_str = if (has_colon) content[i .. i + 7] else content[i .. i + 6];
                if (std.mem.eql(u8, check_str, if (has_colon) ":class=" else "class=")) {
                    i += offset;

                    while (i < content.len and std.ascii.isWhitespace(content[i])) {
                        i += 1;
                    }

                    if (i < content.len and (content[i] == '"' or content[i] == '\'')) {
                        const quote = content[i];
                        i += 1;
                        const start = i;

                        while (i < content.len and content[i] != quote) {
                            i += 1;
                        }

                        if (i > start) {
                            const class_string = content[start..i];
                            try self.splitClasses(class_string, &classes);
                        }
                    }
                }
            }
            i += 1;
        }

        return classes.toOwnedSlice(self.allocator);
    }

    /// Extract from Svelte
    fn extractFromSvelte(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        // Svelte uses class:name syntax and regular class attributes
        return self.extractFromHTML(content);
    }

    /// Extract from plain JS/TS (looking for string literals)
    fn extractFromJS(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        return self.extractFromJSX(content);
    }

    /// Extract class names from template expressions
    fn extractFromExpression(self: *ContentExtractor, expr: []const u8, classes: *std.ArrayList([]const u8)) !void {
        var i: usize = 0;
        while (i < expr.len) {
            if (expr[i] == '"' or expr[i] == '\'' or expr[i] == '`') {
                const quote = expr[i];
                i += 1;
                const start = i;

                while (i < expr.len and expr[i] != quote) {
                    i += 1;
                }

                if (i > start) {
                    const class_string = expr[start..i];
                    try self.splitClasses(class_string, classes);
                }
            }
            i += 1;
        }
    }

    /// Split space-separated class names
    fn splitClasses(self: *ContentExtractor, class_string: []const u8, classes: *std.ArrayList([]const u8)) !void {
        const trimmed = string_utils.trim(class_string);
        if (trimmed.len == 0) return;

        var i: usize = 0;
        var start: usize = 0;

        while (i < trimmed.len) {
            if (std.ascii.isWhitespace(trimmed[i])) {
                if (i > start) {
                    const class_name = try self.allocator.dupe(u8, trimmed[start..i]);
                    try classes.append(self.allocator, class_name);
                }
                // Skip multiple whitespace
                while (i < trimmed.len and std.ascii.isWhitespace(trimmed[i])) {
                    i += 1;
                }
                start = i;
            } else {
                i += 1;
            }
        }

        // Add final class if any
        if (start < trimmed.len) {
            const class_name = try self.allocator.dupe(u8, trimmed[start..]);
            try classes.append(self.allocator, class_name);
        }
    }
};

fn getFileExtension(path: []const u8) []const u8 {
    var i: usize = path.len;
    while (i > 0) {
        i -= 1;
        if (path[i] == '.') {
            return path[i..];
        }
        if (path[i] == '/' or path[i] == '\\') {
            return "";
        }
    }
    return "";
}

test "extractFromHTML" {
    const allocator = std.testing.allocator;
    var extractor = ContentExtractor.init(allocator);

    const html =
        \\<div class="flex items-center justify-between">
        \\  <span class='text-blue-500 font-bold'>Hello</span>
        \\</div>
    ;

    const classes = try extractor.extractFromHTML(html);
    defer {
        for (classes) |class| allocator.free(class);
        allocator.free(classes);
    }

    try std.testing.expectEqual(@as(usize, 5), classes.len);
    try std.testing.expectEqualStrings("flex", classes[0]);
    try std.testing.expectEqualStrings("items-center", classes[1]);
}

test "extractFromJSX" {
    const allocator = std.testing.allocator;
    var extractor = ContentExtractor.init(allocator);

    const jsx =
        \\<div className="flex items-center">
        \\  <Button className='bg-blue-500 text-white' />
        \\</div>
    ;

    const classes = try extractor.extractFromJSX(jsx);
    defer {
        for (classes) |class| allocator.free(class);
        allocator.free(classes);
    }

    try std.testing.expect(classes.len >= 4);
}
