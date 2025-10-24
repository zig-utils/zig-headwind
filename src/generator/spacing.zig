const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Spacing scale (Tailwind defaults)
pub const spacing_scale = std.StaticStringMap([]const u8).initComptime(.{
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
});

/// Generate padding utilities
pub fn generatePadding(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const spacing_value = spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "p")) {
        // All sides
        try rule.addDeclaration(generator.allocator, "padding", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "px")) {
        // Horizontal
        try rule.addDeclaration(generator.allocator, "padding-left", spacing_value);
        try rule.addDeclaration(generator.allocator, "padding-right", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "py")) {
        // Vertical
        try rule.addDeclaration(generator.allocator, "padding-top", spacing_value);
        try rule.addDeclaration(generator.allocator, "padding-bottom", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "pt")) {
        try rule.addDeclaration(generator.allocator, "padding-top", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "pr")) {
        try rule.addDeclaration(generator.allocator, "padding-right", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "pb")) {
        try rule.addDeclaration(generator.allocator, "padding-bottom", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "pl")) {
        try rule.addDeclaration(generator.allocator, "padding-left", spacing_value);
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Generate margin utilities
pub fn generateMargin(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const spacing_value = spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "m")) {
        try rule.addDeclaration(generator.allocator, "margin", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "mx")) {
        try rule.addDeclaration(generator.allocator, "margin-left", spacing_value);
        try rule.addDeclaration(generator.allocator, "margin-right", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "my")) {
        try rule.addDeclaration(generator.allocator, "margin-top", spacing_value);
        try rule.addDeclaration(generator.allocator, "margin-bottom", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "mt")) {
        try rule.addDeclaration(generator.allocator, "margin-top", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "mr")) {
        try rule.addDeclaration(generator.allocator, "margin-right", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "mb")) {
        try rule.addDeclaration(generator.allocator, "margin-bottom", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "ml")) {
        try rule.addDeclaration(generator.allocator, "margin-left", spacing_value);
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Generate gap utilities
pub fn generateGap(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const spacing_value = spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "gap")) {
        try rule.addDeclaration(generator.allocator, "gap", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "gap-x")) {
        try rule.addDeclaration(generator.allocator, "column-gap", spacing_value);
    } else if (std.mem.startsWith(u8, utility, "gap-y")) {
        try rule.addDeclaration(generator.allocator, "row-gap", spacing_value);
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}
