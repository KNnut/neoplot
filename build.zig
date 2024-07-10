const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .wasm32,
            .os_tag = .wasi,
        },
    });
    const optimize = b.standardOptimizeOption(.{});
    const is_debug = optimize == .Debug;

    const exe = b.addExecutable(.{
        .name = "neoplot",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.entry = .disabled;
    exe.rdynamic = true;

    const strip: ?bool = b.option(
        bool,
        "strip",
        "Remove debug information",
    ) orelse null;

    const stub_wasi = b.option(
        bool,
        "stub-wasi",
        "Stub WASI functions",
    ) orelse true;

    const wasi_stub = b.option(
        bool,
        "wasi-stub",
        "Use wasi-stub to stub WASI Preview 1 functions",
    ) orelse false;

    const wasm_opt = b.option(
        bool,
        "wasm-opt",
        "Use wasm-opt (in binaryen) to make Asyncify work and optimize the WASM binary",
    ) orelse true;

    if (!is_debug) {
        exe.root_module.unwind_tables = false;
        exe.root_module.single_threaded = true;
    }

    if (strip) |s|
        exe.root_module.strip = s;

    const gnuplot_mod = b.dependency("gnuplot", .{ .target = target, .optimize = optimize }).module("gnuplot");
    exe.root_module.addImport("gnuplot", gnuplot_mod);

    if (stub_wasi)
        gnuplot_mod.addCSourceFile(.{
            .file = b.path("src/stub.c"),
            .flags = &.{"-std=c23"},
        });

    b.resolveInstallPrefix("pkg", .{});
    const install_exe = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = "" } },
    });

    const stub_wasip1_step = if (wasi_stub) blk: {
        const stub_fd_write = b.addSystemCommand(&.{
            "wasi-stub",
            "--stub-function",
            "wasi_snapshot_preview1:fd_write",
            "-r",
            "76",
        });
        stub_fd_write.addArtifactArg(exe);
        stub_fd_write.addArg("-o");
        stub_fd_write.addArtifactArg(exe);
        stub_fd_write.step.dependOn(&install_exe.step);

        const stub_wasip1 = b.addSystemCommand(&.{
            "wasi-stub",
            "--stub-module",
            "wasi_snapshot_preview1",
            "-r",
            "0",
        });
        stub_wasip1.addArtifactArg(exe);
        stub_wasip1.addArg("-o");
        stub_wasip1.addArtifactArg(exe);
        stub_wasip1.step.dependOn(&stub_fd_write.step);
        break :blk &stub_wasip1.step;
    } else &install_exe.step;

    const opt_wasm_step = if (wasm_opt) blk: {
        // Keep function names for Asyncify lists
        exe.root_module.strip = false;
        const run_wasm_opt = b.addSystemCommand(&.{
            "wasm-opt",
            "-n",
            "-tnh",
            "-lmu",
            "--enable-bulk-memory",
            "--enable-multivalue",
            "--enable-mutable-globals",
            "--enable-reference-types",
            "--enable-nontrapping-float-to-int",
            "--enable-sign-ext",
            "--enable-simd",
            // Remove DWARF to avoid warnings and the fatal error in binaryen
            "--strip-dwarf",
        });
        if (strip orelse !is_debug)
            run_wasm_opt.addArgs(&.{
                "--strip-debug",
                "--strip-eh",
                "--strip-producers",
                "--strip-target-features",
            })
        else
            run_wasm_opt.addArg("-g");
        if (is_debug)
            // Disable optimization in Debug mode
            run_wasm_opt.addArg("-O0")
        else
            run_wasm_opt.addArgs(&.{
                "--gufa",
                "-Oz",
                "-Oz",
            });
        run_wasm_opt.addArg("--asyncify");
        if (optimize == .ReleaseFast)
            run_wasm_opt.addArgs(&.{
                "-O4",
                "--flatten",
                "--rereloop",
                "-O4",
            });
        if (!is_debug)
            run_wasm_opt.addArgs(&.{
                "-Oz",
                "-Oz",
            });
        run_wasm_opt.addArtifactArg(exe);
        run_wasm_opt.addArg("-o");
        run_wasm_opt.addArtifactArg(exe);
        // Asyncify options
        run_wasm_opt.addArgs(&.{
            "-pa",
            "asyncify-ignore-imports",
            "-pa",
            "asyncify-ignore-indirect",
            // Indirect calls
            "-pa",
            try std.mem.concat(b.allocator, u8, &.{
                "asyncify-addlist@",
                if (is_debug)
                    "command,set_terminal,execute_at"
                else
                    "do_line,set_command,evaluate_at",
            }),
        });

        run_wasm_opt.step.dependOn(stub_wasip1_step);
        break :blk &run_wasm_opt.step;
    } else stub_wasip1_step;

    b.getInstallStep().dependOn(opt_wasm_step);
}
