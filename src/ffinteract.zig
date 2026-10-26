const std = @import("std");
const builtin = @import("builtin");

pub fn areTheyEvenInstalled(allocator: std.mem.Allocator, io: std.Io) !void {
    const cmd = if (builtin.os.tag == .windows) "where" else "which";
    const bins = [_][]const u8{ "ffmpeg", "ffprobe" };

    for (bins) |bin| {
        const argv = [_][]const u8{ cmd, bin };
        const result = std.process.run(allocator, io, .{
            .argv = &argv,
            .stdout_limit = .limited(0), // funny way to declare ignore
            .stderr_limit = .limited(0)
        }) catch {
            std.debug.print("{s} is not installed!? Couldn't find via the {s} command.\n", .{ bin, cmd });

            return error.MissingDependency;
        };

        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        if (result.term != .exited or result.term.exited != 0) {
            std.debug.print("{s} is not installed!? Couldn't find via the {s} command.\n", .{ bin, cmd });

            return error.MissingDependency;
        }
    }
}