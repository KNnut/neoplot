const std = @import("std");
const cbor = @import("zbor");
const zgp = @import("zgp");
const typst = @import("typst.zig");
const gnuplot = @import("gnuplot.zig");
const raw_c_allocator = @import("alloc.zig").raw_c_allocator;
const Allocator = std.mem.Allocator;

const Fifo = std.fifo.LinearFifo(u8, .Dynamic);

comptime {
    @export(&pluginInit, .{ .name = "init" });
    @export(&pluginExec, .{ .name = "exec" });
}

fn pluginInit() callconv(.c) typst.ReturnType {
    zgp.init("svg");
    return .success;
}

fn pluginExec(length: usize) callconv(.c) typst.ReturnType {
    // Do nothing when length is 0
    if (length == 0) return .success;

    bridge(length) catch |err| {
        const err_msg = switch (err) {
            error.GnuplotError => zgp.getErrorMessage(),
            else => @errorName(err),
        };
        typst.send(err_msg);
        return .failure;
    };

    return .success;
}

fn bridge(length: usize) !void {
    var arena_state = std.heap.ArenaAllocator.init(raw_c_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const input = try getInputFromTypst(arena, length);
    // Do nothing when code is empty
    if (input.code.len == 0) return;

    const output = try gnuplot.call(arena, input);
    var fifo = Fifo.init(arena);
    try output.toCbor(fifo.writer());
    typst.send(fifo.readableSlice(0));
}

fn getInputFromTypst(allocator: Allocator, length: usize) !gnuplot.Input {
    const buf = try allocator.alloc(u8, length);
    defer allocator.free(buf);
    typst.receive(buf);

    const data_item = try cbor.DataItem.new(buf);
    const input = try cbor.parse(gnuplot.Input, data_item, .{ .allocator = allocator });
    return input;
}
