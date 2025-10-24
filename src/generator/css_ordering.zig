const std = @import("std");
const CSSRule = @import("css_generator.zig").CSSRule;

/// CSS rule ordering priority
/// Lower numbers come first in the output
pub const OrderPriority = enum(u8) {
    base = 0, // Base layer rules
    components = 10, // Component layer rules
    utilities = 20, // Utility layer rules
    variants = 30, // Variant utilities (hover, focus, etc.)
    responsive = 40, // Responsive utilities
    important = 50, // Important modifier rules
};

/// Get the order priority for a CSS rule
pub fn getOrderPriority(rule: *const CSSRule) u8 {
    // Important rules go last
    if (rule.is_important) {
        return @intFromEnum(OrderPriority.important);
    }

    // Responsive rules go after variants
    if (rule.media != null) {
        return @intFromEnum(OrderPriority.responsive);
    }

    // Rules with pseudo-classes/elements are variants
    if (rule.pseudo != null) {
        return @intFromEnum(OrderPriority.variants);
    }

    // Default to utilities
    return @intFromEnum(OrderPriority.utilities);
}

/// Get responsive breakpoint order
/// Smaller breakpoints come first (mobile-first)
fn getBreakpointOrder(media: []const u8) u16 {
    if (std.mem.indexOf(u8, media, "640px")) |_| return 640; // sm
    if (std.mem.indexOf(u8, media, "768px")) |_| return 768; // md
    if (std.mem.indexOf(u8, media, "1024px")) |_| return 1024; // lg
    if (std.mem.indexOf(u8, media, "1280px")) |_| return 1280; // xl
    if (std.mem.indexOf(u8, media, "1536px")) |_| return 1536; // 2xl

    // max-width breakpoints (reverse order)
    if (std.mem.indexOf(u8, media, "max-width: 1535px")) |_| return 2000;
    if (std.mem.indexOf(u8, media, "max-width: 1279px")) |_| return 2100;
    if (std.mem.indexOf(u8, media, "max-width: 1023px")) |_| return 2200;
    if (std.mem.indexOf(u8, media, "max-width: 767px")) |_| return 2300;
    if (std.mem.indexOf(u8, media, "max-width: 639px")) |_| return 2400;

    // Other media queries
    return 9999;
}

/// Compare function for sorting CSS rules
pub fn compareRules(_: void, a: CSSRule, b: CSSRule) bool {
    // 1. Compare by priority (base < components < utilities < variants < responsive < important)
    const a_priority = getOrderPriority(&a);
    const b_priority = getOrderPriority(&b);

    if (a_priority != b_priority) {
        return a_priority < b_priority;
    }

    // 2. Within responsive, sort by breakpoint size
    if (a.media != null and b.media != null) {
        const a_breakpoint = getBreakpointOrder(a.media.?);
        const b_breakpoint = getBreakpointOrder(b.media.?);
        if (a_breakpoint != b_breakpoint) {
            return a_breakpoint < b_breakpoint;
        }
    }

    // 3. Sort by selector name for determinism
    return std.mem.lessThan(u8, a.selector, b.selector);
}

/// Sort CSS rules in place using deterministic ordering
pub fn sortRules(rules: []CSSRule) void {
    std.mem.sort(CSSRule, rules, {}, compareRules);
}

test "rule ordering priority" {
    var rule_base = try CSSRule.init(std.testing.allocator, ".test");
    defer rule_base.deinit(std.testing.allocator);

    var rule_important = try CSSRule.init(std.testing.allocator, ".test");
    defer rule_important.deinit(std.testing.allocator);
    rule_important.is_important = true;

    var rule_variant = try CSSRule.init(std.testing.allocator, ".test");
    defer rule_variant.deinit(std.testing.allocator);
    rule_variant.pseudo = try std.testing.allocator.dupe(u8, ":hover");

    try std.testing.expect(getOrderPriority(&rule_base) < getOrderPriority(&rule_variant));
    try std.testing.expect(getOrderPriority(&rule_variant) < getOrderPriority(&rule_important));
}

test "breakpoint ordering" {
    try std.testing.expect(getBreakpointOrder("@media (min-width: 640px)") < getBreakpointOrder("@media (min-width: 768px)"));
    try std.testing.expect(getBreakpointOrder("@media (min-width: 768px)") < getBreakpointOrder("@media (min-width: 1024px)"));
}
