const std = @import("std");
const CSSGenerator = @import("css_generator.zig").CSSGenerator;
const CSSRule = @import("css_generator.zig").CSSRule;
const class_parser = @import("../parser/class_parser.zig");

/// Aspect ratio values
const aspect_ratios = std.StaticStringMap([]const u8).initComptime(.{
    .{ "auto", "auto" },
    .{ "square", "1 / 1" },
    .{ "video", "16 / 9" },
});

/// Generate aspect ratio utilities (aspect-*)
pub fn generateAspectRatio(
    generator: *CSSGenerator,
    parsed: *const class_parser.ParsedClass,
    value: ?[]const u8,
) !void {
    if (value == null) return;

    // Check for arbitrary value first
    const aspect_value = if (parsed.is_arbitrary and parsed.arbitrary_value != null)
        parsed.arbitrary_value.?
    else
        aspect_ratios.get(value.?) orelse return;

    var rule = try generator.createRule(parsed);
    errdefer rule.deinit(generator.allocator);

    try rule.addDeclaration(generator.allocator, "aspect-ratio", aspect_value);
    try generator.rules.append(generator.allocator, rule);
}
