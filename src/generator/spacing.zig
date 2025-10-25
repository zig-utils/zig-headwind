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

    // Check for arbitrary value first
    const spacing_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    errdefer rule.deinit(generator.allocator);

    // Extract utility name (before brackets if arbitrary)
    const utility = parsed.utility;
    const utility_name = if (parsed.is_arbitrary) blk: {
        // For "p-[20px]", extract "p"
        if (std.mem.indexOf(u8, utility, "-[")) |idx| {
            break :blk utility[0..idx];
        }
        break :blk utility;
    } else utility;

    if (std.mem.eql(u8, utility_name, "p")) {
        // All sides
        try rule.addDeclaration(generator.allocator, "padding", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "px")) {
        // Horizontal
        try rule.addDeclaration(generator.allocator, "padding-left", spacing_value);
        try rule.addDeclaration(generator.allocator, "padding-right", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "py")) {
        // Vertical
        try rule.addDeclaration(generator.allocator, "padding-top", spacing_value);
        try rule.addDeclaration(generator.allocator, "padding-bottom", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "pt")) {
        try rule.addDeclaration(generator.allocator, "padding-top", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "pr")) {
        try rule.addDeclaration(generator.allocator, "padding-right", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "pb")) {
        try rule.addDeclaration(generator.allocator, "padding-bottom", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "pl")) {
        try rule.addDeclaration(generator.allocator, "padding-left", spacing_value);
    } else {
        rule.deinit(generator.allocator);
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Generate margin utilities (including negative margins)
pub fn generateMargin(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check if this is a negative margin
    const utility = parsed.utility;
    const is_negative = std.mem.startsWith(u8, utility, "-");

    // Check for arbitrary value first
    const spacing_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        spacing_scale.get(value.?) orelse return;

    // Negate the value if needed
    const final_value = if (is_negative and !parsed.is_arbitrary) blk: {
        // Prepend minus sign for scale values
        break :blk try std.fmt.allocPrint(generator.allocator, "-{s}", .{spacing_value});
    } else if (is_negative and parsed.is_arbitrary) blk: {
        // For arbitrary values, prepend minus if not already there
        if (!std.mem.startsWith(u8, spacing_value, "-")) {
            break :blk try std.fmt.allocPrint(generator.allocator, "-{s}", .{spacing_value});
        } else {
            break :blk spacing_value;
        }
    } else spacing_value;
    defer if (is_negative and final_value.ptr != spacing_value.ptr) generator.allocator.free(final_value);

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    // Extract utility name (before brackets if arbitrary), removing leading minus
    const utility_name = if (parsed.is_arbitrary) blk: {
        if (std.mem.indexOf(u8, utility, "-[")) |idx| {
            const name = utility[0..idx];
            break :blk if (is_negative) name[1..] else name;
        }
        break :blk if (is_negative) utility[1..] else utility;
    } else blk: {
        // For regular utilities like "-m-4", extract just the margin part
        const base = if (is_negative) utility[1..] else utility;
        // Find the next dash to get just "m" from "m-4"
        if (std.mem.indexOf(u8, base, "-")) |dash_pos| {
            break :blk base[0..dash_pos];
        }
        break :blk base;
    };

    if (std.mem.eql(u8, utility_name, "m")) {
        try rule.addDeclaration(generator.allocator, "margin", final_value);
    } else if (std.mem.startsWith(u8, utility_name, "mx")) {
        try rule.addDeclaration(generator.allocator, "margin-left", final_value);
        try rule.addDeclaration(generator.allocator, "margin-right", final_value);
    } else if (std.mem.startsWith(u8, utility_name, "my")) {
        try rule.addDeclaration(generator.allocator, "margin-top", final_value);
        try rule.addDeclaration(generator.allocator, "margin-bottom", final_value);
    } else if (std.mem.startsWith(u8, utility_name, "mt")) {
        try rule.addDeclaration(generator.allocator, "margin-top", final_value);
    } else if (std.mem.startsWith(u8, utility_name, "mr")) {
        try rule.addDeclaration(generator.allocator, "margin-right", final_value);
    } else if (std.mem.startsWith(u8, utility_name, "mb")) {
        try rule.addDeclaration(generator.allocator, "margin-bottom", final_value);
    } else if (std.mem.startsWith(u8, utility_name, "ml")) {
        try rule.addDeclaration(generator.allocator, "margin-left", final_value);
    } else {
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Generate gap utilities
pub fn generateGap(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const spacing_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    // Extract utility name (before brackets if arbitrary)
    const utility = parsed.utility;
    const utility_name = if (parsed.is_arbitrary) blk: {
        // For "gap-[15px]", extract "gap"
        if (std.mem.indexOf(u8, utility, "-[")) |idx| {
            break :blk utility[0..idx];
        }
        break :blk utility;
    } else utility;

    if (std.mem.eql(u8, utility_name, "gap")) {
        try rule.addDeclaration(generator.allocator, "gap", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "gap-x")) {
        try rule.addDeclaration(generator.allocator, "column-gap", spacing_value);
    } else if (std.mem.startsWith(u8, utility_name, "gap-y")) {
        try rule.addDeclaration(generator.allocator, "row-gap", spacing_value);
    } else {
        rule.deinit(generator.allocator);
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}
