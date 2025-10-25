const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Cursor values
const cursor_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "auto", "auto" },
    .{ "default", "default" },
    .{ "pointer", "pointer" },
    .{ "wait", "wait" },
    .{ "text", "text" },
    .{ "move", "move" },
    .{ "help", "help" },
    .{ "not-allowed", "not-allowed" },
    .{ "none", "none" },
    .{ "context-menu", "context-menu" },
    .{ "progress", "progress" },
    .{ "cell", "cell" },
    .{ "crosshair", "crosshair" },
    .{ "vertical-text", "vertical-text" },
    .{ "alias", "alias" },
    .{ "copy", "copy" },
    .{ "no-drop", "no-drop" },
    .{ "grab", "grab" },
    .{ "grabbing", "grabbing" },
    .{ "all-scroll", "all-scroll" },
    .{ "col-resize", "col-resize" },
    .{ "row-resize", "row-resize" },
    .{ "n-resize", "n-resize" },
    .{ "e-resize", "e-resize" },
    .{ "s-resize", "s-resize" },
    .{ "w-resize", "w-resize" },
    .{ "ne-resize", "ne-resize" },
    .{ "nw-resize", "nw-resize" },
    .{ "se-resize", "se-resize" },
    .{ "sw-resize", "sw-resize" },
    .{ "ew-resize", "ew-resize" },
    .{ "ns-resize", "ns-resize" },
    .{ "nesw-resize", "nesw-resize" },
    .{ "nwse-resize", "nwse-resize" },
    .{ "zoom-in", "zoom-in" },
    .{ "zoom-out", "zoom-out" },
});

/// Pointer events values
const pointer_events_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "none" },
    .{ "auto", "auto" },
});

/// Resize values
const resize_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "none" },
    .{ "", "both" },
    .{ "x", "horizontal" },
    .{ "y", "vertical" },
});

/// Scroll behavior values
const scroll_behavior_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "auto", "auto" },
    .{ "smooth", "smooth" },
});

/// User select values
const user_select_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "none" },
    .{ "text", "text" },
    .{ "all", "all" },
    .{ "auto", "auto" },
});

/// Appearance values
const appearance_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "none" },
    .{ "auto", "auto" },
});

/// Caret color values (uses color system)
const colors = @import("colors.zig");

