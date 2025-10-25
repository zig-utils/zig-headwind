const std = @import("std");

/// Memory pool for frequent allocations
/// Reduces allocation overhead by pre-allocating a large block
pub fn MemoryPool(comptime T: type) type {
    return struct {
        const Self = @This();
        const BlockSize = 256; // Number of items per block

        allocator: std.mem.Allocator,
        blocks: std.ArrayList([]T),
        free_list: std.ArrayList(*T),
        current_block_index: usize,
        current_block_offset: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .blocks = std.ArrayList([]T).init(allocator),
                .free_list = std.ArrayList(*T).init(allocator),
                .current_block_index = 0,
                .current_block_offset = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.blocks.items) |block| {
                self.allocator.free(block);
            }
            self.blocks.deinit();
            self.free_list.deinit();
        }

        /// Allocate an item from the pool
        pub fn create(self: *Self) !*T {
            // Try to reuse from free list first
            if (self.free_list.items.len > 0) {
                return self.free_list.pop();
            }

            // Check if we need a new block
            if (self.blocks.items.len == 0 or self.current_block_offset >= BlockSize) {
                const new_block = try self.allocator.alloc(T, BlockSize);
                try self.blocks.append(new_block);
                self.current_block_index = self.blocks.items.len - 1;
                self.current_block_offset = 0;
            }

            // Get item from current block
            const block = self.blocks.items[self.current_block_index];
            const item = &block[self.current_block_offset];
            self.current_block_offset += 1;

            return item;
        }

        /// Return an item to the pool for reuse
        pub fn destroy(self: *Self, item: *T) !void {
            try self.free_list.append(item);
        }

        /// Get total capacity (items allocated, not necessarily in use)
        pub fn capacity(self: *const Self) usize {
            return self.blocks.items.len * BlockSize;
        }

        /// Get number of items in use
        pub fn inUse(self: *const Self) usize {
            const total_allocated = if (self.blocks.items.len > 0)
                (self.blocks.items.len - 1) * BlockSize + self.current_block_offset
            else
                0;
            return total_allocated - self.free_list.items.len;
        }
    };
}

test "memory pool basic operations" {
    const allocator = std.testing.allocator;

    const Item = struct {
        value: u32,
    };

    var pool = MemoryPool(Item).init(allocator);
    defer pool.deinit();

    // Allocate some items
    const item1 = try pool.create();
    item1.value = 42;

    const item2 = try pool.create();
    item2.value = 100;

    try std.testing.expectEqual(@as(u32, 42), item1.value);
    try std.testing.expectEqual(@as(u32, 100), item2.value);
    try std.testing.expectEqual(@as(usize, 2), pool.inUse());

    // Free one
    try pool.destroy(item1);
    try std.testing.expectEqual(@as(usize, 1), pool.inUse());

    // Reallocate should reuse
    const item3 = try pool.create();
    item3.value = 200;
    try std.testing.expectEqual(@as(usize, 2), pool.inUse());
}

test "memory pool block allocation" {
    const allocator = std.testing.allocator;

    const Item = struct {
        value: usize,
    };

    var pool = MemoryPool(Item).init(allocator);
    defer pool.deinit();

    // Allocate more than one block
    var i: usize = 0;
    while (i < 300) : (i += 1) {
        const item = try pool.create();
        item.value = i;
    }

    try std.testing.expect(pool.capacity() >= 300);
    try std.testing.expectEqual(@as(usize, 300), pool.inUse());
}
