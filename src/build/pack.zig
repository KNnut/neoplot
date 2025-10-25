const std = @import("std");
const build_zon = @import("../../build.zig.zon");

pub const PackageNamespace = enum {
    local,
    preview,
};

pub fn packageSubPath(b: *std.Build, namespace: PackageNamespace, sub_path: ?[]const []const u8) []const u8 {
    // packages/{namespace}/{name}/{version}[/{sub_path}]
    const base_path = b.pathJoin(&.{ "packages", @tagName(namespace), @tagName(build_zon.name), build_zon.version });

    if (sub_path) |path|
        return b.pathJoin(&.{ base_path, b.pathJoin(path) });
    return base_path;
}

pub fn installPackage(b: *std.Build, namespace: PackageNamespace) void {
    inline for (.{ "lib.typ", "neoplot.typ", "utils.typ" }) |filename|
        b.getInstallStep().dependOn(
            &b.addInstallFile(.{
                .cwd_relative = b.pathJoin(&.{ "pkg", filename }),
            }, packageSubPath(b, namespace, &.{filename})).step,
        );
}

pub fn installPackageToml(b: *std.Build, namespace: PackageNamespace) void {
    const wf = b.addWriteFile("typst.toml", generatePackageToml(b));
    b.getInstallStep().dependOn(&b.addInstallDirectory(.{
        .source_dir = wf.getDirectory(),
        .install_dir = .prefix,
        .install_subdir = packageSubPath(b, namespace, null),
    }).step);
}

pub fn packPackage(b: *std.Build, namespace: PackageNamespace) *std.Build.Step {
    const package_root = packageSubPath(b, namespace, null);

    const wf = b.addWriteFiles();
    inline for (.{ "LICENSE", "README.md" }) |filename|
        _ = wf.addCopyFile(.{ .cwd_relative = filename }, b.pathJoin(&.{ package_root, filename }));
    _ = wf.addCopyDirectory(.{ .cwd_relative = b.getInstallPath(.prefix, package_root) }, package_root, .{});
    wf.step.dependOn(b.getInstallStep());

    const tar = b.addSystemCommand(&.{ "tar", "cJf", "-", "." });
    tar.setCwd(wf.getDirectory());
    tar.step.dependOn(&wf.step);

    const install_file = b.addInstallFile(
        tar.captureStdOut(),
        b.fmt("{s}-{s}.tar.xz", .{ @tagName(build_zon.name), build_zon.version }),
    );
    install_file.step.dependOn(&tar.step);

    return &install_file.step;
}

fn generatePackageToml(b: *std.Build) []const u8 {
    return b.fmt(
        \\[package]
        \\name = "{s}"
        \\version = "{s}"
        \\entrypoint = "lib.typ"
        \\authors = ["KNnut <@KNnut>"]
        \\license = "BSD-3-Clause"
        \\description = "Gnuplot in Typst"
        \\repository = "https://github.com/KNnut/neoplot"
        \\keywords = ["gnuplot", "plotting"]
        \\categories = ["visualization", "integration"]
        \\disciplines = ["mathematics"]
        \\compiler = "{s}"
    , .{
        @tagName(build_zon.name),
        build_zon.version,
        build_zon.minimum_typst_version,
    });
}
