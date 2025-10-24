const std = @import("std");

/// Headwind configuration schema
/// This uses zig-config for loading and merging configuration
pub const HeadwindConfig = struct {
    /// Project name
    name: []const u8 = "headwind",

    /// Content paths to scan for class names
    content: ContentConfig = .{},

    /// Theme configuration
    theme: ThemeConfig = .{},

    /// Build options
    build: BuildConfig = .{},

    /// Plugin configuration
    plugins: []const PluginConfig = &.{},

    /// Cache configuration
    cache: CacheConfig = .{},

    /// Dark mode configuration
    darkMode: DarkModeConfig = .{},

    /// Prefix for all utility classes
    prefix: []const u8 = "",

    /// Separator for variants (default: ":")
    separator: []const u8 = ":",

    /// Important modifier
    important: bool = false,

    /// Core plugins to disable
    corePlugins: CorePluginsConfig = .{},
};

pub const ContentConfig = struct {
    /// Paths to scan (glob patterns)
    files: []const []const u8 = &.{
        "src/**/*.{html,js,jsx,ts,tsx,vue,svelte}",
    },

    /// Paths to exclude
    exclude: []const []const u8 = &.{
        "node_modules/**",
        ".git/**",
        "dist/**",
        "build/**",
    },

    /// Relative to this directory
    relative: ?[]const u8 = null,
};

pub const ThemeConfig = struct {
    /// Color palette
    colors: ?std.json.Value = null,

    /// Spacing scale
    spacing: ?std.json.Value = null,

    /// Font families
    fontFamily: ?std.json.Value = null,

    /// Font sizes
    fontSize: ?std.json.Value = null,

    /// Font weights
    fontWeight: ?std.json.Value = null,

    /// Line heights
    lineHeight: ?std.json.Value = null,

    /// Letter spacing
    letterSpacing: ?std.json.Value = null,

    /// Breakpoints
    screens: ?std.json.Value = null,

    /// Border radius
    borderRadius: ?std.json.Value = null,

    /// Box shadows
    boxShadow: ?std.json.Value = null,

    /// Extend theme (merge with defaults)
    extend: ?std.json.Value = null,
};

pub const BuildConfig = struct {
    /// Output file path
    output: []const u8 = "dist/headwind.css",

    /// Minify output
    minify: bool = false,

    /// Generate source maps
    sourcemap: bool = false,

    /// Watch mode
    watch: bool = false,

    /// Preflight (CSS reset)
    preflight: bool = true,

    /// Output mode
    mode: BuildMode = .development,
};

pub const BuildMode = enum {
    development,
    production,
};

pub const PluginConfig = struct {
    /// Plugin name or path
    name: []const u8,

    /// Plugin options
    options: ?std.json.Value = null,
};

pub const CacheConfig = struct {
    /// Enable caching
    enabled: bool = true,

    /// Cache directory
    dir: []const u8 = ".headwind-cache",

    /// Cache TTL in milliseconds
    ttl: u32 = 3600000, // 1 hour
};

pub const DarkModeConfig = struct {
    /// Strategy: "class" or "media"
    strategy: DarkModeStrategy = .@"class",

    /// Class name for dark mode (when strategy is "class")
    className: []const u8 = "dark",
};

pub const DarkModeStrategy = enum {
    @"class",
    media,
    selector,
};

pub const CorePluginsConfig = struct {
    preflight: bool = true,
    container: bool = true,
    accessibility: bool = true,
    pointerEvents: bool = true,
    visibility: bool = true,
    position: bool = true,
    inset: bool = true,
    zIndex: bool = true,
    order: bool = true,
    gridColumn: bool = true,
    gridColumnStart: bool = true,
    gridColumnEnd: bool = true,
    gridRow: bool = true,
    gridRowStart: bool = true,
    gridRowEnd: bool = true,
    float: bool = true,
    clear: bool = true,
    margin: bool = true,
    padding: bool = true,
    space: bool = true,
    width: bool = true,
    minWidth: bool = true,
    maxWidth: bool = true,
    height: bool = true,
    minHeight: bool = true,
    maxHeight: bool = true,
    fontSize: bool = true,
    fontWeight: bool = true,
    textAlign: bool = true,
    textColor: bool = true,
    backgroundColor: bool = true,
    borderColor: bool = true,
    borderRadius: bool = true,
    borderWidth: bool = true,
    display: bool = true,
    flex: bool = true,
    flexDirection: bool = true,
    flexWrap: bool = true,
    alignItems: bool = true,
    justifyContent: bool = true,
    gap: bool = true,
    grid: bool = true,
    gridTemplateColumns: bool = true,
    gridTemplateRows: bool = true,
};

/// Default configuration
pub fn defaultConfig() HeadwindConfig {
    return .{};
}

/// Validate configuration
pub fn validate(config: *const HeadwindConfig) !void {
    if (config.content.files.len == 0) {
        return error.ConfigInvalid;
    }

    if (config.separator.len == 0) {
        return error.ConfigInvalid;
    }

    // Validate build output path
    if (config.build.output.len == 0) {
        return error.ConfigInvalid;
    }
}

test "defaultConfig" {
    const config = defaultConfig();
    try std.testing.expectEqualStrings("headwind", config.name);
    try std.testing.expectEqualStrings(":", config.separator);
}

test "validate" {
    const config = defaultConfig();
    try validate(&config);
}
