const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const class_parser = @import("../parser/class_parser.zig");

/// Container type utilities for container queries
pub fn generateContainerType(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const container_type_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "normal", "normal" },
        .{ "size", "size" },
        .{ "inline-size", "inline-size" },
    });

    const type_value = container_type_map.get(value orelse "inline-size") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "container-type", type_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Container name utilities for named containers
pub fn generateContainerName(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "container-name", value.?);
    try generator.rules.append(generator.allocator, rule);
}

/// Combined container utility (type and optional name)
/// Examples:
///   - container -> container-type: inline-size
///   - container-normal -> container-type: normal
///   - container-size -> container-type: size
pub fn generateContainer(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const container_type_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "normal", "normal" },
        .{ "size", "size" },
        .{ "", "inline-size" }, // Default for just "container"
    });

    const type_value = container_type_map.get(value orelse "") orelse "inline-size";

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "container-type", type_value);
    try generator.rules.append(generator.allocator, rule);
}
