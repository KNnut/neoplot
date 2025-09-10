const std = @import("std");
const zgp = @import("zgp");
const gp_c = @import("gp_c");
const ruby_wasm_runtime = @import("ruby_wasm_runtime");
const Output = @import("Output.zig");
const Allocator = std.mem.Allocator;

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
    var terminal_buf: std.Io.Writer.Allocating = .init(arena);
    gp_c.gpoutfile = gp_c.fopencookie(&terminal_buf.writer, "w", zgp.ioCookieFn(std.Io.Writer));
    // Redirect the output of the `print` command
    var print_buf: std.Io.Writer.Allocating = .init(arena);
    gp_c.print_out = gp_c.fopencookie(&print_buf.writer, "w", zgp.ioCookieFn(std.Io.Writer));

    log.debug("input.type={s}", .{@tagName(input.type)});

    // Use Asyncify-based setjmp
    try ruby_wasm_runtime.start(innerCall, .{input});

    var output: Output = .{
        .terminal = null,
        .print = null,
    };

    const output_terminal = terminal_buf.written();
    if (output_terminal.len > 0)
        output.terminal = output_terminal;

    const output_print = print_buf.written();
    if (output_print.len > 0)
        output.print = output_print;

    return output;
}
