const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Transition property values
const transition_property_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "none" },
    .{ "all", "all" },
    .{ "", "color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter" },
    .{ "colors", "color, background-color, border-color, text-decoration-color, fill, stroke" },
    .{ "opacity", "opacity" },
    .{ "shadow", "box-shadow" },
    .{ "transform", "transform" },
});

/// Duration values (in milliseconds)
const duration_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0s" },
    .{ "75", "75ms" },
    .{ "100", "100ms" },
    .{ "150", "150ms" },
    .{ "200", "200ms" },
    .{ "300", "300ms" },
    .{ "500", "500ms" },
    .{ "700", "700ms" },
    .{ "1000", "1000ms" },
});

/// Timing function values
const timing_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "linear", "linear" },
    .{ "in", "cubic-bezier(0.4, 0, 1, 1)" },
    .{ "out", "cubic-bezier(0, 0, 0.2, 1)" },
    .{ "in-out", "cubic-bezier(0.4, 0, 0.2, 1)" },
});

/// Delay values (in milliseconds)
const delay_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0s" },
    .{ "75", "75ms" },
    .{ "100", "100ms" },
    .{ "150", "150ms" },
    .{ "200", "200ms" },
    .{ "300", "300ms" },
    .{ "500", "500ms" },
    .{ "700", "700ms" },
    .{ "1000", "1000ms" },
});

/// Generate transition-property utilities
pub fn generateTransition(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const transition_value = if (value) |v|
        transition_property_values.get(v) orelse return
    else
        transition_property_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "transition-property", transition_value);
    try rule.addDeclaration(generator.allocator, "transition-timing-function", "cubic-bezier(0.4, 0, 0.2, 1)");
    try rule.addDeclaration(generator.allocator, "transition-duration", "150ms");
    try generator.rules.append(generator.allocator, rule);
}

/// Generate transition-duration utilities
pub fn generateDuration(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const duration_value = duration_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "transition-duration", duration_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate transition-timing-function utilities
pub fn generateEase(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const timing_value = timing_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "transition-timing-function", timing_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate transition-delay utilities
pub fn generateDelay(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const delay_value = delay_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "transition-delay", delay_value);
    try generator.rules.append(generator.allocator, rule);
}
