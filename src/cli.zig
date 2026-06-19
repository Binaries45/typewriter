const std = @import("std");
const Image = @import("Image.zig");
const Color = Image.Color;

const Error = enum {
    InvalidOption,
    ExpectedInt,
    ExpectedValue,
};

const ErrCtx = union(Error) {
    InvalidOption: []const u8,
    ExpectedInt: []const u8,
    ExpectedValue,
};

const Opt = enum {
    none,
    fps,
    cps,
    w,
    h,
    bg,
    font,
};

pub const Proc = struct {
    /// the input file
    input: [:0]const u8,
    /// where to render all output frames
    output_dir: [:0]const u8,
    /// frames per second
    fps: u32 = 30,
    /// characters per second
    cps: u32 = 16,
    /// frame width
    width: u32 = 1920,
    /// frame height
    height: u32 = 1080,
    /// path to a font file
    font: []const u8 = "assets/VictorMono.ttf",
    /// the background color of the animation
    bg: Color = Image.BLACK,
};

pub fn parseArgs(alloc: std.mem.Allocator, args: *std.process.Args.Iterator) Proc {
    _ = args.next(); // skip call location
    var proc: Proc = .{
        .input = args.next() orelse
            reportError(ErrCtx.ExpectedValue, alloc),
        .output_dir = args.next() orelse
            reportError(ErrCtx.ExpectedValue, alloc),
    };
    
    state: switch (nextOpt(args, alloc)) {
        .fps => {
            const val = args.next() orelse
                reportError(ErrCtx.ExpectedValue, alloc);
            const int = std.fmt.parseInt(u32, val, 10) catch
                reportError(.{ .ExpectedInt = val }, alloc);
            proc.fps = int;
            continue :state nextOpt(args, alloc);
        },
        .cps => {
            const val = args.next() orelse
                reportError(ErrCtx.ExpectedValue, alloc);
            const int = std.fmt.parseInt(u32, val, 10) catch
                reportError(.{ .ExpectedInt = val }, alloc);
            proc.cps = int;
            continue :state nextOpt(args, alloc);
        },
        .w => {
            const val = args.next() orelse
                reportError(ErrCtx.ExpectedValue, alloc);
            const int = std.fmt.parseInt(u32, val, 10) catch
                reportError(.{ .ExpectedInt = val }, alloc);
            proc.width = int;
            continue :state nextOpt(args, alloc);
        },
        .h => {
            const val = args.next() orelse
                reportError(ErrCtx.ExpectedValue, alloc);
            const int = std.fmt.parseInt(u32, val, 10) catch
                reportError(.{ .ExpectedInt = val }, alloc);
            proc.height = int;
            continue :state nextOpt(args, alloc);
        },
        .font => {
            const val = args.next() orelse reportError(.ExpectedValue, alloc);
            proc.font = val;
            continue :state nextOpt(args, alloc);
        },
        .bg => {
            const r_val = args.next() orelse
                reportError(ErrCtx.ExpectedValue, alloc);
            const r = std.fmt.parseInt(u8, r_val, 10) catch
                reportError(.{ .ExpectedInt = r_val }, alloc);

            const g_val = args.next() orelse
                reportError(ErrCtx.ExpectedValue, alloc);
            const g = std.fmt.parseInt(u8, g_val, 10) catch
                reportError(.{ .ExpectedInt = g_val }, alloc);

            const b_val = args.next() orelse
                reportError(ErrCtx.ExpectedValue, alloc);
            const b = std.fmt.parseInt(u8, b_val, 10) catch
                reportError(.{ .ExpectedInt = b_val }, alloc);

            proc.bg = Color {r, g, b, 255};
            continue :state nextOpt(args, alloc);
        },
        .none => break :state,
    }
    
    return proc;
}

fn nextOpt(args: *std.process.Args.Iterator, alloc: std.mem.Allocator) Opt {
    const next = args.next() orelse return .none;
    return std.meta.stringToEnum(Opt, next[1..]) orelse
        reportError(.{ .InvalidOption = next }, alloc);
}

fn reportError(ctx: ErrCtx, alloc: std.mem.Allocator) noreturn {
    const msg = fmtCtx(alloc, ctx);
    std.log.err("{s}", .{msg});
    std.process.exit(1);
}

fn fmtCtx(alloc: std.mem.Allocator, ctx: ErrCtx) []const u8 {
     return switch (ctx) {
         .ExpectedInt => |e| std.fmt.allocPrint(alloc, "Expected Integer, found '{s}'", .{e}),
         .ExpectedValue => std.fmt.allocPrint(alloc, "Expected value, got nothing", .{}),
         .InvalidOption => |i| std.fmt.allocPrint(alloc, "Invalid option '{s}'", .{i}),
     } catch unreachable;
}