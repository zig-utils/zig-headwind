const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const Declaration = CSSGenerator.Declaration;
const class_parser = @import("../parser/class_parser.zig");

/// Display utilities
pub fn generateDisplay(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const display_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "block", "block" },
        .{ "inline-block", "inline-block" },
        .{ "inline", "inline" },
        .{ "flex", "flex" },
        .{ "inline-flex", "inline-flex" },
        .{ "table", "table" },
        .{ "inline-table", "inline-table" },
        .{ "table-caption", "table-caption" },
        .{ "table-cell", "table-cell" },
        .{ "table-column", "table-column" },
        .{ "table-column-group", "table-column-group" },
        .{ "table-footer-group", "table-footer-group" },
        .{ "table-header-group", "table-header-group" },
        .{ "table-row-group", "table-row-group" },
        .{ "table-row", "table-row" },
        .{ "flow-root", "flow-root" },
        .{ "grid", "grid" },
        .{ "inline-grid", "inline-grid" },
        .{ "contents", "contents" },
        .{ "list-item", "list-item" },
        .{ "hidden", "none" },
    });

    const display_value = display_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "display", display_value);
}

/// Position utilities
pub fn generatePosition(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const position_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "static", "static" },
        .{ "fixed", "fixed" },
        .{ "absolute", "absolute" },
        .{ "relative", "relative" },
        .{ "sticky", "sticky" },
    });

    const position_value = position_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "position", position_value);
}

/// Top/Right/Bottom/Left utilities (inset)
pub fn generateInset(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, side: []const u8, value: ?[]const u8) !void {
    if (value == null) return;

    const spacing_scale = std.StaticStringMap([]const u8).initComptime(.{
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
        .{ "auto", "auto" },
        .{ "full", "100%" },
        .{ "1/2", "50%" },
        .{ "1/3", "33.333333%" },
        .{ "2/3", "66.666667%" },
        .{ "1/4", "25%" },
        .{ "2/4", "50%" },
        .{ "3/4", "75%" },
    });

    const inset_value = spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    if (std.mem.eql(u8, side, "all")) {
        // inset-* applies to all sides
        try rule.addDeclaration(generator.allocator, "inset", inset_value);
    } else if (std.mem.eql(u8, side, "x")) {
        // inset-x-* applies to left and right
        try rule.addDeclaration(generator.allocator, "left", inset_value);
        try rule.addDeclaration(generator.allocator, "right", inset_value);
    } else if (std.mem.eql(u8, side, "y")) {
        // inset-y-* applies to top and bottom
        try rule.addDeclaration(generator.allocator, "top", inset_value);
        try rule.addDeclaration(generator.allocator, "bottom", inset_value);
    } else {
        // Individual sides
        try rule.addDeclaration(generator.allocator, side, inset_value);
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Z-index utilities
pub fn generateZIndex(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const z_index_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "0", "0" },
        .{ "10", "10" },
        .{ "20", "20" },
        .{ "30", "30" },
        .{ "40", "40" },
        .{ "50", "50" },
        .{ "auto", "auto" },
    });

    const z_value = z_index_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "z-index", z_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Overflow utilities
pub fn generateOverflow(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, axis: ?[]const u8, value: ?[]const u8) !void {
    if (value == null) return;

    const overflow_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "hidden", "hidden" },
        .{ "clip", "clip" },
        .{ "visible", "visible" },
        .{ "scroll", "scroll" },
    });

    const overflow_value = overflow_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    if (axis) |ax| {
        if (std.mem.eql(u8, ax, "x")) {
            try rule.addDeclaration(generator.allocator, "overflow-x", overflow_value);
        } else if (std.mem.eql(u8, ax, "y")) {
            try rule.addDeclaration(generator.allocator, "overflow-y", overflow_value);
        }
    } else {
        try rule.addDeclaration(generator.allocator, "overflow", overflow_value);
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Overscroll behavior utilities
pub fn generateOverscrollBehavior(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, axis: ?[]const u8, value: ?[]const u8) !void {
    if (value == null) return;

    const overscroll_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "contain", "contain" },
        .{ "none", "none" },
    });

    const overscroll_value = overscroll_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    if (axis) |ax| {
        if (std.mem.eql(u8, ax, "x")) {
            try rule.addDeclaration(generator.allocator, "overscroll-behavior-x", overscroll_value);
        } else if (std.mem.eql(u8, ax, "y")) {
            try rule.addDeclaration(generator.allocator, "overscroll-behavior-y", overscroll_value);
        }
    } else {
        try rule.addDeclaration(generator.allocator, "overscroll-behavior", overscroll_value);
    }

    try generator.rules.append(generator.allocator, rule);
}

