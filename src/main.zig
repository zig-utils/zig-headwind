const std = @import("std");
const crosswind = @import("crosswind");
const commands = @import("cli/commands.zig");

pub fn main(init: std.process.Init) !void {
    // 0.17-dev hands `main` a `std.process.Init` carrying the allocator and the
    // argument vector. `std.process.argsAlloc` and the zero-argument `main` it
    // paired with are both gone.
    const allocator = init.gpa;
    const io = init.io;

    // `iterateAllocator`, not `iterate`: the latter is a compile error on
    // Windows and WASI, which must materialize the arguments on the heap.
    var args = try init.minimal.args.iterateAllocator(allocator);
    defer args.deinit();
    _ = args.skip(); // program name

    var cmd_args: std.ArrayList([]const u8) = .empty;
    defer cmd_args.deinit(allocator);
    while (args.next()) |arg| try cmd_args.append(allocator, arg);

    const parsed = commands.parseCommand(cmd_args.items) catch {
        std.debug.print("Error: Unknown command or invalid arguments\n\n", .{});
        commands.printHelp();
        std.process.exit(1);
    };

    commands.executeCommand(allocator, io, parsed.cmd, parsed.opts) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        std.process.exit(1);
    };
}
