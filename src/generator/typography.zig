const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Font size struct
const FontSize = struct { size: []const u8, line_height: []const u8 };

/// Font size scale
const font_sizes = std.StaticStringMap(FontSize).initComptime(.{
    .{ "xs", FontSize{ .size = "0.75rem", .line_height = "1rem" } },
    .{ "sm", FontSize{ .size = "0.875rem", .line_height = "1.25rem" } },
    .{ "base", FontSize{ .size = "1rem", .line_height = "1.5rem" } },
    .{ "lg", FontSize{ .size = "1.125rem", .line_height = "1.75rem" } },
    .{ "xl", FontSize{ .size = "1.25rem", .line_height = "1.75rem" } },
    .{ "2xl", FontSize{ .size = "1.5rem", .line_height = "2rem" } },
    .{ "3xl", FontSize{ .size = "1.875rem", .line_height = "2.25rem" } },
    .{ "4xl", FontSize{ .size = "2.25rem", .line_height = "2.5rem" } },
    .{ "5xl", FontSize{ .size = "3rem", .line_height = "1" } },
    .{ "6xl", FontSize{ .size = "3.75rem", .line_height = "1" } },
    .{ "7xl", FontSize{ .size = "4.5rem", .line_height = "1" } },
    .{ "8xl", FontSize{ .size = "6rem", .line_height = "1" } },
    .{ "9xl", FontSize{ .size = "8rem", .line_height = "1" } },
});

/// Font weights
const font_weights = std.StaticStringMap([]const u8).initComptime(.{
    .{ "thin", "100" },
    .{ "extralight", "200" },
    .{ "light", "300" },
    .{ "normal", "400" },
    .{ "medium", "500" },
    .{ "semibold", "600" },
    .{ "bold", "700" },
    .{ "extrabold", "800" },
    .{ "black", "900" },
});

