const std = @import("std");

// Core modules
pub const types = @import("core/types.zig");
pub const allocator = @import("core/allocator.zig");

// Utilities
pub const string = @import("utils/string.zig");

// Configuration
pub const config = @import("config/schema.zig");
pub const config_loader = @import("config/loader.zig");

// Scanner
pub const Scanner = @import("scanner/scanner.zig").Scanner;
pub const FileScanner = @import("scanner/file_scanner.zig").FileScanner;
pub const ContentExtractor = @import("scanner/content_extractor.zig").ContentExtractor;

// Parser
pub const class_parser = @import("parser/class_parser.zig");
pub const ParsedClass = class_parser.ParsedClass;

// Cache
pub const FileCache = @import("cache/file_cache.zig").FileCache;

// Generator
pub const CSSGenerator = @import("generator/css_generator.zig").CSSGenerator;
pub const CSSRule = @import("generator/css_generator.zig").CSSRule;

// Re-export commonly used types
pub const HeadwindError = types.HeadwindError;
pub const HeadwindConfig = config.HeadwindConfig;
pub const BuildMode = config.BuildMode;
pub const ClassName = types.ClassName;
pub const ScanResult = types.ScanResult;

// Version information
pub const version = "0.1.0";
pub const version_major = 0;
pub const version_minor = 1;
pub const version_patch = 0;

/// Initialize Headwind with configuration
pub const Headwind = struct {
    allocator: std.mem.Allocator,
    config: HeadwindConfig,
    stats: types.Stats,
    scanner: ?Scanner,

    pub fn init(alloc: std.mem.Allocator, cfg: HeadwindConfig) !Headwind {
        return .{
            .allocator = alloc,
            .config = cfg,
            .stats = .{},
            .scanner = null,
        };
    }

    pub fn deinit(self: *Headwind) void {
        if (self.scanner) |*scanner| {
            scanner.deinit();
        }
    }

    /// Build CSS from configuration
    pub fn build(self: *Headwind) ![]const u8 {
        const start = std.time.nanoTimestamp();
        defer {
            const end = std.time.nanoTimestamp();
            self.stats.total_duration_ns = @intCast(end - start);
        }

        // Initialize scanner
        const scan_config = Scanner.ScanConfig{
            .base_path = ".",
            .include_patterns = self.config.content.files,
            .exclude_patterns = self.config.content.exclude,
            .cache_enabled = self.config.cache.enabled,
            .cache_dir = self.config.cache.dir,
        };

        var scanner = Scanner.init(self.allocator, scan_config);
        defer scanner.deinit();

        // Scan for class names
        const classes = try scanner.scan();
        defer {
            for (classes) |class| {
                self.allocator.free(class);
            }
            self.allocator.free(classes);
        }

        // Update stats
        const scan_stats = scanner.getStats();
        self.stats.files_scanned = scan_stats.files_scanned;
        self.stats.classes_extracted = scan_stats.classes_extracted;
        self.stats.cache_hits = scan_stats.cache_hits;
        self.stats.cache_misses = scan_stats.cache_misses;

        // Generate CSS
        var css = string.StringBuilder.init(self.allocator);
        defer css.deinit();

        // Header
        try css.append("/* Headwind CSS v");
        try css.append(version);
        try css.append(" - Generated */\n\n");

        // Preflight (if enabled)
        if (self.config.build.preflight) {
            try css.append("/* Preflight */\n");
            try css.append("*, ::before, ::after { box-sizing: border-box; }\n");
            try css.append("body { margin: 0; line-height: inherit; }\n\n");
        }

        // Generate utilities
        try css.append("/* Utilities */\n");

        var generator = CSSGenerator.init(self.allocator);
        defer generator.deinit();

        for (classes) |class| {
            try generator.generateForClass(class);
        }

        const utilities_css = try generator.generate();
        defer self.allocator.free(utilities_css);
        try css.append(utilities_css);

        self.stats.css_rules_generated = generator.rules.items.len;

        return try css.toOwnedSlice();
    }

    /// Get statistics
    pub fn getStats(self: *const Headwind) types.Stats {
        return self.stats;
    }
};

/// Load configuration from default locations
pub fn loadConfig(alloc: std.mem.Allocator) !HeadwindConfig {
    return config_loader.loadConfig(alloc, .{});
}

/// Load configuration with custom options
pub fn loadConfigWithOptions(
    alloc: std.mem.Allocator,
    options: config_loader.LoadOptions,
) !HeadwindConfig {
    return config_loader.loadConfig(alloc, options);
}

test "version" {
    try std.testing.expectEqualStrings("0.1.0", version);
}

test "Headwind init" {
    const cfg = config.defaultConfig();
    var hw = try Headwind.init(std.testing.allocator, cfg);
    defer hw.deinit();

    const stats = hw.getStats();
    try std.testing.expectEqual(@as(usize, 0), stats.files_scanned);
}

test "Headwind build" {
    const cfg = config.defaultConfig();
    var hw = try Headwind.init(std.testing.allocator, cfg);
    defer hw.deinit();

    const css = try hw.build();
    defer std.testing.allocator.free(css);

    try std.testing.expect(css.len > 0);
}
