const std = @import("std");
// const stb = @import("stb");
const stb = @import("main.zig").stb;
const Text = @import("Text.zig");

pub const Color = @Vector(4, u8);
pub const RED   : Color = .{255, 0, 0, 255};
pub const GREEN : Color = .{0, 255, 0, 255};
pub const BLUE  : Color = .{0, 0, 255, 255};
pub const BLACK : Color = .{0, 0, 0, 255};
pub const WHITE : Color = .{255, 255, 255, 255};

width: u32,
height: u32,
pixels: []Color,

fn writePng(path: [*:0]const u8, width: u32, height: u32, pixels: []const u8) !void {
    const result = stb.stbi_write_png(
        path,
        @intCast(width),
        @intCast(height),
        4,
        pixels.ptr,
        @intCast(width * 4),
    );
    if (result == 0) return error.PngWriteFailed;
}

pub fn blank(alloc: std.mem.Allocator, width: u32, height: u32) Img {
    return .{
        .width = width,
        .height = height,
        .pixels = alloc.alloc(Color, width * height) catch unreachable,
    };
}

pub fn free(img: *Img, alloc: std.mem.Allocator) void {
    alloc.free(img.pixels);
}

pub fn clear(img: *Img, color: Color) void {
    @memset(img.pixels, color);
}

pub fn writeToPng(img: Img, alloc: std.mem.Allocator, path: [:0]const u8) !void {
    const pixels = try alloc.alloc(u8, img.width * img.height * 4);
    defer alloc.free(pixels);

    for(img.pixels, 0..) |c, i| {
        pixels[i*4  ] = c[0];
        pixels[i*4+1] = c[1];
        pixels[i*4+2] = c[2];
        pixels[i*4+3] = c[3];
    }

    try writePng(path, img.width, img.height, pixels);
}

pub fn addText(img: *Img, text: Text, n_chars: usize) void {
    var x: i32 = 0;
    var y: i32 = 0;
    for(0..n_chars) |i| {
        const c = text.raw[i];
        const color = text.colors[i];
        if (c == '\n') {
            y += text.font.ascent;
            x = 0;
            continue;
        }
        x += Text.writeChar(&text.font, img, @intCast(c), x, y, color)
            catch continue; // todo improve error handling here;
    }
}

const Img = @This();
