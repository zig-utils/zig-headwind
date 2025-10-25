const std = @import("std");

/// String pool for deduplication and fast comparison
/// Interned strings can be compared by pointer equality
pub const StringPool = struct {
    allocator: std.mem.Allocator,
    strings: std.StringHashMap([]const u8),
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator) StringPool {
        return .{
            .allocator = allocator,
            .strings = std.StringHashMap([]const u8).init(allocator),
            .arena = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(self: *StringPool) void {
        self.strings.deinit();
        self.arena.deinit();
    }

    /// Intern a string, returning a pointer to the canonical version
    /// If the string already exists in the pool, returns the existing pointer
    /// Otherwise, copies the string into the pool and returns the new pointer
    pub fn intern(self: *StringPool, str: []const u8) ![]const u8 {
        // Check if string already exists
        if (self.strings.get(str)) |existing| {
            return existing;
        }

        // Allocate new string in arena
        const arena_allocator = self.arena.allocator();
        const new_str = try arena_allocator.dupe(u8, str);

        // Store in map
        try self.strings.put(new_str, new_str);

        return new_str;
    }

    /// Check if a string is interned
    pub fn contains(self: *const StringPool, str: []const u8) bool {
        return self.strings.contains(str);
    }

    /// Get number of unique strings in pool
    pub fn count(self: *const StringPool) usize {
        return self.strings.count();
    }

    /// Clear all interned strings
    pub fn clear(self: *StringPool) void {
        self.strings.clearRetainingCapacity();
        // Reset arena
        _ = self.arena.reset(.retain_capacity);
    }

    /// Get memory usage statistics
    pub fn memoryUsage(self: *const StringPool) usize {
        return self.arena.queryCapacity();
    }
};

test "string pool basic operations" {
    var pool = StringPool.init(std.testing.allocator);
    defer pool.deinit();

    const str1 = try pool.intern("hello");
    const str2 = try pool.intern("world");
    const str3 = try pool.intern("hello");

    // Same content should return same pointer
    try std.testing.expect(str1.ptr == str3.ptr);
    try std.testing.expect(str1.ptr != str2.ptr);

    try std.testing.expectEqual(@as(usize, 2), pool.count());
}

test "string pool memory efficiency" {
    var pool = StringPool.init(std.testing.allocator);
    defer pool.deinit();

    // Intern the same string multiple times
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        _ = try pool.intern("repeated-string");
    }

    // Should only store one copy
    try std.testing.expectEqual(@as(usize, 1), pool.count());
}

test "string pool clear" {
    var pool = StringPool.init(std.testing.allocator);
    defer pool.deinit();

    _ = try pool.intern("test1");
    _ = try pool.intern("test2");
    try std.testing.expectEqual(@as(usize, 2), pool.count());

    pool.clear();
    try std.testing.expectEqual(@as(usize, 0), pool.count());
}
