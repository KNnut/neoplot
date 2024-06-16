const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .wasm32,
            .os_tag = .wasi,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "neoplot",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.entry = .disabled;
    exe.rdynamic = true;

    if (optimize != .Debug) {
        exe.root_module.strip = true;
        exe.root_module.unwind_tables = false;
        exe.root_module.single_threaded = true;
    }

    const gnuplot_mod = b.dependency("gnuplot", .{ .target = target, .optimize = optimize }).module("gnuplot");
    exe.root_module.addImport("gnuplot", gnuplot_mod);

    b.installArtifact(exe);
}
