const std = @import("std");
const crosswind = @import("crosswind");

pub const Command = enum {
    init,
    build,
    watch,
    check,
    clean,
    info,
    help,
    version,
};

pub const CommandOptions = struct {
    config_path: ?[]const u8 = null,
    input_file: ?[]const u8 = null,
    output_file: ?[]const u8 = null,
    minify: bool = false,
    sourcemap: bool = false,
    verbose: bool = false,
    quiet: bool = false,
};

pub fn parseCommand(args: []const []const u8) !struct { cmd: Command, opts: CommandOptions } {
    if (args.len == 0) {
        return .{ .cmd = .help, .opts = .{} };
    }

    const cmd_str = args[0];
    const cmd = if (std.mem.eql(u8, cmd_str, "init"))
        Command.init
    else if (std.mem.eql(u8, cmd_str, "build"))
        Command.build
    else if (std.mem.eql(u8, cmd_str, "watch"))
        Command.watch
    else if (std.mem.eql(u8, cmd_str, "check"))
        Command.check
    else if (std.mem.eql(u8, cmd_str, "clean"))
        Command.clean
    else if (std.mem.eql(u8, cmd_str, "info"))
        Command.info
    else if (std.mem.eql(u8, cmd_str, "help") or std.mem.eql(u8, cmd_str, "--help") or std.mem.eql(u8, cmd_str, "-h"))
        Command.help
    else if (std.mem.eql(u8, cmd_str, "version") or std.mem.eql(u8, cmd_str, "--version") or std.mem.eql(u8, cmd_str, "-v"))
        Command.version
    else
        return error.UnknownCommand;

    var opts = CommandOptions{};

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--config") or std.mem.eql(u8, arg, "-c")) {
            i += 1;
            if (i >= args.len) return error.MissingConfigPath;
            opts.config_path = args[i];
        } else if (std.mem.eql(u8, arg, "--input") or std.mem.eql(u8, arg, "-i")) {
            i += 1;
            if (i >= args.len) return error.MissingInputFile;
            opts.input_file = args[i];
        } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            i += 1;
            if (i >= args.len) return error.MissingOutputFile;
            opts.output_file = args[i];
        } else if (std.mem.eql(u8, arg, "--minify") or std.mem.eql(u8, arg, "-m")) {
            opts.minify = true;
        } else if (std.mem.eql(u8, arg, "--sourcemap")) {
            opts.sourcemap = true;
        } else if (std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        } else if (std.mem.eql(u8, arg, "--quiet") or std.mem.eql(u8, arg, "-q")) {
            opts.quiet = true;
        }
    }

    return .{ .cmd = cmd, .opts = opts };
}

pub fn executeCommand(allocator: std.mem.Allocator, io: std.Io, cmd: Command, opts: CommandOptions) !void {
    switch (cmd) {
        .init => try initCommand(allocator, io, opts),
        .build => try buildCommand(allocator, io, opts),
        .watch => try watchCommand(allocator, io, opts),
        .check => try checkCommand(allocator, opts),
        .clean => try cleanCommand(allocator, io, opts),
        .info => try infoCommand(allocator, io, opts),
        .help => printHelp(),
        .version => printVersion(),
    }
}

fn initCommand(allocator: std.mem.Allocator, io: std.Io, opts: CommandOptions) !void {
    _ = opts;

    std.debug.print("Initializing crosswind project...\n", .{});

    // Create default config file
    const config_content =
        \\{
        \\  "content": ["./src/**/*.{html,js,ts,jsx,tsx,vue,svelte}"],
        \\  "theme": {
        \\    "extend": {}
        \\  },
        \\  "plugins": []
        \\}
    ;

    // `Dir.writeFile` replaces create + writeAll: 0.17's Io.File writes through
    // a `writer(io, buffer)` rather than exposing `writeAll` directly, and the
    // one-shot helper is what that collapses to for a whole-file write.
    try std.Io.Dir.cwd().writeFile(io, .{
        .sub_path = "crosswind.config.json",
        .data = config_content,
    });

    // Create input CSS file
    const input_css =
        \\@layer base, components, utilities;
        \\
        \\@import "preflight.css";
        \\
    ;

    try std.Io.Dir.cwd().writeFile(io, .{
        .sub_path = "src/input.css",
        .data = input_css,
    });

    std.debug.print("✓ Created crosswind.config.json\n", .{});
    std.debug.print("✓ Created src/input.css\n", .{});
    std.debug.print("\nRun 'crosswind build' to generate your CSS.\n", .{});
    _ = allocator;
}

