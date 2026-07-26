const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies - manually add zig-config from local path
    const zig_config_path = "../zig-config/src/zig-config.zig";
    const zig_config_mod = b.addModule("zig_config", .{
        .root_source_file = b.path(zig_config_path),
        .target = target,
        .optimize = optimize,
    });

    // Library module
    const crosswind_lib = b.addModule("crosswind", .{
        .root_source_file = b.path("src/crosswind.zig"),
    });

    // Add zig-config as a dependency
    crosswind_lib.addImport("zig_config", zig_config_mod);

    // Executable (CLI)
    const exe = b.addExecutable(.{
        .name = "crosswind",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("crosswind", crosswind_lib);
    exe.root_module.addImport("zig_config", zig_config_mod);

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // `b.args` (the `zig build run -- ...` passthrough) was removed from
    // std.Build in 0.17-dev. The replacement is an explicit, declared option,
    // repeated once per argument — same pattern as the sibling zig-utils
    // libraries:
    //     zig build run -Drun-arg=build -Drun-arg=./src
    const run_args = b.option(
        []const []const u8,
        "run-arg",
        "Argument passed to the CLI; repeat the option for multiple arguments",
    ) orelse &.{};
    run_cmd.addArgs(run_args);

    const run_step = b.step("run", "Run the CLI");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/crosswind.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib_tests.root_module.addImport("zig_config", zig_config_mod);

    const run_lib_tests = b.addRunArtifact(lib_tests);

    // Comprehensive test suite
    const comprehensive_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/test_runner.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    comprehensive_tests.root_module.addImport("zig_config", zig_config_mod);
    comprehensive_tests.root_module.addImport("crosswind", crosswind_lib);

    const run_comprehensive_tests = b.addRunArtifact(comprehensive_tests);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_lib_tests.step);
    test_step.dependOn(&run_comprehensive_tests.step);

    // Benchmarks
    const bench = b.addExecutable(.{
        .name = "benchmark",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/benchmark.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        }),
    });

    bench.root_module.addImport("crosswind", crosswind_lib);

    const run_bench = b.addRunArtifact(bench);
    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&run_bench.step);

    // Format check
    // 0.17-dev takes LazyPath values here, not string literals.
    const fmt_check = b.addFmt(.{
        .paths = &.{ b.path("src"), b.path("test") },
        .check = true,
    });

    const fmt_step = b.step("fmt", "Check formatting");
    fmt_step.dependOn(&fmt_check.step);

    // Cross-compilation build system
    // Define all target platforms with proper naming
    const CrossTarget = struct {
        query: std.Target.Query,
        name: []const u8,
        extension: []const u8,
    };

    const cross_targets = [_]CrossTarget{
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .linux }, .name = "linux-x86_64", .extension = "" },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .linux }, .name = "linux-aarch64", .extension = "" },
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .macos }, .name = "macos-x86_64", .extension = "" },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .macos }, .name = "macos-arm64", .extension = "" },
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .windows }, .name = "windows-x86_64", .extension = ".exe" },
    };

    // Create individual build steps for each platform
    inline for (cross_targets) |cross_target| {
        const platform_step = b.step("build-" ++ cross_target.name, "Build for " ++ cross_target.name);

        const cross_exe = b.addExecutable(.{
            .name = "crosswind",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(cross_target.query),
                .optimize = .ReleaseFast,
            }),
        });

        cross_exe.root_module.addImport("crosswind", crosswind_lib);
        cross_exe.root_module.addImport("zig_config", zig_config_mod);

        // Static linking only for Linux and Windows (macOS doesn't support static libc)
        if (cross_target.query.os_tag == .linux or cross_target.query.os_tag == .windows) {
            cross_exe.linkage = .static;
        }

        // Strip debug symbols in release builds
        cross_exe.root_module.strip = true;

        // Install to platform-specific directory
        const install_cross = b.addInstallArtifact(cross_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = "dist/" ++ cross_target.name,
                },
            },
        });

        platform_step.dependOn(&install_cross.step);
    }

    // Build all platforms
    const build_all_step = b.step("build-all", "Build for all platforms (Linux x86_64/aarch64, macOS x86_64/arm64, Windows x86_64)");

    inline for (cross_targets) |cross_target| {
        const cross_exe = b.addExecutable(.{
            .name = "crosswind",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(cross_target.query),
                .optimize = .ReleaseFast,
            }),
        });

        cross_exe.root_module.addImport("crosswind", crosswind_lib);
        cross_exe.root_module.addImport("zig_config", zig_config_mod);

        // Static linking only for Linux and Windows
        if (cross_target.query.os_tag == .linux or cross_target.query.os_tag == .windows) {
            cross_exe.linkage = .static;
        }

        cross_exe.root_module.strip = true;

        const install_cross = b.addInstallArtifact(cross_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = "dist/" ++ cross_target.name,
                },
            },
        });

        build_all_step.dependOn(&install_cross.step);
    }

    // Legacy cross-compilation step (for compatibility)
    const cross_step = b.step("cross", "Build for all platforms (alias for build-all)");
    cross_step.dependOn(build_all_step);

    // Release build with all optimizations
    const release_step = b.step("release", "Build optimized release binary for current platform");
    const release_exe = b.addExecutable(.{
        .name = "crosswind",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        }),
    });

    release_exe.root_module.addImport("crosswind", crosswind_lib);
    release_exe.root_module.addImport("zig_config", zig_config_mod);
    release_exe.root_module.strip = true;

    const install_release = b.addInstallArtifact(release_exe, .{});
    release_step.dependOn(&install_release.step);

    // Small size optimized build
    const release_small_step = b.step("release-small", "Build size-optimized release binary");
    const release_small_exe = b.addExecutable(.{
        .name = "crosswind",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .ReleaseSmall,
        }),
    });

    release_small_exe.root_module.addImport("crosswind", crosswind_lib);
    release_small_exe.root_module.addImport("zig_config", zig_config_mod);
    release_small_exe.root_module.strip = true;

    const install_release_small = b.addInstallArtifact(release_small_exe, .{});
    release_small_step.dependOn(&install_release_small.step);
}
