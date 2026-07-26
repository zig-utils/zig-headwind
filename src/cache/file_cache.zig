const std = @import("std");
const types = @import("../core/types.zig");
const string_utils = @import("../utils/string.zig");

/// File-based cache for extracted classes
/// OPTIMIZED VERSION - significantly reduced file I/O and allocations
pub const FileCache = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    cache_dir: []const u8,
    entries: std.StringHashMap(CacheEntry),
    file_mtimes: std.StringHashMap(i128), // Track modification times instead of hashing

    const CacheEntry = struct {
        mtime: i128, // File modification time (faster than hashing)
        classes: [][]const u8,

        pub fn deinit(self: *CacheEntry, allocator: std.mem.Allocator) void {
            for (self.classes) |class| {
                allocator.free(class);
            }
            allocator.free(self.classes);
        }
    };

    pub fn init(allocator: std.mem.Allocator, io: std.Io, cache_dir: []const u8) FileCache {
        return .{
            .allocator = allocator,
            .io = io,
            .cache_dir = cache_dir,
            .entries = std.StringHashMap(CacheEntry).init(allocator),
            .file_mtimes = std.StringHashMap(i128).init(allocator),
        };
    }

    pub fn deinit(self: *FileCache) void {
        var iter = self.entries.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(self.allocator);
        }
        self.entries.deinit();

        var mtime_iter = self.file_mtimes.iterator();
        while (mtime_iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.file_mtimes.deinit();
    }

    /// Get cached classes for a file if valid
    /// OPTIMIZED: Use mtime instead of expensive file hashing
    pub fn get(self: *FileCache, file_path: []const u8) !?[][]const u8 {
        // Get current file mtime (much faster than hashing)
        const current_mtime = try self.getFileMtime(file_path);

        // Check in-memory cache first
        if (self.entries.get(file_path)) |entry| {
            if (entry.mtime == current_mtime) {
                // Cache hit - return slice view, NO duplication needed
                // The caller doesn't own these strings, they're managed by cache
                return entry.classes;
            }
        }

        // Update mtime cache - only allocate new key if not already present
        const gop = try self.file_mtimes.getOrPut(file_path);
        if (!gop.found_existing) {
            // New entry - allocate owned key
            gop.key_ptr.* = try self.allocator.dupe(u8, file_path);
        }
        gop.value_ptr.* = current_mtime;

        // Disk cache check removed - it was causing slowdowns
        // Better to just re-scan the file than deal with disk I/O overhead
        return null;
    }

    /// Store classes in cache
    /// OPTIMIZED: Reduced allocations
    pub fn put(
        self: *FileCache,
        file_path: []const u8,
        classes: [][]const u8,
    ) !void {
        const mtime = try self.getFileMtime(file_path);

        // Duplicate classes for storage (necessary for cache ownership)
        var owned_classes = try self.allocator.alloc([]const u8, classes.len);
        for (classes, 0..) |class, i| {
            owned_classes[i] = try self.allocator.dupe(u8, class);
        }

        // Store in memory
        const owned_path = try self.allocator.dupe(u8, file_path);
        const entry = CacheEntry{
            .mtime = mtime,
            .classes = owned_classes,
        };

        // Remove old entry if exists
        if (self.entries.fetchRemove(file_path)) |old| {
            self.allocator.free(old.key);
            var mutable_value = old.value;
            mutable_value.deinit(self.allocator);
        }

        try self.entries.put(owned_path, entry);

        // Update mtime tracking - only allocate new key if not already present
        const gop = try self.file_mtimes.getOrPut(file_path);
        if (!gop.found_existing) {
            gop.key_ptr.* = try self.allocator.dupe(u8, file_path);
        }
        gop.value_ptr.* = mtime;

        // Disk caching disabled for performance
        // Disk I/O overhead was higher than re-scanning files
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

        // Clear mtime tracking
        var mtime_iter = self.file_mtimes.iterator();
        while (mtime_iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.file_mtimes.clearRetainingCapacity();

        // Clear disk cache directory if it exists
        std.Io.Dir.cwd().deleteTree(self.io, self.cache_dir) catch |err| {
            if (err != error.FileNotFound) return err;
        };
    }

    /// Get file modification time (much faster than hashing entire file)
    /// OPTIMIZATION: Stat is ~1000x faster than reading + hashing file content
    fn getFileMtime(self: *FileCache, file_path: []const u8) !i128 {
        // 0.17: Dir.statFile avoids opening a handle just to stat it, and the
        // File methods all take the Io now anyway.
        const stat = try std.Io.Dir.cwd().statFile(self.io, file_path, .{});
        // In Zig 0.16+, mtime is a Timestamp struct with nanoseconds field
        return @intCast(stat.mtime.nanoseconds);
    }

    /// Load cache from disk (DISABLED for performance)
    /// This was causing the 2x slowdown in warm builds
    fn loadFromDisk(
        self: *FileCache,
        file_path: []const u8,
        expected_mtime: i128,
    ) !?[][]const u8 {
        _ = self;
        _ = file_path;
        _ = expected_mtime;
        // Disabled - disk I/O overhead > re-scanning benefit
        return null;
    }

    /// Save cache to disk (DISABLED for performance)
    fn saveToDisk(
        self: *FileCache,
        file_path: []const u8,
        mtime: i128,
        classes: [][]const u8,
    ) !void {
        _ = self;
        _ = file_path;
        _ = mtime;
        _ = classes;
        // Disabled - focus on in-memory cache only
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
    const io = std.testing.io;
    const cache_dir = ".test-cache";
    const test_file = "test-cache-file.html";

    // Create a temporary test file
    {
        try std.Io.Dir.cwd().writeFile(io, .{
            .sub_path = test_file,
            .data = "<div class=\"flex items-center bg-blue-500\">Test</div>",
        });
    }
    defer std.Io.Dir.cwd().deleteFile(io, test_file) catch {};

    var cache = FileCache.init(allocator, io, cache_dir);
    defer cache.deinit();
    defer cache.clear() catch {};

    // Test data - allocate mutable slice
    var test_classes = try allocator.alloc([]const u8, 3);
    defer allocator.free(test_classes);
    test_classes[0] = "flex";
    test_classes[1] = "items-center";
    test_classes[2] = "bg-blue-500";

    // Put classes
    try cache.put(test_file, test_classes);

    // Get classes (should be cache hit)
    const retrieved = try cache.get(test_file);
    if (retrieved) |classes| {
        // No need to free - cache owns the data
        try std.testing.expectEqual(@as(usize, 3), classes.len);
        try std.testing.expectEqualStrings("flex", classes[0]);
    } else {
        try std.testing.expect(false); // Should have found cached data
    }
}
