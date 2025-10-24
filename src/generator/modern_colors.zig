const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Generate oklch color utilities
/// Example: oklch-[0.5_0.2_180] -> oklch(0.5 0.2 180deg)
pub fn generateOklchColor(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
    property: []const u8,
) !void {
    if (value == null) return;

    // Parse oklch value: lightness_chroma_hue
    const oklch_str = value.?;

    // Simple validation: should contain underscores
    if (std.mem.indexOf(u8, oklch_str, "_") == null) return;

    // Replace underscores with spaces and add "deg" to hue
    var color_value = std.ArrayList(u8).init(generator.allocator);
    defer color_value.deinit();

    try color_value.appendSlice("oklch(");

    var iter = std.mem.split(u8, oklch_str, "_");
    var part_num: usize = 0;
    while (iter.next()) |part| {
        if (part_num > 0) try color_value.append(' ');
        try color_value.appendSlice(part);
        if (part_num == 2) try color_value.appendSlice("deg"); // Add deg to hue
        part_num += 1;
    }
    try color_value.append(')');

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(
        generator.allocator,
        property,
        try color_value.toOwnedSlice(),
    );
    try generator.rules.append(generator.allocator, rule);
}

/// Generate color-mix utilities
/// Example: color-mix-[in_srgb,_blue_50%,_red]
pub fn generateColorMix(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
    property: []const u8,
) !void {
    if (value == null) return;

    // Parse color-mix value and create CSS color-mix() function
    const mix_str = value.?;

    // Simple approach: replace underscores with spaces
    var color_value = std.ArrayList(u8).init(generator.allocator);
    defer color_value.deinit();

    try color_value.appendSlice("color-mix(");
    for (mix_str) |c| {
        if (c == '_') {
            try color_value.append(' ');
        } else {
            try color_value.append(c);
        }
    }
    try color_value.append(')');

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(
        generator.allocator,
        property,
        try color_value.toOwnedSlice(),
    );
    try generator.rules.append(generator.allocator, rule);
}

/// Generate oklch background color
pub fn generateOklchBackground(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    return generateOklchColor(generator, parsed, value, "background-color");
}

/// Generate oklch text color
pub fn generateOklchText(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    return generateOklchColor(generator, parsed, value, "color");
}

/// Generate oklch border color
pub fn generateOklchBorder(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    return generateOklchColor(generator, parsed, value, "border-color");
}

/// Parse oklch value from arbitrary value syntax
pub fn parseOklchValue(value: []const u8) ?struct { l: []const u8, c: []const u8, h: []const u8 } {
    var iter = std.mem.split(u8, value, "_");

    const l = iter.next() orelse return null;
    const c = iter.next() orelse return null;
    const h = iter.next() orelse return null;

    return .{ .l = l, .c = c, .h = h };
}

/// Generate rgb() color with modern syntax
pub fn generateRgbColor(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
    property: []const u8,
) !void {
    if (value == null) return;

    // Modern rgb syntax: rgb(r g b / alpha)
    const rgb_str = value.?;

    var color_value = std.ArrayList(u8).init(generator.allocator);
    defer color_value.deinit();

    try color_value.appendSlice("rgb(");
    for (rgb_str) |c| {
        if (c == '_') {
            try color_value.append(' ');
        } else {
            try color_value.append(c);
        }
    }
    try color_value.append(')');

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(
        generator.allocator,
        property,
        try color_value.toOwnedSlice(),
    );
    try generator.rules.append(generator.allocator, rule);
}

/// Generate hsl() color with modern syntax
pub fn generateHslColor(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
    property: []const u8,
) !void {
    if (value == null) return;

    // Modern hsl syntax: hsl(h s l / alpha)
    const hsl_str = value.?;

    var color_value = std.ArrayList(u8).init(generator.allocator);
    defer color_value.deinit();

    try color_value.appendSlice("hsl(");
    for (hsl_str) |c| {
        if (c == '_') {
            try color_value.append(' ');
        } else {
            try color_value.append(c);
        }
    }
    try color_value.append(')');

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(
        generator.allocator,
        property,
        try color_value.toOwnedSlice(),
    );
    try generator.rules.append(generator.allocator, rule);
}

test "parseOklchValue" {
    const result = parseOklchValue("0.5_0.2_180");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("0.5", result.?.l);
    try std.testing.expectEqualStrings("0.2", result.?.c);
    try std.testing.expectEqualStrings("180", result.?.h);
}