/// Generate cursor utilities
pub fn generateCursor(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const cursor_value = cursor_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "cursor", cursor_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate pointer-events utilities
pub fn generatePointerEvents(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const pointer_value = pointer_events_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "pointer-events", pointer_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate resize utilities
pub fn generateResize(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const resize_value = if (value) |v|
        resize_values.get(v) orelse return
    else
        resize_values.get("") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "resize", resize_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate scroll-behavior utilities
pub fn generateScrollBehavior(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const scroll_value = scroll_behavior_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "scroll-behavior", scroll_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate user-select utilities
pub fn generateSelect(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const select_value = user_select_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "user-select", select_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate appearance utilities
pub fn generateAppearance(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const appearance_value = appearance_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "appearance", appearance_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate caret-color utilities
pub fn generateCaretColor(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const color_info = colors.parseColorShade(value.?) orelse return;
    const color_value = colors.getColorValue(color_info.color, color_info.shade) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "caret-color", color_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate accent-color utilities
pub fn generateAccentColor(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const color_info = colors.parseColorShade(value.?) orelse return;
    const color_value = colors.getColorValue(color_info.color, color_info.shade) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "accent-color", color_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate will-change utilities
pub fn generateWillChange(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const will_change_values = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "scroll", "scroll-position" },
        .{ "contents", "contents" },
        .{ "transform", "transform" },
    });

    const will_change_value = will_change_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "will-change", will_change_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Spacing scale for scroll margin/padding
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
    .{ "12", "3rem" },
    .{ "16", "4rem" },
    .{ "20", "5rem" },
    .{ "24", "6rem" },
    .{ "32", "8rem" },
});

/// Generate scroll-margin utilities
pub fn generateScrollMargin(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    side: ?[]const u8,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const spacing_value = spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    if (side) |s| {
        if (std.mem.eql(u8, s, "x")) {
            try rule.addDeclaration(generator.allocator, "scroll-margin-left", spacing_value);
            try rule.addDeclaration(generator.allocator, "scroll-margin-right", spacing_value);
        } else if (std.mem.eql(u8, s, "y")) {
            try rule.addDeclaration(generator.allocator, "scroll-margin-top", spacing_value);
            try rule.addDeclaration(generator.allocator, "scroll-margin-bottom", spacing_value);
        } else if (std.mem.eql(u8, s, "t")) {
            try rule.addDeclaration(generator.allocator, "scroll-margin-top", spacing_value);
        } else if (std.mem.eql(u8, s, "r")) {
            try rule.addDeclaration(generator.allocator, "scroll-margin-right", spacing_value);
        } else if (std.mem.eql(u8, s, "b")) {
            try rule.addDeclaration(generator.allocator, "scroll-margin-bottom", spacing_value);
        } else if (std.mem.eql(u8, s, "l")) {
            try rule.addDeclaration(generator.allocator, "scroll-margin-left", spacing_value);
        }
    } else {
        try rule.addDeclaration(generator.allocator, "scroll-margin", spacing_value);
    }
    try generator.rules.append(generator.allocator, rule);
}

/// Generate scroll-padding utilities
pub fn generateScrollPadding(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    side: ?[]const u8,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const spacing_value = spacing_scale.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    if (side) |s| {
        if (std.mem.eql(u8, s, "x")) {
            try rule.addDeclaration(generator.allocator, "scroll-padding-left", spacing_value);
            try rule.addDeclaration(generator.allocator, "scroll-padding-right", spacing_value);
        } else if (std.mem.eql(u8, s, "y")) {
            try rule.addDeclaration(generator.allocator, "scroll-padding-top", spacing_value);
            try rule.addDeclaration(generator.allocator, "scroll-padding-bottom", spacing_value);
        } else if (std.mem.eql(u8, s, "t")) {
            try rule.addDeclaration(generator.allocator, "scroll-padding-top", spacing_value);
        } else if (std.mem.eql(u8, s, "r")) {
            try rule.addDeclaration(generator.allocator, "scroll-padding-right", spacing_value);
        } else if (std.mem.eql(u8, s, "b")) {
            try rule.addDeclaration(generator.allocator, "scroll-padding-bottom", spacing_value);
        } else if (std.mem.eql(u8, s, "l")) {
            try rule.addDeclaration(generator.allocator, "scroll-padding-left", spacing_value);
        }
    } else {
        try rule.addDeclaration(generator.allocator, "scroll-padding", spacing_value);
    }
    try generator.rules.append(generator.allocator, rule);
}

/// Generate scroll-snap-type utilities
pub fn generateScrollSnapType(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const snap_type_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "none", "none" },
        .{ "x", "x var(--tw-scroll-snap-strictness)" },
        .{ "y", "y var(--tw-scroll-snap-strictness)" },
        .{ "both", "both var(--tw-scroll-snap-strictness)" },
        .{ "mandatory", "var(--tw-scroll-snap-strictness)" },
        .{ "proximity", "var(--tw-scroll-snap-strictness)" },
    });

    const snap_value = snap_type_map.get(value orelse "none") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "scroll-snap-type", snap_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate scroll-snap-align utilities
pub fn generateScrollSnapAlign(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const snap_align_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "start", "start" },
        .{ "end", "end" },
        .{ "center", "center" },
        .{ "none", "none" },
    });

    const align_value = snap_align_map.get(value orelse "start") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "scroll-snap-align", align_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate scroll-snap-stop utilities
pub fn generateScrollSnapStop(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const snap_stop_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "normal", "normal" },
        .{ "always", "always" },
    });

    const stop_value = snap_stop_map.get(value orelse "normal") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "scroll-snap-stop", stop_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate touch-action utilities
pub fn generateTouchAction(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    const touch_action_map = std.StaticStringMap([]const u8).initComptime(.{
        .{ "auto", "auto" },
        .{ "none", "none" },
        .{ "pan-x", "pan-x" },
        .{ "pan-left", "pan-left" },
        .{ "pan-right", "pan-right" },
        .{ "pan-y", "pan-y" },
        .{ "pan-up", "pan-up" },
        .{ "pan-down", "pan-down" },
        .{ "pinch-zoom", "pinch-zoom" },
        .{ "manipulation", "manipulation" },
    });

    const action_value = touch_action_map.get(value orelse "auto") orelse return;

    var rule = try generator.createRule(parsed);
    try rule.addDeclaration(generator.allocator, "touch-action", action_value);
    try generator.rules.append(generator.allocator, rule);
}
