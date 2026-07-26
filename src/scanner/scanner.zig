const std = @import("std");
const types = @import("../core/types.zig");
const FileScanner = @import("file_scanner.zig").FileScanner;
const ContentExtractor = @import("content_extractor.zig").ContentExtractor;
const FileCache = @import("../cache/file_cache.zig").FileCache;
const string_utils = @import("../utils/string.zig");
const config_schema = @import("../config/schema.zig");

/// Main scanner that coordinates file scanning and class extraction
pub const Scanner = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
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
        cache_dir: []const u8 = ".crosswind-cache",
        /// Attributify mode configuration
        attributify: config_schema.AttributifyConfig = .{},
        /// Grouped syntax configuration
        grouped_syntax: config_schema.GroupedSyntaxConfig = .{},
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

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: ScanConfig) Scanner {
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .cache = FileCache.init(allocator, io, config.cache_dir),
            .stats = .{},
        };
    }

    pub fn deinit(self: *Scanner) void {
        self.cache.deinit();
    }

    /// Scan all files and extract class names
    /// OPTIMIZED: Uses arena allocator for temporary allocations
    pub fn scan(self: *Scanner) ![][]const u8 {
        const started = std.Io.Timestamp.now(self.io, .awake);
        defer self.stats.duration_ms = @intCast(@divTrunc(
            started.durationTo(std.Io.Timestamp.now(self.io, .awake)).toNanoseconds(),
            std.time.ns_per_ms,
        ));

        // OPTIMIZATION: Use arena for temporary allocations during scan
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const temp_allocator = arena.allocator();

        // Initialize file scanner
        var file_scanner = FileScanner.init(
            temp_allocator,
            self.io,
            self.config.base_path,
            self.config.include_patterns,
            self.config.exclude_patterns,
        );

        // Scan for files
        const files = try file_scanner.scan();
        self.stats.files_scanned = files.len;

        // OPTIMIZATION: Pre-allocate approximate capacity
        var all_classes: std.ArrayList([]const u8) = .empty;
        try all_classes.ensureTotalCapacity(temp_allocator, files.len * 10); // Estimate ~10 classes per file

        var extractor = ContentExtractor.initWithConfig(
            temp_allocator,
            self.io,
            self.config.attributify,
            self.config.grouped_syntax,
        );

        for (files) |file_path| {
            const classes = try self.extractWithCache(file_path, &extractor);

            // Add to all_classes (deduplicating will happen later)
            // No need to dupe - arena will clean up
            try all_classes.appendSlice(temp_allocator, classes);
        }

        self.stats.classes_extracted = all_classes.items.len;

        // Deduplicate classes and transfer to main allocator
        const unique_classes = try self.deduplicateClasses(all_classes.items);

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

        var unique: std.ArrayList([]const u8) = .empty;
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

    var scanner = Scanner.init(allocator, std.testing.io, config);
    defer scanner.deinit();

    // Scanner test would require actual files
    // This is just a compilation test
}
