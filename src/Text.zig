const std = @import("std");
// const stb = @import("stb");
const stb = @import("main.zig").stb;
const Image = @import("Image.zig");
const Color = Image.Color;

const Text = @This();

raw: []const u8,
font: Font,

const Error = error {
    FontInitFailed,
};

pub const Font = struct {
    info: stb.stbtt_fontinfo,
    scale: f32,
    ascent: i32,
    descent: i32,
    gap: i32,
    width: i32,
    height: i32,

    pub fn init(bytes: []const u8, height: f32) !Font {
        var info: stb.stbtt_fontinfo = undefined;
        if (stb.stbtt_InitFont(&info, bytes.ptr, 0) == 0) {
            return error.FontInitFailed;
        }

        const scale = stb.stbtt_ScaleForPixelHeight(&info, height);
        var ascent: c_int = 0;
        var descent: c_int = 0;
        var line_gap: c_int = 0;
        stb.stbtt_GetFontVMetrics(&info, &ascent, &descent, &line_gap);

        var adv: c_int = 0;
        var lsb: c_int = 0;
        stb.stbtt_GetCodepointHMetrics(&info, 'M', &adv, &lsb);

        return .{
            .info = info,
            .scale = scale,
            .ascent = @intFromFloat(@as(f32, @floatFromInt(ascent)) * scale),
            .descent = @intFromFloat(@as(f32, @floatFromInt(descent)) * scale),
            .gap = @intFromFloat(@as(f32, @floatFromInt(line_gap)) * scale),
            .width = @intFromFloat(@as(f32, @floatFromInt(adv)) * scale),
            .height     = @intFromFloat(height),
        };
    }
};

/// write a char to the given image
pub fn writeChar(
    font: *const Font,
    img: *Image,
    codepoint: u32,
    x: i32,
    y: i32,
    color: Color,
) !i32 {
    var width: c_int = 0;
    var height: c_int = 0;
    var x_off: c_int = 0;
    var y_off: c_int = 0;

    var advance: c_int = 0;
    var lsb: c_int = 0;
    stb.stbtt_GetCodepointHMetrics(&font.info, @intCast(codepoint), &advance, &lsb);
    const advance_px: i32 = @intFromFloat(@as(f32, @floatFromInt(advance)) * font.scale);

    const bitmap = stb.stbtt_GetCodepointBitmap(
        &font.info, 0, font.scale, @intCast(codepoint),
        &width, &height, &x_off, &y_off
    );
    defer stb.stbtt_FreeBitmap(bitmap, null);

    const dy = y + font.ascent + y_off;
    const dx = x + x_off;

    for(0..@intCast(height)) |cy| for(0..@intCast(width)) |cx| {
        const fx = dx + @as(i32, @intCast(cx));
        const fy = dy + @as(i32, @intCast(cy));
        if (fx < 0 or fy < 0) continue;
        if (@as(u32, @intCast(fx)) >= img.width) continue;

        const alpha = bitmap[@as(usize, @intCast(width)) * cy + cx];
        if (alpha == 0) continue;

        const i = (@as(u32, @intCast(fy)) * img.width + @as(u32, @intCast(fx)));
        if (i >= img.pixels.len) continue;

        const a = @as(f32, @floatFromInt(alpha)) / 255;
        const r: u8 = @intFromFloat(@as(f32, @floatFromInt(color[0])) * a + @as(f32, @floatFromInt(img.pixels[i][0])) * (1 - a));
        const g: u8 = @intFromFloat(@as(f32, @floatFromInt(color[1])) * a + @as(f32, @floatFromInt(img.pixels[i][1])) * (1 - a));
        const b: u8 = @intFromFloat(@as(f32, @floatFromInt(color[2])) * a + @as(f32, @floatFromInt(img.pixels[i][2])) * (1 - a));

        img.pixels[i] = .{ r, g, b, 255};
    };

    return advance_px;
}