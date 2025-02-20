const std = @import("std");
const build_options = @import("build_options");

extern "typst_env" fn wasm_minimal_protocol_send_result_to_host(ptr: [*]const u8, len: usize) void;
extern "typst_env" fn wasm_minimal_protocol_write_args_to_buffer(ptr: [*]u8) void;

pub const ReturnType = enum(i32) {
    success,
    failure,
};

pub fn send(bytes: []const u8) void {
    const log = std.log.scoped(.typst_sender);
    log.debug("bytes={s}", .{bytes});

    if (build_options.has_typst_env)
        wasm_minimal_protocol_send_result_to_host(bytes.ptr, bytes.len);
}

pub fn receive(buf: []u8) void {
    if (build_options.has_typst_env)
        wasm_minimal_protocol_write_args_to_buffer(buf.ptr);
}
