const std = @import("std");
const c = @import("gp_c");
const assert = std.debug.assert;
const mem = std.mem;
const Allocator = mem.Allocator;

pub const raw_c_allocator: Allocator = .{
    .ptr = undefined,
    .vtable = &raw_c_allocator_vtable,
};
const raw_c_allocator_vtable: Allocator.VTable = .{
    .alloc = rawCAlloc,
    .resize = rawCResize,
    .remap = rawCRemap,
    .free = rawCFree,
};

fn rawCAlloc(
    context: *anyopaque,
    len: usize,
    alignment: mem.Alignment,
    return_address: usize,
) ?[*]u8 {
    _ = context;
    _ = return_address;
    assert(alignment.compare(.lte, comptime .fromByteUnits(@alignOf(c.max_align_t))));
    // Note that this pointer cannot be aligncasted to max_align_t because if
    // len is < max_align_t then the alignment can be smaller. For example, if
    // max_align_t is 16, but the user requests 8 bytes, there is no built-in
    // type in C that is size 8 and has 16 byte alignment, so the alignment may
    // be 8 bytes rather than 16. Similarly if only 1 byte is requested, malloc
    // is allowed to return a 1-byte aligned pointer.
    return @ptrCast(c.malloc(len));
}

fn rawCResize(
    context: *anyopaque,
    memory: []u8,
    alignment: mem.Alignment,
    new_len: usize,
    return_address: usize,
) bool {
    _ = context;
    _ = memory;
    _ = alignment;
    _ = new_len;
    _ = return_address;
    return false;
}

fn rawCRemap(
    context: *anyopaque,
    memory: []u8,
    alignment: mem.Alignment,
    new_len: usize,
    return_address: usize,
) ?[*]u8 {
    _ = context;
    _ = alignment;
    _ = return_address;
    return @ptrCast(c.realloc(memory.ptr, new_len));
}

fn rawCFree(
    context: *anyopaque,
    memory: []u8,
    alignment: mem.Alignment,
    return_address: usize,
) void {
    _ = context;
    _ = alignment;
    _ = return_address;
    c.free(memory.ptr);
}
