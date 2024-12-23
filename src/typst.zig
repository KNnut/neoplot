extern "typst_env" fn wasm_minimal_protocol_send_result_to_host(ptr: [*]const u8, len: usize) void;
extern "typst_env" fn wasm_minimal_protocol_write_args_to_buffer(ptr: [*]u8) void;

pub const ReturnType = enum(i32) {
    success,
    failure,
};

pub fn send(bytes: []const u8) void {
    wasm_minimal_protocol_send_result_to_host(bytes.ptr, bytes.len);
}

pub fn receive(buf: []u8) void {
    wasm_minimal_protocol_write_args_to_buffer(buf.ptr);
}
