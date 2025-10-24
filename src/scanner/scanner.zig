const std = @import("std");
const types = @import("../core/types.zig");
const FileScanner = @import("file_scanner.zig").FileScanner;
const ContentExtractor = @import("content_extractor.zig").ContentExtractor;
const FileCache = @import("../cache/file_cache.zig").FileCache;
const string_utils = @import("../utils/string.zig");

/// Main scanner that coordinates file scanning and class extraction
pub const Scanner = struct {
    allocator: std.mem.Allocator,
    config: ScanConfig,
    cache: FileCache,
    stats: Stats,

    pub const ScanConfig = struct {
        base_path: []const u8 = ".",
        include_patterns: []const []const u8,
        exclude_patterns: []const []const u8 = &.{
            "node_modules/**",
            ".git/**",
            "dist/**",
            "build/**",
        },
        cache_enabled: bool = true,
        cache_dir: []const u8 = ".headwind-cache",
    };

    pub const Stats = struct {
        files_scanned: usize = 0,
        classes_extracted: usize = 0,
        cache_hits: usize = 0,
        cache_misses: usize = 0,
        duration_ms: i64 = 0,

        pub fn report(self: *const Stats) void {
            std.debug.print("\nScan Statistics:\n", .{});
            std.debug.print("  Files scanned: {d}\n", .{self.files_scanned});
            std.debug.print("  Classes extracted: {d}\n", .{self.classes_extracted});
            std.debug.print("  Cache hits: {d}\n", .{self.cache_hits});
            std.debug.print("  Cache misses: {d}\n", .{self.cache_misses});
            std.debug.print("  Duration: {d}ms\n", .{self.duration_ms});
        }
    };

    pub fn init(allocator: std.mem.Allocator, config: ScanConfig) Scanner {
        return .{
            .allocator = allocator,
            .config = config,
            .cache = FileCache.init(allocator, config.cache_dir),
            .stats = .{},
        };
    }

    pub fn deinit(self: *Scanner) void {
        self.cache.deinit();
    }

    /// Scan all files and extract class names
    pub fn scan(self: *Scanner) ![][]const u8 {
        const start_time = std.time.milliTimestamp();
        defer {
            const end_time = std.time.milliTimestamp();
            self.stats.duration_ms = end_time - start_time;
        }

        // Initialize file scanner
        var file_scanner = FileScanner.init(
            self.allocator,
            self.config.base_path,
            self.config.include_patterns,
            self.config.exclude_patterns,
        );

        // Scan for files
        const files = try file_scanner.scan();
        defer {
            for (files) |file| self.allocator.free(file);
            self.allocator.free(files);
        }

        self.stats.files_scanned = files.len;

        // Extract classes from each file
        var all_classes: std.ArrayList([]const u8) = .{};
        errdefer {
            for (all_classes.items) |class| self.allocator.free(class);
            all_classes.deinit(self.allocator);
        }

        var extractor = ContentExtractor.init(self.allocator);

        for (files) |file_path| {
            const classes = try self.extractWithCache(file_path, &extractor);
            defer {
                for (classes) |class| self.allocator.free(class);
                self.allocator.free(classes);
            }

            // Add to all_classes (deduplicating will happen later)
            for (classes) |class| {
                const owned = try self.allocator.dupe(u8, class);
                try all_classes.append(self.allocator, owned);
            }
        }

        self.stats.classes_extracted = all_classes.items.len;

        // Deduplicate classes
        const unique_classes = try self.deduplicateClasses(all_classes.items);

        // Free original list
        for (all_classes.items) |class| self.allocator.free(class);
        all_classes.deinit(self.allocator);

        return unique_classes;
    }

    /// Extract classes with caching
    fn extractWithCache(
        self: *Scanner,
        file_path: []const u8,
        extractor: *ContentExtractor,
    ) ![][]const u8 {
        // Try cache first if enabled
        if (self.config.cache_enabled) {
            if (try self.cache.get(file_path)) |cached| {
                self.stats.cache_hits += 1;
                return cached;
            }
        }

        self.stats.cache_misses += 1;

        // Extract from file
        const classes = try extractor.extractFromFile(file_path);

        // Store in cache
        if (self.config.cache_enabled) {
            try self.cache.put(file_path, classes);
        }

        return classes;
    }

    /// Deduplicate class names
    fn deduplicateClasses(self: *Scanner, classes: [][]const u8) ![][]const u8 {
        var seen = std.StringHashMap(void).init(self.allocator);
        defer seen.deinit();

        var unique: std.ArrayList([]const u8) = .{};
        errdefer {
            for (unique.items) |class| self.allocator.free(class);
            unique.deinit(self.allocator);
        }

        for (classes) |class| {
            if (!seen.contains(class)) {
                try seen.put(class, {});
                const owned = try self.allocator.dupe(u8, class);
                try unique.append(self.allocator, owned);
            }
        }

        return unique.toOwnedSlice(self.allocator);
    }

    /// Clear cache
    pub fn clearCache(self: *Scanner) !void {
        try self.cache.clear();
    }

    /// Get statistics
    pub fn getStats(self: *const Scanner) Stats {
        return self.stats;
    }
};

test "Scanner basic" {
    const allocator = std.testing.allocator;

    const config = Scanner.ScanConfig{
        .base_path = ".",
        .include_patterns = &.{"*.test.html"},
        .exclude_patterns = &.{"node_modules/**"},
        .cache_enabled = false,
    };

    var scanner = Scanner.init(allocator, config);
    defer scanner.deinit();

    // Scanner test would require actual files
    // This is just a compilation test
}
