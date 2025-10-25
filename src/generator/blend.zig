const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Blend mode values (shared between mix-blend-mode and background-blend-mode)
const blend_modes = std.StaticStringMap([]const u8).initComptime(.{
    .{ "normal", "normal" },
    .{ "multiply", "multiply" },
    .{ "screen", "screen" },
    .{ "overlay", "overlay" },
    .{ "darken", "darken" },
    .{ "lighten", "lighten" },
    .{ "color-dodge", "color-dodge" },
    .{ "color-burn", "color-burn" },
    .{ "hard-light", "hard-light" },
    .{ "soft-light", "soft-light" },
    .{ "difference", "difference" },
    .{ "exclusion", "exclusion" },
    .{ "hue", "hue" },
    .{ "saturation", "saturation" },
    .{ "color", "color" },
    .{ "luminosity", "luminosity" },
    .{ "plus-darker", "plus-darker" },
    .{ "plus-lighter", "plus-lighter" },
});

/// Generate mix-blend-mode utilities
pub fn generateMixBlend(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const blend_value = blend_modes.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "mix-blend-mode", blend_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate background-blend-mode utilities
pub fn generateBgBlend(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const blend_value = blend_modes.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "background-blend-mode", blend_value);
    try generator.rules.append(generator.allocator, rule);
}
