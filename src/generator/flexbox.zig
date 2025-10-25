const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Flex direction utilities
pub fn generateFlexDirection(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const flex_direction_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "row", "row" },
        .{ "row-reverse", "row-reverse" },
        .{ "col", "column" },
        .{ "col-reverse", "column-reverse" },
    });

    const direction_value = flex_direction_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "flex-direction", .value = direction_value },
    });
}

/// Flex wrap utilities
pub fn generateFlexWrap(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const flex_wrap_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "wrap", "wrap" },
        .{ "wrap-reverse", "wrap-reverse" },
        .{ "nowrap", "nowrap" },
    });

    const wrap_value = flex_wrap_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "flex-wrap", .value = wrap_value },
    });
}

/// Flex utilities (flex-grow, flex-shrink, flex-basis combined)
pub fn generateFlex(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const flex_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "1", "1 1 0%" },
        .{ "auto", "1 1 auto" },
        .{ "initial", "0 1 auto" },
        .{ "none", "none" },
    });

    const flex_value = flex_map.get(value.?) orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "flex", .value = flex_value },
    });
}

/// Flex grow utilities
pub fn generateFlexGrow(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const flex_grow_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "", "1" },
        .{ "0", "0" },
    });

    const grow_value = flex_grow_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "flex-grow", .value = grow_value },
    });
}

/// Flex shrink utilities
pub fn generateFlexShrink(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const flex_shrink_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "", "1" },
        .{ "0", "0" },
    });

    const shrink_value = flex_shrink_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "flex-shrink", .value = shrink_value },
    });
}

/// Flex basis utilities
pub fn generateFlexBasis(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const flex_basis_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "0", "0px" },
        .{ "1", "0.25rem" },
        .{ "2", "0.5rem" },
        .{ "3", "0.75rem" },
        .{ "4", "1rem" },
        .{ "5", "1.25rem" },
        .{ "6", "1.5rem" },
        .{ "7", "1.75rem" },
        .{ "8", "2rem" },
        .{ "9", "2.25rem" },
        .{ "10", "2.5rem" },
        .{ "11", "2.75rem" },
        .{ "12", "3rem" },
        .{ "auto", "auto" },
        .{ "full", "100%" },
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
        .{ "1/12", "8.333333%" },
        .{ "2/12", "16.666667%" },
        .{ "3/12", "25%" },
        .{ "4/12", "33.333333%" },
        .{ "5/12", "41.666667%" },
        .{ "6/12", "50%" },
        .{ "7/12", "58.333333%" },
        .{ "8/12", "66.666667%" },
        .{ "9/12", "75%" },
        .{ "10/12", "83.333333%" },
        .{ "11/12", "91.666667%" },
    });

    const basis_value = flex_basis_map.get(value.?) orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "flex-basis", .value = basis_value },
    });
}

/// Justify content utilities
pub fn generateJustifyContent(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const justify_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "normal", "normal" },
        .{ "start", "flex-start" },
        .{ "end", "flex-end" },
        .{ "center", "center" },
        .{ "between", "space-between" },
        .{ "around", "space-around" },
        .{ "evenly", "space-evenly" },
        .{ "stretch", "stretch" },
    });

    const justify_value = justify_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "justify-content", .value = justify_value },
    });
}

/// Justify items utilities
pub fn generateJustifyItems(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const justify_items_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "start", "start" },
        .{ "end", "end" },
        .{ "center", "center" },
        .{ "stretch", "stretch" },
    });

    const justify_value = justify_items_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "justify-items", .value = justify_value },
    });
}

/// Justify self utilities
pub fn generateJustifySelf(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const justify_self_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "start", "start" },
        .{ "end", "end" },
        .{ "center", "center" },
        .{ "stretch", "stretch" },
    });

    const justify_value = justify_self_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "justify-self", .value = justify_value },
    });
}

/// Align content utilities
pub fn generateAlignContent(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const align_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "normal", "normal" },
        .{ "center", "center" },
        .{ "start", "flex-start" },
        .{ "end", "flex-end" },
        .{ "between", "space-between" },
        .{ "around", "space-around" },
        .{ "evenly", "space-evenly" },
        .{ "baseline", "baseline" },
        .{ "stretch", "stretch" },
    });

    const align_value = align_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "align-content", .value = align_value },
    });
}

/// Align items utilities
pub fn generateAlignItems(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const align_items_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "start", "flex-start" },
        .{ "end", "flex-end" },
        .{ "center", "center" },
        .{ "baseline", "baseline" },
        .{ "stretch", "stretch" },
    });

    const align_value = align_items_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "align-items", .value = align_value },
    });
}

/// Align self utilities
pub fn generateAlignSelf(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const align_self_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "start", "flex-start" },
        .{ "end", "flex-end" },
        .{ "center", "center" },
        .{ "stretch", "stretch" },
        .{ "baseline", "baseline" },
    });

    const align_value = align_self_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "align-self", .value = align_value },
    });
}

/// Place content utilities
pub fn generatePlaceContent(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const place_content_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "center", "center" },
        .{ "start", "start" },
        .{ "end", "end" },
        .{ "between", "space-between" },
        .{ "around", "space-around" },
        .{ "evenly", "space-evenly" },
        .{ "baseline", "baseline" },
        .{ "stretch", "stretch" },
    });

    const place_value = place_content_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "place-content", .value = place_value },
    });
}

/// Place items utilities
pub fn generatePlaceItems(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const place_items_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "start", "start" },
        .{ "end", "end" },
        .{ "center", "center" },
        .{ "baseline", "baseline" },
        .{ "stretch", "stretch" },
    });

    const place_value = place_items_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "place-items", .value = place_value },
    });
}

/// Place self utilities
pub fn generatePlaceSelf(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const place_self_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "start", "start" },
        .{ "end", "end" },
        .{ "center", "center" },
        .{ "stretch", "stretch" },
    });

    const place_value = place_self_map.get(value orelse "") orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "place-self", .value = place_value },
    });
}

/// Order utilities
pub fn generateOrder(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const order_map = std.StaticStringMap([]const u8).initComptime(.{
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
        .{ "first", "-9999" },
        .{ "last", "9999" },
        .{ "none", "0" },
    });

    const order_value = order_map.get(value.?) orelse return;

    try generator.addUtility(parsed, &[_]CSSRule.Declaration{
        .{ .property = "order", .value = order_value },
    });
}
