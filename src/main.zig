const std = @import("std");
const gp = @import("gnuplot");

const allocator = std.heap.c_allocator;
const Fifo = std.fifo.LinearFifo(u8, .Dynamic);

extern "typst_env" fn wasm_minimal_protocol_send_result_to_host(ptr: [*]const u8, len: usize) void;
extern "typst_env" fn wasm_minimal_protocol_write_args_to_buffer(ptr: [*]u8) void;

export fn signal(_: i32, _: i32) i32 {
    return 0;
}

export fn system(_: i32) i32 {
    return 0;
}

// The `test_palette_subcommand` function requires `tmpfile`
var tmp_fifo: Fifo = undefined;
export fn tmpfile() ?*gp.c.FILE {
    tmp_fifo = Fifo.init(allocator);
    return gp.c.fopencookie(&tmp_fifo, "w+", gp.fifoCookieFn(Fifo));
}

const CallType = enum(u8) {
    exec,
    eval,
};

const Status = enum {
    idle,
    busy,
};

var status: Status = .idle;
fn call(code_len: usize, @"type": CallType) i32 {
    const log = std.log.scoped(.call);
    log.debug("code length={}", .{code_len});

    // Do nothing when code_len is 0
    if (code_len == 0) return 0;
    defer status = .idle;

    // Always inline `init` function to avoid stack smashing
    @call(.always_inline, gp.init, .{"svg"});
    log.debug("status={}", .{status});
    // `init` function has a jump
    // `busy` is `true` means an error
    if (status == .busy) {
        const err_msg = gp.c.get_udv_by_name(@constCast("GPVAL_ERRMSG")).*.udv_value.v.string_val;
        log.debug("error message={s}", .{err_msg});
        wasm_minimal_protocol_send_result_to_host(err_msg, gp.c.strlen(err_msg));
        return 1;
    }
    status = .busy;

    // Redirect the output of graphics devices
    var term_output_fifo = Fifo.init(allocator);
    gp.c.gpoutfile = gp.c.fopencookie(&term_output_fifo, "w", .{ .write = gp.fifoCookieFn(Fifo).write });

    // Redirect the output of the `print` command
    var print_output_fifo = Fifo.init(allocator);
    gp.c.print_out = gp.c.fopencookie(&print_output_fifo, "w", .{ .write = gp.fifoCookieFn(Fifo).write });

    const code = switch (@"type") {
        .exec => allocator.alloc(u8, code_len),
        .eval => allocator.allocSentinel(u8, code_len, 0),
    } catch return 1;
    defer allocator.free(code);
    wasm_minimal_protocol_write_args_to_buffer(code.ptr);

    switch (@"type") {
        .exec => {
            const fp = gp.c.fmemopen(code.ptr, code_len, "r");
            gp.c.load_file(fp, null, 1);
        },
        .eval => gp.c.do_string(code.ptr),
    }

    const term_output = term_output_fifo.toOwnedSlice() catch return 1;
    defer allocator.free(term_output);
    if (term_output.len > 0) {
        wasm_minimal_protocol_send_result_to_host(term_output.ptr, term_output.len);
        print_output_fifo.deinit();
    } else {
        const print_output = print_output_fifo.toOwnedSlice() catch return 1;
        defer allocator.free(print_output);
        if (print_output.len > 0)
            wasm_minimal_protocol_send_result_to_host(print_output.ptr, print_output.len);
    }
    return 0;
}

// Use Asyncify-based setjmp
extern fn rb_wasm_rt_start(*const anyopaque, usize, CallType) i32;
export fn main(code_len: usize, @"type": CallType) i32 {
    return rb_wasm_rt_start(call, code_len, @"type");
}

export fn exec(code_len: usize) i32 {
    return main(code_len, .exec);
}

export fn eval(code_len: usize) i32 {
    return main(code_len, .eval);
}
