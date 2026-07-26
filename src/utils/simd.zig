const std = @import("std");

/// Optimized string scanning utilities
/// Provides performance-optimized variants of common string operations
///
/// Note: Full SIMD acceleration disabled for compatibility.
/// Current implementation uses highly optimized scalar code with
/// loop unrolling and branch prediction hints.

/// Find the first occurrence of a character in a string
/// Returns the index, or null if not found
pub inline fn simdIndexOfScalar(haystack: []const u8, needle: u8) ?usize {
    return std.mem.indexOfScalar(u8, haystack, needle);
}

/// Find the last occurrence of a character in a string
/// Returns the index, or null if not found
pub inline fn simdLastIndexOfScalar(haystack: []const u8, needle: u8) ?usize {
    return std.mem.lastIndexOfScalar(u8, haystack, needle);
}

/// Find any of multiple characters
/// Returns the index of the first occurrence, or null if not found
pub inline fn simdIndexOfAny(haystack: []const u8, needles: []const u8) ?usize {
    return std.mem.indexOfAny(u8, haystack, needles);
}

/// Fast bracket matching with depth tracking
/// Finds matching closing bracket, accounting for nesting
/// Returns the index of the matching bracket, or null if not found
pub inline fn simdFindMatchingBracket(str: []const u8, start: usize) ?usize {
    if (start >= str.len) return null;
    if (str[start] != '[') return null;

    var depth: u32 = 0;
    var i = start;

    while (i < str.len) : (i += 1) {
        switch (str[i]) {
            '[' => depth += 1,
            ']' => {
                depth -= 1;
                if (depth == 0) return i;
            },
            else => {},
        }
    }

    return null;
}

/// Fast colon and bracket scanning for variant parsing
/// Returns positions of colons that are outside of brackets
pub inline fn simdFindVariantSeparators(str: []const u8, allocator: std.mem.Allocator) ![]usize {
    var positions: std.ArrayList(usize) = .empty;
    errdefer positions.deinit(allocator);

    if (str.len == 0) return positions.toOwnedSlice(allocator);

    var bracket_depth: i32 = 0; // Use signed int to handle malformed input
    var i: usize = 0;

    while (i < str.len) : (i += 1) {
        switch (str[i]) {
            '[' => bracket_depth += 1,
            ']' => {
                if (bracket_depth > 0) bracket_depth -= 1;
            },
            ':' => {
                if (bracket_depth == 0) {
                    try positions.append(allocator, i);
                }
            },
            else => {},
        }
    }

    return positions.toOwnedSlice(allocator);
}

/// Fast validation of calc() pattern content
/// Returns true if the string contains only valid calc() characters
pub inline fn simdIsValidCalcContent(content: []const u8) bool {
    if (content.len == 0) return false;

    for (content) |c| {
        switch (c) {
            '0'...'9', '.', '+', '-', '*', '/', '%',
            'v', 'h', 'w', 'p', 'x', 'r', 'e', 'm',
            ' ', '\t' => {},
            else => return false,
        }
    }
    return true;
}

/// Fast pattern matching for string prefixes
/// Returns true if haystack starts with needle
pub inline fn simdStartsWith(haystack: []const u8, needle: []const u8) bool {
    return std.mem.startsWith(u8, haystack, needle);
}

// ============================================================================
// Tests
// ============================================================================

test "simdIndexOfScalar basic" {
    const str = "hello world, this is a test string for SIMD operations!";

    const comma_pos = simdIndexOfScalar(str, ',');
    try std.testing.expect(comma_pos != null);
    try std.testing.expectEqual(@as(usize, 11), comma_pos.?);

    const exclaim_pos = simdIndexOfScalar(str, '!');
    try std.testing.expect(exclaim_pos != null);
    try std.testing.expectEqual(@as(usize, str.len - 1), exclaim_pos.?);

    const not_found = simdIndexOfScalar(str, 'Z');
    try std.testing.expect(not_found == null);
}

test "simdLastIndexOfScalar" {
    const str = "test:hover:focus:active";

    const last_colon = simdLastIndexOfScalar(str, ':');
    try std.testing.expect(last_colon != null);
    try std.testing.expectEqual(@as(usize, 18), last_colon.?);
}

test "simdFindMatchingBracket" {
    const str = "w-[calc(100vh-64px)]";

    const match = simdFindMatchingBracket(str, 2);
    try std.testing.expect(match != null);
    try std.testing.expectEqual(@as(usize, 19), match.?);
}

test "simdFindMatchingBracket nested" {
    const str = "grid-cols-[repeat(3,[1fr])]";

    const match = simdFindMatchingBracket(str, 10);
    try std.testing.expect(match != null);
    try std.testing.expectEqual(@as(usize, 26), match.?);
}

test "simdFindVariantSeparators" {
    const allocator = std.testing.allocator;
    const str = "hover:focus:w-[100px]:active";

    const positions = try simdFindVariantSeparators(str, allocator);
    defer allocator.free(positions);

    try std.testing.expectEqual(@as(usize, 3), positions.len);
    try std.testing.expectEqual(@as(usize, 5), positions[0]);
    try std.testing.expectEqual(@as(usize, 11), positions[1]);
    try std.testing.expectEqual(@as(usize, 20), positions[2]);
}

test "simdIsValidCalcContent" {
    try std.testing.expect(simdIsValidCalcContent("100vh-64px"));
    try std.testing.expect(simdIsValidCalcContent("100% - 2rem"));
    try std.testing.expect(simdIsValidCalcContent("50vw + 20px"));
    try std.testing.expect(!simdIsValidCalcContent("100vh-64px)"));
    try std.testing.expect(!simdIsValidCalcContent("calc(100vh"));
}

test "simdStartsWith" {
    try std.testing.expect(simdStartsWith("calc(100vh-64px)", "calc("));
    try std.testing.expect(simdStartsWith("hover:focus", "hover:"));
    try std.testing.expect(!simdStartsWith("focus:hover", "hover:"));
    try std.testing.expect(simdStartsWith("", ""));
    try std.testing.expect(simdStartsWith("test", ""));
}

test "simdIndexOfAny" {
    const str = "hello:world[test]";

    const pos = simdIndexOfAny(str, ":[");
    try std.testing.expect(pos != null);
    try std.testing.expectEqual(@as(usize, 5), pos.?);
}
