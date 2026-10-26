const std = @import("std");
const Io = std.Io;

const quikompress = @import("quikompress");
const interact = @import("ffinteract.zig");
const TARGET: f64 = 19.8; // size in MB; just making sure
const AUDIO_BITRATE: u32 = 64; // kbps

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len < 2) {
        std.debug.print("Usage: {s} x y z\n", .{args[0]});
        std.process.exit(1);
    }

    const io = init.io;
    const path = args[1];
    var outPath: []u8 = undefined;

    if (args.len >= 3) {
        outPath = try allocator.dupe(u8, args[2]);
    } else {
        outPath = try std.fmt.allocPrint(allocator, "{s}_compress.webm", .{std.fs.path.stem(path)});
    }

    defer allocator.free(outPath);

    {
        const file = Io.Dir.cwd().openFile(io, path, .{}) catch |err| {
            std.debug.print("oh no!!! Couldn't open input \"{s}\": {}\n", .{ path, err });
            std.process.exit(1);
        };

        file.close(io);
    }

    std.debug.print("in: {s}; out: {s}\n", .{path, outPath});

    const duration = interact.getDuration(allocator, path) catch {
        std.debug.print("Couldn't get the duration.\n", .{});
        std.process.exit(1);
    };

    if (duration <= 0) {
        std.debug.print("Invalid duration!\n", .{});
        std.process.exit(1);
    }

    const totalBits = TARGET * 8192.0;
    const totalBitrate: i32 = @trunc(totalBits / duration);
    const vidBitrate: i32 = totalBitrate - @as(i32, @intCast(AUDIO_BITRATE));

    if (vidBitrate <= 25) {
        std.debug.print("This video is way too long to fit into {d}mb!\nRequired bitrate: {d} kbps\n", .{ TARGET, vidBitrate });
        std.process.exit(1);
    }
}