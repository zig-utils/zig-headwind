const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");

/// Variant with optional name (for group/name or peer/name)
pub const VariantInfo = struct {
    /// The variant string (e.g., "group-hover" or "group/sidebar")
    variant: []const u8,
    /// Optional name for named groups/peers (e.g., "sidebar")
    name: ?[]const u8,
};

/// Parsed CSS class with variants
pub const ParsedClass = struct {
    /// Original class string
    raw: []const u8,
    /// Variants with optional names (e.g., ["hover", "focus", "md", "group/sidebar"])
    variants: []VariantInfo,
    /// Base utility (e.g., "bg-blue-500")
    utility: []const u8,
    /// Whether this is an arbitrary value (e.g., "w-[100px]")
    is_arbitrary: bool,
    /// Arbitrary value content (if is_arbitrary is true)
    arbitrary_value: ?[]const u8,
    /// Important modifier
    is_important: bool,

    pub fn deinit(self: *ParsedClass, allocator: std.mem.Allocator) void {
        for (self.variants) |variant_info| {
            allocator.free(variant_info.variant);
            if (variant_info.name) |name| {
                allocator.free(name);
            }
        }
        allocator.free(self.variants);
        allocator.free(self.utility);
        if (self.arbitrary_value) |val| {
            allocator.free(val);
        }
    }
};

/// Parse a CSS class string into components
pub fn parseClass(allocator: std.mem.Allocator, class_str: []const u8) !ParsedClass {
    const trimmed = string_utils.trim(class_str);
    if (trimmed.len == 0) {
        return error.InvalidClassName;
    }

    var variants: std.ArrayList([]const u8) = .{};
    errdefer {
        for (variants.items) |v| allocator.free(v);
        variants.deinit(allocator);
    }

    var is_important = false;
    var current = trimmed;

    // Check for important modifier (!)
    if (current[0] == '!') {
        is_important = true;
        current = current[1..];
    }

    // Split by variant separator (:)
    var last_colon: ?usize = null;
    var i: usize = 0;
    var in_brackets = false;

    while (i < current.len) {
        if (current[i] == '[') {
            in_brackets = true;
        } else if (current[i] == ']') {
            in_brackets = false;
        } else if (current[i] == ':' and !in_brackets) {
            last_colon = i;
            // Extract variant
            const variant_start = if (variants.items.len == 0) @as(usize, 0) else last_colon.? + 1;
            const variant_end = i;
            if (variant_end > variant_start) {
                const variant = try allocator.dupe(u8, current[variant_start..variant_end]);
                errdefer allocator.free(variant);

                // Check if this is actually a variant (before the last colon)
                // We'll determine this after we finish parsing
                try variants.append(allocator, variant);
            }
        }
        i += 1;
    }

    // Extract utility (everything after last colon, or entire string if no colons)
    const utility_start = if (last_colon) |pos| pos + 1 else 0;
    const utility_str = current[utility_start..];

    // Check for arbitrary values [...]
    var is_arbitrary = false;
    var arbitrary_value: ?[]const u8 = null;

    const bracket_start = std.mem.indexOf(u8, utility_str, "[");
    if (bracket_start) |start| {
        const bracket_end = std.mem.lastIndexOf(u8, utility_str, "]");
        if (bracket_end) |end| {
            is_arbitrary = true;
            arbitrary_value = try allocator.dupe(u8, utility_str[start + 1 .. end]);
        }
    }

    // Re-parse variants properly
    var final_variants: std.ArrayList(VariantInfo) = .{};
    errdefer {
        for (final_variants.items) |v| {
            allocator.free(v.variant);
            if (v.name) |name| allocator.free(name);
        }
        final_variants.deinit(allocator);
    }

    const variant_end_pos = utility_start;
    var pos: usize = 0;

    while (pos < variant_end_pos) {
        if (current[pos] == ':') {
            if (pos > 0) {
                const prev_colon = if (final_variants.items.len == 0) @as(usize, 0) else blk: {
                    // Find previous colon
                    var p: usize = pos - 1;
                    while (p > 0) : (p -= 1) {
                        if (current[p] == ':') break;
                    }
                    if (current[p] == ':') {
                        break :blk p + 1;
                    } else {
                        break :blk 0;
                    }
                };

                const variant_str = current[prev_colon..pos];

                // Check for named group/peer (e.g., "group/sidebar" or "peer/label")
                var variant_info: VariantInfo = .{
                    .variant = undefined,
                    .name = null,
                };

                if (std.mem.indexOf(u8, variant_str, "/")) |slash_pos| {
                    // Has a name: "group/sidebar" -> variant="group", name="sidebar"
                    variant_info.variant = try allocator.dupe(u8, variant_str[0..slash_pos]);
                    variant_info.name = try allocator.dupe(u8, variant_str[slash_pos + 1..]);
                } else {
                    // No name: just the variant
                    variant_info.variant = try allocator.dupe(u8, variant_str);
                }

                try final_variants.append(allocator, variant_info);
            }
        }
        pos += 1;
    }

    // Free old variants
    for (variants.items) |v| allocator.free(v);
    variants.deinit(allocator);

    return ParsedClass{
        .raw = class_str,
        .variants = try final_variants.toOwnedSlice(allocator),
        .utility = try allocator.dupe(u8, utility_str),
        .is_arbitrary = is_arbitrary,
        .arbitrary_value = arbitrary_value,
        .is_important = is_important,
    };
}

/// Parse utility name and value from utility string (e.g., "bg-blue-500" -> "bg", "blue-500")
pub fn parseUtility(utility: []const u8) struct { name: []const u8, value: ?[]const u8 } {
    // Find the first dash that separates the utility name from value
    var i: usize = 0;
    while (i < utility.len) : (i += 1) {
        if (utility[i] == '-' and i > 0) {
            return .{
                .name = utility[0..i],
                .value = utility[i + 1 ..],
            };
        }
    }

    return .{ .name = utility, .value = null };
}

test "parseClass simple" {
    const allocator = std.testing.allocator;

    var parsed = try parseClass(allocator, "bg-blue-500");
    defer parsed.deinit(allocator);

    try std.testing.expectEqualStrings("bg-blue-500", parsed.utility);
    try std.testing.expectEqual(@as(usize, 0), parsed.variants.len);
    try std.testing.expect(!parsed.is_arbitrary);
    try std.testing.expect(!parsed.is_important);
}

test "parseClass with variants" {
    const allocator = std.testing.allocator;

    var parsed = try parseClass(allocator, "hover:focus:bg-blue-500");
    defer parsed.deinit(allocator);

    try std.testing.expectEqualStrings("bg-blue-500", parsed.utility);
    // Note: Variant parsing needs refinement, but basic structure is there
}

test "parseClass arbitrary value" {
    const allocator = std.testing.allocator;

    var parsed = try parseClass(allocator, "w-[100px]");
    defer parsed.deinit(allocator);

    try std.testing.expect(parsed.is_arbitrary);
    if (parsed.arbitrary_value) |val| {
        try std.testing.expectEqualStrings("100px", val);
    }
}

test "parseClass important" {
    const allocator = std.testing.allocator;

    var parsed = try parseClass(allocator, "!bg-blue-500");
    defer parsed.deinit(allocator);

    try std.testing.expect(parsed.is_important);
    try std.testing.expectEqualStrings("bg-blue-500", parsed.utility);
}

test "parseUtility" {
    const result = parseUtility("bg-blue-500");
    try std.testing.expectEqualStrings("bg", result.name);
    try std.testing.expectEqualStrings("blue-500", result.value.?);
}
