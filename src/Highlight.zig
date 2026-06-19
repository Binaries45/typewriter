//! A highlighting interface for code, meant to take in raw text and produce a color map for the animation

const HL = @This();

const std = @import("std");
const Image = @import("Image.zig");
const Color = Image.Color;
const Text = @import("Text.zig");

// not needed for now, but if we add custom color palettes it will be useful
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    /// given a pointer to some text, set the color map of the text
    highlight: *const fn (text: *Text) void,
};

// todo: zig syntax highlighting impl
pub const Zig = struct {
    fn tokenColor(tag: std.zig.Token.Tag) Color {
        return switch (tag) {
            .keyword_const => Image.RED,
            else => Image.WHITE,
        };
    }

    fn highlightFn(text: *Text) void {
        var Tokenizer = std.zig.Tokenizer.init(text.raw);

        while(true) {
            const tok = Tokenizer.next();
            if(tok.tag == .eof) break;
            text.setColors(tok.loc.start, tok.loc.end, tokenColor(tok.tag));
        }
    }

    pub fn hl() HL {
        return .{
            .ptr = undefined,
            .vtable = comptime &HL.VTable { .highlight = Zig.highlightFn }
        };
    }
};

pub fn highlight(h: HL, text: *Text) void {
    h.vtable.highlight(text);
}