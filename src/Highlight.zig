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

pub fn highlight(h: HL, text: *Text) void {
    h.vtable.highlight(text);
}

pub const Zig = struct {
    fn tokenColor(tag: std.zig.Token.Tag) Color {
        return switch (tag) {
            .identifier => Image.WHITE,
            .builtin => Color {0, 187, 212, 255},
            .multiline_string_literal_line,
            .string_literal,
            .char_literal => Color {204, 184, 6, 255},
            .number_literal => Color {22, 87, 224, 255},
            .doc_comment,
            .container_doc_comment => Color {90, 90, 90, 255},

            .keyword_addrspace,
            .keyword_align,
            .keyword_allowzero,
            .keyword_and,
            .keyword_anyframe,
            .keyword_anytype,
            .keyword_asm,
            .keyword_break,
            .keyword_callconv,
            .keyword_catch,
            .keyword_comptime,
            .keyword_const,
            .keyword_continue,
            .keyword_defer,
            .keyword_else,
            .keyword_enum,
            .keyword_errdefer,
            .keyword_error,
            .keyword_export,
            .keyword_extern,
            .keyword_fn,
            .keyword_for,
            .keyword_if,
            .keyword_inline,
            .keyword_noalias,
            .keyword_noinline,
            .keyword_nosuspend,
            .keyword_opaque,
            .keyword_or,
            .keyword_orelse,
            .keyword_packed,
            .keyword_pub,
            .keyword_resume,
            .keyword_return,
            .keyword_linksection,
            .keyword_struct,
            .keyword_suspend,
            .keyword_switch,
            .keyword_test,
            .keyword_threadlocal,
            .keyword_try,
            .keyword_union,
            .keyword_unreachable,
            .keyword_var,
            .keyword_volatile,
            .keyword_while => Image.RED,
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