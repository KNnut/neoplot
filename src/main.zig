const std = @import("std");
const gp = @import("gnuplot");
const gp_c = @import("gnuplot_c");
const cbor = @import("zbor");
const ruby_wasm_runtime = @import("ruby_wasm_runtime");
const typst = @import("typst.zig");

const allocator = std.heap.c_allocator;
const Fifo = std.fifo.LinearFifo(u8, .Dynamic);

export fn signal(_: i32, _: i32) i32 {
    return 0;
}

export fn system(_: i32) i32 {
    return 0;
}

// The `test_palette_subcommand` function requires `tmpfile`
var tmp_fifo: Fifo = undefined;
export fn tmpfile() ?*gp_c.FILE {
    tmp_fifo = Fifo.init(allocator);
    return gp_c.fopencookie(&tmp_fifo, "w+", gp.fifoCookieFn(Fifo));
}

const CallType = enum {
    script,
    command,
};

const Status = enum {
    idle,
    busy,
};

var status: Status = .idle;
fn call(code: [:0]const u8, @"type": CallType) !void {
    const log = std.log.scoped(.call);
    // Reset `status` to `idle` after this call
    defer status = .idle;

    // Always inline `init` function to avoid stack smashing
    @call(.always_inline, gp.init, .{"svg"});
    log.debug("status={s}", .{@tagName(status)});
    // `init` function has a jump
    // `status` is `busy` here if and only if there is an error
    if (status == .busy) return error.GnuplotError;
    status = .busy;

    // Redirect the output of graphics devices
    var term_output_fifo = Fifo.init(allocator);
    errdefer term_output_fifo.deinit();
    gp_c.gpoutfile = gp_c.fopencookie(&term_output_fifo, "w", .{ .write = gp.fifoCookieFn(Fifo).write });

    // Redirect the output of the `print` command
    var print_output_fifo = Fifo.init(allocator);
    errdefer print_output_fifo.deinit();
    gp_c.print_out = gp_c.fopencookie(&print_output_fifo, "w", .{ .write = gp.fifoCookieFn(Fifo).write });

    log.debug("type={s}", .{@tagName(@"type")});
    switch (@"type") {
        .script => {
            const fp = gp_c.fmemopen(@constCast(code.ptr), code.len, "r");
            gp_c.load_file(fp, null, 1);
        },
        .command => gp_c.do_string(code.ptr),
    }

    const term_output = try term_output_fifo.toOwnedSlice();
    defer allocator.free(term_output);

    const print_output = try print_output_fifo.toOwnedSlice();
    defer allocator.free(print_output);

    const svg_end_mark = "\n</svg>\n";

    var svg_array_list = std.ArrayList([]const u8).init(allocator);
    errdefer svg_array_list.deinit();

    var last_pos: usize = 0;
    while (std.mem.indexOf(u8, term_output[last_pos..], svg_end_mark)) |pos| {
        const svg = term_output[last_pos..][0 .. pos + svg_end_mark.len - 1];
        try svg_array_list.append(svg);
        last_pos += svg.len + 1;
    }

    const svg_list = try svg_array_list.toOwnedSlice();
    defer allocator.free(svg_list);

    var result_fifo = Fifo.init(allocator);
    errdefer result_fifo.deinit();

    try cbor.stringify(.{
        .term_output = if (svg_list.len > 0) svg_list else null,
        .print_output = if (print_output.len > 0) print_output else null,
    }, .{
        .field_settings = &.{
            .{ .name = "term_output", .field_options = .{ .skip = .None } },
            .{ .name = "print_output", .field_options = .{ .skip = .None } },
        },
    }, result_fifo.writer());

    const result = try result_fifo.toOwnedSlice();
    defer allocator.free(result);

    typst.send(result);
}

fn bridge(length: usize) !void {
    const log = std.log.scoped(.bridge);

    const buf = try allocator.alloc(u8, length);
    defer allocator.free(buf);

    typst.receive(buf);

    const data_item = try cbor.DataItem.new(buf);
    const arg = try cbor.parse(struct {
        code: [:0]const u8,
        type: CallType,
    }, data_item, .{ .allocator = allocator });
    defer allocator.free(arg.code);

    log.debug("code length={d}", .{arg.code.len});

    // Do nothing when code is empty
    if (arg.code.len == 0) return;

    // Use Asyncify-based setjmp
    try ruby_wasm_runtime.start(call, .{ arg.code, arg.type });
}

export fn exec(length: usize) typst.ReturnType {
    const log = std.log.scoped(.exec);

    // Do nothing when length is 0
    if (length == 0) return .success;

    bridge(length) catch |err| {
        var buf: [32]u8 = undefined;
        const err_msg = blk: switch (err) {
            error.GnuplotError => {
                const gp_errmsg = gp_c.get_udv_by_name(@constCast("GPVAL_ERRMSG")).*.udv_value.v.string_val;
                break :blk std.mem.sliceTo(gp_errmsg, 0);
            },
            else => {
                break :blk std.fmt.bufPrint(&buf, "{}", .{err}) catch "Error message is too long";
            },
        };
        log.debug("error message={s}", .{err_msg});
        typst.send(err_msg);
        return .failure;
    };

    return .success;
}
