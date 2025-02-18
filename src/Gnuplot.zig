const std = @import("std");
const cbor = @import("zbor");
const zgp = @import("zgp");
const gp_c = @import("gp_c");
const ruby_wasm_runtime = @import("ruby_wasm_runtime");

const mem = std.mem;
const Allocator = mem.Allocator;

const Fifo = std.fifo.LinearFifo(u8, .Dynamic);

const Gnuplot = @This();

arena: Allocator,
output: struct {
    terminal: []const u8,
    print: []const u8,
},

const log = std.log.scoped(.Gnuplot);

pub const CallType = enum {
    script,
    command,
};

const Status = enum {
    idle,
    busy,
};

const GnuplotOutput = struct {
    arena: Allocator,
    terminal: ?[]const u8,
    print: ?[]const u8,

    pub fn process(self: GnuplotOutput) !Output {
        var output: Output = .{
            .images = null,
            .print = self.print,
        };

        if (self.terminal) |terminal| {
            const svg_end_mark = "\n</svg>";
            const new_line = "\n\n";
            const end_mark = svg_end_mark ++ new_line;

            var svg_array_list = std.fifo.LinearFifo([]const u8, .Dynamic).init(self.arena);

            var last_pos: usize = 0;
            while (mem.indexOfPos(u8, terminal, last_pos, end_mark)) |pos| {
                const svg = terminal[last_pos .. pos + svg_end_mark.len];
                try svg_array_list.writeItem(svg);
                last_pos += svg.len + new_line.len;
            }
            output.images = try svg_array_list.toOwnedSlice();
        }

        log.debug("output={}", .{output});
        if (output.images) |images|
            log.debug("images length={d}", .{images.len});
        return output;
    }
};

pub const Output = struct {
    images: ?[][]const u8,
    print: ?[]const u8,

    pub fn format(
        self: Output,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeAll("images:");
        if (self.images) |images| {
            try writer.writeByte('\n');
            for (images) |image| {
                try writer.writeAll(image);
                try writer.writeByte('\n');
            }
        } else {
            try writer.writeAll(" none\n");
        }
        try writer.writeAll("print:");
        if (self.print) |print| {
            try writer.writeByte('\n');
            try writer.writeAll(print);
        } else {
            try writer.writeAll(" none");
        }
        try writer.writeByte('\n');
    }

    pub fn toCbor(self: Output, allocator: Allocator) ![]const u8 {
        var fifo = Fifo.init(allocator);
        errdefer fifo.deinit();

        try cbor.stringify(self, .{
            .field_settings = &.{
                .{ .name = "images", .field_options = .{ .skip = .None } },
                .{ .name = "print", .field_options = .{ .skip = .None } },
            },
        }, fifo.writer());

        return try fifo.toOwnedSlice();
    }
};

pub fn init(arena: Allocator) Gnuplot {
    return .{
        .arena = arena,
        .output = undefined,
    };
}

fn innerCall(code: [:0]const u8, call_type: CallType) !void {
    try zgp.setJmp();
    switch (call_type) {
        .script => {
            const fp = gp_c.fmemopen(@constCast(code.ptr), code.len, "r");
            gp_c.load_file(fp, null, 1);
        },
        .command => gp_c.do_string(code.ptr),
    }
}

pub fn call(self: *Gnuplot, code: [:0]const u8, call_type: CallType) !void {
    // Redirect the output of graphics devices
    var terminal_fifo = Fifo.init(self.arena);
    gp_c.gpoutfile = gp_c.fopencookie(&terminal_fifo, "w", .{ .write = zgp.fifoCookieFn(Fifo).write });
    // Redirect the output of the `print` command
    var print_fifo = Fifo.init(self.arena);
    gp_c.print_out = gp_c.fopencookie(&print_fifo, "w", .{ .write = zgp.fifoCookieFn(Fifo).write });

    log.debug("call_type={s}", .{@tagName(call_type)});

    // Use Asyncify-based setjmp
    try ruby_wasm_runtime.start(innerCall, .{ code, call_type });

    self.output.terminal = try terminal_fifo.toOwnedSlice();
    self.output.print = try print_fifo.toOwnedSlice();
}

pub fn getOutput(self: *Gnuplot) GnuplotOutput {
    return .{
        .arena = self.arena,
        .terminal = if (self.output.terminal.len > 0) self.output.terminal else null,
        .print = if (self.output.print.len > 0) self.output.print else null,
    };
}
