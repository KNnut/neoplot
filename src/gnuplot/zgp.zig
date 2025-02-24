const std = @import("std");
const c = @import("c");
const plot = @import("plot.zig");

pub fn fifoCookieFn(comptime FifoType: type) c.cookie_io_functions_t {
    const cookieFn = struct {
        fn readFn(cookie: ?*anyopaque, buf: [*c]u8, size: usize) callconv(.c) isize {
            const fifo: *FifoType = @ptrCast(@alignCast(cookie orelse return 0));
            const read_size = fifo.read(buf[0..size]);
            return @intCast(read_size);
        }

        fn writeFn(cookie: ?*anyopaque, buf: [*c]const u8, size: usize) callconv(.c) isize {
            if (size == 0) return 0;
            const fifo: *FifoType = @ptrCast(@alignCast(cookie orelse return 0));

            const slice = buf[0..size];
            fifo.write(slice) catch return 0;
            return @intCast(size);
        }

        // fn seekFn(cookie: ?*anyopaque, offset: [*c]c.off_t, whence: c_int) callconv(.c) c_int {
        //     const fifo: *FifoType = @ptrCast(@alignCast(cookie orelse return 0));
        //     _ = fifo;
        //     std.log.debug("Seek, offset: {}, whence: {d}", .{ offset.*, whence });
        //     return 0;
        // }

        fn closeFn(cookie: ?*anyopaque) callconv(.c) c_int {
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

fn init_memory() void {
    c.extend_input_line();
    c.extend_token_table();
    c.replot_line = c.gp_strdup("");
}

fn init_term(term: [:0]const u8) void {
    const udv_term = c.get_udv_by_name(@constCast("GNUTERM"));
    _ = c.Gstring(&udv_term.*.udv_value, c.gp_strdup(term));

    if (c.change_term(term, @intCast(term.len)) == null)
        _ = c.change_term("unknown", 7);

    c.term_on_entry = false;
}

pub fn init(term: [:0]const u8) void {
    _ = c.add_udv_by_name(@constCast("GNUTERM"));
    _ = c.add_udv_by_name(@constCast("I"));
    _ = c.add_udv_by_name(@constCast("NaN"));
    plot.init_constants();
    c.udv_user_head = &c.udv_NaN.*.next_udv;

    init_memory();

    c.sm_palette = std.mem.zeroes(c.t_sm_palette);

    c.init_fit();
    // Make fit verbosity level quiet by default
    c.fit_verbosity = c.QUIET;
    // Suppress fit log by default
    c.fit_suppress_log = true;
    // Disable floating point exception
    // c.df_nofpe_trap = true;

    c.init_gadgets();

    init_term(term);
    c.push_terminal(0);

    c.update_gpval_variables(3);
    plot.init_session();
}

// Only set once
var set = false;
pub fn setJmp() !void {
    if (set) return;
    set = true;

    if (c._rb_wasm_setjmp(@ptrCast(&plot.command_line_env)) != 0) {
        c.clause_reset_after_error();
        c.lf_reset_after_error();
        c.inside_plot_command = false;
        return error.GnuplotError;
    }
}

pub fn getErrorMessage() []const u8 {
    const gp_errmsg = c.get_udv_by_name(@constCast("GPVAL_ERRMSG")).*.udv_value.v.string_val;
    return std.mem.sliceTo(gp_errmsg, 0);
}
