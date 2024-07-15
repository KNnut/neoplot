const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    if (!target.result.isWasm())
        @panic("Unsupported target.");

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "ruby_wasm_runtime",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const module = b.addModule("ruby_wasm_runtime", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.linkLibrary(lib);

    lib.installHeader(b.path("src/setjmp.h"), "setjmp.h");

    const sources = [_][]const u8{
        "setjmp.c",
        "setjmp_core.S",
    };

    lib.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &sources,
    });

    b.installArtifact(lib);
}
