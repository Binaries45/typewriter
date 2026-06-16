const std = @import("std");
const Io = std.Io;
const cli = @import("cli.zig");
const stb = @import("stb");
const Image = @import("Image.zig");

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();

    var arg_iter = try init.minimal.args.iterateAllocator(alloc);
    defer arg_iter.deinit();

    const proc = cli.parseArgs(alloc, &arg_iter);
    std.log.info(
        \\input:      {s}
        \\      output:     {s}
        \\      fps:        {d}
        \\      cps:        {d}
        \\      dimensions: {d}x{d}
    , .{
        proc.input, proc.output_dir, proc.fps,
        proc.cps, proc.width, proc.height
    });

    // test image write : this is temporary
    var img: Image = .blank(alloc, 256, 256);
    defer img.free(alloc);
    img.clear(Image.BLUE);
    try img.writeToPng(alloc, "test.png");
}
