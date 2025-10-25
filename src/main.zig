const std = @import("std");
const headwind = @import("headwind");
const commands = @import("cli/commands.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Skip the program name
    const cmd_args = if (args.len > 1) args[1..] else args[0..0];

    const parsed = commands.parseCommand(cmd_args) catch {
        std.debug.print("Error: Unknown command or invalid arguments\n\n", .{});
        commands.printHelp();
        std.process.exit(1);
    };

    commands.executeCommand(allocator, parsed.cmd, parsed.opts) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        std.process.exit(1);
    };
}
