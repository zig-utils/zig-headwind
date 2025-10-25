const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Tailwind color palette (simplified - just common colors with main shades)
const ColorShade = struct { shade: []const u8, value: []const u8 };

pub const colors = std.StaticStringMap([]const ColorShade).initComptime(.{
    .{ "slate", &.{
        ColorShade{ .shade = "50", .value = "#f8fafc" },
        ColorShade{ .shade = "100", .value = "#f1f5f9" },
        ColorShade{ .shade = "200", .value = "#e2e8f0" },
        ColorShade{ .shade = "300", .value = "#cbd5e1" },
        ColorShade{ .shade = "400", .value = "#94a3b8" },
        ColorShade{ .shade = "500", .value = "#64748b" },
        ColorShade{ .shade = "600", .value = "#475569" },
        ColorShade{ .shade = "700", .value = "#334155" },
        ColorShade{ .shade = "800", .value = "#1e293b" },
        ColorShade{ .shade = "900", .value = "#0f172a" },
    } },
    .{ "gray", &.{
        ColorShade{ .shade = "50", .value = "#f9fafb" },
        ColorShade{ .shade = "100", .value = "#f3f4f6" },
        ColorShade{ .shade = "200", .value = "#e5e7eb" },
        ColorShade{ .shade = "300", .value = "#d1d5db" },
        ColorShade{ .shade = "400", .value = "#9ca3af" },
        ColorShade{ .shade = "500", .value = "#6b7280" },
        ColorShade{ .shade = "600", .value = "#4b5563" },
        ColorShade{ .shade = "700", .value = "#374151" },
        ColorShade{ .shade = "800", .value = "#1f2937" },
        ColorShade{ .shade = "900", .value = "#111827" },
    } },
    .{ "red", &.{
        ColorShade{ .shade = "50", .value = "#fef2f2" },
        ColorShade{ .shade = "100", .value = "#fee2e2" },
        ColorShade{ .shade = "200", .value = "#fecaca" },
        ColorShade{ .shade = "300", .value = "#fca5a5" },
        ColorShade{ .shade = "400", .value = "#f87171" },
        ColorShade{ .shade = "500", .value = "#ef4444" },
        ColorShade{ .shade = "600", .value = "#dc2626" },
        ColorShade{ .shade = "700", .value = "#b91c1c" },
        ColorShade{ .shade = "800", .value = "#991b1b" },
        ColorShade{ .shade = "900", .value = "#7f1d1d" },
    } },
    .{ "blue", &.{
        ColorShade{ .shade = "50", .value = "#eff6ff" },
        ColorShade{ .shade = "100", .value = "#dbeafe" },
        ColorShade{ .shade = "200", .value = "#bfdbfe" },
        ColorShade{ .shade = "300", .value = "#93c5fd" },
        ColorShade{ .shade = "400", .value = "#60a5fa" },
        ColorShade{ .shade = "500", .value = "#3b82f6" },
        ColorShade{ .shade = "600", .value = "#2563eb" },
        ColorShade{ .shade = "700", .value = "#1d4ed8" },
        ColorShade{ .shade = "800", .value = "#1e40af" },
        ColorShade{ .shade = "900", .value = "#1e3a8a" },
    } },
    .{ "green", &.{
        ColorShade{ .shade = "50", .value = "#f0fdf4" },
        ColorShade{ .shade = "100", .value = "#dcfce7" },
        ColorShade{ .shade = "200", .value = "#bbf7d0" },
        ColorShade{ .shade = "300", .value = "#86efac" },
        ColorShade{ .shade = "400", .value = "#4ade80" },
        ColorShade{ .shade = "500", .value = "#22c55e" },
        ColorShade{ .shade = "600", .value = "#16a34a" },
        ColorShade{ .shade = "700", .value = "#15803d" },
        ColorShade{ .shade = "800", .value = "#166534" },
        ColorShade{ .shade = "900", .value = "#14532d" },
    } },
    .{ "yellow", &.{
        ColorShade{ .shade = "50", .value = "#fefce8" },
        ColorShade{ .shade = "100", .value = "#fef9c3" },
        ColorShade{ .shade = "200", .value = "#fef08a" },
        ColorShade{ .shade = "300", .value = "#fde047" },
        ColorShade{ .shade = "400", .value = "#facc15" },
        ColorShade{ .shade = "500", .value = "#eab308" },
        ColorShade{ .shade = "600", .value = "#ca8a04" },
        ColorShade{ .shade = "700", .value = "#a16207" },
        ColorShade{ .shade = "800", .value = "#854d0e" },
        ColorShade{ .shade = "900", .value = "#713f12" },
    } },
    .{ "white", &.{ColorShade{ .shade = "", .value = "#ffffff" }} },
    .{ "black", &.{ColorShade{ .shade = "", .value = "#000000" }} },
});

pub fn getColorValue(color_name: []const u8, shade: []const u8) ?[]const u8 {
    const shades = colors.get(color_name) orelse return null;
    for (shades) |s| {
        if (std.mem.eql(u8, s.shade, shade)) {
            return s.value;
        }
    }
    return null;
}

/// Parse color-shade pattern (e.g., "blue-500" -> "blue", "500")
pub fn parseColorShade(value: []const u8) ?struct { color: []const u8, shade: []const u8 } {
    // Find last dash
    var i: usize = value.len;
    while (i > 0) {
        i -= 1;
        if (value[i] == '-') {
            return .{
                .color = value[0..i],
                .shade = value[i + 1 ..],
            };
        }
    }
    // No dash, might be "white" or "black"
    return .{ .color = value, .shade = "" };
}

/// Generate background color utilities
pub fn generateBackground(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const color_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null) blk: {
        break :blk parsed.arbitrary_value.?;
    } else blk: {
        const color_info = parseColorShade(value.?) orelse return;
        break :blk getColorValue(color_info.color, color_info.shade) orelse return;
    };

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "background-color", color_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate text color utilities (reused in typography.zig but extended here)
pub fn generateTextColor(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const color_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null) blk: {
        break :blk parsed.arbitrary_value.?;
    } else blk: {
        const color_info = parseColorShade(value.?) orelse return;
        break :blk getColorValue(color_info.color, color_info.shade) orelse return;
    };

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "color", color_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate border color utilities
pub fn generateBorderColor(generator: *CSSGenerator, parsed: *const class_parser.ParsedClass, value: ?[]const u8) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const color_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null) blk: {
        break :blk parsed.arbitrary_value.?;
    } else blk: {
        const color_info = parseColorShade(value.?) orelse return;
        break :blk getColorValue(color_info.color, color_info.shade) orelse return;
    };

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "border-color", color_value);
    try generator.rules.append(generator.allocator, rule);
}
