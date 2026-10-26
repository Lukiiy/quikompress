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

pub fn getDuration(allocator: std.mem.Allocator, input: []const u8, io: std.Io) !f64 {
    const argv = [_][]const u8{ "ffprobe", "-show_entries", "format=duration", "-v", "error", "-of", "default=noprint_wrappers=1:nokey=1", input }; // wow: extract duration + ignore anything that's not an error + output only the duration or field
    const result = try std.process.run(allocator, io, .{
        .argv = &argv
    });

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term != .exited or result.term.exited != 0) {
        return error.FfprobeFailed;
    }

    return std.fmt.parseFloat(f64, std.mem.trim(u8, result.stdout, " \n\r\t")); // trims whitespace
}

fn run(allocator: std.mem.Allocator, io: std.Io, args: []const []const u8) !void {
    const result = try std.process.run(allocator, io, .{
        .argv = args
    });

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term != .exited or result.term.exited != 0) return error.CommandFailed;
}