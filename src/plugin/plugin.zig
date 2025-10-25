const std = @import("std");
const HeadwindConfig = @import("../config/schema.zig").HeadwindConfig;
const CSSGenerator = @import("../generator/css_generator.zig").CSSGenerator;

/// Plugin interface for extending Headwind
pub const Plugin = struct {
    name: []const u8,
    init_fn: *const fn (*PluginContext) anyerror!void,
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        name: []const u8,
        init_fn: *const fn (*PluginContext) anyerror!void,
    ) Plugin {
        return .{
            .name = name,
            .init_fn = init_fn,
            .allocator = allocator,
        };
    }

    pub fn execute(self: *Plugin, ctx: *PluginContext) !void {
        try self.init_fn(ctx);
    }
};

/// Plugin context provides APIs for plugins to extend Headwind
pub const PluginContext = struct {
    allocator: std.mem.Allocator,
    config: *const HeadwindConfig,
    base_styles: std.ArrayList(CustomStyle),
    component_styles: std.ArrayList(CustomStyle),
    utility_styles: std.ArrayList(CustomStyle),
    custom_variants: std.StringHashMap(VariantDefinition),

    pub fn init(allocator: std.mem.Allocator, config: *const HeadwindConfig) PluginContext {
        return .{
            .allocator = allocator,
            .config = config,
            .base_styles = .{},
            .component_styles = .{},
            .utility_styles = .{},
            .custom_variants = std.StringHashMap(VariantDefinition).init(allocator),
        };
    }

    pub fn deinit(self: *PluginContext) void {
        for (self.base_styles.items) |*style| {
            style.deinit(self.allocator);
        }
        self.base_styles.deinit(self.allocator);

        for (self.component_styles.items) |*style| {
            style.deinit(self.allocator);
        }
        self.component_styles.deinit(self.allocator);

        for (self.utility_styles.items) |*style| {
            style.deinit(self.allocator);
        }
        self.utility_styles.deinit(self.allocator);

        var variant_iter = self.custom_variants.valueIterator();
        while (variant_iter.next()) |variant| {
            variant.deinit(self.allocator);
        }
        self.custom_variants.deinit();
    }

    /// Add base styles (similar to Tailwind's addBase)
    pub fn addBase(self: *PluginContext, selector: []const u8, styles: []const StyleDeclaration) !void {
        const custom_style = try CustomStyle.init(self.allocator, selector, styles);
        try self.base_styles.append(self.allocator, custom_style);
    }

    /// Add component styles (similar to Tailwind's addComponents)
    pub fn addComponents(self: *PluginContext, selector: []const u8, styles: []const StyleDeclaration) !void {
        const custom_style = try CustomStyle.init(self.allocator, selector, styles);
        try self.component_styles.append(self.allocator, custom_style);
    }

    /// Add utility styles (similar to Tailwind's addUtilities)
    pub fn addUtilities(self: *PluginContext, utilities: []const UtilityDefinition) !void {
        for (utilities) |util| {
            const custom_style = try CustomStyle.initFromUtility(self.allocator, util);
            try self.utility_styles.append(self.allocator, custom_style);
        }
    }

    /// Add custom variant (similar to Tailwind's addVariant)
    pub fn addVariant(self: *PluginContext, name: []const u8, definition: VariantDefinition) !void {
        const owned_name = try self.allocator.dupe(u8, name);
        try self.custom_variants.put(owned_name, definition);
    }

    /// Get theme value (similar to Tailwind's theme())
    pub fn theme(self: *PluginContext, path: []const u8) ?[]const u8 {
        _ = self;
        _ = path;
        // TODO: Implement theme value lookup
        return null;
    }

    /// Get config value (similar to Tailwind's config())
    pub fn configValue(self: *PluginContext, path: []const u8) ?[]const u8 {
        _ = self;
        _ = path;
        // TODO: Implement config value lookup
        return null;
    }

    /// Escape class name (similar to Tailwind's e())
    pub fn escape(self: *PluginContext, className: []const u8) ![]const u8 {
        // Escape special characters in class names
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        for (className) |char| {
            switch (char) {
                ':', '.', '/', '[', ']', '(', ')', '#', '!', '@' => {
                    try result.append('\\');
                    try result.append(char);
                },
                else => try result.append(char),
            }
        }

        return result.toOwnedSlice();
    }
};

