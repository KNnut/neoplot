const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "gnuplot",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
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

    lib.root_module.addCMacro("HAVE_CONFIG_H", "");
    const config_header = b.addConfigHeader(
        .{ .include_path = "config.h" },
        .{
            .HAVE_STRING_H = true,
            .HAVE_MEMCPY = true,
            .HAVE_STDLIB_H = true,
            .HAVE_VFPRINTF = true,
            .STDC_HEADERS = true,
            .HAVE_UNISTD_H = true,
            .HAVE_ERRNO_H = true,
            .HAVE_STRERROR = true,
            .HAVE_SYS_TYPES_H = true,
            .HAVE_LIMITS_H = true,
            .HAVE_FLOAT_H = true,
            .HAVE_LOCALE_H = true,
            .HAVE_MATH_H = true,
            .HAVE_STRCASECMP = true,
            .HAVE_STRCSPN = true,
            .HAVE_STRDUP = true,
            .HAVE_STRNDUP = true,
            .HAVE_STRNLEN = true,
            .HAVE_STRCHR = true,
            .HAVE_STRSTR = true,
            .HAVE_STRLCPY = true,
            .HAVE_GETCWD = true,
            .HAVE_USLEEP = true,
            .HAVE_SLEEP = true,
            .HAVE_TIME_H = true,

            .HAVE_STDBOOL_H = true,
            .HAVE_INTTYPES_H = true,
            .HAVE_FENV_H = true,
            .HAVE_COMPLEX_H = true,
            .HAVE_CSQRT = true,
            .HAVE_CABS = true,
            .HAVE_CLOG = true,
            .HAVE_CEXP = true,
            .HAVE_LGAMMA = true,
            .HAVE_TGAMMA = true,
            .HAVE_ERF = true,
            .HAVE_ERFC = true,
            .HAVE_DECL_SIGNGAM = true,
            .HAVE_DIRENT_H = true,
            .HAVE_MEMSET = true,

            .USE_POLAR_GRID = true,
            .USE_STATS = true,
            .USE_WATCHPOINTS = true,
            .USE_FUNCTIONBLOCKS = true,
            .WITH_CHI_SHAPES = true,
            .WITH_EXTRA_COORDINATE = true,
            .NO_BITMAP_SUPPORT = true,

            .NO_GIH = true,
            .HELPFILE = "",
        },
    );
    lib.addConfigHeader(config_header);

    const upstream_dir = upstream.builder.build_root.handle;
    upstream_dir.access("src/default_term.h", .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const replace_term_h = upstream.builder.addUpdateSourceFiles();
            replace_term_h.addCopyFileToSource(upstream.path("src/term.h"), "src/default_term.h");
            replace_term_h.addBytesToSource(
                \\#ifdef TERM_H
                \\#include TERM_H
                \\#else
                \\#include "default_term.h"
                \\#endif
            , "src/term.h");
            lib.step.dependOn(&replace_term_h.step);
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

        if (b.lazyDependency("ruby_wasm_runtime", .{ .target = target, .optimize = optimize })) |ruby_wasm_runtime| {
            const artifact = ruby_wasm_runtime.artifact("ruby_wasm_runtime");
            lib.linkLibrary(artifact);
            lib.installLibraryHeaders(artifact);
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

    const wf = b.addWriteFiles();
    const gnuplot_h = wf.add("gnuplot.h",
        \\#include "setshow.h"
        \\#include "fit.h"
        \\#include "gadgets.h"
        \\#include "voxelgrid.h"
        \\#include "term_api.h"
        \\#include "misc.h"
        \\#include "command.h"
    );

    const translate_c = b.addTranslateC(.{
        .root_source_file = gnuplot_h,
        .target = target,
        .optimize = optimize,
    });
    translate_c.defineCMacro("_GNU_SOURCE", null);
    translate_c.defineCMacro("HAVE_CONFIG_H", null);

    translate_c.addConfigHeader(config_header);
    translate_c.addIncludePath(upstream.path("src"));
    translate_c.addIncludePath(upstream.path("term"));
    if (target.result.os.tag == .wasi) {
        if (b.lazyDependency("ruby_wasm_runtime", .{ .target = target, .optimize = optimize })) |ruby_wasm_runtime| {
            translate_c.addIncludePath(ruby_wasm_runtime.path("src"));
        }
    }

    const c = translate_c.addModule("c");
    module.addImport("c", c);
}
