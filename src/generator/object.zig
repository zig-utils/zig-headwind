const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Object fit values
const object_fit_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "contain", "contain" },
    .{ "cover", "cover" },
    .{ "fill", "fill" },
    .{ "none", "none" },
    .{ "scale-down", "scale-down" },
});

/// Object position values
const object_position_values = std.StaticStringMap([]const u8).initComptime(.{
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

/// Generate object-fit utilities
pub fn generateObjectFit(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const fit_value = object_fit_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "object-fit", fit_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate object-position utilities
pub fn generateObjectPosition(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const position_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        object_position_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "object-position", position_value);
    try generator.rules.append(generator.allocator, rule);
}
