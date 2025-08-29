const std = @import("std");
const roaring = @import("roaring");

const DataSet = struct {
    allocator: std.mem.Allocator,
    bitmaps32: []*roaring.Bitmap,
    max_value: u32,
    max_cardinality: usize,
};

fn readAllIntegerFiles(allocator: std.mem.Allocator, dir_path: []const u8) ![][]u32 {
    // First pass: count .txt files
    var d1 = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer d1.close();
    var count: usize = 0;
    var it1 = d1.iterate();
    while (try it1.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".txt")) continue;
        count += 1;
    }
    // Allocate names array
    var names = try allocator.alloc([]u8, count);
    var idx: usize = 0;
    // Second pass: collect names
    var d2 = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer d2.close();
    var it2 = d2.iterate();
    while (try it2.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".txt")) continue;
        names[idx] = try allocator.dupe(u8, entry.name);
        idx += 1;
    }
    // Sort names
    std.mem.sort([]u8, names, {}, struct {
        fn lt(_: void, a: []u8, b: []u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt);

    var out = try allocator.alloc([]u32, names.len);
    var i: usize = 0;
    while (i < names.len) : (i += 1) {
        const name = names[i];
        const full = try std.fs.path.join(allocator, &.{ dir_path, name });
        defer allocator.free(full);
        const bytes = try std.fs.cwd().readFileAlloc(allocator, full, 1 << 28);
        defer allocator.free(bytes);
        out[i] = try parseU32List(allocator, bytes);
    }
    // free names
    for (names) |n| allocator.free(n);
    allocator.free(names);
    return out;
}

fn parseU32List(allocator: std.mem.Allocator, bytes: []const u8) ![]u32 {
    // Count numbers first (sequences of digits)
    var count: usize = 0;
    var i: usize = 0;
    while (i < bytes.len) : (i += 1) {
        const ch = bytes[i];
        if (ch >= '0' and ch <= '9') {
            count += 1;
            // skip rest of digits
            i += 1;
            while (i < bytes.len and (bytes[i] >= '0' and bytes[i] <= '9')) : (i += 1) {}
        }
    }
    var nums = try allocator.alloc(u32, count);
    var idx: usize = 0;
    i = 0;
    while (i < bytes.len) : (i += 1) {
        const ch = bytes[i];
        if (ch >= '0' and ch <= '9') {
            var v: u64 = (ch - '0');
            i += 1;
            while (i < bytes.len and (bytes[i] >= '0' and bytes[i] <= '9')) : (i += 1) {
                v = v * 10 + (bytes[i] - '0');
            }
            if (v > std.math.maxInt(u32)) return error.ValueTooLarge;
            nums[idx] = @intCast(v);
            idx += 1;
        }
    }
    return nums;
}

fn buildBitmaps32(allocator: std.mem.Allocator, all_numbers: [][]u32) !DataSet {
    var bitmaps = try allocator.alloc(*roaring.Bitmap, all_numbers.len);
    var max_value: u32 = 0;
    var max_card: usize = 0;
    for (all_numbers, 0..) |nums, i| {
        if (nums.len > 0) {
            if (nums[nums.len - 1] > max_value) max_value = nums[nums.len - 1];
        }
        if (nums.len > max_card) max_card = nums.len;
        bitmaps[i] = try roaring.Bitmap.fromSlice(nums);
        _ = bitmaps[i].runOptimize();
        _ = bitmaps[i].shrinkToFit();
    }
    return .{ .allocator = allocator, .bitmaps32 = bitmaps, .max_value = max_value, .max_cardinality = max_card };
}

fn freeBitmaps32(ds: *DataSet) void {
    for (ds.bitmaps32) |bm| bm.free();
    ds.allocator.free(ds.bitmaps32);
}

fn runBenchmarks(allocator: std.mem.Allocator, ds: *const DataSet) !void {
    std.debug.print("data source: {s}\n", .{global_data_source orelse "(unspecified)"});
    std.debug.print("number of bitmaps: {d}\n", .{ds.bitmaps32.len});

    // List of benches: name, function pointer
    const Entry = struct { name: []const u8, func: *const fn (*const DataSet) u64 };
    const benches = [_]Entry{
        .{ .name = "SuccessiveIntersectionCardinality", .func = bench_successive_intersection_cardinality },
        .{ .name = "SuccessiveUnionCardinality", .func = bench_successive_union_cardinality },
        .{ .name = "SuccessiveDifferenceCardinality", .func = bench_successive_difference_cardinality },
        .{ .name = "RandomAccess", .func = bench_random_access },
        .{ .name = "ComputeCardinality", .func = bench_compute_cardinality },
        .{ .name = "IterateAll", .func = bench_iterate_all },
    };

    std.debug.print("\n", .{});
    std.debug.print("benchmark\ttime_ns\tmarker\n", .{});

    for (benches) |b| {
        // Run a few times and take best (min) to reduce noise
        var best: u64 = std.math.maxInt(u64);
        var best_marker: u64 = 0;
        var rep: usize = 0;
        while (rep < 5) : (rep += 1) {
            var t = std.time.Timer.start() catch unreachable;
            const marker = b.func(ds);
            const elapsed = t.read();
            if (elapsed < best) {
                best = elapsed;
                best_marker = marker;
            }
        }
        std.debug.print("{s}\t{d}\t{d}\n", .{ b.name, best, best_marker });
    }
    _ = allocator; // reserved for future counters
}

fn bench_successive_intersection_cardinality(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps32.len) : (i += 1) {
        marker += ds.bitmaps32[i]._andCardinality(ds.bitmaps32[i + 1]);
    }
    return marker;
}

