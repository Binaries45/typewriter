const std = @import("std");
const Io = std.Io;
const Proc = @import("cli.zig").Proc;
const Text = @import("Text.zig");
const Image = @import("Image.zig");
const Highlight = @import("Highlight.zig");

var frames_rendered: std.atomic.Value(usize) = .init(0);

const Batch = struct {
    alloc: std.mem.Allocator,
    text: *const Text,
    proc: Proc,
    start: usize,
    end: usize,
};

fn renderBatch(b: *Batch) !void {
    var img: Image = .blank(b.alloc, b.proc.width, b.proc.height);
    defer img.free(b.alloc);

    for(b.start..b.end) |i| {
        img.clear(b.proc.bg);
        const nc = @as(usize, @intFromFloat(@round((
        @as(f32, @floatFromInt(i))
            / @as(f32, @floatFromInt(b.proc.fps)))
            * @as(f32, @floatFromInt(b.proc.cps))
        )));
        const path = try std.fmt.allocPrintSentinel(b.alloc, "{s}/{d:0>6}.png", .{b.proc.output_dir, i}, 0);
        defer b.alloc.free(path);
        img.addText(b.text, nc);
        try img.writeToPng(b.alloc, path);
        _ = frames_rendered.fetchAdd(1, .monotonic);
        std.debug.print("\r    frames rendered: {d}", .{frames_rendered.raw});
    }
}

pub fn render(alloc: std.mem.Allocator, io: Io, proc: Proc) !void {
    const file = try Io.Dir.cwd().openFile(io, proc.font, .{.mode = .read_only});
    defer file.close(io);
    const size = (try file.stat(io)).size;

    const font_data = try alloc.alloc(u8, size);
    const content = try Io.Dir.readFile(Io.Dir.cwd(), io, proc.font, font_data);

    var text: Text = try .fromPath(alloc, io, proc.input);
    text.font = try .init(content, 30);

    Highlight.highlight(Highlight.Zig.hl(), &text);

    const total_frames = (text.raw.len / proc.cps) * proc.fps;
    const n_threads = @min(10, try std.Thread.getCpuCount());
    var threads = try alloc.alloc(std.Thread, n_threads);
    defer alloc.free(threads);

    var batches = try alloc.alloc(Batch, n_threads);
    defer alloc.free(batches);

    const batch_frames = total_frames / n_threads;

    std.debug.print("rendering {d} frames\n", .{total_frames});

    for(0..n_threads) |i| {
        const start = i * batch_frames;
        const end = if (i == n_threads - 1) total_frames
                    else start + batch_frames;

        batches[i] = Batch {
            .alloc = alloc,
            .proc = proc,
            .text = &text,
            .start = start,
            .end = end,
        };

        threads[i] = try std.Thread.spawn(.{}, renderBatch, .{&batches[i]});
    }

    for(threads) |t| t.join();
}