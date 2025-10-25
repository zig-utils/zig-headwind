const std = @import("std");
const zig_config = @import("zig-config");
const schema = @import("schema.zig");

pub const ConfigResult = zig_config.ConfigResult(schema.HeadwindConfig);

/// Load Headwind configuration using zig-config
/// Returns the full ConfigResult which must be deinitialized by the caller
pub fn loadConfigResult(allocator: std.mem.Allocator, options: LoadOptions) !ConfigResult {
    // Use zig-config to load configuration
    var config_result = try zig_config.loadConfig(
        schema.HeadwindConfig,
        allocator,
        .{
            .name = options.name orelse "headwind",
            .cwd = options.cwd,
            .env_prefix = "HEADWIND",
        },
    );
    errdefer config_result.deinit(allocator);

    // Validate the configuration
    try schema.validate(&config_result.value);

    return config_result;
}

/// Load Headwind configuration using zig-config
/// Note: The returned config owns its memory. Strings and arrays in the config
/// must be freed by the caller using the same allocator.
/// DEPRECATED: Use loadConfigResult() instead and call deinit() on the result
/// WARNING: This function leaks memory - the ConfigResult is not properly cleaned up
pub fn loadConfig(allocator: std.mem.Allocator, options: LoadOptions) !schema.HeadwindConfig {
    const config_result = try loadConfigResult(allocator, options);
    // WARNING: This leaks memory! The config_result should be deinitialized
    // but we can't do it here because we're returning the value.
    // Callers should use loadConfigResult() instead.
    return config_result.value;
}

pub const LoadOptions = struct {
    /// Config name (default: "headwind")
    name: ?[]const u8 = null,

    /// Working directory to search for config
    cwd: ?[]const u8 = null,
};

/// Find configuration file
pub fn findConfigFile(allocator: std.mem.Allocator, cwd: ?[]const u8) !?[]const u8 {
    const search_dir = cwd orelse try std.fs.cwd().realpathAlloc(allocator, ".");
    defer if (cwd == null) allocator.free(search_dir);

    const config_names = [_][]const u8{
        "headwind.config.json",
        "headwind.config.zig",
        ".headwindrc.json",
        ".headwindrc",
    };

    for (config_names) |name| {
        const path = try std.fs.path.join(allocator, &.{ search_dir, name });
        defer allocator.free(path);

        std.fs.accessAbsolute(path, .{}) catch continue;

        return try allocator.dupe(u8, path);
    }

    return null;
}

test "findConfigFile" {
    const result = try findConfigFile(std.testing.allocator, null);
    if (result) |path| {
        defer std.testing.allocator.free(path);
        std.debug.print("Found config: {s}\n", .{path});
    }
}
