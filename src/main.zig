const std = @import("std");
const build_options = @import("build_options");
const cbor = @import("zbor");
const zgp = @import("zgp");
const typst = @import("typst.zig");
const ruby_wasm_runtime = @import("ruby_wasm_runtime");
const Gnuplot = @import("Gnuplot.zig");

const mem = std.mem;
const Allocator = mem.Allocator;

const raw_c_allocator = @import("alloc.zig").raw_c_allocator;
const Fifo = std.fifo.LinearFifo(u8, .Dynamic);

const Input = struct {
    code: [:0]const u8,
    type: Gnuplot.CallType,
};

fn bridge(length: usize) !void {
    const log = std.log.scoped(.bridge);

    var arena_state = std.heap.ArenaAllocator.init(raw_c_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const arg = blk: {
        const buf = try raw_c_allocator.alloc(u8, length);
        defer raw_c_allocator.free(buf);
        typst.receive(buf);

        const data_item = try cbor.DataItem.new(buf);
        break :blk try cbor.parse(Input, data_item, .{ .allocator = arena });
    };
    log.debug("code length={d}", .{arg.code.len});

    // Do nothing when code is empty
    if (arg.code.len == 0) return;

    var gnuplot = Gnuplot.init(arena);
    try gnuplot.call(arg.code, arg.type);
    const gnuplot_output = gnuplot.getOutput();
    const output = try gnuplot_output.process();

    const cbor_output = try output.toCbor(arena);
    typst.send(cbor_output);
}

export fn init() typst.ReturnType {
    zgp.init("svg");
    return .success;
}

export fn exec(length: usize) typst.ReturnType {
    const log = std.log.scoped(.exec);

    // Do nothing when length is 0
    if (length == 0) return .success;

    bridge(length) catch |err| {
        var buf: [32]u8 = undefined;
        const err_msg = switch (err) {
            error.GnuplotError => zgp.getErrorMessage(),
            else => std.fmt.bufPrint(&buf, "{}", .{err}) catch "Error message is too long",
        };
        log.debug("error message={s}", .{err_msg});
        typst.send(err_msg);
        return .failure;
    };

    return .success;
}
