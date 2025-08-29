const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const lib = add(b, target, optimize);
    b.installArtifact(lib);

    var main_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    main_tests.linkLibrary(lib);
    main_tests.addIncludePath(b.path("croaring"));

    const run_main_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    // 64-bit tests
    var tests64 = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test64.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    tests64.linkLibrary(lib);
    tests64.addIncludePath(b.path("croaring"));
    const run_tests64 = b.addRunArtifact(tests64);
    test_step.dependOn(&run_tests64.step);

    var example = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    example.linkLibrary(lib);
    example.addIncludePath(b.path("croaring"));

    const run_example = b.addRunArtifact(example);
    run_example.step.dependOn(&example.step); // gotta build it first
    b.step("run-example", "Run the example").dependOn(&run_example.step);

    // Microbench executable similar to CRoaring's bench
    var bench = b.addExecutable(.{
        .name = "bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("microbench/bench.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // Allow bench to import the Zig roaring wrapper as `@import("roaring")`
    const roaring_mod = b.addModule("roaring_mod", .{
        .root_source_file = b.path("src/roaring.zig"),
        .target = target,
        .optimize = optimize,
    });
    roaring_mod.addIncludePath(b.path("croaring"));
    bench.root_module.addImport("roaring", roaring_mod);
    // And 64-bit wrapper
    const roaring64_mod = b.addModule("roaring64_mod", .{
        .root_source_file = b.path("src/roaring64.zig"),
        .target = target,
        .optimize = optimize,
    });
    roaring64_mod.addIncludePath(b.path("croaring"));
    roaring64_mod.addImport("roaring", roaring_mod);
    bench.root_module.addImport("roaring64", roaring64_mod);
    // Compile CRoaring C source into the bench so Zig wrapper can link
    bench.addCSourceFile(.{ .file = b.path("croaring/roaring.c"), .flags = &.{} });
    bench.addIncludePath(b.path("croaring"));
    bench.linkLibC();
    const run_bench = b.addRunArtifact(bench);
    // Allow passing a dataset directory like: zig build bench -- <dir>
    const bench_step = b.step("bench", "Run microbenchmarks (optionally pass a data dir)");
    bench_step.dependOn(&run_bench.step);
}

/// Add Roaring Bitmaps to your build process
pub fn add(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    var lib = b.addLibrary(.{
        .name = "roaring-zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/roaring.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });

    lib.addCSourceFile(.{ .file = b.path("croaring/roaring.c"), .flags = &.{} });
    lib.addIncludePath(b.path("croaring"));
    lib.linkLibC();
    return lib;
}
