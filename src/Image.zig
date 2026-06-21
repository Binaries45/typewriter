const std = @import("std");
const ImageWrite = @import("zstb").ImageWrite;
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

pub const Symbol = struct {
    width: usize,
    height: usize,
    x_off: i32,
    y_off: i32,
    advance: i32,
    pixels: []u8,
};

fn writePng(path: [*:0]const u8, width: u32, height: u32, pixels: []const u8) !void {
    const result = ImageWrite.stbi_write_png(
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

fn textHeight(text: *const Text, n_chars: usize) i32 {
    var lines: i32 = 1;

    for(0..n_chars) |i| {
        if (text.raw[i] == '\n') lines += 1;
    }

    return (lines + 1) * text.font.ascent;
}

fn addSymbol(img: *Img, s: Symbol, x: i32, y: i32, color: Color) void {
    const dx = x + s.x_off;
    const dy = y + s.y_off;
    for (0..s.height) |cy| for (0..s.width) |cx| {
        // const i = (@as(u32, @intCast(by)) * @as(u32, @intCast(sy))) * img.width + (@as(u32, @intCast(bx)) * @as(u32, @intCast(sx)));
        const fx = dx + @as(i32, @intCast(cx));
        const fy = dy + @as(i32, @intCast(cy));
        if (fx < 0 or fy < 0) continue;
        if (fx >= img.width or fy >= img.height) continue;

        const alpha = s.pixels[cy * s.width + cx];
        if(alpha == 0) continue;

        const i = @as(usize, @intCast(fy)) * img.width + @as(usize, @intCast(fx));
        if (i >= img.pixels.len) continue;

        const a = @as(f32, @floatFromInt(alpha)) / 255;
        const r: u8 = @trunc(@as(f32, @floatFromInt(color[0])) * a + @as(f32, @floatFromInt(img.pixels[i][0])) * (1 - a));
        const g: u8 = @trunc(@as(f32, @floatFromInt(color[1])) * a + @as(f32, @floatFromInt(img.pixels[i][1])) * (1 - a));
        const b: u8 = @trunc(@as(f32, @floatFromInt(color[2])) * a + @as(f32, @floatFromInt(img.pixels[i][2])) * (1 - a));

        img.pixels[i] = .{r, g, b, 255};
    };
}

pub fn addText(img: *Img, text: *Text, n_chars: usize, cache: [256]?Symbol) void {
    const text_height = textHeight(text, n_chars);
    const scroll = @as(i32, @max(0, text_height - @as(i32, @intCast(img.height))));
    var x: i32 = 0;
    var y: i32 = text.font.ascent - scroll;
    for(0..n_chars) |i| {
        const c = text.raw[i];
        const color = text.colors[i];
        if (c == '\n') {
            y += text.font.ascent;
            x = 0;
            continue;
        }
        if (c <= 31) continue;

        const s = cache[c].?; // is expected to be non-null by now
        img.addSymbol(s, x, y, color);
        x += s.advance;
    }
}

const Img = @This();
