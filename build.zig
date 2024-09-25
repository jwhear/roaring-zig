const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const lib = add(b, target, optimize);
    b.installArtifact(lib);

    var main_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
    });
    main_tests.linkLibrary(lib);
    main_tests.addIncludePath(b.path("croaring"));

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    var example = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("src/example.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.linkLibrary(lib);
    example.addIncludePath(b.path("croaring"));

    const run_example = b.addRunArtifact(example);
    run_example.step.dependOn(&example.step); // gotta build it first
    b.step("run-example", "Run the example").dependOn(&run_example.step);
}

/// Add Roaring Bitmaps to your build process
pub fn add(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.Mode) *std.Build.Step.Compile {
    var lib = b.addStaticLibrary(.{
        .name = "roaring-zig",
        .root_source_file = b.path("src/roaring.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.addCSourceFile(.{ .file = b.path("croaring/roaring.c"), .flags = &.{} });
    lib.addIncludePath(b.path("croaring"));
    return lib;
}
