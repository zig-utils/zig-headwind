const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Border radius values
const border_radius = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "0px" },
    .{ "sm", "0.125rem" },
    .{ "", "0.25rem" }, // rounded (no suffix)
    .{ "md", "0.375rem" },
    .{ "lg", "0.5rem" },
    .{ "xl", "0.75rem" },
    .{ "2xl", "1rem" },
    .{ "3xl", "1.5rem" },
    .{ "full", "9999px" },
});

/// Border width values
const border_widths = std.StaticStringMap([]const u8).initComptime(.{
    .{ "", "1px" }, // border (no suffix)
    .{ "0", "0px" },
    .{ "2", "2px" },
    .{ "4", "4px" },
    .{ "8", "8px" },
});

/// Generate border utilities
pub fn generateBorder(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const val = value orelse "";

    const border_width = border_widths.get(val) orelse return;

    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "border")) {
        try rule.addDeclaration(generator.allocator, "border-width", border_width);
    } else if (std.mem.startsWith(u8, utility, "border-t")) {
        try rule.addDeclaration(generator.allocator, "border-top-width", border_width);
    } else if (std.mem.startsWith(u8, utility, "border-r")) {
        try rule.addDeclaration(generator.allocator, "border-right-width", border_width);
    } else if (std.mem.startsWith(u8, utility, "border-b")) {
        try rule.addDeclaration(generator.allocator, "border-bottom-width", border_width);
    } else if (std.mem.startsWith(u8, utility, "border-l")) {
        try rule.addDeclaration(generator.allocator, "border-left-width", border_width);
    } else if (std.mem.startsWith(u8, utility, "border-x")) {
        try rule.addDeclaration(generator.allocator, "border-left-width", border_width);
        try rule.addDeclaration(generator.allocator, "border-right-width", border_width);
    } else if (std.mem.startsWith(u8, utility, "border-y")) {
        try rule.addDeclaration(generator.allocator, "border-top-width", border_width);
        try rule.addDeclaration(generator.allocator, "border-bottom-width", border_width);
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Generate border-radius utilities
pub fn generateBorderRadius(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const val = value orelse "";

    const radius = border_radius.get(val) orelse return;

    var rule = try generator.createRule(parsed);

    const utility = parsed.utility;
    if (std.mem.eql(u8, utility, "rounded")) {
        try rule.addDeclaration(generator.allocator, "border-radius", radius);
    } else if (std.mem.startsWith(u8, utility, "rounded-t")) {
        try rule.addDeclaration(generator.allocator, "border-top-left-radius", radius);
        try rule.addDeclaration(generator.allocator, "border-top-right-radius", radius);
    } else if (std.mem.startsWith(u8, utility, "rounded-r")) {
        try rule.addDeclaration(generator.allocator, "border-top-right-radius", radius);
        try rule.addDeclaration(generator.allocator, "border-bottom-right-radius", radius);
    } else if (std.mem.startsWith(u8, utility, "rounded-b")) {
        try rule.addDeclaration(generator.allocator, "border-bottom-left-radius", radius);
        try rule.addDeclaration(generator.allocator, "border-bottom-right-radius", radius);
    } else if (std.mem.startsWith(u8, utility, "rounded-l")) {
        try rule.addDeclaration(generator.allocator, "border-top-left-radius", radius);
        try rule.addDeclaration(generator.allocator, "border-bottom-left-radius", radius);
    }

    try generator.rules.append(generator.allocator, rule);
}
