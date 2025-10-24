const std = @import("std");

// Core modules
pub const types = @import("core/types.zig");
pub const allocator = @import("core/allocator.zig");

// Utilities
pub const string = @import("utils/string.zig");

// Configuration
pub const config = @import("config/schema.zig");
pub const config_loader = @import("config/loader.zig");

// Re-export commonly used types
pub const HeadwindError = types.HeadwindError;
pub const HeadwindConfig = config.HeadwindConfig;
pub const BuildMode = config.BuildMode;
pub const ClassName = types.ClassName;
pub const CSSRule = types.CSSRule;
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

    pub fn init(alloc: std.mem.Allocator, cfg: HeadwindConfig) !Headwind {
        return .{
            .allocator = alloc,
            .config = cfg,
            .stats = .{},
        };
    }

    pub fn deinit(self: *Headwind) void {
        _ = self;
        // Cleanup will be added as we build more features
    }

    /// Build CSS from configuration
    pub fn build(self: *Headwind) ![]const u8 {
        const start = std.time.nanoTimestamp();
        defer {
            const end = std.time.nanoTimestamp();
            self.stats.total_duration_ns = @intCast(end - start);
        }

        // TODO: Implement actual build logic
        // For now, return a placeholder
        return try std.fmt.allocPrint(
            self.allocator,
            "/* Headwind CSS v{s} - Generated */\n",
            .{version},
        );
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
