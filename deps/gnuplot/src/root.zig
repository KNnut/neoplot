const std = @import("std");
const builtin = @import("builtin");
const c = @import("c");

pub fn fifoCookieFn(comptime FifoType: type) c.cookie_io_functions_t {
    const cookieFn = struct {
        fn readFn(cookie: ?*anyopaque, buf: [*c]u8, size: usize) callconv(.C) isize {
            const fifo: *FifoType = @ptrCast(@alignCast(cookie orelse return 0));
            const read_size = fifo.read(buf[0..size]);
            return @intCast(read_size);
        }

        fn writeFn(cookie: ?*anyopaque, buf: [*c]const u8, size: usize) callconv(.C) isize {
            if (size == 0) return 0;
            const fifo: *FifoType = @ptrCast(@alignCast(cookie orelse return 0));

            const slice = buf[0..size];
            fifo.write(slice) catch return 0;
            return @intCast(size);
        }

        // fn seekFn(cookie: ?*anyopaque, offset: [*c]c.off_t, whence: c_int) callconv(.C) c_int {
        //     const fifo: *FifoType = @ptrCast(@alignCast(cookie orelse return 0));
        //     _ = fifo;
        //     std.log.debug("Seek, offset: {}, whence: {d}", .{ offset.*, whence });
        //     return 0;
        // }

        fn closeFn(cookie: ?*anyopaque) callconv(.C) c_int {
            const fifo: *FifoType = @ptrCast(@alignCast(cookie orelse return 0));
            fifo.deinit();
            return 0;
        }
    };

    return .{
        .read = cookieFn.readFn,
        .write = cookieFn.writeFn,
        // .seek = cookieFn.seekFn,
        .close = cookieFn.closeFn,
    };
}

export const user_shell = "";
export const interactive = false;
export const noinputfiles = false;
export const ctrlc_flag = false;

export fn interrupt_setup() void {}
export fn restrict_popen() void {}
export fn gp_expand_tilde(_: i32) void {}

var command_line_env = std.mem.zeroes(c.JMP_BUF);
export fn bail_to_command_line() void {
    if (builtin.target.isWasm()) {
        if (c.fit_env) |fit_env| {
            c._rb_wasm_longjmp(fit_env, c.TRUE);
        } else {
            c._rb_wasm_longjmp(&command_line_env, c.TRUE);
        }
    }
}

export fn init_constants() void {
    _ = c.Gcomplex(&c.udv_pi.udv_value, std.math.pi, 0.0);

    c.udv_I = c.get_udv_by_name(@constCast("I"));
    _ = c.Gcomplex(&c.udv_I.*.udv_value, 0.0, 1.0);

    c.udv_NaN = c.get_udv_by_name(@constCast("NaN"));
    _ = c.Gcomplex(&c.udv_NaN.*.udv_value, c.not_a_number(), 0.0);
}

export fn init_session() void {
    c.del_udv_by_name(@constCast(""), true);

    while (c.first_perm_linestyle != null)
        c.delete_linestyle(&c.first_perm_linestyle, null, c.first_perm_linestyle);

    c.set_colorsequence(1);
    c.overflow_handling = c.INT64_OVERFLOW_TO_FLOAT;
    c.suppress_warnings = false;

    c.init_voxelsupport();

    c.reset_command();
}

fn init_memory() void {
    c.extend_input_line();
    c.extend_token_table();
    c.replot_line = c.gp_strdup("");
}

fn init_term(term: [:0]const u8) void {
    const set_term = "set term ";
    const term_copied = c.gp_strdup(term);
    c.do_string(c.strcat(@constCast(set_term), term_copied));

    const udv_term = c.get_udv_by_name(@constCast("GNUTERM"));
    _ = c.Gstring(&udv_term.*.udv_value, term_copied);

    c.term_on_entry = false;
}

var inited = false;
pub fn init(term: [:0]const u8) void {
    if (inited) return;
    inited = true;

    _ = c.add_udv_by_name(@constCast("GNUTERM"));
    _ = c.add_udv_by_name(@constCast("I"));
    _ = c.add_udv_by_name(@constCast("NaN"));
    init_constants();
    c.udv_user_head = &c.udv_NaN.*.next_udv;

    init_memory();

    c.sm_palette = std.mem.zeroes(c.t_sm_palette);

    c.init_fit();
    c.init_gadgets();

    init_term(term);
    c.push_terminal(0);

    c.update_gpval_variables(3);
    init_session();

    if (builtin.target.isWasm()) {
        if (c._rb_wasm_setjmp(@ptrCast(&command_line_env)) != 0) {
            c.clause_reset_after_error();
            c.lf_reset_after_error();
            c.inside_plot_command = false;
        }
    }
}
