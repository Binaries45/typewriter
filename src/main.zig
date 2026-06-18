const std = @import("std");
const Io = std.Io;
const cli = @import("cli.zig");
const Image = @import("Image.zig");
const Text = @import("Text.zig");
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
    const file = try Io.Dir.cwd().openFile(init.io, proc.font, .{.mode = .read_only});
    defer file.close(init.io);
    const size = (try file.stat(init.io)).size;

    const font_data = try alloc.alloc(u8, size);
    const content = try Io.Dir.readFile(Io.Dir.cwd(), init.io, proc.font, font_data);

    // collect text
    var txt: Text = try .fromPath(alloc, init.io, proc.input);
    txt.font = try .init(content, 40);

    // write image : this is a test for now and will be replaced with animation generation later
    var img: Image = .blank(alloc, proc.width, proc.height);
    defer img.free(alloc);
    img.clear(Image.BLACK);
    img.addText(txt, Image.WHITE);
    try img.writeToPng(alloc, "test.png");
}
