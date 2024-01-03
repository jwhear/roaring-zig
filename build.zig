const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const include_path = .{ .path = "croaring" };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    var lib = add(b, target, optimize);
    b.installArtifact(lib);

    var main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/test.zig" },
    });
    main_tests.linkLibrary(lib);
    main_tests.addIncludePath(include_path);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    var example = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{ .path = "src/example.zig" },
        .target = target,
        .optimize = optimize,
    });
    example.linkLibrary(lib);
    example.addIncludePath(include_path);

    const run_example = b.addRunArtifact(example);
    run_example.step.dependOn(&example.step); // gotta build it first
    b.step("run-example", "Run the example").dependOn(&run_example.step);
}

/// Add Roaring Bitmaps to your build process
pub fn add(b: *std.Build, target: CrossTarget, optimize: std.builtin.Mode) *std.build.LibExeObjStep {
    var lib = b.addStaticLibrary(.{
        .name = "roaring-zig",
        .root_source_file = .{ .path = "src/roaring.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.addCSourceFile(.{ .file = .{ .path = "croaring/roaring.c" }, .flags = &.{} });
    lib.addIncludePath(include_path);
    return lib;
}
