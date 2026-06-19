const std = @import("std");
const Io = std.Io;
const cli = @import("cli.zig");
const Image = @import("Image.zig");
const Text = @import("Text.zig");
const animation = @import("animation.zig");
// im forwarding this type because zls is struggling with importing it to other files
pub const stb = @import("stb");

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
        \\      font: {s}
    , .{
        proc.input, proc.output_dir, proc.fps,
        proc.cps, proc.width, proc.height,
        proc.font,
    });

    // load the font
    try animation.render(alloc, init.io, proc);
}
