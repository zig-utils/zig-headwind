const std = @import("std");

/// Arbitrary value result
pub const ArbitraryValue = struct {
    value: []const u8,
    is_arbitrary: bool,

    pub fn init(value: []const u8, is_arbitrary: bool) ArbitraryValue {
        return .{
            .value = value,
            .is_arbitrary = is_arbitrary,
        };
    }
};

/// Parse arbitrary value from a utility value
/// Examples:
///   - w-[100px] -> ArbitraryValue{ .value = "100px", .is_arbitrary = true }
///   - w-full -> ArbitraryValue{ .value = "full", .is_arbitrary = false }
pub fn parseArbitraryValue(input: []const u8) ?ArbitraryValue {
    if (input.len == 0) return null;

    // Check if it starts with [ and ends with ]
    if (input[0] == '[' and input[input.len - 1] == ']') {
        const value = input[1 .. input.len - 1];
        if (value.len == 0) return null;
        return ArbitraryValue.init(value, true);
    }

    return ArbitraryValue.init(input, false);
}

/// Validate arbitrary value
pub fn validateArbitraryValue(value: []const u8) bool {
    if (value.len == 0) return false;

    // Check for basic CSS value patterns
    // Allow: numbers, units (px, rem, em, %, vh, vw, etc.), calc(), var(), colors (#hex, rgb, hsl)

    // Allow CSS variables
    if (std.mem.startsWith(u8, value, "var(") and std.mem.endsWith(u8, value, ")")) {
        return true;
    }

    // Allow calc() expressions
    if (std.mem.startsWith(u8, value, "calc(") and std.mem.endsWith(u8, value, ")")) {
        return true;
    }

    // Allow hex colors
    if (value[0] == '#') {
        const hex = value[1..];
        if (hex.len == 3 or hex.len == 6 or hex.len == 8) {
            for (hex) |c| {
                if (!std.ascii.isHex(c)) return false;
            }
            return true;
        }
    }

    // Allow rgb/rgba colors
    if (std.mem.startsWith(u8, value, "rgb(") or std.mem.startsWith(u8, value, "rgba(")) {
        return std.mem.endsWith(u8, value, ")");
    }

    // Allow hsl/hsla colors
    if (std.mem.startsWith(u8, value, "hsl(") or std.mem.startsWith(u8, value, "hsla(")) {
        return std.mem.endsWith(u8, value, ")");
    }

    // Allow numbers with units
    var has_digit = false;
    for (value) |c| {
        if (std.ascii.isDigit(c) or c == '.' or c == '-') {
            has_digit = true;
        } else if (std.ascii.isAlphabetic(c) or c == '%') {
            // Unit character, allowed if we've seen a digit
            if (!has_digit) return false;
        } else if (c == ' ' or c == ',' or c == '(' or c == ')' or c == '/') {
            // Allow spaces, commas, parens, slashes (for things like "0 0 10px", "1/2")
            continue;
        } else {
            return false;
        }
    }

    return has_digit;
}

/// Escape special characters in arbitrary values for CSS
pub fn escapeForCSS(allocator: std.mem.Allocator, value: []const u8) ![]const u8 {
    // Count characters that need escaping
    var escape_count: usize = 0;
    for (value) |c| {
        if (needsEscape(c)) escape_count += 1;
    }

    if (escape_count == 0) {
        return try allocator.dupe(u8, value);
    }

    // Allocate with extra space for escape characters
    var result = try allocator.alloc(u8, value.len + escape_count);
    var i: usize = 0;
    for (value) |c| {
        if (needsEscape(c)) {
            result[i] = '\\';
            i += 1;
        }
        result[i] = c;
        i += 1;
    }

    return result;
}

fn needsEscape(c: u8) bool {
    return c == '(' or c == ')' or c == '[' or c == ']' or
           c == '{' or c == '}' or c == ',' or c == ':' or
           c == '.' or c == '#' or c == ' ';
}

/// Extract opacity modifier from value (e.g., "blue-500/50" -> { color: "blue-500", opacity: "50" })
pub const ValueWithOpacity = struct {
    value: []const u8,
    opacity: ?[]const u8,
};

pub fn parseOpacityModifier(value: []const u8) ValueWithOpacity {
    // Find the last '/' character
    var i: usize = value.len;
    while (i > 0) {
        i -= 1;
        if (value[i] == '/') {
            return .{
                .value = value[0..i],
                .opacity = value[i + 1 ..],
            };
        }
    }

    return .{
        .value = value,
        .opacity = null,
    };
}

test "parseArbitraryValue" {
    const result1 = parseArbitraryValue("[100px]");
    try std.testing.expect(result1 != null);
    try std.testing.expect(result1.?.is_arbitrary);
    try std.testing.expectEqualStrings("100px", result1.?.value);

    const result2 = parseArbitraryValue("full");
    try std.testing.expect(result2 != null);
    try std.testing.expect(!result2.?.is_arbitrary);
    try std.testing.expectEqualStrings("full", result2.?.value);

    const result3 = parseArbitraryValue("[]");
    try std.testing.expect(result3 == null);
}

test "validateArbitraryValue" {
    try std.testing.expect(validateArbitraryValue("100px"));
    try std.testing.expect(validateArbitraryValue("10rem"));
    try std.testing.expect(validateArbitraryValue("50%"));
    try std.testing.expect(validateArbitraryValue("var(--my-color)"));
    try std.testing.expect(validateArbitraryValue("calc(100% - 2rem)"));
    try std.testing.expect(validateArbitraryValue("#ff0000"));
    try std.testing.expect(validateArbitraryValue("rgb(255, 0, 0)"));
    try std.testing.expect(!validateArbitraryValue(""));
    try std.testing.expect(!validateArbitraryValue("invalid"));
}

test "parseOpacityModifier" {
    const result1 = parseOpacityModifier("blue-500/50");
    try std.testing.expectEqualStrings("blue-500", result1.value);
    try std.testing.expectEqualStrings("50", result1.opacity.?);

    const result2 = parseOpacityModifier("blue-500");
    try std.testing.expectEqualStrings("blue-500", result2.value);
    try std.testing.expect(result2.opacity == null);
}
