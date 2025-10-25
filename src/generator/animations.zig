const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Animation values with their corresponding animation property
const animation_values = std.StaticStringMap([]const u8).initComptime(.{
    .{ "none", "none" },
    .{ "spin", "spin 1s linear infinite" },
    .{ "ping", "ping 1s cubic-bezier(0, 0, 0.2, 1) infinite" },
    .{ "pulse", "pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite" },
    .{ "bounce", "bounce 1s infinite" },
});

/// Generate animation utilities
pub fn generateAnimate(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    const animation_value = animation_values.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);
    try rule.addDeclaration(generator.allocator, "animation", animation_value);
    try generator.rules.append(generator.allocator, rule);
}

/// Generate @keyframes for built-in animations
/// This should be called once to add keyframes to the base layer
pub fn generateKeyframes(allocator: std.mem.Allocator) ![]const u8 {
    const string_utils = @import("../utils/string.zig");
    var result = string_utils.StringBuilder.init(allocator);
    errdefer result.deinit();

    // Spin animation
    try result.append("@keyframes spin {\n");
    try result.append("  from { transform: rotate(0deg); }\n");
    try result.append("  to { transform: rotate(360deg); }\n");
    try result.append("}\n\n");

    // Ping animation
    try result.append("@keyframes ping {\n");
    try result.append("  75%, 100% {\n");
    try result.append("    transform: scale(2);\n");
    try result.append("    opacity: 0;\n");
    try result.append("  }\n");
    try result.append("}\n\n");

    // Pulse animation
    try result.append("@keyframes pulse {\n");
    try result.append("  0%, 100% { opacity: 1; }\n");
    try result.append("  50% { opacity: .5; }\n");
    try result.append("}\n\n");

    // Bounce animation
    try result.append("@keyframes bounce {\n");
    try result.append("  0%, 100% {\n");
    try result.append("    transform: translateY(-25%);\n");
    try result.append("    animation-timing-function: cubic-bezier(0.8, 0, 1, 1);\n");
    try result.append("  }\n");
    try result.append("  50% {\n");
    try result.append("    transform: translateY(0);\n");
    try result.append("    animation-timing-function: cubic-bezier(0, 0, 0.2, 1);\n");
    try result.append("  }\n");
    try result.append("}\n");

    return result.toOwnedSlice();
}
