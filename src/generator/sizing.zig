const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");
const spacing = @import("spacing.zig");

/// Additional sizing values
const sizing_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "auto", "auto" },
    .{ "full", "100%" },
    .{ "screen", "100vh" },
    .{ "min", "min-content" },
    .{ "max", "max-content" },
    .{ "fit", "fit-content" },
    // Fractions
    .{ "1/2", "50%" },
    .{ "1/3", "33.333333%" },
    .{ "2/3", "66.666667%" },
    .{ "1/4", "25%" },
    .{ "2/4", "50%" },
    .{ "3/4", "75%" },
    .{ "1/5", "20%" },
    .{ "2/5", "40%" },
    .{ "3/5", "60%" },
    .{ "4/5", "80%" },
    .{ "1/6", "16.666667%" },
    .{ "2/6", "33.333333%" },
    .{ "3/6", "50%" },
    .{ "4/6", "66.666667%" },
    .{ "5/6", "83.333333%" },
});

fn getSizingValue(value: []const u8) ?[]const u8 {
    // First check explicit sizing values
    if (sizing_values.get(value)) |v| return v;
    // Fall back to spacing scale
    if (spacing.spacing_scale.get(value)) |v| return v;
    return null;
}

/// Generate width utilities
pub fn generateWidth(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const css_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        getSizingValue(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "width", css_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate height utilities
pub fn generateHeight(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const css_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        getSizingValue(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "height", css_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate min-width utilities
pub fn generateMinWidth(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const css_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        getSizingValue(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "min-width", css_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate max-width utilities
pub fn generateMaxWidth(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const css_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        getSizingValue(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "max-width", css_value);
    try generator.rules.append(generator.allocator, rule);
}
