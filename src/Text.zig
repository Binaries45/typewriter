const std = @import("std");
const TrueType = @import("zstb").TrueType;
const Image = @import("Image.zig");
const Color = Image.Color;

const Text = @This();

raw: [:0]const u8,
/// the color mapping for each char, this array is parallel to raw,
/// color[i] is the color of the character raw[i]
colors: []const Color,
font: Font,

const Error = error {
    FontInitFailed,
};

pub const Font = struct {
    info: TrueType.stbtt_fontinfo,
    scale: f32,
    ascent: i32,
    descent: i32,
    gap: i32,
    width: i32,
    height: i32,

    pub fn init(bytes: []const u8, height: f32) !Font {
        var info: TrueType.stbtt_fontinfo = undefined;
        if (TrueType.stbtt_InitFont(&info, bytes.ptr, 0) == 0) {
            return error.FontInitFailed;
        }

        const scale = TrueType.stbtt_ScaleForPixelHeight(&info, height);
        var ascent: c_int = 0;
        var descent: c_int = 0;
        var line_gap: c_int = 0;
        TrueType.stbtt_GetFontVMetrics(&info, &ascent, &descent, &line_gap);

        var adv: c_int = 0;
        var lsb: c_int = 0;
        TrueType.stbtt_GetCodepointHMetrics(&info, 'M', &adv, &lsb);

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

pub fn fromPath(alloc: std.mem.Allocator, io: std.Io, path: []const u8) !Text {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{.mode = .read_only});
    defer file.close(io);

    const content = try std.Io.Dir.readFileAllocOptions(
        std.Io.Dir.cwd(),
        io, path, alloc,
        .unlimited, .@"1", 0
    );

    const colors = try alloc.alloc(Color, content.len);
    @memset(colors, Image.WHITE);

    return .{
        .raw = content,
        .colors = colors,
        // must be set later by the caller
        .font = undefined,
    };
}

/// set a range of the color map to the given color
pub fn setColors(self: *Text, start: usize, end: usize, color: Color) void {
    @memset(@constCast(self.colors[start..end]), color);
}

pub fn TextToSymbol(alloc: std.mem.Allocator, text: *Text, c: u32) Image.Symbol {
    var x0: i32 = undefined;
    var x1: i32 = undefined;
    var y0: i32 = undefined;
    var y1: i32 = undefined;

    TrueType.stbtt_GetCodepointBitmapBox(
        &text.font.info, @intCast(c), text.font.scale, text.font.scale,
        &x0, &y0, &x1, &y1
    );

    const w = @as(usize, @intCast(x1 - x0));
    const h = @as(usize, @intCast(y1 - y0));

    const bmp = alloc.alloc(u8, w * h) catch unreachable;
    _ = TrueType.stbtt_MakeCodepointBitmap(
        &text.font.info, bmp.ptr,
        @intCast(w), @intCast(h), @intCast(w),
        text.font.scale, text.font.scale, @intCast(c)
    );

    var advance: c_int = 0;
    var lsb: c_int = 0;
    TrueType.stbtt_GetCodepointHMetrics(&text.font.info, @intCast(c), &advance, &lsb);

    return .{
        .width = w,
        .height = h,
        .pixels = bmp,
        .x_off = x0,
        .y_off = y0,
        .advance = @intFromFloat( @as(f32, @floatFromInt(advance)) * text.font.scale),
    };
}