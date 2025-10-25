const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");

/// File-based cache for extracted classes
pub const FileCache = struct {
    allocator: std.mem.Allocator,
    cache_dir: []const u8,
    entries: std.StringHashMap(CacheEntry),

    const CacheEntry = struct {
        file_hash: u64,
        classes: [][]const u8,
        timestamp: i64,

        pub fn deinit(self: *CacheEntry, allocator: std.mem.Allocator) void {
            for (self.classes) |class| {
                allocator.free(class);
            }
            allocator.free(self.classes);
        }
    };

    pub fn init(allocator: std.mem.Allocator, cache_dir: []const u8) FileCache {
        return .{
            .allocator = allocator,
            .cache_dir = cache_dir,
            .entries = std.StringHashMap(CacheEntry).init(allocator),
        };
    }

    pub fn deinit(self: *FileCache) void {
        var iter = self.entries.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(self.allocator);
        }
        self.entries.deinit();
    }

    /// Get cached classes for a file if valid
    pub fn get(self: *FileCache, file_path: []const u8) !?[][]const u8 {
        // Calculate current file hash
        const current_hash = try self.hashFile(file_path);

        // Check in-memory cache
        if (self.entries.get(file_path)) |entry| {
            if (entry.file_hash == current_hash) {
                // Cache hit - duplicate the classes array
                var classes = try self.allocator.alloc([]const u8, entry.classes.len);
                for (entry.classes, 0..) |class, i| {
                    classes[i] = try self.allocator.dupe(u8, class);
                }
                return classes;
            }
        }

        // Check disk cache
        return try self.loadFromDisk(file_path, current_hash);
    }

    /// Store classes in cache
    pub fn put(
        self: *FileCache,
        file_path: []const u8,
        classes: [][]const u8,
    ) !void {
        const file_hash = try self.hashFile(file_path);
        const timestamp = std.time.timestamp();

        // Duplicate classes for storage
        var owned_classes = try self.allocator.alloc([]const u8, classes.len);
        for (classes, 0..) |class, i| {
            owned_classes[i] = try self.allocator.dupe(u8, class);
        }

        // Store in memory
        const owned_path = try self.allocator.dupe(u8, file_path);
        const entry = CacheEntry{
            .file_hash = file_hash,
            .classes = owned_classes,
            .timestamp = timestamp,
        };

        // Remove old entry if exists
        if (self.entries.fetchRemove(file_path)) |old| {
            self.allocator.free(old.key);
            var mutable_value = old.value;
            mutable_value.deinit(self.allocator);
        }

        try self.entries.put(owned_path, entry);

        // Save to disk
        try self.saveToDisk(file_path, file_hash, classes);
    }

    /// Clear all cache entries
    pub fn clear(self: *FileCache) !void {
        // Clear memory cache
        var iter = self.entries.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(self.allocator);
        }
        self.entries.clearRetainingCapacity();

        // Clear disk cache
        std.fs.cwd().deleteTree(self.cache_dir) catch |err| {
            if (err != error.FileNotFound) return err;
        };
    }

    /// Hash a file's contents
    fn hashFile(self: *FileCache, file_path: []const u8) !u64 {
        const content = try std.fs.cwd().readFileAlloc(
            self.allocator,
            file_path,
            10 * 1024 * 1024, // 10MB max
        );
        defer self.allocator.free(content);

        return string_utils.hashString(content);
    }

    /// Load cache from disk
    fn loadFromDisk(
        self: *FileCache,
        file_path: []const u8,
        expected_hash: u64,
    ) !?[][]const u8 {
        _ = expected_hash;

        // Create cache file path
        const cache_file_path = try self.getCacheFilePath(file_path);
        defer self.allocator.free(cache_file_path);

        // Read cache file
        const content = std.fs.cwd().readFileAlloc(
            self.allocator,
            cache_file_path,
            1024 * 1024, // 1MB max
        ) catch |err| {
            if (err == error.FileNotFound) return null;
            return err;
        };
        defer self.allocator.free(content);

        // Parse cache file (simple newline-separated format)
        var classes: std.ArrayList([]const u8) = .{};
        errdefer {
            for (classes.items) |class| self.allocator.free(class);
            classes.deinit(self.allocator);
        }

        var lines = std.mem.splitScalar(u8, content, '\n');
        while (lines.next()) |line| {
            const trimmed = string_utils.trim(line);
            if (trimmed.len > 0) {
                const class = try self.allocator.dupe(u8, trimmed);
                try classes.append(self.allocator, class);
            }
        }

        const result = try classes.toOwnedSlice(self.allocator);
        return result;
    }

    /// Save cache to disk
    fn saveToDisk(
        self: *FileCache,
        file_path: []const u8,
        file_hash: u64,
        classes: [][]const u8,
    ) !void {
        _ = file_hash;

        // Ensure cache directory exists
        std.fs.cwd().makePath(self.cache_dir) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };

        // Create cache file
        const cache_file_path = try self.getCacheFilePath(file_path);
        defer self.allocator.free(cache_file_path);

        const file = try std.fs.cwd().createFile(cache_file_path, .{});
        defer file.close();

        // Write each class on a new line
        for (classes) |class| {
            try file.writeAll(class);
            try file.writeAll("\n");
        }
    }

    /// Get cache file path for a source file
    fn getCacheFilePath(self: *FileCache, file_path: []const u8) ![]const u8 {
        // Hash the file path to create a unique cache filename
        const path_hash = string_utils.hashString(file_path);
        const cache_filename = try std.fmt.allocPrint(
            self.allocator,
            "{x}.cache",
            .{path_hash},
        );
        defer self.allocator.free(cache_filename);

        return std.fs.path.join(self.allocator, &.{ self.cache_dir, cache_filename });
    }
};

test "FileCache basic operations" {
    const allocator = std.testing.allocator;
    const cache_dir = ".test-cache";

    var cache = FileCache.init(allocator, cache_dir);
    defer cache.deinit();
    defer cache.clear() catch {};

    // Test data - allocate mutable slice
    var test_classes = try allocator.alloc([]const u8, 3);
    defer allocator.free(test_classes);
    test_classes[0] = "flex";
    test_classes[1] = "items-center";
    test_classes[2] = "bg-blue-500";

    // Put classes
    try cache.put("test.html", test_classes);

    // Get classes (should be cache hit)
    const retrieved = try cache.get("test.html");
    if (retrieved) |classes| {
        defer {
            for (classes) |class| allocator.free(class);
            allocator.free(classes);
        }

        try std.testing.expectEqual(@as(usize, 3), classes.len);
        try std.testing.expectEqualStrings("flex", classes[0]);
    } else {
        try std.testing.expect(false); // Should have found cached data
    }
}