fn buildCommand(allocator: std.mem.Allocator, io: std.Io, opts: CommandOptions) !void {
    if (!opts.quiet) {
        std.debug.print("Building CSS...\n", .{});
    }

    // Load configuration
    _ = opts.config_path; // TODO: Support custom config path
    var config_result = crosswind.loadConfigResult(allocator) catch |err| {
        std.debug.print("Error loading config: {}\n", .{err});
        return err;
    };
    defer config_result.deinit(allocator);

    if (opts.verbose) {
        std.debug.print("\n[verbose] Configuration loaded successfully\n", .{});
        const files = config_result.value.content.files;
        std.debug.print("[verbose] Content files configured: {d}\n", .{files.len});
        for (files) |f| {
            std.debug.print("[verbose]   - {s}\n", .{f});
        }
        std.debug.print("[verbose] Grouped syntax: {s}\n", .{if (config_result.value.groupedSyntax.enabled) "enabled" else "disabled"});
        std.debug.print("[verbose] Attributify mode: {s}\n", .{if (config_result.value.attributify.enabled) "enabled" else "disabled"});
    }

    // Initialize crosswind
    var hw = try crosswind.crosswind.init(allocator, io, config_result.value);
    defer hw.deinit();

    // Build (includes scanning and CSS generation)
    const css = try hw.build();
    defer allocator.free(css);

    if (opts.verbose) {
        std.debug.print("[verbose] CSS generated: {d} bytes\n", .{css.len});
        // Count CSS rules (approximate by counting opening braces)
        var rule_count: usize = 0;
        for (css) |c| {
            if (c == '{') rule_count += 1;
        }
        std.debug.print("[verbose] Approximate CSS rules: {d}\n", .{rule_count});
    }

    // Write output
    const output_path = opts.output_file orelse "dist/output.css";

    // Create output directory if it doesn't exist
    if (std.fs.path.dirname(output_path)) |dir| {
        std.Io.Dir.cwd().createDirPath(io, dir) catch {};
    }

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = css });

    if (!opts.quiet) {
        std.debug.print("✓ Built successfully to {s}\n", .{output_path});

        // Size comes from the written bytes rather than a stat: the file is no
        // longer held open (writeFile closes it), and `css.len` is exactly what
        // was just written.
        const size_kb = @as(f64, @floatFromInt(css.len)) / 1024.0;
        std.debug.print("  Size: {d:.2} KB\n", .{size_kb});
    }
}

fn watchCommand(allocator: std.mem.Allocator, io: std.Io, opts: CommandOptions) !void {
    std.debug.print("Starting watch mode...\n", .{});

    // Load configuration
    _ = opts.config_path; // TODO: Support custom config path
    var config_result = crosswind.loadConfigResult(allocator) catch |err| {
        std.debug.print("Error loading config: {}\n", .{err});
        return err;
    };
    defer config_result.deinit(allocator);
    const config = config_result.value;

    // Set up file watcher callback
    const WatchContext = struct {
        var needs_rebuild: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
        var debouncer: @import("../watcher/file_watcher.zig").Debouncer = undefined;

        fn onChange(path: []const u8) void {
            _ = path;
            if (debouncer.trigger()) {
                needs_rebuild.store(true, .seq_cst);
            }
        }
    };

    WatchContext.debouncer = @import("../watcher/file_watcher.zig").Debouncer.init(allocator, 300);

    // Create file watcher
    var watcher = try @import("../watcher/file_watcher.zig").FileWatcher.init(allocator, WatchContext.onChange);
    defer watcher.deinit();

    // Add content paths to watch
    for (config.content.files) |_| {
        // For now, just watch the current directory
        // TODO: Properly expand glob patterns
        try watcher.addPath(".");
        break; // Only add once
    }

    std.debug.print("Watching for changes... (Press Ctrl+C to stop)\n", .{});
    std.debug.print("Content patterns: {d}\n", .{config.content.files.len});

    // Initial build
    std.debug.print("\nInitial build...\n", .{});
    try buildCommand(allocator, io, opts);

    // Start watching in a separate thread
    const watch_thread = try std.Thread.spawn(.{}, struct {
        fn run(w: *@import("../watcher/file_watcher.zig").FileWatcher) !void {
            try w.start();
        }
    }.run, .{&watcher});

    // Main loop: check for rebuild triggers
    while (true) {
        std.posix.nanosleep(0, 100 * std.time.ns_per_ms);

        if (WatchContext.needs_rebuild.load(.seq_cst)) {
            WatchContext.needs_rebuild.store(false, .seq_cst);

            std.debug.print("\n🔄 Change detected, rebuilding...\n", .{});
            buildCommand(allocator, io, opts) catch |err| {
                std.debug.print("Build error: {}\n", .{err});
                continue;
            };
            std.debug.print("✓ Rebuild complete\n", .{});
        }
    }

    watch_thread.join();
}

