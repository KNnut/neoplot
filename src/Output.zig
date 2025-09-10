const std = @import("std");
const cbor = @import("zbor");

pub const Output = @This();

terminal: ?[]const u8,
print: ?[]const u8,

pub fn toCbor(self: Output, writer: *std.Io.Writer) !void {
    try cbor.stringify(self, .{
        .field_settings = &.{
            .{ .name = "terminal", .field_options = .{ .skip = .None } },
            .{ .name = "print", .field_options = .{ .skip = .None } },
        },
    }, writer);
}
