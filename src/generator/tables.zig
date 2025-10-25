const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Table layout values
const table_layout_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "auto", "auto" },
    .{ "fixed", "fixed" },
});

/// Border collapse values
const border_collapse_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "collapse", "collapse" },
    .{ "separate", "separate" },
});

/// Border spacing scale (same as spacing scale)
const spacing_scale = std.StaticStringMap([]const u8).initComptime(.{
    .{ "0", "0px" },
    .{ "px", "1px" },
    .{ "0.5", "0.125rem" },
    .{ "1", "0.25rem" },
    .{ "2", "0.5rem" },
    .{ "3", "0.75rem" },
    .{ "4", "1rem" },
    .{ "5", "1.25rem" },
    .{ "6", "1.5rem" },
    .{ "8", "2rem" },
    .{ "10", "2.5rem" },
});

/// Generate table-layout utilities
pub fn generateTableLayout(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const layout_value = table_layout_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "table-layout", layout_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate border-collapse utilities
pub fn generateBorderCollapse(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const collapse_value = border_collapse_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "border-collapse", collapse_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate border-spacing utilities
pub fn generateBorderSpacing(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const spacing_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    // Extract utility name
    const utility = parsed.utility;
    const utility_name = if (parsed.is_arbitrary) blk: {
        if (std.mem.indexOf(u8, utility, "-[")) |idx| {
            break :blk utility[0..idx];
        }
        break :blk utility;
    } else utility;

    if (std.mem.eql(u8, utility_name, "border-spacing")) {
        try rule.addDeclaration(generator.allocator, "border-spacing", spacing_value);
    } else if (std.mem.eql(u8, utility_name, "border-spacing-x")) {
        try rule.addDeclarationOwned(
            generator.allocator,
            "border-spacing",
            try std.fmt.allocPrint(generator.allocator, "{s} 0", .{spacing_value}),
        );
    } else if (std.mem.eql(u8, utility_name, "border-spacing-y")) {
        try rule.addDeclarationOwned(
            generator.allocator,
            "border-spacing",
            try std.fmt.allocPrint(generator.allocator, "0 {s}", .{spacing_value}),
        );
    } else {
        rule.deinit(generator.allocator);
        return;
    }

    try generator.rules.append(generator.allocator, rule);
}
