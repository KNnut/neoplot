const asyncify_start_rewind = @extern(*const fn (buf: ?*anyopaque) callconv(.c) void, .{ .name = "start_rewind", .library_name = "asyncify" });

extern "asyncify" fn stop_unwind() void;
fn asyncify_stop_unwind() void {
    var rb_asyncify_unwind_buf = @extern(?*anyopaque, .{ .name = "rb_asyncify_unwind_buf" });
    rb_asyncify_unwind_buf = null;
    stop_unwind();
}

extern fn rb_wasm_handle_jmp_unwind() ?*anyopaque;
pub fn start(comptime func: anytype, args: anytype) @typeInfo(@TypeOf(func)).@"fn".return_type.? {
    const ReturnType = @typeInfo(@TypeOf(func)).@"fn".return_type.?;
    var result: ReturnType = undefined;

    while (true) {
        result = @call(.never_inline, func, args);

        // Exit Asyncify loop if there is no unwound buffer, which
        // means that main function has returned normally.
        const rb_asyncify_unwind_buf = @extern(?*anyopaque, .{ .name = "rb_asyncify_unwind_buf" });
        if (rb_asyncify_unwind_buf == null) break;

        // NOTE: it's important to call 'asyncify_stop_unwind' here instead in rb_wasm_handle_jmp_unwind
        // because unless that, Asyncify inserts another unwind check here and it unwinds to the root frame.
        asyncify_stop_unwind();

        if (rb_wasm_handle_jmp_unwind()) |asyncify_buf| {
            asyncify_start_rewind(asyncify_buf);
            continue;
        }

        break;
    }
    return result;
}
