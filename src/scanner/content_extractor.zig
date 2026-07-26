const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");
const simd = @import("../utils/simd.zig");
const config_schema = @import("../config/schema.zig");
const grouped_syntax = @import("../parser/grouped_syntax.zig");

/// Extract CSS class names from various file formats
pub const ContentExtractor = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    attributify_config: config_schema.AttributifyConfig,
    grouped_syntax_config: config_schema.GroupedSyntaxConfig,

    pub fn init(allocator: std.mem.Allocator, io: std.Io) ContentExtractor {
        return .{
            .allocator = allocator,
            .io = io,
            .attributify_config = .{},
            .grouped_syntax_config = .{},
        };
    }

    pub fn initWithConfig(
        allocator: std.mem.Allocator,
        io: std.Io,
        attributify_config: config_schema.AttributifyConfig,
        grouped_syntax_config: config_schema.GroupedSyntaxConfig,
    ) ContentExtractor {
        return .{
            .allocator = allocator,
            .io = io,
            .attributify_config = attributify_config,
            .grouped_syntax_config = grouped_syntax_config,
        };
    }

    /// Extract class names from a file
    pub fn extractFromFile(self: *ContentExtractor, file_path: []const u8) ![][]const u8 {
        // Read file content
        const content = try std.Io.Dir.cwd().readFileAlloc(
            self.io,
            file_path,
            self.allocator,
            std.Io.Limit.limited(10 * 1024 * 1024), // 10MB max
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
    /// Also extracts attributify mode utilities and grouped syntax patterns
    /// OPTIMIZED: Uses SIMD for pattern matching
    fn extractFromHTML(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        var classes: std.ArrayList([]const u8) = .empty;
        errdefer classes.deinit(self.allocator);

        var i: usize = 0;
        while (i < content.len) {
            // Look for tag start
            if (content[i] == '<') {
                i += 1;
                // Skip comments and closing tags
                if (i < content.len and (content[i] == '!' or content[i] == '/')) {
                    // Skip to end of tag
                    while (i < content.len and content[i] != '>') i += 1;
                    if (i < content.len) i += 1;
                    continue;
                }

                // Skip tag name
                while (i < content.len and !std.ascii.isWhitespace(content[i]) and content[i] != '>' and content[i] != '/') {
                    i += 1;
                }

                // Parse attributes until tag closes
                while (i < content.len and content[i] != '>') {
                    // Skip whitespace
                    while (i < content.len and std.ascii.isWhitespace(content[i])) i += 1;

                    if (i >= content.len or content[i] == '>' or content[i] == '/') break;

                    // Parse attribute name
                    const attr_start = i;
                    while (i < content.len and content[i] != '=' and content[i] != '>' and !std.ascii.isWhitespace(content[i]) and content[i] != '/') {
                        i += 1;
                    }
                    const attr_name = content[attr_start..i];

                    // Skip whitespace around =
                    while (i < content.len and std.ascii.isWhitespace(content[i])) i += 1;

                    var attr_value: ?[]const u8 = null;
                    if (i < content.len and content[i] == '=') {
                        i += 1;
                        // Skip whitespace
                        while (i < content.len and std.ascii.isWhitespace(content[i])) i += 1;

                        if (i < content.len) {
                            const quote = content[i];
                            if (quote == '"' or quote == '\'') {
                                i += 1;
                                const val_start = i;
                                // Find closing quote using SIMD
                                if (simd.simdIndexOfScalar(content[i..], quote)) |quote_offset| {
                                    attr_value = content[val_start .. i + quote_offset];
                                    i += quote_offset + 1;
                                }
                            } else {
                                // Unquoted attribute value
                                const val_start = i;
                                while (i < content.len and !std.ascii.isWhitespace(content[i]) and content[i] != '>') {
                                    i += 1;
                                }
                                attr_value = content[val_start..i];
                            }
                        }
                    }

                    // Process attribute
                    if (std.mem.eql(u8, attr_name, "class") or std.mem.eql(u8, attr_name, "className")) {
                        if (attr_value) |val| {
                            try self.splitClasses(val, &classes);
                        }
                    } else if (self.attributify_config.enabled) {
                        // Check for attributify mode utilities
                        try self.extractAttributifyClasses(attr_name, attr_value, &classes);
                    }
                }
            } else {
                i += 1;
            }
        }

        // Process grouped syntax if enabled
        if (self.grouped_syntax_config.enabled) {
            return try self.processGroupedSyntax(classes);
        }

        return classes.toOwnedSlice(self.allocator);
    }

    /// Extract utilities from attributify mode attributes
    /// Supports variant syntax: hw-hover:bg="blue-500" → hover:bg-blue-500
    fn extractAttributifyClasses(
        self: *ContentExtractor,
        attr_name: []const u8,
        attr_value: ?[]const u8,
        classes: *std.ArrayList([]const u8),
    ) !void {
        // Skip ignored attributes
        for (self.attributify_config.ignoreAttributes) |ignored| {
            if (std.mem.eql(u8, attr_name, ignored)) return;
            // Handle wildcards like "data-*" and "aria-*"
            if (std.mem.endsWith(u8, ignored, "*")) {
                const prefix_str = ignored[0 .. ignored.len - 1];
                if (std.mem.startsWith(u8, attr_name, prefix_str)) return;
            }
        }

        // Check for prefix requirement and extract actual utility name
        const configured_prefix = self.attributify_config.prefix;
        var utility_name = attr_name;

        if (configured_prefix.len > 0) {
            if (!std.mem.startsWith(u8, attr_name, configured_prefix)) return;
            // Strip the configured prefix (e.g., "hw-" from "hw-flex")
            utility_name = attr_name[configured_prefix.len..];
        }

        // Check for variant syntax: hover:bg, md:flex, etc.
        // Format: [variant:]utility where variant is optional
        var variant: ?[]const u8 = null;
        var base_utility = utility_name;

        if (simd.simdIndexOfScalar(utility_name, ':')) |colon_pos| {
            // Check if the part before colon is a known variant
            const potential_variant = utility_name[0..colon_pos];
            if (isKnownVariant(potential_variant)) {
                variant = potential_variant;
                base_utility = utility_name[colon_pos + 1 ..];
            }
        }

        // Check if attribute name is a known utility prefix
        var is_utility_prefix = false;
        for (self.attributify_config.prefixes) |prefix| {
            if (std.mem.eql(u8, base_utility, prefix)) {
                is_utility_prefix = true;
                break;
            }
        }

        // In strict mode, only process known prefixes
        if (self.attributify_config.strict and !is_utility_prefix) return;

        // Handle boolean/valueless attributes: <div hw-flex> → flex
        if (attr_value == null or attr_value.?.len == 0) {
            if (variant) |v| {
                const class_name = try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ v, base_utility });
                try classes.append(self.allocator, class_name);
            } else {
                const class_name = try self.allocator.dupe(u8, base_utility);
                try classes.append(self.allocator, class_name);
            }
            return;
        }

        const value = attr_value.?;

        // Handle "~" which means use the attribute name as-is
        // <div flex="~ col"> → flex flex-col
        var iter = std.mem.splitScalar(u8, value, ' ');
        while (iter.next()) |part| {
            const trimmed = string_utils.trim(part);
            if (trimmed.len == 0) continue;

            if (std.mem.eql(u8, trimmed, "~")) {
                // Just the utility itself
                if (variant) |v| {
                    const class_name = try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ v, base_utility });
                    try classes.append(self.allocator, class_name);
                } else {
                    const class_name = try self.allocator.dupe(u8, base_utility);
                    try classes.append(self.allocator, class_name);
                }
            } else {
                // Combine utility with value: attr="value" → [variant:]utility-value
                if (variant) |v| {
                    const class_name = try std.fmt.allocPrint(self.allocator, "{s}:{s}-{s}", .{ v, base_utility, trimmed });
                    try classes.append(self.allocator, class_name);
                } else {
                    const class_name = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ base_utility, trimmed });
                    try classes.append(self.allocator, class_name);
                }
            }
        }
    }

    /// Check if a string is a known variant prefix
    fn isKnownVariant(str: []const u8) bool {
        const variants = [_][]const u8{
            // Responsive
            "sm",            "md",            "lg",            "xl",           "2xl",
            // State
            "hover",         "focus",         "active",        "visited",      "disabled",
            "enabled",       "checked",       "indeterminate", "default",      "required",
            "valid",         "invalid",       "in-range",      "out-of-range", "placeholder-shown",
            "autofill",      "read-only",
            // First/last/odd/even
                "first",         "last",         "odd",
            "even",          "only",          "first-of-type", "last-of-type", "empty",
            // Focus
            "focus-within",  "focus-visible",
            // Dark mode
            "dark",
            // Print
                     "print",
            // Motion
                   "motion-safe",
            "motion-reduce",
            // Contrast
            "contrast-more", "contrast-less",
            // Content
            "before",       "after",
            "selection",     "marker",        "file",
            // RTL/LTR
                     "rtl",          "ltr",
            // Orientation
            "portrait",      "landscape",
            // Group/Peer
                "group-hover",   "group-focus",  "peer-hover",
            "peer-focus",
            // Container queries
               "@sm",           "@md",           "@lg",          "@xl",
            "@2xl",
        };

        for (variants) |v| {
            if (std.mem.eql(u8, str, v)) return true;
        }
        return false;
    }

    /// Process grouped syntax patterns in extracted classes
    fn processGroupedSyntax(self: *ContentExtractor, classes: std.ArrayList([]const u8)) ![][]const u8 {
        var result: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (result.items) |item| self.allocator.free(item);
            result.deinit(self.allocator);
        }

        var parser = grouped_syntax.GroupedSyntaxParser.init(self.allocator);

        for (classes.items) |class| {
            if (try parser.parseAndExpand(class)) |expanded| {
                // Free the original class since we're replacing it
                self.allocator.free(class);
                // Add expanded classes (they're already allocated)
                for (expanded) |exp_class| {
                    try result.append(self.allocator, exp_class);
                }
                self.allocator.free(expanded);
            } else {
                // Not grouped syntax, keep as-is
                try result.append(self.allocator, class);
            }
        }

        // Don't deinit classes since we've either freed or moved all items
        var mutable_classes = classes;
        mutable_classes.deinit(self.allocator);

        return try result.toOwnedSlice(self.allocator);
    }

    /// Extract from JSX/TSX (className="..." and className={...})
    /// OPTIMIZED: Uses SIMD for pattern matching
    fn extractFromJSX(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        var classes: std.ArrayList([]const u8) = .empty;
        errdefer classes.deinit(self.allocator);

        var i: usize = 0;
        while (i < content.len) {
            // OPTIMIZATION: Use SIMD to find 'c' character
            const remaining = content[i..];
            if (simd.simdIndexOfScalar(remaining, 'c')) |offset| {
                i += offset;

                // Look for className="..." or className='...'
                if (i + 9 <= content.len and simd.simdStartsWith(content[i..], "className")) {
                    i += 9;

                    // Skip whitespace and =
                    while (i < content.len and (std.ascii.isWhitespace(content[i]) or content[i] == '=')) {
                        i += 1;
                    }

                    if (i >= content.len) break;

                    if (content[i] == '"' or content[i] == '\'') {
                        // String literal - use SIMD to find closing quote
                        const quote = content[i];
                        i += 1;
                        const start = i;

                        if (simd.simdIndexOfScalar(content[i..], quote)) |quote_offset| {
                            i += quote_offset;

                            if (i > start) {
                                const class_string = content[start..i];
                                try self.splitClasses(class_string, &classes);
                            }
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
                else if (i + 6 <= content.len and simd.simdStartsWith(content[i..], "class=")) {
                    i += 6;

                    while (i < content.len and (std.ascii.isWhitespace(content[i]) or content[i] == '=')) {
                        i += 1;
                    }

                    if (i < content.len and (content[i] == '"' or content[i] == '\'')) {
                        const quote = content[i];
                        i += 1;
                        const start = i;

                        if (simd.simdIndexOfScalar(content[i..], quote)) |quote_offset| {
                            i += quote_offset;

                            if (i > start) {
                                const class_string = content[start..i];
                                try self.splitClasses(class_string, &classes);
                            }
                        }
                    }
                } else {
                    i += 1;
                }
            } else {
                // No more 'c' characters
                break;
            }
        }

        return classes.toOwnedSlice(self.allocator);
    }

    /// Extract from Vue templates
    fn extractFromVue(self: *ContentExtractor, content: []const u8) ![][]const u8 {
        // For Vue, we need to extract from <template> section
        // This is a simplified version - look for class and :class
        var classes: std.ArrayList([]const u8) = .empty;
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
    /// Respects brackets - does not split inside [...] patterns
    fn splitClasses(self: *ContentExtractor, class_string: []const u8, classes: *std.ArrayList([]const u8)) !void {
        const trimmed = string_utils.trim(class_string);
        if (trimmed.len == 0) return;

        var i: usize = 0;
        var start: usize = 0;
        var bracket_depth: i32 = 0;

        while (i < trimmed.len) {
            const c = trimmed[i];

            if (c == '[') {
                bracket_depth += 1;
                i += 1;
            } else if (c == ']') {
                if (bracket_depth > 0) bracket_depth -= 1;
                i += 1;
            } else if (std.ascii.isWhitespace(c) and bracket_depth == 0) {
                // Only split on whitespace when not inside brackets
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
    var extractor = ContentExtractor.init(allocator, std.testing.io);

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
    var extractor = ContentExtractor.init(allocator, std.testing.io);

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

test "extractFromHTML with attributify mode" {
    const allocator = std.testing.allocator;
    var extractor = ContentExtractor.initWithConfig(
        allocator,
        std.testing.io,
        .{ .enabled = true, .strict = true },
        .{},
    );

    const html =
        \\<div flex="~ col" items="center" bg="blue-500">
        \\  <span text="white lg">Hello</span>
        \\</div>
    ;

    const classes = try extractor.extractFromHTML(html);
    defer {
        for (classes) |class| allocator.free(class);
        allocator.free(classes);
    }

    // Should extract: flex, flex-col, items-center, bg-blue-500, text-white, text-lg
    try std.testing.expect(classes.len >= 5);
}

test "extractFromHTML with grouped syntax" {
    const allocator = std.testing.allocator;
    var extractor = ContentExtractor.initWithConfig(
        allocator,
        std.testing.io,
        .{},
        .{ .enabled = true },
    );

    const html =
        \\<div class="flex[col jc-center ai-center] bg:black">
        \\</div>
    ;

    const classes = try extractor.extractFromHTML(html);
    defer {
        for (classes) |class| allocator.free(class);
        allocator.free(classes);
    }

    // flex[col jc-center ai-center] → flex-col, justify-center, items-center
    // bg:black → bg-black
    try std.testing.expect(classes.len >= 4);
}

test "extractFromHTML with reset utility" {
    const allocator = std.testing.allocator;
    var extractor = ContentExtractor.initWithConfig(
        allocator,
        std.testing.io,
        .{},
        .{ .enabled = true },
    );

    const html =
        \\<main class="reset:meyer">
        \\</main>
    ;

    const classes = try extractor.extractFromHTML(html);
    defer {
        for (classes) |class| allocator.free(class);
        allocator.free(classes);
    }

    try std.testing.expectEqual(@as(usize, 1), classes.len);
    try std.testing.expectEqualStrings("reset-meyer", classes[0]);
}

test "extractFromHTML with attributify variant syntax" {
    const allocator = std.testing.allocator;
    var extractor = ContentExtractor.initWithConfig(
        allocator,
        std.testing.io,
        .{ .enabled = true, .strict = false, .prefix = "hw-" },
        .{},
    );

    const html =
        \\<div hw-hover:bg="blue-600" hw-md:flex="col">
        \\</div>
    ;

    const classes = try extractor.extractFromHTML(html);
    defer {
        for (classes) |class| allocator.free(class);
        allocator.free(classes);
    }

    // hw-hover:bg="blue-600" → hover:bg-blue-600
    // hw-md:flex="col" → md:flex-col
    try std.testing.expectEqual(@as(usize, 2), classes.len);
    try std.testing.expectEqualStrings("hover:bg-blue-600", classes[0]);
    try std.testing.expectEqualStrings("md:flex-col", classes[1]);
}