/// Generate text utilities (size, color, alignment, etc.)
pub fn generateText(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    var rule = try generator.createRule(parsed);

    // Font size
    if (font_sizes.get(value.?)) |size_info| {
        try rule.addDeclaration(generator.allocator, "font-size", size_info.size);
        try rule.addDeclaration(generator.allocator, "line-height", size_info.line_height);
    }
    // Text alignment
    else if (std.mem.eql(u8, value.?, "left")) {
        try rule.addDeclaration(generator.allocator, "text-align", "left");
    } else if (std.mem.eql(u8, value.?, "center")) {
        try rule.addDeclaration(generator.allocator, "text-align", "center");
    } else if (std.mem.eql(u8, value.?, "right")) {
        try rule.addDeclaration(generator.allocator, "text-align", "right");
    } else if (std.mem.eql(u8, value.?, "justify")) {
        try rule.addDeclaration(generator.allocator, "text-align", "justify");
    } else if (std.mem.eql(u8, value.?, "start")) {
        try rule.addDeclaration(generator.allocator, "text-align", "start");
    } else if (std.mem.eql(u8, value.?, "end")) {
        try rule.addDeclaration(generator.allocator, "text-align", "end");
    }
    // Text color - simplified (using color names)
    else if (std.mem.startsWith(u8, value.?, "white")) {
        try rule.addDeclaration(generator.allocator, "color", "#fff");
    } else if (std.mem.startsWith(u8, value.?, "black")) {
        try rule.addDeclaration(generator.allocator, "color", "#000");
    } else if (std.mem.startsWith(u8, value.?, "gray")) {
        try rule.addDeclaration(generator.allocator, "color", "#6b7280");
    } else if (std.mem.startsWith(u8, value.?, "blue")) {
        try rule.addDeclaration(generator.allocator, "color", "#3b82f6");
    } else if (std.mem.startsWith(u8, value.?, "red")) {
        try rule.addDeclaration(generator.allocator, "color", "#ef4444");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Generate font utilities (weight, family)
pub fn generateFont(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    var rule = try generator.createRule(parsed);

    // Font weight
    if (font_weights.get(value.?)) |weight| {
        try rule.addDeclaration(generator.allocator, "font-weight", weight);
    }
    // Font family
    else if (std.mem.eql(u8, value.?, "sans")) {
        try rule.addDeclaration(generator.allocator, "font-family", "system-ui, sans-serif");
    } else if (std.mem.eql(u8, value.?, "serif")) {
        try rule.addDeclaration(generator.allocator, "font-family", "Georgia, serif");
    } else if (std.mem.eql(u8, value.?, "mono")) {
        try rule.addDeclaration(generator.allocator, "font-family", "monospace");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Text shadow utilities
pub fn generateTextShadow(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const text_shadow_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "sm", "0 1px 2px rgb(0 0 0 / 0.05)" },
        .{ "", "0 1px 3px rgb(0 0 0 / 0.1), 0 1px 2px rgb(0 0 0 / 0.06)" },
        .{ "md", "0 4px 6px rgb(0 0 0 / 0.1), 0 2px 4px rgb(0 0 0 / 0.06)" },
        .{ "lg", "0 10px 15px rgb(0 0 0 / 0.1), 0 4px 6px rgb(0 0 0 / 0.05)" },
        .{ "xl", "0 20px 25px rgb(0 0 0 / 0.1), 0 8px 10px rgb(0 0 0 / 0.04)" },
        .{ "2xl", "0 25px 50px rgb(0 0 0 / 0.25)" },
        .{ "none", "none" },
    });

    const shadow_value = text_shadow_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "text-shadow", shadow_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Font style utilities (italic, not-italic)
pub fn generateFontStyle(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "italic")) {
        try rule.addDeclaration(generator.allocator, "font-style", "italic");
    } else if (std.mem.eql(u8, utility, "not-italic")) {
        try rule.addDeclaration(generator.allocator, "font-style", "normal");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Text decoration utilities (underline, line-through, no-underline, overline)
pub fn generateTextDecoration(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "underline")) {
        try rule.addDeclaration(generator.allocator, "text-decoration-line", "underline");
    } else if (std.mem.eql(u8, utility, "overline")) {
        try rule.addDeclaration(generator.allocator, "text-decoration-line", "overline");
    } else if (std.mem.eql(u8, utility, "line-through")) {
        try rule.addDeclaration(generator.allocator, "text-decoration-line", "line-through");
    } else if (std.mem.eql(u8, utility, "no-underline")) {
        try rule.addDeclaration(generator.allocator, "text-decoration-line", "none");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Text transform utilities (uppercase, lowercase, capitalize, normal-case)
pub fn generateTextTransform(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "uppercase")) {
        try rule.addDeclaration(generator.allocator, "text-transform", "uppercase");
    } else if (std.mem.eql(u8, utility, "lowercase")) {
        try rule.addDeclaration(generator.allocator, "text-transform", "lowercase");
    } else if (std.mem.eql(u8, utility, "capitalize")) {
        try rule.addDeclaration(generator.allocator, "text-transform", "capitalize");
    } else if (std.mem.eql(u8, utility, "normal-case")) {
        try rule.addDeclaration(generator.allocator, "text-transform", "none");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Text overflow utilities (truncate, text-ellipsis, text-clip)
pub fn generateTextOverflow(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "truncate")) {
        // truncate is a shorthand for overflow-hidden + text-ellipsis + whitespace-nowrap
        try rule.addDeclaration(generator.allocator, "overflow", "hidden");
        try rule.addDeclaration(generator.allocator, "text-overflow", "ellipsis");
        try rule.addDeclaration(generator.allocator, "white-space", "nowrap");
    } else if (std.mem.eql(u8, utility, "text-ellipsis")) {
        try rule.addDeclaration(generator.allocator, "text-overflow", "ellipsis");
    } else if (std.mem.eql(u8, utility, "text-clip")) {
        try rule.addDeclaration(generator.allocator, "text-overflow", "clip");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Line height (leading) scale
const line_heights = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "1" },
    .{ "tight", "1.25" },
    .{ "snug", "1.375" },
    .{ "normal", "1.5" },
    .{ "relaxed", "1.625" },
    .{ "loose", "2" },
    .{ "3", ".75rem" },
    .{ "4", "1rem" },
    .{ "5", "1.25rem" },
    .{ "6", "1.5rem" },
    .{ "7", "1.75rem" },
    .{ "8", "2rem" },
    .{ "9", "2.25rem" },
    .{ "10", "2.5rem" },
});

/// Line height utilities (leading-*)
pub fn generateLineHeight(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const line_height = line_heights.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "line-height", line_height);
    try generator.rules.append(generator.allocator, rule);
}

/// Letter spacing (tracking) scale
const letter_spacings = std.StaticStringMap([]const u8).initComptime(.{
    .{ "tighter", "-0.05em" },
    .{ "tight", "-0.025em" },
    .{ "normal", "0em" },
    .{ "wide", "0.025em" },
    .{ "wider", "0.05em" },
    .{ "widest", "0.1em" },
});

/// Letter spacing utilities (tracking-*)
pub fn generateLetterSpacing(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const letter_spacing = letter_spacings.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "letter-spacing", letter_spacing);
    try generator.rules.append(generator.allocator, rule);
}

