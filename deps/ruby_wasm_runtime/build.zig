const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    if (!target.result.isWasm()) {
        std.debug.print("The target should be wasm but is {s}.\n", .{@tagName(target.result.os.tag)});
        return error.InvalidOS;
    }

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "ruby_wasm_runtime",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
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
