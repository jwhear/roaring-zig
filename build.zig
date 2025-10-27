const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add option to disable AVX512 in CRoaring, or auto-detect CPU capabilities
    const disable_avx512 = b.option(bool, "ROARING_DISABLE_AVX512", "Disable AVX512 in CRoaring") orelse blk: {
        // Auto-detect: disable AVX512 if the target CPU doesn't support it
        const resolved_target = b.resolveTargetQuery(target.query);
        const cpu_arch = resolved_target.result.cpu.arch;

        // AVX512 is only available on x86_64 architecture
        if (cpu_arch != .x86_64) {
            std.log.info("Non-x86_64 target detected ({s}), disabling AVX512 in CRoaring", .{@tagName(cpu_arch)});
            break :blk true; // disable AVX512
        }

        // For x86_64, check if the CPU supports the required AVX512 features
        const cpu_features = resolved_target.result.cpu.features;
        const has_avx512f = cpu_features.isEnabled(@intFromEnum(std.Target.x86.Feature.avx512f));
        const has_avx512dq = cpu_features.isEnabled(@intFromEnum(std.Target.x86.Feature.avx512dq));
        const has_avx512bw = cpu_features.isEnabled(@intFromEnum(std.Target.x86.Feature.avx512bw));

        // CRoaring requires multiple AVX512 features, not just AVX512F
        const has_required_avx512 = has_avx512f and has_avx512dq and has_avx512bw;

        if (!has_required_avx512) {
            std.log.info("AVX512 features not detected on x86_64 target CPU, disabling AVX512 in CRoaring", .{});
        } else {
            std.log.info("AVX512 features detected on x86_64 target CPU, enabling AVX512 optimizations", .{});
        }

        break :blk !has_required_avx512;
    };

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const lib = add(b, target, optimize, disable_avx512);
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
    bench.root_module.addImport("roaring64", roaring64_mod);

    // Compile CRoaring C source into the bench so Zig wrapper can link
    const bench_flags: []const []const u8 = if (disable_avx512) &[_][]const u8{"-DCROARING_COMPILER_SUPPORTS_AVX512=0"} else &[_][]const u8{};
    bench.addCSourceFile(.{ .file = b.path("croaring/roaring.c"), .flags = bench_flags });
    bench.addIncludePath(b.path("croaring"));
    bench.linkLibC();
    const run_bench = b.addRunArtifact(bench);
    // forward args passed after `--` to the bench executable
    if (b.args) |cli_args| {
        run_bench.addArgs(cli_args);
    }
    // Allow passing a dataset directory like: zig build bench -- <dir>
    const bench_step = b.step("bench", "Run microbenchmarks (optionally pass a data dir)");
    bench_step.dependOn(&run_bench.step);
}

/// Add Roaring Bitmaps to your build process
pub fn add(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, disable_avx512: bool) *std.Build.Step.Compile {
    var lib = b.addLibrary(.{
        .name = "roaring-zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/roaring.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });

    const lib_flags: []const []const u8 = if (disable_avx512) &[_][]const u8{"-DCROARING_COMPILER_SUPPORTS_AVX512=0"} else &[_][]const u8{};
    lib.addCSourceFile(.{ .file = b.path("croaring/roaring.c"), .flags = lib_flags });
    lib.addIncludePath(b.path("croaring"));
    lib.linkLibC();
    return lib;
}