/// Custom style definition
pub const CustomStyle = struct {
    selector: []const u8,
    declarations: []StyleDeclaration,

    pub fn init(allocator: std.mem.Allocator, selector: []const u8, declarations: []const StyleDeclaration) !CustomStyle {
        const owned_selector = try allocator.dupe(u8, selector);
        const owned_decls = try allocator.alloc(StyleDeclaration, declarations.len);

        for (declarations, 0..) |decl, i| {
            owned_decls[i] = try StyleDeclaration.init(allocator, decl.property, decl.value);
        }

        return .{
            .selector = owned_selector,
            .declarations = owned_decls,
        };
    }

    pub fn initFromUtility(allocator: std.mem.Allocator, util: UtilityDefinition) !CustomStyle {
        const selector = try std.fmt.allocPrint(allocator, ".{s}", .{util.name});
        defer allocator.free(selector);
        return init(allocator, selector, util.declarations);
    }

    pub fn deinit(self: *CustomStyle, allocator: std.mem.Allocator) void {
        allocator.free(self.selector);
        for (self.declarations) |*decl| {
            decl.deinit(allocator);
        }
        allocator.free(self.declarations);
    }

    pub fn toCss(self: *const CustomStyle, allocator: std.mem.Allocator) ![]const u8 {
        const string_utils = @import("../utils/string.zig");
        var result = string_utils.StringBuilder.init(allocator);
        errdefer result.deinit();

        try result.append(self.selector);
        try result.append(" { ");

        for (self.declarations, 0..) |decl, i| {
            if (i > 0) try result.append("; ");
            try result.append(decl.property);
            try result.append(": ");
            try result.append(decl.value);
        }

        try result.append(" }");
        return result.toOwnedSlice();
    }
};

/// Style declaration (property: value)
pub const StyleDeclaration = struct {
    property: []const u8,
    value: []const u8,

    pub fn init(allocator: std.mem.Allocator, property: []const u8, value: []const u8) !StyleDeclaration {
        return .{
            .property = try allocator.dupe(u8, property),
            .value = try allocator.dupe(u8, value),
        };
    }

    pub fn deinit(self: *StyleDeclaration, allocator: std.mem.Allocator) void {
        allocator.free(self.property);
        allocator.free(self.value);
    }
};

/// Utility definition
pub const UtilityDefinition = struct {
    name: []const u8,
    declarations: []const StyleDeclaration,
};

/// Variant definition
pub const VariantDefinition = struct {
    selector_transform: []const u8, // e.g., ":hover", "::before", etc.
    media_query: ?[]const u8 = null,

    pub fn deinit(self: *VariantDefinition, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
        // Currently no allocations, but keep for future use
    }
};

/// Plugin registry
pub const PluginRegistry = struct {
    plugins: std.ArrayList(Plugin),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) PluginRegistry {
        return .{
            .plugins = .{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PluginRegistry) void {
        self.plugins.deinit(self.allocator);
    }

    pub fn register(self: *PluginRegistry, plugin: Plugin) !void {
        try self.plugins.append(self.allocator, plugin);
    }

    pub fn executeAll(self: *PluginRegistry, ctx: *PluginContext) !void {
        for (self.plugins.items) |*plugin| {
            try plugin.execute(ctx);
        }
    }
};

test "plugin context init" {
    const config = @import("../config/schema.zig").defaultConfig();
    var ctx = PluginContext.init(std.testing.allocator, &config);
    defer ctx.deinit();

    try std.testing.expect(ctx.base_styles.items.len == 0);
    try std.testing.expect(ctx.component_styles.items.len == 0);
    try std.testing.expect(ctx.utility_styles.items.len == 0);
}

test "add utilities" {
    const config = @import("../config/schema.zig").defaultConfig();
    var ctx = PluginContext.init(std.testing.allocator, &config);
    defer ctx.deinit();

    const decls = [_]StyleDeclaration{
        .{ .property = "display", .value = "flex" },
        .{ .property = "align-items", .value = "center" },
    };

    const utils = [_]UtilityDefinition{
        .{ .name = "flex-center", .declarations = &decls },
    };

    try ctx.addUtilities(&utils);
    try std.testing.expect(ctx.utility_styles.items.len == 1);
}
