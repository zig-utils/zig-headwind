const std = @import("std");
const headwind = @import("headwind");

const Command = enum {
    build,
    watch,
    init,
    check,
    clean,
    help,
    version,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const command = parseCommand(args);

    switch (command) {
        .build => try buildCommand(allocator, args),
        .watch => try watchCommand(allocator, args),
        .init => try initCommand(allocator, args),
        .check => try checkCommand(allocator),
        .clean => try cleanCommand(allocator),
        .help => printHelp(),
        .version => printVersion(),
    }
}

fn parseCommand(args: [][:0]u8) Command {
    if (args.len < 2) return .help;

    const cmd = args[1];

    if (std.mem.eql(u8, cmd, "build")) return .build;
    if (std.mem.eql(u8, cmd, "watch")) return .watch;
    if (std.mem.eql(u8, cmd, "init")) return .init;
    if (std.mem.eql(u8, cmd, "check")) return .check;
    if (std.mem.eql(u8, cmd, "clean")) return .clean;
    if (std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "-v")) return .version;
    if (std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "-h")) return .help;

    return .help;
}

fn buildCommand(allocator: std.mem.Allocator, args: [][:0]u8) !void {
    _ = args;

    std.debug.print("Building CSS...\n", .{});

    // Load configuration
    const config = headwind.loadConfig(allocator) catch |err| blk: {
        if (err == error.ConfigFileNotFound) {
            std.debug.print("No configuration found, using defaults\n", .{});
            break :blk headwind.config.defaultConfig();
        }
        return err;
    };

    // Initialize Headwind
    var hw = try headwind.Headwind.init(allocator, config);
    defer hw.deinit();

    // Build CSS
    const start = std.time.milliTimestamp();
    const css = try hw.build();
    defer allocator.free(css);
    const duration = std.time.milliTimestamp() - start;

    // Write output
    const output_path = config.build.output;
    const file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();
    try file.writeAll(css);

    // Print stats
    const stats = hw.getStats();
    std.debug.print("\n✓ Built successfully in {d}ms\n", .{duration});
    std.debug.print("  Output: {s}\n", .{output_path});
    std.debug.print("  Size: {d} bytes\n", .{css.len});
    if (stats.files_scanned > 0) {
        std.debug.print("  Files scanned: {d}\n", .{stats.files_scanned});
        std.debug.print("  Classes extracted: {d}\n", .{stats.classes_extracted});
    }
}

fn watchCommand(allocator: std.mem.Allocator, args: [][:0]u8) !void {
    _ = allocator;
    _ = args;
    std.debug.print("Watch mode not yet implemented\n", .{});
    std.debug.print("Use 'headwind build' for now\n", .{});
}

fn initCommand(allocator: std.mem.Allocator, args: [][:0]u8) !void {
    _ = args;

    std.debug.print("Initializing Headwind configuration...\n", .{});

    // Create default config file
    const config_content =
        \\{
        \\  "content": {
        \\    "files": [
        \\      "src/**/*.{html,js,jsx,ts,tsx,vue,svelte}"
        \\    ]
        \\  },
        \\  "theme": {
        \\    "extend": {}
        \\  },
        \\  "plugins": []
        \\}
        \\
    ;

    const file = std.fs.cwd().createFile("headwind.config.json", .{}) catch |err| {
        if (err == error.PathAlreadyExists) {
            std.debug.print("Configuration file already exists!\n", .{});
            return;
        }
        return err;
    };
    defer file.close();

    try file.writeAll(config_content);

    std.debug.print("✓ Created headwind.config.json\n", .{});
    std.debug.print("\nNext steps:\n", .{});
    std.debug.print("  1. Customize your configuration in headwind.config.json\n", .{});
    std.debug.print("  2. Run 'headwind build' to generate CSS\n", .{});

    _ = allocator;
}

fn checkCommand(allocator: std.mem.Allocator) !void {
    std.debug.print("Checking configuration...\n", .{});

    const config = headwind.loadConfig(allocator) catch |err| {
        std.debug.print("✗ Configuration error: {}\n", .{err});
        return;
    };

    try headwind.config.validate(&config);

    std.debug.print("✓ Configuration is valid\n", .{});
    std.debug.print("  Content paths: {d}\n", .{config.content.files.len});
    std.debug.print("  Output: {s}\n", .{config.build.output});
}

fn cleanCommand(allocator: std.mem.Allocator) !void {
    _ = allocator;

    std.debug.print("Cleaning cache...\n", .{});

    const cache_dir = ".headwind-cache";
    std.fs.cwd().deleteTree(cache_dir) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("Cache directory not found\n", .{});
            return;
        }
        return err;
    };

    std.debug.print("✓ Cache cleaned\n", .{});
}

fn printVersion() void {
    std.debug.print("Headwind v{s}\n", .{headwind.version});
    std.debug.print("A high-performance Tailwind CSS alternative built with Zig\n", .{});
}

fn printHelp() void {
    std.debug.print(
        \\Headwind - High-performance CSS framework
        \\
        \\Usage: headwind <command> [options]
        \\
        \\Commands:
        \\  build       Build CSS from source files
        \\  watch       Watch for changes and rebuild (coming soon)
        \\  init        Initialize a new configuration file
        \\  check       Validate configuration
        \\  clean       Clean the cache
        \\  version     Show version information
        \\  help        Show this help message
        \\
        \\Options:
        \\  --config <path>    Path to configuration file
        \\  --output <path>    Output file path
        \\  --minify           Minify the output
        \\  --watch            Watch for changes
        \\
        \\Examples:
        \\  headwind build
        \\  headwind build --minify
        \\  headwind watch
        \\  headwind init
        \\
        \\For more information, visit: https://github.com/yourusername/headwind
        \\
    , .{});
}
