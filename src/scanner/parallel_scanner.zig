const std = @import("std");
const ThreadPool = @import("../core/thread_pool.zig").ThreadPool;
const ContentExtractor = @import("content_extractor.zig").ContentExtractor;
const FileCache = @import("../cache/file_cache.zig").FileCache;

/// Parallel scanner using thread pool for better performance
pub const ParallelScanner = struct {
    allocator: std.mem.Allocator,
    cache_enabled: bool,
    cache_dir: []const u8,

    pub fn init(allocator: std.mem.Allocator, cache_enabled: bool, cache_dir: []const u8) ParallelScanner {
        return .{
            .allocator = allocator,
            .cache_enabled = cache_enabled,
            .cache_dir = cache_dir,
        };
    }

    /// Scan files in parallel
    pub fn scanFiles(self: *ParallelScanner, files: [][]const u8) ![][]const u8 {
        if (files.len == 0) return &[_][]const u8{};

        // For small numbers of files, don't bother with threading
        if (files.len < 4) {
            return try self.scanFilesSequential(files);
        }

        // Create thread pool
        var pool = try ThreadPool.init(self.allocator, 0); // 0 = auto-detect CPU count
        defer pool.deinit();

        // Shared data structure for results
        var results = try self.allocator.alloc(FileResult, files.len);
        defer self.allocator.free(results);

        // Initialize results
        for (results) |*result| {
            result.* = .{
                .classes = &[_][]const u8{},
                .mutex = .{},
            };
        }

        // Submit work items
        var work_data = try self.allocator.alloc(WorkData, files.len);
        defer self.allocator.free(work_data);

        for (files, 0..) |file_path, i| {
            work_data[i] = .{
                .allocator = self.allocator,
                .file_path = file_path,
                .result = &results[i],
                .cache_enabled = self.cache_enabled,
                .cache_dir = self.cache_dir,
            };

            try pool.submit(.{
                .func = extractFileWork,
                .data = &work_data[i],
            });
        }

        // Wait for all work to complete
        // Simple spin-wait until all results are ready
        while (true) {
            var all_done = true;
            for (results) |*result| {
                result.mutex.lock();
                const ready = result.ready;
                result.mutex.unlock();
                if (!ready) {
                    all_done = false;
                    break;
                }
            }
            if (all_done) break;
            std.Thread.yield() catch {};
        }

        // Collect all classes
        var all_classes = std.ArrayList([]const u8).init(self.allocator);
        errdefer {
            for (all_classes.items) |class| self.allocator.free(class);
            all_classes.deinit();
        }

        for (results) |*result| {
            result.mutex.lock();
            defer result.mutex.unlock();

            for (result.classes) |class| {
                const owned = try self.allocator.dupe(u8, class);
                try all_classes.append(owned);
            }

            // Free result classes
            for (result.classes) |class| self.allocator.free(class);
            self.allocator.free(result.classes);
        }

        // Deduplicate
        const unique = try deduplicateClasses(self.allocator, all_classes.items);

        // Free duplicates
        for (all_classes.items) |class| self.allocator.free(class);
        all_classes.deinit();

        return unique;
    }

    /// Fallback sequential scanning for small file counts
    fn scanFilesSequential(self: *ParallelScanner, files: [][]const u8) ![][]const u8 {
        var all_classes = std.ArrayList([]const u8).init(self.allocator);
        errdefer {
            for (all_classes.items) |class| self.allocator.free(class);
            all_classes.deinit();
        }

        var cache = FileCache.init(self.allocator, self.cache_dir);
        defer cache.deinit();

        var extractor = ContentExtractor.init(self.allocator);

        for (files) |file_path| {
            const classes = try extractWithCache(self.allocator, file_path, &extractor, &cache, self.cache_enabled);
            defer {
                for (classes) |class| self.allocator.free(class);
                self.allocator.free(classes);
            }

            for (classes) |class| {
                const owned = try self.allocator.dupe(u8, class);
                try all_classes.append(owned);
            }
        }

        // Deduplicate
        const unique = try deduplicateClasses(self.allocator, all_classes.items);

        // Free duplicates
        for (all_classes.items) |class| self.allocator.free(class);
        all_classes.deinit();

        return unique;
    }
};

/// Work data for parallel extraction
const WorkData = struct {
    allocator: std.mem.Allocator,
    file_path: []const u8,
    result: *FileResult,
    cache_enabled: bool,
    cache_dir: []const u8,
};

/// Result container for each file
const FileResult = struct {
    classes: [][]const u8,
    mutex: std.Thread.Mutex,
    ready: bool = false,
};

/// Worker function to extract classes from a file
fn extractFileWork(item: *@import("../core/thread_pool.zig").WorkItem) void {
    const data: *WorkData = @ptrCast(@alignCast(item.data.?));

    // Extract classes
    var cache = FileCache.init(data.allocator, data.cache_dir);
    defer cache.deinit();

    var extractor = ContentExtractor.init(data.allocator);

    const classes = extractWithCache(
        data.allocator,
        data.file_path,
        &extractor,
        &cache,
        data.cache_enabled,
    ) catch &[_][]const u8{}; // On error, return empty array

    // Store result
    data.result.mutex.lock();
    data.result.classes = classes;
    data.result.ready = true;
    data.result.mutex.unlock();
}

/// Extract classes with caching
fn extractWithCache(
    allocator: std.mem.Allocator,
    file_path: []const u8,
    extractor: *ContentExtractor,
    cache: *FileCache,
    cache_enabled: bool,
) ![][]const u8 {
    // Try cache first if enabled
    if (cache_enabled) {
        if (try cache.get(file_path)) |cached| {
            return cached;
        }
    }

    // Extract from file
    const classes = try extractor.extractFromFile(file_path);

    // Store in cache
    if (cache_enabled) {
        try cache.put(file_path, classes);
    }

    return classes;
}

/// Deduplicate class names using a hash set
fn deduplicateClasses(allocator: std.mem.Allocator, classes: [][]const u8) ![][]const u8 {
    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();

    var unique = std.ArrayList([]const u8).init(allocator);
    errdefer {
        for (unique.items) |class| allocator.free(class);
        unique.deinit();
    }

    for (classes) |class| {
        const result = try seen.getOrPut(class);
        if (!result.found_existing) {
            const owned = try allocator.dupe(u8, class);
            try unique.append(owned);
        }
    }

    return unique.toOwnedSlice();
}