/// Whitespace utilities (whitespace-normal, whitespace-nowrap, whitespace-pre, etc.)
pub fn generateWhitespace(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    var rule = try generator.createRule(parsed);

    if (std.mem.eql(u8, value.?, "normal")) {
        try rule.addDeclaration(generator.allocator, "white-space", "normal");
    } else if (std.mem.eql(u8, value.?, "nowrap")) {
        try rule.addDeclaration(generator.allocator, "white-space", "nowrap");
    } else if (std.mem.eql(u8, value.?, "pre")) {
        try rule.addDeclaration(generator.allocator, "white-space", "pre");
    } else if (std.mem.eql(u8, value.?, "pre-line")) {
        try rule.addDeclaration(generator.allocator, "white-space", "pre-line");
    } else if (std.mem.eql(u8, value.?, "pre-wrap")) {
        try rule.addDeclaration(generator.allocator, "white-space", "pre-wrap");
    } else if (std.mem.eql(u8, value.?, "break-spaces")) {
        try rule.addDeclaration(generator.allocator, "white-space", "break-spaces");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Text wrap utilities (text-wrap, text-nowrap, text-balance, text-pretty)
pub fn generateTextWrap(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "text-wrap")) {
        try rule.addDeclaration(generator.allocator, "text-wrap", "wrap");
    } else if (std.mem.eql(u8, utility, "text-nowrap")) {
        try rule.addDeclaration(generator.allocator, "text-wrap", "nowrap");
    } else if (std.mem.eql(u8, utility, "text-balance")) {
        try rule.addDeclaration(generator.allocator, "text-wrap", "balance");
    } else if (std.mem.eql(u8, utility, "text-pretty")) {
        try rule.addDeclaration(generator.allocator, "text-wrap", "pretty");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Vertical align utilities
pub fn generateVerticalAlign(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    var rule = try generator.createRule(parsed);

    if (std.mem.eql(u8, value.?, "baseline")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "baseline");
    } else if (std.mem.eql(u8, value.?, "top")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "top");
    } else if (std.mem.eql(u8, value.?, "middle")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "middle");
    } else if (std.mem.eql(u8, value.?, "bottom")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "bottom");
    } else if (std.mem.eql(u8, value.?, "text-top")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "text-top");
    } else if (std.mem.eql(u8, value.?, "text-bottom")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "text-bottom");
    } else if (std.mem.eql(u8, value.?, "sub")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "sub");
    } else if (std.mem.eql(u8, value.?, "super")) {
        try rule.addDeclaration(generator.allocator, "vertical-align", "super");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Word break utilities
pub fn generateWordBreak(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "break-normal")) {
        try rule.addDeclaration(generator.allocator, "overflow-wrap", "normal");
        try rule.addDeclaration(generator.allocator, "word-break", "normal");
    } else if (std.mem.eql(u8, utility, "break-words")) {
        try rule.addDeclaration(generator.allocator, "overflow-wrap", "break-word");
    } else if (std.mem.eql(u8, utility, "break-all")) {
        try rule.addDeclaration(generator.allocator, "word-break", "break-all");
    } else if (std.mem.eql(u8, utility, "break-keep")) {
        try rule.addDeclaration(generator.allocator, "word-break", "keep-all");
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Text indent scale
const text_indent_scale = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0" },
    .{ "px", "1px" },
    .{ "0.5", "0.125rem" },
    .{ "1", "0.25rem" },
    .{ "1.5", "0.375rem" },
    .{ "2", "0.5rem" },
    .{ "2.5", "0.625rem" },
    .{ "3", "0.75rem" },
    .{ "4", "1rem" },
    .{ "5", "1.25rem" },
    .{ "6", "1.5rem" },
    .{ "8", "2rem" },
    .{ "10", "2.5rem" },
    .{ "12", "3rem" },
    .{ "16", "4rem" },
});

/// Generate text-indent utilities
pub fn generateTextIndent(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const indent_value = text_indent_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "text-indent", indent_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate hyphens utilities
pub fn generateHyphens(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const css_value = if (std.mem.eql(u8, value.?, "none"))
        "none"
    else if (std.mem.eql(u8, value.?, "manual"))
        "manual"
    else if (std.mem.eql(u8, value.?, "auto"))
        "auto"
    else
        return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "hyphens", css_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate text-align start/end utilities
pub fn generateTextAlign(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const css_value = if (std.mem.eql(u8, value.?, "start"))
        "start"
    else if (std.mem.eql(u8, value.?, "end"))
        "end"
    else if (std.mem.eql(u8, value.?, "left"))
        "left"
    else if (std.mem.eql(u8, value.?, "center"))
        "center"
    else if (std.mem.eql(u8, value.?, "right"))
        "right"
    else if (std.mem.eql(u8, value.?, "justify"))
        "justify"
    else
        return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "text-align", css_value);
    try generator.rules.append(generator.allocator, rule);
}
