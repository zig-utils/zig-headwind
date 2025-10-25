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
