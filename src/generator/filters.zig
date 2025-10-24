const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Blur values
const blur_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "0" },
    .{ "sm", "4px" },
    .{ "", "8px" },
    .{ "md", "12px" },
    .{ "lg", "16px" },
    .{ "xl", "24px" },
    .{ "2xl", "40px" },
    .{ "3xl", "64px" },
});

/// Brightness values
const brightness_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0" },
    .{ "50", ".5" },
    .{ "75", ".75" },
    .{ "90", ".9" },
    .{ "95", ".95" },
    .{ "100", "1" },
    .{ "105", "1.05" },
    .{ "110", "1.1" },
    .{ "125", "1.25" },
    .{ "150", "1.5" },
    .{ "200", "2" },
});

/// Contrast values
const contrast_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0" },
    .{ "50", ".5" },
    .{ "75", ".75" },
    .{ "100", "1" },
    .{ "125", "1.25" },
    .{ "150", "1.5" },
    .{ "200", "2" },
});

/// Grayscale values
const grayscale_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "", "100%" },
    .{ "0", "0" },
});

/// Hue-rotate values
const hue_rotate_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0deg" },
    .{ "15", "15deg" },
    .{ "30", "30deg" },
    .{ "60", "60deg" },
    .{ "90", "90deg" },
    .{ "180", "180deg" },
});

/// Invert values
const invert_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "", "100%" },
    .{ "0", "0" },
});

/// Saturate values
const saturate_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0" },
    .{ "50", ".5" },
    .{ "100", "1" },
    .{ "150", "1.5" },
    .{ "200", "2" },
});

/// Sepia values
const sepia_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "", "100%" },
    .{ "0", "0" },
});

/// Drop shadow values
const drop_shadow_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "sm", "0 1px 1px rgb(0 0 0 / 0.05)" },
    .{ "", "0 1px 2px rgb(0 0 0 / 0.1)" },
    .{ "md", "0 4px 3px rgb(0 0 0 / 0.07)" },
    .{ "lg", "0 10px 8px rgb(0 0 0 / 0.04)" },
    .{ "xl", "0 20px 13px rgb(0 0 0 / 0.03)" },
    .{ "2xl", "0 25px 25px rgb(0 0 0 / 0.15)" },
    .{ "none", "0 0 #0000" },
});

/// Generate blur utilities
pub fn generateBlur(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const blur_value = if (value) |v|
        blur_values.get(v) orelse return
    else
        blur_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "blur({s})",
        .{blur_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate brightness utilities
pub fn generateBrightness(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const brightness_value = brightness_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "brightness({s})",
        .{brightness_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate contrast utilities
pub fn generateContrast(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const contrast_value = contrast_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "contrast({s})",
        .{contrast_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate grayscale utilities
pub fn generateGrayscale(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const grayscale_value = if (value) |v|
        grayscale_values.get(v) orelse return
    else
        grayscale_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "grayscale({s})",
        .{grayscale_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate hue-rotate utilities
pub fn generateHueRotate(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const hue_value = hue_rotate_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "hue-rotate({s})",
        .{hue_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate invert utilities
pub fn generateInvert(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const invert_value = if (value) |v|
        invert_values.get(v) orelse return
    else
        invert_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "invert({s})",
        .{invert_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate saturate utilities
pub fn generateSaturate(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const saturate_value = saturate_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "saturate({s})",
        .{saturate_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate sepia utilities
pub fn generateSepia(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const sepia_value = if (value) |v|
        sepia_values.get(v) orelse return
    else
        sepia_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "sepia({s})",
        .{sepia_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate drop-shadow utilities
pub fn generateDropShadow(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const shadow_value = if (value) |v|
        drop_shadow_values.get(v) orelse return
    else
        drop_shadow_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "filter", try std.fmt.allocPrint(
        generator.allocator,
        "drop-shadow({s})",
        .{shadow_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate backdrop-blur utilities
pub fn generateBackdropBlur(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const blur_value = if (value) |v|
        blur_values.get(v) orelse return
    else
        blur_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "backdrop-filter", try std.fmt.allocPrint(
        generator.allocator,
        "blur({s})",
        .{blur_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate backdrop-brightness utilities
pub fn generateBackdropBrightness(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const brightness_value = brightness_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "backdrop-filter", try std.fmt.allocPrint(
        generator.allocator,
        "brightness({s})",
        .{brightness_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate backdrop-contrast utilities
pub fn generateBackdropContrast(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const contrast_value = contrast_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "backdrop-filter", try std.fmt.allocPrint(
        generator.allocator,
        "contrast({s})",
        .{contrast_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate backdrop-grayscale utilities
pub fn generateBackdropGrayscale(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const grayscale_value = if (value) |v|
        grayscale_values.get(v) orelse return
    else
        grayscale_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "backdrop-filter", try std.fmt.allocPrint(
        generator.allocator,
        "grayscale({s})",
        .{grayscale_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}
