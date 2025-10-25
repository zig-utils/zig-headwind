const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Column count values
const column_counts = std.StaticStringMap([]const u8).initComptime(.{
    .{ "auto", "auto" },
    .{ "1", "1" },
    .{ "2", "2" },
    .{ "3", "3" },
    .{ "4", "4" },
    .{ "5", "5" },
    .{ "6", "6" },
    .{ "7", "7" },
    .{ "8", "8" },
    .{ "9", "9" },
    .{ "10", "10" },
    .{ "11", "11" },
    .{ "12", "12" },
    .{ "3xs", "16rem" },
    .{ "2xs", "18rem" },
    .{ "xs", "20rem" },
    .{ "sm", "24rem" },
    .{ "md", "28rem" },
    .{ "lg", "32rem" },
    .{ "xl", "36rem" },
    .{ "2xl", "42rem" },
    .{ "3xl", "48rem" },
    .{ "4xl", "56rem" },
    .{ "5xl", "64rem" },
    .{ "6xl", "72rem" },
    .{ "7xl", "80rem" },
});

/// Break values
const break_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "auto", "auto" },
    .{ "avoid", "avoid" },
    .{ "all", "all" },
    .{ "avoid-page", "avoid-page" },
    .{ "page", "page" },
    .{ "left", "left" },
    .{ "right", "right" },
    .{ "column", "column" },
});

/// Generate columns utilities
pub fn generateColumns(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const columns_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        column_counts.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "columns", columns_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate break-before utilities
pub fn generateBreakBefore(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const break_value = break_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "break-before", break_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate break-after utilities
pub fn generateBreakAfter(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const break_value = break_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "break-after", break_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate break-inside utilities
pub fn generateBreakInside(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const break_value = break_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "break-inside", break_value);
    try generator.rules.append(generator.allocator, rule);
}