fn bench_successive_union_cardinality(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps32.len) : (i += 1) {
        marker += ds.bitmaps32[i]._orCardinality(ds.bitmaps32[i + 1]);
    }
    return marker;
}

fn bench_successive_difference_cardinality(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps32.len) : (i += 1) {
        marker += ds.bitmaps32[i]._andnotCardinality(ds.bitmaps32[i + 1]);
    }
    return marker;
}

fn bench_random_access(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    const mv = ds.max_value;
    for (ds.bitmaps32) |bm| {
        if (bm.contains(mv / 4)) marker += 1;
        if (bm.contains(mv / 2)) marker += 1;
        if (bm.contains(mv - mv / 4)) marker += 1;
    }
    return marker;
}

fn bench_compute_cardinality(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    for (ds.bitmaps32) |bm| {
        marker += bm.cardinality();
    }
    return marker;
}

fn bench_iterate_all(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    for (ds.bitmaps32) |bm| {
        var it = bm.iterator();
        while (it.hasValue()) {
            marker += 1;
            _ = it.next();
        }
    }
    return marker;
}

var global_data_source: ?[]const u8 = null;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var data_dir: []const u8 = undefined;
    if (args.len <= 1 or (args.len > 1 and args[1].len > 0 and args[1][0] == '-')) {
        // Default to CRoaring realdata census1881 if available
        const home = std.process.getEnvVarOwned(allocator, "HOME") catch null;
        if (home) |h| {
            defer allocator.free(h);
            const def = try std.fs.path.join(allocator, &.{ h, "source", "CRoaring", "benchmarks", "realdata", "census1881" });
            defer allocator.free(def);
            if (std.fs.cwd().openDir(def, .{})) |d| {
                var dir = d; // make mutable to close
                dir.close();
                data_dir = try allocator.dupe(u8, def);
            } else |_| {
                data_dir = "."; // fallback
            }
        } else {
            data_dir = ".";
        }
    } else {
        data_dir = args[1];
    }
    global_data_source = data_dir;

    const numbers = try readAllIntegerFiles(allocator, data_dir);
    if (numbers.len == 0) {
        std.debug.print("No .txt files found in {s}\n", .{data_dir});
        return error.NotFound;
    }

    var ds = try buildBitmaps32(allocator, numbers);
    defer {
        freeBitmaps32(&ds);
        for (numbers) |arr| allocator.free(arr);
        allocator.free(numbers);
        if (global_data_source) |p| allocator.free(p);
    }

    try runBenchmarks(allocator, &ds);
}
