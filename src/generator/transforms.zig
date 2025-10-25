const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Transform scale values
const scale_values = std.StaticStringMap([]const u8).initComptime(.{
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
});

/// Rotate values (in degrees)
const rotate_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0deg" },
    .{ "1", "1deg" },
    .{ "2", "2deg" },
    .{ "3", "3deg" },
    .{ "6", "6deg" },
    .{ "12", "12deg" },
    .{ "45", "45deg" },
    .{ "90", "90deg" },
    .{ "180", "180deg" },
});

/// Translate values (based on spacing scale)
const translate_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0px" },
    .{ "px", "1px" },
    .{ "0.5", "0.125rem" },
    .{ "1", "0.25rem" },
    .{ "1.5", "0.375rem" },
    .{ "2", "0.5rem" },
    .{ "2.5", "0.625rem" },
    .{ "3", "0.75rem" },
    .{ "3.5", "0.875rem" },
    .{ "4", "1rem" },
    .{ "5", "1.25rem" },
    .{ "6", "1.5rem" },
    .{ "7", "1.75rem" },
    .{ "8", "2rem" },
    .{ "9", "2.25rem" },
    .{ "10", "2.5rem" },
    .{ "11", "2.75rem" },
    .{ "12", "3rem" },
    .{ "14", "3.5rem" },
    .{ "16", "4rem" },
    .{ "20", "5rem" },
    .{ "24", "6rem" },
    .{ "28", "7rem" },
    .{ "32", "8rem" },
    .{ "36", "9rem" },
    .{ "40", "10rem" },
    .{ "44", "11rem" },
    .{ "48", "12rem" },
    .{ "52", "13rem" },
    .{ "56", "14rem" },
    .{ "60", "15rem" },
    .{ "64", "16rem" },
    .{ "72", "18rem" },
    .{ "80", "20rem" },
    .{ "96", "24rem" },
    .{ "1/2", "50%" },
    .{ "1/3", "33.333333%" },
    .{ "2/3", "66.666667%" },
    .{ "1/4", "25%" },
    .{ "2/4", "50%" },
    .{ "3/4", "75%" },
    .{ "full", "100%" },
});

/// Skew values (in degrees)
const skew_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0deg" },
    .{ "1", "1deg" },
    .{ "2", "2deg" },
    .{ "3", "3deg" },
    .{ "6", "6deg" },
    .{ "12", "12deg" },
});

/// Transform origin values
const origin_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "center", "center" },
    .{ "top", "top" },
    .{ "top-right", "top right" },
    .{ "right", "right" },
    .{ "bottom-right", "bottom right" },
    .{ "bottom", "bottom" },
    .{ "bottom-left", "bottom left" },
    .{ "left", "left" },
    .{ "top-left", "top left" },
});

/// Generate scale utilities
pub fn generateScale(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const scale_value = scale_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "scale({s})",
        .{scale_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate scale-x utilities
pub fn generateScaleX(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const scale_value = scale_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "scaleX({s})",
        .{scale_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate scale-y utilities
pub fn generateScaleY(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const scale_value = scale_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "scaleY({s})",
        .{scale_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate rotate utilities
pub fn generateRotate(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const rotate_value = rotate_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "rotate({s})",
        .{rotate_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate translate-x utilities
pub fn generateTranslateX(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const translate_value = translate_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "translateX({s})",
        .{translate_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate translate-y utilities
pub fn generateTranslateY(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const translate_value = translate_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "translateY({s})",
        .{translate_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate skew-x utilities
pub fn generateSkewX(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const skew_value = skew_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "skewX({s})",
        .{skew_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate skew-y utilities
pub fn generateSkewY(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const skew_value = skew_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclarationOwned(generator.allocator, "transform", try std.fmt.allocPrint(
        generator.allocator,
        "skewY({s})",
        .{skew_value},
    ));
    try generator.rules.append(generator.allocator, rule);
}

/// Generate transform-origin utilities
pub fn generateOrigin(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const origin_value = origin_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "transform-origin", origin_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Transform-style utilities (for 3D transforms)
pub fn generateTransformStyle(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const transform_style_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "flat", "flat" },
        .{ "preserve-3d", "preserve-3d" },
    });

    const style_value = transform_style_map.get(value orelse "flat") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "transform-style", style_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Perspective utilities
pub fn generatePerspective(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const perspective_scale = std.StaticStringMap([]const u8).initComptime(.{
        .{ "none", "none" },
        .{ "0", "0px" },
        .{ "100", "100px" },
        .{ "200", "200px" },
        .{ "300", "300px" },
        .{ "400", "400px" },
        .{ "500", "500px" },
        .{ "600", "600px" },
        .{ "700", "700px" },
        .{ "800", "800px" },
        .{ "900", "900px" },
        .{ "1000", "1000px" },
        .{ "1500", "1500px" },
        .{ "2000", "2000px" },
    });

    const perspective_value = perspective_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "perspective", perspective_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Perspective-origin utilities
pub fn generatePerspectiveOrigin(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const perspective_origin_values = std.StaticStringMap([]const u8).initComptime(.{
        .{ "center", "center" },
        .{ "top", "top" },
        .{ "top-right", "top right" },
        .{ "right", "right" },
        .{ "bottom-right", "bottom right" },
        .{ "bottom", "bottom" },
        .{ "bottom-left", "bottom left" },
        .{ "left", "left" },
        .{ "top-left", "top left" },
    });

    const origin_value = perspective_origin_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "perspective-origin", origin_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Backface-visibility utilities
pub fn generateBackfaceVisibility(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const visibility_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "visible", "visible" },
        .{ "hidden", "hidden" },
    });

    const visibility_value = visibility_map.get(value orelse "visible") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "backface-visibility", visibility_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Animation iteration count utilities
pub fn generateAnimationIterationCount(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const iteration_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "infinite", "infinite" },
        .{ "1", "1" },
        .{ "2", "2" },
        .{ "3", "3" },
        .{ "4", "4" },
        .{ "5", "5" },
    });

    const iteration_value = iteration_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "animation-iteration-count", iteration_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Animation direction utilities
pub fn generateAnimationDirection(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const direction_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "normal", "normal" },
        .{ "reverse", "reverse" },
        .{ "alternate", "alternate" },
        .{ "alternate-reverse", "alternate-reverse" },
    });

    const direction_value = direction_map.get(value orelse "normal") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "animation-direction", direction_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Animation fill mode utilities
pub fn generateAnimationFillMode(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const fill_mode_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "none", "none" },
        .{ "forwards", "forwards" },
        .{ "backwards", "backwards" },
        .{ "both", "both" },
    });

    const fill_mode_value = fill_mode_map.get(value orelse "none") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "animation-fill-mode", fill_mode_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Animation play state utilities
pub fn generateAnimationPlayState(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const play_state_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "running", "running" },
        .{ "paused", "paused" },
    });

    const play_state_value = play_state_map.get(value orelse "running") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "animation-play-state", play_state_value);
    try generator.rules.append(generator.allocator, rule);
}