fn checkCommand(allocator: std.mem.Allocator, opts: CommandOptions) !void {
    _ = opts.config_path; // TODO: Support custom config path
    std.debug.print("Checking configuration...\n", .{});

    const config = crosswind.loadConfig(allocator) catch |err| {
        std.debug.print("✗ Invalid configuration: {}\n", .{err});
        return err;
    };

    std.debug.print("✓ Configuration is valid\n", .{});
    std.debug.print("  Content files: {d}\n", .{config.content.files.len});
}

fn cleanCommand(allocator: std.mem.Allocator, io: std.Io, opts: CommandOptions) !void {
    std.debug.print("Cleaning cache...\n", .{});

    // Remove cache directory
    std.Io.Dir.cwd().deleteTree(io, ".crosswind-cache") catch |err| {
        if (err != error.FileNotFound) {
            return err;
        }
    };

    std.debug.print("✓ Cache cleaned\n", .{});

    _ = allocator;
    _ = opts;
}

fn infoCommand(allocator: std.mem.Allocator, io: std.Io, opts: CommandOptions) !void {
    std.debug.print("crosswind CSS Framework\n", .{});
    std.debug.print("Version: 0.1.0\n", .{});
    std.debug.print("Zig Version: {s}\n", .{@import("builtin").zig_version_string});

    const config_path = opts.config_path orelse "crosswind.config.json";
    const config_exists = blk: {
        std.Io.Dir.cwd().access(io, config_path, .{}) catch {
            break :blk false;
        };
        break :blk true;
    };

    std.debug.print("Config: {s} ({s})\n", .{ config_path, if (config_exists) "found" else "not found" });

    _ = allocator;
}

pub fn printHelp() void {
    std.debug.print(
        \\crosswind - A high-performance Tailwind CSS alternative
        \\
        \\USAGE:
        \\    crosswind <COMMAND> [OPTIONS]
        \\
        \\COMMANDS:
        \\    init        Initialize a new crosswind project
        \\    build       Build CSS from source files
        \\    watch       Watch files and rebuild on changes
        \\    check       Validate configuration
        \\    clean       Clean cache directory
        \\    info        Display system information
        \\    help        Display this help message
        \\    version     Display version information
        \\
        \\OPTIONS:
        \\    -c, --config <PATH>     Path to config file (default: crosswind.config.json)
        \\    -i, --input <PATH>      Input CSS file
        \\    -o, --output <PATH>     Output CSS file (default: dist/output.css)
        \\    -m, --minify            Minify output CSS
        \\    --sourcemap             Generate source map
        \\    --verbose               Enable verbose logging
        \\    -q, --quiet             Suppress output
        \\    -h, --help              Display help
        \\    -v, --version           Display version
        \\
        \\EXAMPLES:
        \\    crosswind init
        \\    crosswind build
        \\    crosswind build --minify --output dist/styles.css
        \\    crosswind watch --verbose
        \\
    , .{});
}

fn printVersion() void {
    std.debug.print("crosswind v0.1.0\n", .{});
}
