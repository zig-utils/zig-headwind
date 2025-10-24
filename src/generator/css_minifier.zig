const std = @import("std");
const string_utils = @import("../utils/string.zig");

/// Minify CSS by removing unnecessary whitespace, comments, and optimizing values
pub fn minify(allocator: std.mem.Allocator, css: []const u8) ![]u8 {
    var result = string_utils.StringBuilder.init(allocator);
    errdefer result.deinit();

    var i: usize = 0;
    var in_string: bool = false;
    var string_char: u8 = 0;
    var in_comment: bool = false;

    while (i < css.len) {
        const c = css[i];

        // Handle comments
        if (!in_string and i + 1 < css.len and css[i] == '/' and css[i + 1] == '*') {
            in_comment = true;
            i += 2;
            continue;
        }

        if (in_comment) {
            if (i + 1 < css.len and css[i] == '*' and css[i + 1] == '/') {
                in_comment = false;
                i += 2;
            } else {
                i += 1;
            }
            continue;
        }

        // Handle strings
        if (c == '"' or c == '\'') {
            if (!in_string) {
                in_string = true;
                string_char = c;
            } else if (c == string_char) {
                in_string = false;
            }
            try result.appendChar(c);
            i += 1;
            continue;
        }

        // Inside strings, preserve everything
        if (in_string) {
            try result.appendChar(c);
            i += 1;
            continue;
        }

        // Minify whitespace
        if (c == ' ' or c == '\n' or c == '\r' or c == '\t') {
            // Check if we need a space
            const prev_char = if (result.len() > 0) result.toString()[result.len() - 1] else 0;
            const next_char = if (i + 1 < css.len) css[i + 1] else 0;

            // Keep space in certain contexts
            const need_space = needsSpace(prev_char, next_char);

            if (need_space) {
                try result.appendChar(' ');
            }

            i += 1;
            continue;
        }

        // Remove space before certain characters
        if (c == '{' or c == '}' or c == ';' or c == ':' or c == ',' or c == ')') {
            // Remove trailing space before these characters
            if (result.len() > 0 and result.toString()[result.len() - 1] == ' ') {
                _ = result.pop();
            }
        }

        // Add the character
        try result.appendChar(c);
        i += 1;
    }

    // Optimize the result
    const unoptimized = try result.toOwnedSlice();
    const color_optimized = try optimizeColors(allocator, unoptimized);
    allocator.free(unoptimized);
    const final_optimized = try optimizeZeros(allocator, color_optimized);
    allocator.free(color_optimized);

    return final_optimized;
}

/// Check if space is needed between two characters
fn needsSpace(prev: u8, next: u8) bool {
    // Need space between alphanumeric characters
    if (isAlphanumeric(prev) and isAlphanumeric(next)) {
        return true;
    }

    // Need space after ':' before value
    if (prev == ':' and isAlphanumeric(next)) {
        return true;
    }

    // Need space in media queries
    if (prev == ')' and isAlphanumeric(next)) {
        return true;
    }

    return false;
}

fn isAlphanumeric(c: u8) bool {
    return (c >= 'a' and c <= 'z') or
        (c >= 'A' and c <= 'Z') or
        (c >= '0' and c <= '9') or
        c == '-' or c == '_';
}

/// Optimize color values (#ffffff -> #fff)
fn optimizeColors(allocator: std.mem.Allocator, css: []const u8) ![]u8 {
    var result = string_utils.StringBuilder.init(allocator);
    errdefer result.deinit();

    var i: usize = 0;
    while (i < css.len) {
        if (css[i] == '#' and i + 7 <= css.len) {
            // Check if it's a 6-digit hex color that can be shortened
            const hex = css[i + 1 .. i + 7];
            if (isHexColor(hex)) {
                if (hex[0] == hex[1] and hex[2] == hex[3] and hex[4] == hex[5]) {
                    // Can be shortened: #ffffff -> #fff
                    try result.appendChar('#');
                    try result.appendChar(hex[0]);
                    try result.appendChar(hex[2]);
                    try result.appendChar(hex[4]);
                    i += 7;
                    continue;
                }
            }
        }

        try result.appendChar(css[i]);
        i += 1;
    }

    return result.toOwnedSlice();
}

fn isHexColor(hex: []const u8) bool {
    if (hex.len != 6) return false;
    for (hex) |c| {
        if (!((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F'))) {
            return false;
        }
    }
    return true;
}

/// Optimize zero values (0px -> 0, 0.5 -> .5)
fn optimizeZeros(allocator: std.mem.Allocator, css: []const u8) ![]u8 {
    var result = string_utils.StringBuilder.init(allocator);
    errdefer result.deinit();

    var i: usize = 0;
    while (i < css.len) {
        // Optimize 0px, 0em, 0rem, etc. -> 0
        if (css[i] == '0' and i + 2 < css.len) {
            if ((css[i + 1] == 'p' and css[i + 2] == 'x') or
                (css[i + 1] == 'e' and css[i + 2] == 'm') or
                (css[i + 1] == 'r' and css[i + 2] == 'e' and i + 3 < css.len and css[i + 3] == 'm'))
            {
                try result.appendChar('0');
                if (css[i + 1] == 'r' and css[i + 2] == 'e' and i + 3 < css.len and css[i + 3] == 'm') {
                    i += 4;
                } else {
                    i += 3;
                }
                continue;
            }
        }

        // Optimize 0.5 -> .5
        if (css[i] == '0' and i + 1 < css.len and css[i + 1] == '.') {
            i += 1; // Skip the leading 0
            continue;
        }

        try result.appendChar(css[i]);
        i += 1;
    }

    return result.toOwnedSlice();
}

test "minify basic CSS" {
    const allocator = std.testing.allocator;

    const input =
        \\.test {
        \\  color: red;
        \\  margin: 0px;
        \\}
    ;

    const output = try minify(allocator, input);
    defer allocator.free(output);

    try std.testing.expect(output.len < input.len);
    try std.testing.expect(std.mem.indexOf(u8, output, ".test{") != null);
}

test "optimize colors" {
    const allocator = std.testing.allocator;

    const input = "color: #ffffff; background: #ff00ff;";
    const output = try optimizeColors(allocator, input);
    defer allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, "#fff") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "#f0f") != null);
}

test "optimize zeros" {
    const allocator = std.testing.allocator;

    const input = "margin: 0px; opacity: 0.5; padding: 0rem;";
    const output = try optimizeZeros(allocator, input);
    defer allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, "0px") == null);
    try std.testing.expect(std.mem.indexOf(u8, output, ".5") != null);
}