/// Visibility utilities
pub fn generateVisibility(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const visibility_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "visible", "visible" },
        .{ "invisible", "hidden" },
        .{ "collapse", "collapse" },
    });

    const visibility_value = visibility_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "visibility", visibility_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Isolation utilities
pub fn generateIsolation(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const isolation_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "isolate", "isolate" },
        .{ "isolation-auto", "auto" },
    });

    const isolation_value = isolation_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "isolation", isolation_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Float utilities
pub fn generateFloat(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const float_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "start", "inline-start" },
        .{ "end", "inline-end" },
        .{ "right", "right" },
        .{ "left", "left" },
        .{ "none", "none" },
    });

    const float_value = float_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "float", float_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Clear utilities
pub fn generateClear(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const clear_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "start", "inline-start" },
        .{ "end", "inline-end" },
        .{ "left", "left" },
        .{ "right", "right" },
        .{ "both", "both" },
        .{ "none", "none" },
    });

    const clear_value = clear_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "clear", clear_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Object-fit utilities
pub fn generateObjectFit(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const object_fit_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "contain", "contain" },
        .{ "cover", "cover" },
        .{ "fill", "fill" },
        .{ "none", "none" },
        .{ "scale-down", "scale-down" },
    });

    const object_fit_value = object_fit_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "object-fit", object_fit_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Object-position utilities
pub fn generateObjectPosition(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const object_position_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "bottom", "bottom" },
        .{ "center", "center" },
        .{ "left", "left" },
        .{ "left-bottom", "left bottom" },
        .{ "left-top", "left top" },
        .{ "right", "right" },
        .{ "right-bottom", "right bottom" },
        .{ "right-top", "right top" },
        .{ "top", "top" },
    });

    const object_position_value = object_position_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "object-position", object_position_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Aspect ratio utilities
pub fn generateAspectRatio(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const aspect_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "square", "1 / 1" },
        .{ "video", "16 / 9" },
    });

    const aspect_value = aspect_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "aspect-ratio", aspect_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Container utilities
pub fn generateContainer(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass) !void {
    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "width", "100%");
    try generator.rules.append(generator.allocator, rule);
    // TODO: Add breakpoint-specific max-widths using media queries
}

/// Box decoration break utilities
pub fn generateBoxDecorationBreak(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const box_decoration_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "clone", "clone" },
        .{ "slice", "slice" },
    });

    const box_decoration_value = box_decoration_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "box-decoration-break", box_decoration_value);
    try rule.addDeclaration(generator.allocator, "-webkit-box-decoration-break", box_decoration_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Box sizing utilities
pub fn generateBoxSizing(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const box_sizing_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "border", "border-box" },
        .{ "content", "content-box" },
    });

    const box_sizing_value = box_sizing_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "box-sizing", box_sizing_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Columns utilities
pub fn generateColumns(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const columns_map = std.StaticStringMap([]const u8).initComptime(.{
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
        .{ "auto", "auto" },
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

    const columns_value = columns_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "columns", columns_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Break utilities (break-before, break-after, break-inside)
pub fn generateBreak(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, position: []const u8, value: ?[]const u8) !void {
    if (value == null) return;

    const break_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "avoid", "avoid" },
        .{ "all", "all" },
        .{ "avoid-page", "avoid-page" },
        .{ "page", "page" },
        .{ "left", "left" },
        .{ "right", "right" },
        .{ "column", "column" },
    });

    const break_value = break_map.get(value.?) orelse return;

    const property = try std.fmt.allocPrint(generator.allocator, "break-{s}", .{position});
    defer generator.allocator.free(property);

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, property, break_value);
    try generator.rules.append(generator.allocator, rule);
}
