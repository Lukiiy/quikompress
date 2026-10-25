const std = @import("std");
const Io = std.Io;

const quikompress = @import("quikompress");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len < 2) {
        std.debug.print("Usage: {s} x y z\n", .{args[0]});
        std.process.exit(1);
    }
}