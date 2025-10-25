const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const class_parser = @import("../parser/class_parser.zig");

/// Background attachment utilities
pub fn generateBackgroundAttachment(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const attachment_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "fixed", "fixed" },
        .{ "local", "local" },
        .{ "scroll", "scroll" },
    });

    const attachment_value = attachment_map.get(value orelse "scroll") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-attachment", attachment_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Background clip utilities
pub fn generateBackgroundClip(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const clip_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "border", "border-box" },
        .{ "padding", "padding-box" },
        .{ "content", "content-box" },
        .{ "text", "text" },
    });

    const clip_value = clip_map.get(value orelse "border") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-clip", clip_value);
    // Add -webkit-background-clip for text clipping (needed for Safari)
    if (std.mem.eql(u8, clip_value, "text")) {
        try rule.addDeclaration(generator.allocator, "-webkit-background-clip", "text");
        try rule.addDeclaration(generator.allocator, "-webkit-text-fill-color", "transparent");
    }
    try generator.rules.append(generator.allocator, rule);
}

/// Background origin utilities
pub fn generateBackgroundOrigin(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const origin_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "border", "border-box" },
        .{ "padding", "padding-box" },
        .{ "content", "content-box" },
    });

    const origin_value = origin_map.get(value orelse "padding") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-origin", origin_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Background position utilities
pub fn generateBackgroundPosition(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const position_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "bottom", "bottom" },
        .{ "center", "center" },
        .{ "left", "left" },
        .{ "left-bottom", "left bottom" },
        .{ "left-top", "left top" },
        .{ "right", "right" },
        .{ "right-bottom", "right bottom" },
        .{ "right-top", "right top" },
        .{ "top", "top" },
    });

    const position_value = position_map.get(value orelse "center") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-position", position_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Background repeat utilities
pub fn generateBackgroundRepeat(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const repeat_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "repeat", "repeat" },
        .{ "no-repeat", "no-repeat" },
        .{ "repeat-x", "repeat-x" },
        .{ "repeat-y", "repeat-y" },
        .{ "round", "round" },
        .{ "space", "space" },
    });

    const repeat_value = repeat_map.get(value orelse "repeat") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-repeat", repeat_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Background size utilities
pub fn generateBackgroundSize(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const size_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "cover", "cover" },
        .{ "contain", "contain" },
    });

    const size_value = size_map.get(value orelse "auto") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-size", size_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Background image utilities (for gradients, handled elsewhere)
/// This is a placeholder for custom background-image values
pub fn generateBackgroundImage(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-image", value.?);
    try generator.rules.append(generator.allocator, rule);
}
