const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// List style type values
const list_style_types = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "none" },
    .{ "disc", "disc" },
    .{ "decimal", "decimal" },
    .{ "circle", "circle" },
    .{ "square", "square" },
    .{ "lower-alpha", "lower-alpha" },
    .{ "upper-alpha", "upper-alpha" },
    .{ "lower-roman", "lower-roman" },
    .{ "upper-roman", "upper-roman" },
    .{ "lower-greek", "lower-greek" },
    .{ "lower-latin", "lower-latin" },
    .{ "upper-latin", "upper-latin" },
});

/// List style position values
const list_style_positions = std.StaticStringMap([]const u8).initComptime(.{
    .{ "inside", "inside" },
    .{ "outside", "outside" },
});

/// Generate list-style-type utilities
pub fn generateListStyleType(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const type_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        list_style_types.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "list-style-type", type_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate list-style-position utilities
pub fn generateListStylePosition(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const position_value = list_style_positions.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "list-style-position", position_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate list-style-image utilities
pub fn generateListStyleImage(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const image_value = if (std.mem.eql(u8, value.?, "none"))
        "none"
    else if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "list-style-image", image_value);
    try generator.rules.append(generator.allocator, rule);
}
