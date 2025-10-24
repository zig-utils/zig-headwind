const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");
const colors = @import("colors.zig");

/// Box shadow values
const shadow_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "sm", "0 1px 2px 0 rgb(0 0 0 / 0.05)" },
    .{ "", "0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)" },
    .{ "md", "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)" },
    .{ "lg", "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)" },
    .{ "xl", "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)" },
    .{ "2xl", "0 25px 50px -12px rgb(0 0 0 / 0.25)" },
    .{ "inner", "inset 0 2px 4px 0 rgb(0 0 0 / 0.05)" },
    .{ "none", "0 0 #0000" },
});

/// Generate box-shadow utilities
pub fn generateShadow(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const shadow_value = if (value) |v|
        shadow_values.get(v) orelse return
    else
        shadow_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "box-shadow", shadow_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate shadow color utilities
pub fn generateShadowColor(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const color_info = colors.parseColorShade(value.?) orelse return;
    const color_value = colors.getColorValue(color_info.color, color_info.shade) orelse return;

    var rule = try generator.createRule(parsed);

    // Set --tw-shadow-color custom property
    try rule.addDeclaration(generator.allocator, "--tw-shadow-color", color_value);
    try rule.addDeclaration(generator.allocator, "--tw-shadow", "var(--tw-shadow-colored)");

    try generator.rules.append(generator.allocator, rule);
}
