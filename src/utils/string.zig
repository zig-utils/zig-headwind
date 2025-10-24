const std = @import("std");

/// Fast string hashing using FNV-1a
pub fn hashString(str: []const u8) u64 {
    const FNV_OFFSET: u64 = 14695981039346656037;
    const FNV_PRIME: u64 = 1099511628211;

    var hash: u64 = FNV_OFFSET;
    for (str) |byte| {
        hash ^= byte;
        hash *%= FNV_PRIME;
    }
    return hash;
}

/// StringBuilder for efficient string concatenation
pub const StringBuilder = struct {
    buffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) StringBuilder {
        return .{
            .buffer = std.ArrayList(u8){},
            .allocator = allocator,
        };
    }

    pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) !StringBuilder {
        var buffer: std.ArrayList(u8) = .{};
        try buffer.ensureTotalCapacity(allocator, capacity);
        return .{
            .buffer = buffer,
            .allocator = allocator,
        };
    }

    pub fn append(self: *StringBuilder, str: []const u8) !void {
        try self.buffer.appendSlice(self.allocator, str);
    }

    pub fn appendChar(self: *StringBuilder, char: u8) !void {
        try self.buffer.append(self.allocator, char);
    }

    pub fn clear(self: *StringBuilder) void {
        self.buffer.clearRetainingCapacity();
    }

    pub fn toString(self: *StringBuilder) []const u8 {
        return self.buffer.items;
    }

    pub fn toOwnedSlice(self: *StringBuilder) ![]u8 {
        return self.buffer.toOwnedSlice(self.allocator);
    }

    pub fn len(self: *const StringBuilder) usize {
        return self.buffer.items.len;
    }

    pub fn pop(self: *StringBuilder) ?u8 {
        if (self.buffer.items.len == 0) return null;
        return self.buffer.pop();
    }

    pub fn deinit(self: *StringBuilder) void {
        self.buffer.deinit(self.allocator);
    }
};

/// Case conversion utilities
pub fn toKebabCase(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .{};
    errdefer result.deinit(allocator);

    for (str, 0..) |char, i| {
        if (char >= 'A' and char <= 'Z') {
            if (i > 0) {
                try result.append(allocator, '-');
            }
            try result.append(allocator, char + 32); // Convert to lowercase
        } else if (char == '_') {
            try result.append(allocator, '-');
        } else {
            try result.append(allocator, char);
        }
    }

    return result.toOwnedSlice(allocator);
}

pub fn toCamelCase(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .{};
    errdefer result.deinit(allocator);

    var capitalize_next = false;
    for (str) |char| {
        if (char == '-' or char == '_') {
            capitalize_next = true;
            continue;
        }

        if (capitalize_next) {
            if (char >= 'a' and char <= 'z') {
                try result.append(allocator, char - 32);
            } else {
                try result.append(allocator, char);
            }
            capitalize_next = false;
        } else {
            try result.append(allocator, char);
        }
    }

    return result.toOwnedSlice(allocator);
}

/// Split string by delimiter
pub fn split(allocator: std.mem.Allocator, str: []const u8, delimiter: u8) ![][]const u8 {
    var parts: std.ArrayList([]const u8) = .{};
    errdefer parts.deinit(allocator);

    var start: usize = 0;
    for (str, 0..) |char, i| {
        if (char == delimiter) {
            if (i > start) {
                try parts.append(allocator, str[start..i]);
            }
            start = i + 1;
        }
    }

    if (start < str.len) {
        try parts.append(allocator, str[start..]);
    }

    return parts.toOwnedSlice(allocator);
}

/// Trim whitespace from both ends
pub fn trim(str: []const u8) []const u8 {
    if (str.len == 0) return str;

    var start: usize = 0;
    var end: usize = str.len;

    while (start < end and std.ascii.isWhitespace(str[start])) {
        start += 1;
    }

    while (end > start and std.ascii.isWhitespace(str[end - 1])) {
        end -= 1;
    }

    return str[start..end];
}

/// Escape string for CSS
pub fn escapeCSSString(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
    var result = StringBuilder.init(allocator);
    errdefer result.deinit();

    for (str) |char| {
        switch (char) {
            '\\', '"', '\'' => {
                try result.appendChar('\\');
                try result.appendChar(char);
            },
            '\n' => {
                try result.append("\\n");
            },
            '\r' => {
                try result.append("\\r");
            },
            '\t' => {
                try result.append("\\t");
            },
            else => {
                try result.appendChar(char);
            },
        }
    }

    return result.toOwnedSlice();
}

/// Check if string contains substring
pub fn contains(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;
    if (needle.len == 0) return true;

    for (0..haystack.len - needle.len + 1) |i| {
        if (std.mem.eql(u8, haystack[i .. i + needle.len], needle)) {
            return true;
        }
    }

    return false;
}

/// Check if string starts with prefix
pub fn startsWith(str: []const u8, prefix: []const u8) bool {
    if (prefix.len > str.len) return false;
    return std.mem.eql(u8, str[0..prefix.len], prefix);
}

/// Check if string ends with suffix
pub fn endsWith(str: []const u8, suffix: []const u8) bool {
    if (suffix.len > str.len) return false;
    return std.mem.eql(u8, str[str.len - suffix.len ..], suffix);
}

test "hashString" {
    const hash1 = hashString("test");
    const hash2 = hashString("test");
    const hash3 = hashString("different");

    try std.testing.expectEqual(hash1, hash2);
    try std.testing.expect(hash1 != hash3);
}

test "StringBuilder" {
    var sb = StringBuilder.init(std.testing.allocator);
    defer sb.deinit();

    try sb.append("Hello");
    try sb.append(" ");
    try sb.append("World");

    const result = sb.toString();
    try std.testing.expectEqualStrings("Hello World", result);
}

test "toKebabCase" {
    const result = try toKebabCase(std.testing.allocator, "camelCase");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("camel-case", result);
}

test "toCamelCase" {
    const result = try toCamelCase(std.testing.allocator, "kebab-case");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("kebabCase", result);
}

test "split" {
    const result = try split(std.testing.allocator, "a:b:c", ':');
    defer std.testing.allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectEqualStrings("a", result[0]);
    try std.testing.expectEqualStrings("b", result[1]);
    try std.testing.expectEqualStrings("c", result[2]);
}

test "trim" {
    try std.testing.expectEqualStrings("test", trim("  test  "));
    try std.testing.expectEqualStrings("test", trim("test"));
    try std.testing.expectEqualStrings("", trim("   "));
}

test "contains" {
    try std.testing.expect(contains("hello world", "world"));
    try std.testing.expect(!contains("hello world", "foo"));
}

test "startsWith and endsWith" {
    try std.testing.expect(startsWith("hello world", "hello"));
    try std.testing.expect(!startsWith("hello world", "world"));
    try std.testing.expect(endsWith("hello world", "world"));
    try std.testing.expect(!endsWith("hello world", "hello"));
}
