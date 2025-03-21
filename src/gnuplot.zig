const std = @import("std");
const zgp = @import("zgp");
const gp_c = @import("gp_c");
const ruby_wasm_runtime = @import("ruby_wasm_runtime");
const Output = @import("Output.zig");
const Allocator = std.mem.Allocator;

const Fifo = std.fifo.LinearFifo(u8, .Dynamic);

const log = std.log.scoped(.gnuplot);

pub const CallType = enum {
    script,
    command,
};

pub const Input = struct {
    code: [:0]const u8,
    type: CallType,
};

fn innerCall(input: Input) !void {
    try zgp.setJmp();
    switch (input.type) {
        .script => {
            const fp = gp_c.fmemopen(@constCast(input.code.ptr), input.code.len, "r");
            gp_c.load_file(fp, null, 1);
        },
        .command => gp_c.do_string(input.code.ptr),
    }
}

pub fn call(arena: Allocator, input: Input) !Output {
    // Redirect the output of graphics devices
    var terminal_fifo = Fifo.init(arena);
    gp_c.gpoutfile = gp_c.fopencookie(&terminal_fifo, "w", .{ .write = zgp.fifoCookieFn(Fifo).write });
    // Redirect the output of the `print` command
    var print_fifo = Fifo.init(arena);
    gp_c.print_out = gp_c.fopencookie(&print_fifo, "w", .{ .write = zgp.fifoCookieFn(Fifo).write });

    log.debug("input.type={s}", .{@tagName(input.type)});

    // Use Asyncify-based setjmp
    try ruby_wasm_runtime.start(innerCall, .{input});

    return .{
        .terminal = if (terminal_fifo.readableLength() > 0) terminal_fifo.readableSlice(0) else null,
        .print = if (print_fifo.readableLength() > 0) print_fifo.readableSlice(0) else null,
    };
}
