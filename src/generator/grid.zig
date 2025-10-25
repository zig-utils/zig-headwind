const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Grid template columns utilities
pub fn generateGridTemplateColumns(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const grid_cols_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "1", "repeat(1, minmax(0, 1fr))" },
        .{ "2", "repeat(2, minmax(0, 1fr))" },
        .{ "3", "repeat(3, minmax(0, 1fr))" },
        .{ "4", "repeat(4, minmax(0, 1fr))" },
        .{ "5", "repeat(5, minmax(0, 1fr))" },
        .{ "6", "repeat(6, minmax(0, 1fr))" },
        .{ "7", "repeat(7, minmax(0, 1fr))" },
        .{ "8", "repeat(8, minmax(0, 1fr))" },
        .{ "9", "repeat(9, minmax(0, 1fr))" },
        .{ "10", "repeat(10, minmax(0, 1fr))" },
        .{ "11", "repeat(11, minmax(0, 1fr))" },
        .{ "12", "repeat(12, minmax(0, 1fr))" },
        .{ "none", "none" },
        .{ "subgrid", "subgrid" },
    });

    const grid_value = grid_cols_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "grid-template-columns", grid_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Grid column utilities (span, start, end)
pub fn generateGridColumn(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, property_type: []const u8, value: ?[]const u8) !void {
    if (value == null) return;

    if (std.mem.eql(u8, property_type, "span")) {
        // col-span-*
        if (std.mem.eql(u8, value.?, "auto")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-column", "auto");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        if (std.mem.eql(u8, value.?, "full")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-column", "1 / -1");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        // col-span-1 through col-span-12
        const span_value = try std.fmt.allocPrint(generator.allocator, "span {s} / span {s}", .{ value.?, value.? });
        defer generator.allocator.free(span_value);

        var rule = try generator.createRule(parsed);
        errdefer rule.deinit(generator.allocator);
        try rule.addDeclaration(generator.allocator, "grid-column", span_value);
        try generator.rules.append(generator.allocator, rule);
    } else if (std.mem.eql(u8, property_type, "start")) {
        // col-start-*
        if (std.mem.eql(u8, value.?, "auto")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-column-start", "auto");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        var rule = try generator.createRule(parsed);
        errdefer rule.deinit(generator.allocator);
        try rule.addDeclaration(generator.allocator, "grid-column-start", value.?);
        try generator.rules.append(generator.allocator, rule);
    } else if (std.mem.eql(u8, property_type, "end")) {
        // col-end-*
        if (std.mem.eql(u8, value.?, "auto")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-column-end", "auto");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        var rule = try generator.createRule(parsed);
        errdefer rule.deinit(generator.allocator);
        try rule.addDeclaration(generator.allocator, "grid-column-end", value.?);
        try generator.rules.append(generator.allocator, rule);
    }
}

/// Grid template rows utilities
pub fn generateGridTemplateRows(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const grid_rows_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "1", "repeat(1, minmax(0, 1fr))" },
        .{ "2", "repeat(2, minmax(0, 1fr))" },
        .{ "3", "repeat(3, minmax(0, 1fr))" },
        .{ "4", "repeat(4, minmax(0, 1fr))" },
        .{ "5", "repeat(5, minmax(0, 1fr))" },
        .{ "6", "repeat(6, minmax(0, 1fr))" },
        .{ "7", "repeat(7, minmax(0, 1fr))" },
        .{ "8", "repeat(8, minmax(0, 1fr))" },
        .{ "9", "repeat(9, minmax(0, 1fr))" },
        .{ "10", "repeat(10, minmax(0, 1fr))" },
        .{ "11", "repeat(11, minmax(0, 1fr))" },
        .{ "12", "repeat(12, minmax(0, 1fr))" },
        .{ "none", "none" },
        .{ "subgrid", "subgrid" },
    });

    const grid_value = grid_rows_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "grid-template-rows", grid_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Grid row utilities (span, start, end)
pub fn generateGridRow(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, property_type: []const u8, value: ?[]const u8) !void {
    if (value == null) return;

    if (std.mem.eql(u8, property_type, "span")) {
        // row-span-*
        if (std.mem.eql(u8, value.?, "auto")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-row", "auto");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        if (std.mem.eql(u8, value.?, "full")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-row", "1 / -1");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        // row-span-1 through row-span-12
        const span_value = try std.fmt.allocPrint(generator.allocator, "span {s} / span {s}", .{ value.?, value.? });
        defer generator.allocator.free(span_value);

        var rule = try generator.createRule(parsed);
        errdefer rule.deinit(generator.allocator);
        try rule.addDeclaration(generator.allocator, "grid-row", span_value);
        try generator.rules.append(generator.allocator, rule);
    } else if (std.mem.eql(u8, property_type, "start")) {
        // row-start-*
        if (std.mem.eql(u8, value.?, "auto")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-row-start", "auto");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        var rule = try generator.createRule(parsed);
        errdefer rule.deinit(generator.allocator);
        try rule.addDeclaration(generator.allocator, "grid-row-start", value.?);
        try generator.rules.append(generator.allocator, rule);
    } else if (std.mem.eql(u8, property_type, "end")) {
        // row-end-*
        if (std.mem.eql(u8, value.?, "auto")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "grid-row-end", "auto");
            try generator.rules.append(generator.allocator, rule);
            return;
        }

        var rule = try generator.createRule(parsed);
        errdefer rule.deinit(generator.allocator);
        try rule.addDeclaration(generator.allocator, "grid-row-end", value.?);
        try generator.rules.append(generator.allocator, rule);
    }
}

/// Grid auto flow utilities
pub fn generateGridAutoFlow(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    const grid_flow_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "row", "row" },
        .{ "col", "column" },
        .{ "dense", "dense" },
        .{ "row-dense", "row dense" },
        .{ "col-dense", "column dense" },
    });

    const flow_value = grid_flow_map.get(value orelse "") orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "grid-auto-flow", flow_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Grid auto columns utilities
pub fn generateGridAutoColumns(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const grid_auto_cols_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "min", "min-content" },
        .{ "max", "max-content" },
        .{ "fr", "minmax(0, 1fr)" },
    });

    const auto_value = grid_auto_cols_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "grid-auto-columns", auto_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Grid auto rows utilities
pub fn generateGridAutoRows(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    const grid_auto_rows_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "min", "min-content" },
        .{ "max", "max-content" },
        .{ "fr", "minmax(0, 1fr)" },
    });

    const auto_value = grid_auto_rows_map.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "grid-auto-rows", auto_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Gap utilities (for both flexbox and grid)
pub fn generateGap(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, axis: ?[]const u8, value: ?[]const u8) !void {
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
    });

    const gap_value = spacing_scale.get(value.?) orelse return;

    if (axis) |ax| {
        if (std.mem.eql(u8, ax, "x")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "column-gap", gap_value);
            try generator.rules.append(generator.allocator, rule);
        } else if (std.mem.eql(u8, ax, "y")) {
            var rule = try generator.createRule(parsed);
            errdefer rule.deinit(generator.allocator);
            try rule.addDeclaration(generator.allocator, "row-gap", gap_value);
            try generator.rules.append(generator.allocator, rule);
        }
    } else {
        var rule = try generator.createRule(parsed);
        errdefer rule.deinit(generator.allocator);
        try rule.addDeclaration(generator.allocator, "gap", gap_value);
        try generator.rules.append(generator.allocator, rule);
    }
}
