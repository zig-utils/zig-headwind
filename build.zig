const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies - manually add zig-config from local path
    const zig_config_path = "../zig-config/src/zig-config.zig";
    const zig_config_mod = b.addModule("zig-config", .{
        .root_source_file = b.path(zig_config_path),
        .target = target,
        .optimize = optimize,
    });

    // Library module
    const headwind_lib = b.addModule("headwind", .{
        .root_source_file = b.path("src/headwind.zig"),
    });

    // Add zig-config as a dependency
    headwind_lib.addImport("zig-config", zig_config_mod);

    // Executable (CLI)
    const exe = b.addExecutable(.{
        .name = "headwind",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("headwind", headwind_lib);
    exe.root_module.addImport("zig-config", zig_config_mod);

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the CLI");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/headwind.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib_tests.root_module.addImport("zig-config", zig_config_mod);

    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);

    // Benchmarks
    const bench = b.addExecutable(.{
        .name = "benchmark",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/benchmark.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        }),
    });

    bench.root_module.addImport("headwind", headwind_lib);

    const run_bench = b.addRunArtifact(bench);
    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&run_bench.step);

    // Format check
    const fmt_check = b.addFmt(.{
        .paths = &.{ "src", "test" },
        .check = true,
    });

    const fmt_step = b.step("fmt", "Check formatting");
    fmt_step.dependOn(&fmt_check.step);

    // Cross-compilation targets
    const cross_targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64, .os_tag = .linux },
        .{ .cpu_arch = .aarch64, .os_tag = .linux },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
    };

    const cross_step = b.step("cross", "Build for all platforms");

    for (cross_targets) |cross_target| {
        const cross_exe = b.addExecutable(.{
            .name = "headwind",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(cross_target),
                .optimize = .ReleaseFast,
            }),
        });

        cross_exe.root_module.addImport("headwind", headwind_lib);
        cross_exe.root_module.addImport("zig-config", zig_config_mod);

        const install_cross = b.addInstallArtifact(cross_exe, .{});
        cross_step.dependOn(&install_cross.step);
    }
}
