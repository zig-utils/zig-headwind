const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Gradient directions for linear gradients
const gradient_directions = std.StaticStringMap([]const u8).initComptime(.{
    .{ "to-t", "to top" },
    .{ "to-tr", "to top right" },
    .{ "to-r", "to right" },
    .{ "to-br", "to bottom right" },
    .{ "to-b", "to bottom" },
    .{ "to-bl", "to bottom left" },
    .{ "to-l", "to left" },
    .{ "to-tl", "to top left" },
});

/// Generate background gradient utilities (bg-gradient-*)
pub fn generateBackgroundGradient(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const direction = gradient_directions.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "background-image", try std.fmt.allocPrint(
        generator.allocator,
        "linear-gradient({s}, var(--tw-gradient-stops))",
        .{direction},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate gradient from color (from-*)
pub fn generateGradientFrom(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const colors_module = @import("colors.zig");
    const color_info = colors_module.parseColorShade(value.?) orelse return;
    const color_value = colors_module.getColorValue(color_info.color, color_info.shade) orelse return;

    var rule = try generator.createRule(parsed);

    // Set CSS variable for gradient start
    try rule.addDeclaration(
        generator.allocator,
        "--tw-gradient-from",
        color_value,
    );
    try rule.addDeclaration(
        generator.allocator,
        "--tw-gradient-to",
        "transparent",
    );
    try rule.addDeclaration(
        generator.allocator,
        "--tw-gradient-stops",
        "var(--tw-gradient-from), var(--tw-gradient-to)",
    );

    try generator.rules.append(generator.allocator, rule);
}

/// Generate gradient via color (via-*)
pub fn generateGradientVia(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const colors_module = @import("colors.zig");
    const color_info = colors_module.parseColorShade(value.?) orelse return;
    const color_value = colors_module.getColorValue(color_info.color, color_info.shade) orelse return;

    var rule = try generator.createRule(parsed);

    try rule.addDeclaration(
        generator.allocator,
        "--tw-gradient-stops",
        try std.fmt.allocPrint(
            generator.allocator,
            "var(--tw-gradient-from), {s}, var(--tw-gradient-to)",
            .{color_value},
        ),
    );

    try generator.rules.append(generator.allocator, rule);
}

/// Generate gradient to color (to-*)
pub fn generateGradientTo(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const colors_module = @import("colors.zig");
    const color_info = colors_module.parseColorShade(value.?) orelse return;
    const color_value = colors_module.getColorValue(color_info.color, color_info.shade) orelse return;

    var rule = try generator.createRule(parsed);

    try rule.addDeclaration(
        generator.allocator,
        "--tw-gradient-to",
        color_value,
    );

    try generator.rules.append(generator.allocator, rule);
}

/// Generate radial gradient utilities
pub fn generateRadialGradient(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    _ = value;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(
        generator.allocator,
        "background-image",
        "radial-gradient(circle, var(--tw-gradient-stops))",
    );
    try generator.rules.append(generator.allocator, rule);
}

/// Generate conic gradient utilities
pub fn generateConicGradient(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    _ = value;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(
        generator.allocator,
        "background-image",
        "conic-gradient(from 0deg, var(--tw-gradient-stops))",
    );
    try generator.rules.append(generator.allocator, rule);
}
