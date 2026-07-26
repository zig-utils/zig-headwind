const std = @import("std");

// Core modules
pub const types = @import("core/types.zig");
pub const allocator = @import("core/allocator.zig");

// Utilities
pub const string = @import("utils/string.zig");

// Configuration
pub const config = @import("config/schema.zig");
pub const config_loader = @import("config/loader.zig");
pub const theme = @import("config/theme.zig");

// Scanner
pub const Scanner = @import("scanner/scanner.zig").Scanner;
pub const FileScanner = @import("scanner/file_scanner.zig").FileScanner;
pub const ContentExtractor = @import("scanner/content_extractor.zig").ContentExtractor;

// Parser
pub const class_parser = @import("parser/class_parser.zig");
pub const ParsedClass = class_parser.ParsedClass;
pub const theme_reference = @import("parser/theme_reference.zig");
pub const grouped_syntax = @import("parser/grouped_syntax.zig");

// Cache
pub const FileCache = @import("cache/file_cache.zig").FileCache;

// Validators
pub const css_variable = @import("validator/css_variable.zig");

// Variants
pub const variant_registry = @import("variants/registry.zig");

// Generator
pub const CSSGenerator = @import("generator/css_generator.zig").CSSGenerator;
pub const CSSRule = @import("generator/css_generator.zig").CSSRule;
pub const colors = @import("generator/colors.zig");
pub const backgrounds = @import("generator/backgrounds.zig");
pub const borders = @import("generator/borders.zig");
pub const sizing = @import("generator/sizing.zig");
pub const spacing = @import("generator/spacing.zig");
pub const typography = @import("generator/typography.zig");
pub const layout = @import("generator/layout.zig");
pub const flexbox = @import("generator/flexbox.zig");
pub const grid = @import("generator/grid.zig");
pub const shadows = @import("generator/shadows.zig");
pub const blend = @import("generator/blend.zig");
pub const transforms = @import("generator/transforms.zig");
pub const filters = @import("generator/filters.zig");
pub const transitions = @import("generator/transitions.zig");
pub const animations = @import("generator/animations.zig");
pub const resets = @import("generator/resets.zig");

// Plugin system
pub const Plugin = @import("plugin/plugin.zig").Plugin;
pub const PluginContext = @import("plugin/plugin.zig").PluginContext;
pub const PluginRegistry = @import("plugin/plugin.zig").PluginRegistry;

// Built-in plugins
pub const typographyPlugin = @import("plugin/typography.zig").typographyPlugin;
pub const formsPlugin = @import("plugin/forms.zig").formsPlugin;

// Re-export commonly used types
pub const crosswindError = types.crosswindError;
pub const crosswindConfig = config.crosswindConfig;
pub const BuildMode = config.BuildMode;
pub const ClassName = types.ClassName;
pub const ScanResult = types.ScanResult;

// Version information
pub const version = "0.1.0";
pub const version_major = 0;
pub const version_minor = 1;
pub const version_patch = 0;

