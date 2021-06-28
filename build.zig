const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    var lib = add(b, mode);
    lib.install();

    var main_tests = b.addTest("src/test.zig");
    main_tests.setBuildMode(mode);
    main_tests.linkLibrary(lib);
    main_tests.addIncludeDir("croaring");

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

/// Add Roaring Bitmaps to your build process
pub fn add(b: *Builder, mode: std.builtin.Mode) *std.build.LibExeObjStep {
    var lib = b.addStaticLibrary("roaring-zig", "src/roaring.zig");
    lib.setBuildMode(mode);
    lib.linkLibC();
    lib.addCSourceFile("croaring/roaring.c", &[_][]const u8{""});
    lib.addIncludeDir("croaring");
    return lib;
}
