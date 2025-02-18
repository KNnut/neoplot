const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
        .cpu_model = .{
            .explicit = &std.Target.wasm.cpu.lime1,
        },
        .cpu_features_add = std.Target.wasm.featureSet(&.{
            .bulk_memory,
            .reference_types,
            // Not supported by Asyncify
            // .tail_call,
            // Not supported by Safari
            // .multimemory,
        }),
    });

    const optimize = b.standardOptimizeOption(.{});
    const is_debug = optimize == .Debug;

    const exe = b.addExecutable(.{
        .name = "neoplot",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.entry = .disabled;
    exe.rdynamic = true;
    exe.wasi_exec_model = .reactor;

    const has_typst_env: bool = b.option(
        bool,
        "typst-env",
        "Build for Typst environment",
    ) orelse true;

    const exe_options = b.addOptions();
    exe_options.addOption(bool, "has_typst_env", has_typst_env);
    exe.root_module.addOptions("build_options", exe_options);

    const strip: ?bool = b.option(
        bool,
        "strip",
        "Remove debug information",
    );

    const stub_wasi = b.option(
        bool,
        "stub-wasi",
        "Stub WASI functions",
    ) orelse true;

    const wasm_opt = b.option(
        bool,
        "wasm-opt",
        "Use wasm-opt (in binaryen) to make Asyncify work and optimize the Wasm binary",
    ) orelse true;

    const mimalloc: bool = b.option(
        bool,
        "mimalloc",
        "Enable mimalloc",
    ) orelse true;

    if (!is_debug) {
        exe.want_lto = true;
        exe.root_module.unwind_tables = .none;
    }

    if (strip) |s|
        exe.root_module.strip = s;

    const ziguplot_dep = b.dependency("ziguplot", .{
        .target = target,
        .optimize = optimize,
        .mimalloc = mimalloc,
    });

    const zbor_dep = b.dependency("zbor", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("zbor", zbor_dep.module("zbor"));

    const ruby_wasm_runtime_dep = b.dependency("ruby_wasm_runtime", .{ .target = target, .optimize = optimize });
    const ruby_wasm_runtime_mod = ruby_wasm_runtime_dep.module("ruby_wasm_runtime");
    exe.root_module.addImport("ruby_wasm_runtime", ruby_wasm_runtime_mod);

    const zgp_mod = b.createModule(.{
        .root_source_file = b.path("src/gnuplot/zgp.zig"),
        .target = target,
        .optimize = optimize,
    });
    zgp_mod.addImport("ruby_wasm_runtime", ruby_wasm_runtime_mod);
    exe.root_module.addImport("zgp", zgp_mod);

    const libgnuplot = ziguplot_dep.artifact("libgnuplot");
    libgnuplot.linkLibrary(ruby_wasm_runtime_dep.artifact("ruby_wasm_runtime"));
    libgnuplot.addCSourceFile(.{
        .file = b.path("src/gp_stub.c"),
        .flags = &.{"-std=c23"},
    });
    if (stub_wasi)
        libgnuplot.addCSourceFile(.{
            .file = b.path("src/wasip1_stub.c"),
            .flags = &.{"-std=c23"},
        });
    exe.linkLibrary(libgnuplot);

    const gnuplot_h_wf = b.addWriteFiles();
    const gnuplot_h = gnuplot_h_wf.add("gnuplot.h",
        \\#include "setshow.h"
        \\#include "fit.h"
        \\#include "gadgets.h"
        \\#include "voxelgrid.h"
        \\#include "term_api.h"
        \\#include "misc.h"
        \\#include "command.h"
        \\#include "datafile.h"
    );

    const translate_c = b.addTranslateC(.{
        .root_source_file = gnuplot_h,
        .target = target,
        .optimize = optimize,
    });
    translate_c.defineCMacro("_GNU_SOURCE", null);
    translate_c.defineCMacro("HAVE_CONFIG_H", null);

    translate_c.addIncludePath(ruby_wasm_runtime_dep.path("src"));
    for (libgnuplot.root_module.include_dirs.items) |item|
        try translate_c.include_dirs.append(item);
    translate_c.step.dependOn(&libgnuplot.step);

    const translate_c_mod = translate_c.createModule();
    zgp_mod.addImport("c", translate_c_mod);
    exe.root_module.addImport("gp_c", translate_c_mod);

    b.resolveInstallPrefix(b.pathFromRoot("pkg"), .{});
    const install_exe = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = "" } },
    });

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
            // "--enable-simd",
            // Not supported by Asyncify
            // "--enable-tail-call",
            "--enable-extended-const",
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
        run_wasm_opt.addArgs(&.{
            "-ocimfs=0",
            "--asyncify",
        });
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
            if (is_debug)
                "asyncify-addlist@command,set_terminal,execute_at"
            else
                "asyncify-addlist@step_through_line,set_command,evaluate_at",
        });

        run_wasm_opt.step.dependOn(&install_exe.step);
        break :blk &run_wasm_opt.step;
    } else &install_exe.step;

    b.getInstallStep().dependOn(opt_wasm_step);
}
