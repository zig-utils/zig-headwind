const std = @import("std");
const colors = @import("colors.zig");
const spacing = @import("spacing.zig");
const string_utils = @import("../utils/string.zig");

/// Generate CSS custom properties for the theme
pub fn generateThemeVariables(allocator: std.mem.Allocator) ![]const u8 {
    var result = string_utils.StringBuilder.init(allocator);
    errdefer result.deinit();

    try result.append(":root {\n");

    // Generate color variables
    try result.append("  /* Colors */\n");
    try generateColorVariables(allocator, &result);

    // Generate spacing variables
    try result.append("\n  /* Spacing */\n");
    try generateSpacingVariables(allocator, &result);

    try result.append("}\n");

    return result.toOwnedSlice();
}

fn generateColorVariables(allocator: std.mem.Allocator, builder: *string_utils.StringBuilder) !void {
    _ = allocator;

    // Base colors
    try builder.append("  --color-white: #ffffff;\n");
    try builder.append("  --color-black: #000000;\n");

    // Color palette
    const color_names = [_][]const u8{ "slate", "gray", "red", "blue", "green", "yellow" };

    for (color_names) |color_name| {
        const color_shades = colors.colors.get(color_name) orelse continue;

        for (color_shades) |shade| {
            try builder.append("  --color-");
            try builder.append(color_name);
            try builder.append("-");
            try builder.append(shade.shade);
            try builder.append(": ");
            try builder.append(shade.value);
            try builder.append(";\n");
        }
    }
}

fn generateSpacingVariables(allocator: std.mem.Allocator, builder: *string_utils.StringBuilder) !void {
    _ = allocator;

    // Spacing scale - manually list common values since StaticStringMap doesn't have iterator
    const spacing_values = [_]struct { key: []const u8, value: []const u8 }{
        .{ .key = "0", .value = "0px" },
        .{ .key = "px", .value = "1px" },
        .{ .key = "1", .value = "0.25rem" },
        .{ .key = "2", .value = "0.5rem" },
        .{ .key = "3", .value = "0.75rem" },
        .{ .key = "4", .value = "1rem" },
        .{ .key = "5", .value = "1.25rem" },
        .{ .key = "6", .value = "1.5rem" },
        .{ .key = "8", .value = "2rem" },
        .{ .key = "10", .value = "2.5rem" },
        .{ .key = "12", .value = "3rem" },
        .{ .key = "16", .value = "4rem" },
        .{ .key = "20", .value = "5rem" },
        .{ .key = "24", .value = "6rem" },
        .{ .key = "32", .value = "8rem" },
        .{ .key = "40", .value = "10rem" },
        .{ .key = "48", .value = "12rem" },
        .{ .key = "56", .value = "14rem" },
        .{ .key = "64", .value = "16rem" },
    };

    for (spacing_values) |entry| {
        try builder.append("  --spacing-");
        try builder.append(entry.key);
        try builder.append(": ");
        try builder.append(entry.value);
        try builder.append(";\n");
    }
}

/// Generate CSS with @layer support
pub fn generateLayeredCSS(
    allocator: std.mem.Allocator,
    base: []const u8,
    utilities: []const u8,
) ![]const u8 {
    var result = string_utils.StringBuilder.init(allocator);
    errdefer result.deinit();

    // Define layer order
    try result.append("@layer base, components, utilities;\n\n");

    // Base layer (preflight + theme variables)
    try result.append("@layer base {\n");
    try result.append(base);
    try result.append("}\n\n");

    // Utilities layer
    try result.append("@layer utilities {\n");
    try result.append(utilities);
    try result.append("}\n");

    return result.toOwnedSlice();
}

test "generateThemeVariables" {
    const allocator = std.testing.allocator;

    const css = try generateThemeVariables(allocator);
    defer allocator.free(css);

    try std.testing.expect(css.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, css, "--color-blue-500") != null);
    try std.testing.expect(std.mem.indexOf(u8, css, "--spacing-4") != null);
}
