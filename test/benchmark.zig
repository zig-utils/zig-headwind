const std = @import("std");
const headwind = @import("headwind");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Headwind Benchmarks ===\n\n", .{});

    try benchmarkStringHashing(allocator);
    try benchmarkStringBuilder(allocator);
    try benchmarkStringPool(allocator);

    std.debug.print("\n✓ All benchmarks completed\n", .{});
}

fn benchmarkStringHashing(allocator: std.mem.Allocator) !void {
    const iterations = 1_000_000;
    const test_string = "hover:focus:bg-blue-500";

    const start = std.time.nanoTimestamp();
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        _ = headwind.string.hashString(test_string);
    }
    const end = std.time.nanoTimestamp();

    const duration_ns = end - start;
    const ops_per_sec = @as(f64, @floatFromInt(iterations)) / (@as(f64, @floatFromInt(duration_ns)) / 1_000_000_000.0);

    std.debug.print("String Hashing:\n", .{});
    std.debug.print("  Iterations: {d}\n", .{iterations});
    std.debug.print("  Duration: {d}ms\n", .{@divTrunc(duration_ns, 1_000_000)});
    std.debug.print("  Ops/sec: {d:.0}\n\n", .{ops_per_sec});

    _ = allocator;
}

fn benchmarkStringBuilder(allocator: std.mem.Allocator) !void {
    const iterations = 100_000;

    const start = std.time.nanoTimestamp();
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        var sb = headwind.string.StringBuilder.init(allocator);
        defer sb.deinit();

        try sb.append("hover:");
        try sb.append("focus:");
        try sb.append("bg-blue-500");

        const result = sb.toString();
        _ = result;
    }
    const end = std.time.nanoTimestamp();

    const duration_ns = end - start;
    const ops_per_sec = @as(f64, @floatFromInt(iterations)) / (@as(f64, @floatFromInt(duration_ns)) / 1_000_000_000.0);

    std.debug.print("StringBuilder:\n", .{});
    std.debug.print("  Iterations: {d}\n", .{iterations});
    std.debug.print("  Duration: {d}ms\n", .{@divTrunc(duration_ns, 1_000_000)});
    std.debug.print("  Ops/sec: {d:.0}\n\n", .{ops_per_sec});
}

fn benchmarkStringPool(allocator: std.mem.Allocator) !void {
    const iterations = 100_000;

    var pool = headwind.allocator.StringPool.init(allocator);
    defer pool.deinit();

    const start = std.time.nanoTimestamp();
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        _ = try pool.intern("hover:bg-blue-500");
        _ = try pool.intern("focus:text-white");
        _ = try pool.intern("hover:bg-blue-500"); // Duplicate
    }
    const end = std.time.nanoTimestamp();

    const duration_ns = end - start;
    const ops_per_sec = @as(f64, @floatFromInt(iterations * 3)) / (@as(f64, @floatFromInt(duration_ns)) / 1_000_000_000.0);

    std.debug.print("StringPool:\n", .{});
    std.debug.print("  Iterations: {d} (x3 = {d} ops)\n", .{ iterations, iterations * 3 });
    std.debug.print("  Duration: {d}ms\n", .{@divTrunc(duration_ns, 1_000_000)});
    std.debug.print("  Ops/sec: {d:.0}\n", .{ops_per_sec});
    std.debug.print("  Unique strings: {d}\n\n", .{pool.count()});
}
