const std = @import("std");

/// Centralized allocator management for Headwind
pub const AllocatorManager = struct {
    /// The base allocator (usually GPA)
    base: std.mem.Allocator,
    /// Arena for request-scoped allocations
    request_arena: ?std.heap.ArenaAllocator = null,

    pub fn init(base_allocator: std.mem.Allocator) AllocatorManager {
        return .{
            .base = base_allocator,
        };
    }

    /// Get allocator for request-scoped operations
    /// This arena will be reset between requests
    pub fn requestAllocator(self: *AllocatorManager) !std.mem.Allocator {
        if (self.request_arena == null) {
            self.request_arena = std.heap.ArenaAllocator.init(self.base);
        }
        return self.request_arena.?.allocator();
    }

    /// Reset request arena (call between build cycles)
    pub fn resetRequest(self: *AllocatorManager) void {
        if (self.request_arena) |*arena| {
            _ = arena.reset(.retain_capacity);
        }
    }

    /// Get base allocator for long-lived allocations
    pub fn baseAllocator(self: *AllocatorManager) std.mem.Allocator {
        return self.base;
    }

    pub fn deinit(self: *AllocatorManager) void {
        if (self.request_arena) |*arena| {
            arena.deinit();
        }
    }
};

/// String pool for deduplication and interning
pub const StringPool = struct {
    allocator: std.mem.Allocator,
    pool: std.StringHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator) StringPool {
        return .{
            .allocator = allocator,
            .pool = std.StringHashMap([]const u8).init(allocator),
        };
    }

    /// Intern a string - returns a deduplicated copy
    pub fn intern(self: *StringPool, str: []const u8) ![]const u8 {
        if (self.pool.get(str)) |existing| {
            return existing;
        }

        const owned = try self.allocator.dupe(u8, str);
        try self.pool.put(owned, owned);
        return owned;
    }

    /// Check if string is already interned
    pub fn contains(self: *StringPool, str: []const u8) bool {
        return self.pool.contains(str);
    }

    /// Get the number of unique strings
    pub fn count(self: *StringPool) usize {
        return self.pool.count();
    }

    pub fn deinit(self: *StringPool) void {
        var iter = self.pool.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.pool.deinit();
    }
};

/// Object pool for reusing allocations
pub fn ObjectPool(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        available: std.ArrayList(*T),
        all: std.ArrayList(*T),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .available = std.ArrayList(*T).init(allocator),
                .all = std.ArrayList(*T).init(allocator),
            };
        }

        /// Acquire an object from the pool
        pub fn acquire(self: *Self) !*T {
            if (self.available.items.len > 0) {
                return self.available.pop();
            }

            const obj = try self.allocator.create(T);
            try self.all.append(obj);
            return obj;
        }

        /// Release an object back to the pool
        pub fn release(self: *Self, obj: *T) !void {
            try self.available.append(obj);
        }

        pub fn deinit(self: *Self) void {
            for (self.all.items) |obj| {
                self.allocator.destroy(obj);
            }
            self.available.deinit();
            self.all.deinit();
        }
    };
}

test "AllocatorManager" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var manager = AllocatorManager.init(gpa.allocator());
    defer manager.deinit();

    const alloc = try manager.requestAllocator();
    const str = try alloc.dupe(u8, "test");
    _ = str;

    manager.resetRequest();
}

test "StringPool" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var pool = StringPool.init(gpa.allocator());
    defer pool.deinit();

    const str1 = try pool.intern("hello");
    const str2 = try pool.intern("hello");

    try std.testing.expect(str1.ptr == str2.ptr); // Same pointer = deduplicated
    try std.testing.expectEqual(@as(usize, 1), pool.count());
}

test "ObjectPool" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const TestStruct = struct { value: u32 };
    var pool = ObjectPool(TestStruct).init(gpa.allocator());
    defer pool.deinit();

    const obj1 = try pool.acquire();
    obj1.value = 42;

    try pool.release(obj1);

    const obj2 = try pool.acquire();
    try std.testing.expect(obj1 == obj2); // Same object reused
}
