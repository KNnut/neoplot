const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "gnuplot",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const module = b.addModule("gnuplot", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.linkLibrary(lib);

    const upstream = b.dependency("gnuplot", .{ .target = target, .optimize = optimize });

    lib.addIncludePath(upstream.path("src"));
    lib.addIncludePath(upstream.path("term"));
    lib.installHeadersDirectory(
        upstream.path("src"),
        "",
        .{ .include_extensions = &.{".h"} },
    );

    lib.addIncludePath(b.path("override/config"));
    lib.root_module.addCMacro("HAVE_CONFIG_H", "");
    lib.installHeader(
        b.path("override/config/config.h"),
        "config.h",
    );

    const upstream_dir = upstream.builder.build_root.handle;
    upstream_dir.access("src/default_term.h", .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const copy_term_h = upstream.builder.addUpdateSourceFiles();
            copy_term_h.addCopyFileToSource(upstream.path("src/term.h"), "src/default_term.h");
            copy_term_h.addCopyFileToSource(b.path("override/include/term.h"), "src/term.h");
            lib.step.dependOn(&copy_term_h.step);
        },
        else => return err,
    };

    if (target.result.os.tag == .wasi) {
        const new_filepath = "term/pure_svg.trm";
        upstream_dir.access(new_filepath, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                const file = try upstream_dir.openFile("term/svg.trm", .{});
                defer file.close();

                const stat = try file.stat();

                const bytes = try file.readToEndAlloc(b.allocator, stat.size);
                defer b.allocator.free(bytes);

                _ = std.mem.replace(u8, bytes, "TERM_TABLE_START (domterm_driver)", "#if 0\nABLE_START (domterm_driver)", bytes);
                _ = std.mem.replace(u8, bytes, "#define LAST_TERM domterm_driver", "#define LAST_TERM domterm\n#endif", bytes);

                const enable_domterm = "strcmp(term->name, \"domterm\") == ";
                const enable_mouse = "SVG_mouseable = TRUE;";
                const enable_standalone = "SVG_standalone = TRUE;";
                const enable_doctype = "SVG_emit_doctype)";
                const enable_hypertext = "SVG_hypertext\t";

                var times = std.mem.replace(u8, bytes, enable_domterm, "", bytes);
                var size = bytes.len - enable_domterm.len * times;
                times = std.mem.replace(u8, bytes[0..size], enable_mouse, "", bytes);
                size -= enable_mouse.len * times;
                times = std.mem.replace(u8, bytes[0..size], enable_standalone, "", bytes);
                size -= enable_standalone.len * times;
                times = std.mem.replace(u8, bytes[0..size], enable_doctype, "0)", bytes);
                size -= (enable_doctype.len - 2) * times;
                times = std.mem.replace(u8, bytes[0..size], enable_hypertext, "0", bytes);
                size -= (enable_hypertext.len - 1) * times;

                const new_file = try upstream_dir.createFile(new_filepath, .{});
                defer new_file.close();

                try new_file.writeAll(bytes[0..size]);
            },
            else => return err,
        };

        lib.addIncludePath(b.path("override/wasi/include"));
        lib.root_module.addCMacro("TERM_H", "\"wasi_term.h\"");
        lib.root_module.addCMacro("_WASI_EMULATED_SIGNAL", "");

        lib.installHeadersDirectory(
            b.path("override/wasi/include"),
            "",
            .{ .include_extensions = &.{".h"} },
        );

        if (b.lazyDependency("ruby_wasm_runtime", .{ .target = target, .optimize = optimize })) |ruby_wasm_runtime| {
            lib.linkLibrary(ruby_wasm_runtime.artifact("ruby_wasm_runtime"));
            lib.installHeader(ruby_wasm_runtime.path("src/setjmp.h"), "setjmp.h");
        }
    }

    const sources = [_][]const u8{
        "alloc.c",
        "amos_airy.c",
        "axis.c",
        "breaders.c",
        "boundary.c",
        "color.c",
        "command.c",
        "contour.c",
        "complexfun.c",
        "datablock.c",
        "datafile.c",
        "dynarray.c",
        "encoding.c",
        "eval.c",
        "external.c",
        "filters.c",
        "fit.c",
        "gadgets.c",
        "getcolor.c",
        "gplocale.c",
        "graph3d.c",
        "graphics.c",
        "help.c",
        "hidden3d.c",
        "history.c",
        "internal.c",
        "interpol.c",
        "jitter.c",
        "libcerf.c",
        "loadpath.c",
        "matrix.c",
        "misc.c",
        // "mouse.c",
        "multiplot.c",
        "parse.c",
        // "plot.c",
        "plot2d.c",
        "plot3d.c",
        "pm3d.c",
        // "readline.c",
        "save.c",
        "scanner.c",
        "set.c",
        "show.c",
        "specfun.c",
        "standard.c",
        "stats.c",
        "stdfn.c",
        "tables.c",
        "tabulate.c",
        "term.c",
        "time.c",
        "unset.c",
        "util.c",
        "util3d.c",
        "version.c",
        "voxelgrid.c",
        "vplot.c",
        "watch.c",
        // "xdg.c",
    };

    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &sources,
        .flags = &.{"-fno-sanitize=undefined"},
    });

    b.installArtifact(lib);
}
