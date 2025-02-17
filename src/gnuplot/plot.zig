const std = @import("std");
const c = @import("c");
const ruby_wasm_runtime = @import("ruby_wasm_runtime");

export fn interrupt_setup() void {}
export fn gp_expand_tilde(_: i32) void {}
export fn restrict_popen() void {}

pub var command_line_env = std.mem.zeroes(c.JMP_BUF);
export fn bail_to_command_line() noreturn {
    if (c.fit_env) |fit_env| {
        c._rb_wasm_longjmp(fit_env, c.TRUE);
    } else {
        c._rb_wasm_longjmp(&command_line_env, c.TRUE);
    }
    unreachable;
}

pub export fn init_constants() void {
    _ = c.Gcomplex(&c.udv_pi.udv_value, std.math.pi, 0.0);

    c.udv_I = c.get_udv_by_name(@constCast("I"));
    _ = c.Gcomplex(&c.udv_I.*.udv_value, 0.0, 1.0);

    c.udv_NaN = c.get_udv_by_name(@constCast("NaN"));
    _ = c.Gcomplex(&c.udv_NaN.*.udv_value, c.not_a_number(), 0.0);
}

pub export fn init_session() void {
    c.del_udv_by_name(@constCast(""), true);

    while (c.first_perm_linestyle != null)
        c.delete_linestyle(&c.first_perm_linestyle, null, c.first_perm_linestyle);

    ruby_wasm_runtime.start(c.set_colorsequence, .{1});
    c.overflow_handling = c.INT64_OVERFLOW_TO_FLOAT;
    c.suppress_warnings = true;

    c.init_voxelsupport();

    c.reset_command();
}