/// Initialize crosswind with configuration
pub const crosswind = struct {
    allocator: std.mem.Allocator,
    config: crosswindConfig,
    stats: types.Stats,
    scanner: ?Scanner,

    pub fn init(alloc: std.mem.Allocator, cfg: crosswindConfig) !crosswind {
        return .{
            .allocator = alloc,
            .config = cfg,
            .stats = .{},
            .scanner = null,
        };
    }

    pub fn deinit(self: *crosswind) void {
        if (self.scanner) |*scanner| {
            scanner.deinit();
        }
    }

    /// Build CSS from configuration
    pub fn build(self: *crosswind) ![]const u8 {
        var timer = std.time.Timer.start() catch null;
        defer {
            if (timer) |*t| {
                self.stats.total_duration_ns = @intCast(t.read());
            }
        }

        // Initialize scanner
        const scan_config = Scanner.ScanConfig{
            .base_path = ".",
            .include_patterns = self.config.content.files,
            .exclude_patterns = self.config.content.exclude,
            .cache_enabled = self.config.cache.enabled,
            .cache_dir = self.config.cache.dir,
            .attributify = self.config.attributify,
            .grouped_syntax = self.config.groupedSyntax,
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
        try css.append("/* crosswind CSS v");
        try css.append(version);
        try css.append(" - Generated */\n\n");

        // CSS Layers
        try css.append("@layer base, components, utilities;\n\n");

        // Base layer
        try css.append("@layer base {\n");

        // CSS Custom Properties (theme variables)
        const css_variables_module = @import("generator/css_variables.zig");
        const theme_vars = try css_variables_module.generateThemeVariables(self.allocator);
        defer self.allocator.free(theme_vars);
        try css.append(theme_vars);
        try css.append("\n");

        // Animation keyframes
        const animations_module = @import("generator/animations.zig");
        const keyframes = try animations_module.generateKeyframes(self.allocator);
        defer self.allocator.free(keyframes);
        try css.append("  /* Keyframes */\n");
        var keyframe_lines = std.mem.splitSequence(u8, keyframes, "\n");
        while (keyframe_lines.next()) |line| {
            if (line.len > 0) {
                try css.append("  ");
                try css.append(line);
                try css.append("\n");
            }
        }
        try css.append("\n");

        // CSS Resets (from reset:type classes)
        const resets_module = @import("generator/resets.zig");
        var reset_generator = resets_module.ResetGenerator.init(self.allocator);
        var has_reset = false;
        for (classes) |class| {
            if (resets_module.getResetType(class)) |reset_type| {
                if (try reset_generator.generateReset(reset_type)) |reset_css| {
                    if (!has_reset) {
                        try css.append("  /* CSS Reset */\n");
                        has_reset = true;
                    }
                    var reset_lines = std.mem.splitSequence(u8, reset_css, "\n");
                    while (reset_lines.next()) |line| {
                        if (line.len > 0) {
                            try css.append("  ");
                            try css.append(line);
                            try css.append("\n");
                        }
                    }
                    try css.append("\n");
                }
            }
        }

        // Preflight (if enabled and no custom reset was specified)
        if (self.config.build.preflight and !has_reset) {
            const preflight_module = @import("generator/preflight.zig");
            const preflight_css = try preflight_module.generatePreflight(self.allocator);
            // Note: preflight_css is a string literal, no need to free
            try css.append(preflight_css);
            try css.append("\n");
        }

        // Initialize plugin system
        var plugin_ctx = PluginContext.init(self.allocator, &self.config);
        defer plugin_ctx.deinit();

        var plugin_registry = PluginRegistry.init(self.allocator);
        defer plugin_registry.deinit();

        // Register built-in plugins
        try plugin_registry.register(Plugin.init(self.allocator, "forms", formsPlugin));
        try plugin_registry.register(Plugin.init(self.allocator, "typography", typographyPlugin));

        // Execute all plugins
        try plugin_registry.executeAll(&plugin_ctx);

        // Add plugin base styles
        if (plugin_ctx.base_styles.items.len > 0) {
            try css.append("  /* Plugin Base Styles */\n");
            for (plugin_ctx.base_styles.items) |*style| {
                const style_css = try style.toCss(self.allocator);
                defer self.allocator.free(style_css);
                try css.append("  ");
                try css.append(style_css);
                try css.append("\n");
            }
            try css.append("\n");
        }

        try css.append("}\n\n");

        // Components layer
        try css.append("@layer components {\n");

        // Add plugin component styles
        if (plugin_ctx.component_styles.items.len > 0) {
            try css.append("  /* Plugin Components */\n");
            for (plugin_ctx.component_styles.items) |*style| {
                const style_css = try style.toCss(self.allocator);
                defer self.allocator.free(style_css);
                try css.append("  ");
                try css.append(style_css);
                try css.append("\n");
            }
        }

        try css.append("}\n\n");

        // Utilities layer
        try css.append("@layer utilities {\n");
        try css.append("  /* Utilities */\n");

        // Configure CSS generator with dark mode settings
        const generator_config = CSSGenerator.Config{
            .dark_mode_selector = self.config.darkMode.className,
            .dark_mode_strategy = switch (self.config.darkMode.strategy) {
                .class, .selector => .class,
                .media => .media,
            },
        };
        var generator = CSSGenerator.initWithConfig(self.allocator, generator_config);
        defer generator.deinit();

        for (classes) |class| {
            try generator.generateForClass(class);
        }

        const utilities_css = try generator.generate();
        defer self.allocator.free(utilities_css);

        // Indent utilities
        var lines = std.mem.splitSequence(u8, utilities_css, "\n");
        while (lines.next()) |line| {
            if (line.len > 0) {
                try css.append("  ");
                try css.append(line);
                try css.append("\n");
            }
        }

        // Add plugin utility styles
        if (plugin_ctx.utility_styles.items.len > 0) {
            try css.append("\n  /* Plugin Utilities */\n");
            for (plugin_ctx.utility_styles.items) |*style| {
                const style_css = try style.toCss(self.allocator);
                defer self.allocator.free(style_css);
                try css.append("  ");
                try css.append(style_css);
                try css.append("\n");
            }
        }

        try css.append("}\n");

        self.stats.css_rules_generated = generator.rules.items.len;

        var result = try css.toOwnedSlice();

        // Minify if enabled
        if (self.config.build.minify) {
            const minifier = @import("generator/css_minifier.zig");
            const minified = try minifier.minify(self.allocator, result);
            self.allocator.free(result);
            result = minified;
        }

        return result;
    }

    /// Get statistics
    pub fn getStats(self: *const crosswind) types.Stats {
        return self.stats;
    }
};

pub const ConfigResult = config_loader.ConfigResult;

/// Load configuration from default locations
/// Returns ConfigResult which must be deinitialized by caller
pub fn loadConfigResult(alloc: std.mem.Allocator) !ConfigResult {
    return config_loader.loadConfigResult(alloc, .{});
}

/// Load configuration with custom options
/// Returns ConfigResult which must be deinitialized by caller
pub fn loadConfigResultWithOptions(
    alloc: std.mem.Allocator,
    options: config_loader.LoadOptions,
) !ConfigResult {
    return config_loader.loadConfigResult(alloc, options);
}

/// Load configuration from default locations
/// DEPRECATED: Use loadConfigResult() instead
pub fn loadConfig(alloc: std.mem.Allocator) !crosswindConfig {
    return config_loader.loadConfig(alloc, .{});
}

/// Load configuration with custom options
/// DEPRECATED: Use loadConfigResultWithOptions() instead
pub fn loadConfigWithOptions(
    alloc: std.mem.Allocator,
    options: config_loader.LoadOptions,
) !crosswindConfig {
    return config_loader.loadConfig(alloc, options);
}

test "version" {
    try std.testing.expectEqualStrings("0.1.0", version);
}

test "crosswind init" {
    const cfg = config.defaultConfig();
    var hw = try crosswind.init(std.testing.allocator, cfg);
    defer hw.deinit();

    const stats = hw.getStats();
    try std.testing.expectEqual(@as(usize, 0), stats.files_scanned);
}

test "crosswind build" {
    const cfg = config.defaultConfig();
    var hw = try crosswind.init(std.testing.allocator, cfg);
    defer hw.deinit();

    const css = try hw.build();
    defer std.testing.allocator.free(css);

    try std.testing.expect(css.len > 0);
}
