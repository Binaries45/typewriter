const std = @import("std");
const Io = std.Io;
const Proc = @import("cli.zig").Proc;
const Text = @import("Text.zig");
const Image = @import("Image.zig");

pub fn render(alloc: std.mem.Allocator, io: Io, proc: Proc) !void {
    const file = try Io.Dir.cwd().openFile(io, proc.font, .{.mode = .read_only});
    defer file.close(io);
    const size = (try file.stat(io)).size;

    const font_data = try alloc.alloc(u8, size);
    const content = try Io.Dir.readFile(Io.Dir.cwd(), io, proc.font, font_data);

    var text: Text = try .fromPath(alloc, io, proc.input);
    text.font = try .init(content, 30);

    var img: Image = .blank(alloc, proc.width, proc.height);
    defer img.free(alloc);

    const total_frames = (text.raw.len / proc.cps) * proc.fps;
    std.debug.print("rendering {d} frames\n", .{total_frames});

    // todo maybe parallelize this since frames are independent, it would help with render times a lot
    for(0..total_frames) |i| {
        img.clear(Image.BLACK); // todo : take clear color as option
        const nc = @as(usize, @intFromFloat(@round((
            @as(f32, @floatFromInt(i))
            / @as(f32, @floatFromInt(proc.fps)))
            * @as(f32, @floatFromInt(proc.cps))
        )));
        const path = try std.fmt.allocPrintSentinel(alloc, "{s}/{d:0>6}.png", .{proc.output_dir, i}, 0);
        img.addText(text, nc, Image.WHITE);
        try img.writeToPng(alloc, path);
        std.debug.print("\r    rendered {d}/{d} frames    ", .{i, total_frames});
    }
}