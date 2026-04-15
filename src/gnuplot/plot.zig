const std = @import("std");
const c = @import("c");
const ruby_wasm_runtime = @import("ruby_wasm_runtime");

comptime {
    @export(&bailToCommandLine, .{ .name = "bail_to_command_line", .visibility = .hidden });
    @export(&restrictPopen, .{ .name = "restrict_popen", .visibility = .hidden });
    @export(&initConstants, .{ .name = "init_constants", .visibility = .hidden });
    @export(&initSession, .{ .name = "init_session", .visibility = .hidden });
}

pub var command_line_env = std.mem.zeroes(c.JMP_BUF);
fn bailToCommandLine() callconv(.c) noreturn {
    if (c.fit_env) |fit_env|
        c._rb_wasm_longjmp(fit_env, c.TRUE)
    else
        c._rb_wasm_longjmp(&command_line_env, c.TRUE);
    unreachable;
}

fn restrictPopen() callconv(.c) void {
    c.int_error(c.c_token - 1, "This copy of gnuplot does not support popen");
}

fn initUdv(name: [:0]const u8, re: c.double_t, im: c.double_t) void {
    const udv = c.get_udv_by_name(@constCast(name));
    _ = c.Gcomplex(&udv.*.udv_value, re, im);
    udv.*.locality = -1;
}

pub fn initConstants() callconv(.c) void {
    const names = .{ "pi", "I", "Inf", "NaN" };
    const res = .{ c.M_PI, 0.0, c.INFINITY, c.not_a_number() };
    const ims = .{ 0.0, 1.0, 0.0, 0.0 };

    inline for (names) |name|
        c.del_udv_by_name(@constCast(name), false);
    inline for (names) |name|
        _ = c.add_udv_by_name(@constCast(name));
    inline for (names, res, ims) |name, re, im|
        initUdv(name, re, im);
}

pub fn initSession() callconv(.c) void {
    c.del_udv_by_name(@constCast(""), true);

    while (c.first_perm_linestyle != null)
        c.delete_linestyle(&c.first_perm_linestyle, null, c.first_perm_linestyle);

    ruby_wasm_runtime.start(c.set_colorsequence, .{1});
    c.overflow_handling = c.INT64_OVERFLOW_TO_FLOAT;
    c.suppress_warnings = true;

    c.init_voxelsupport();

    c.reset_command();
}
