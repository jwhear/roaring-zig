const std = @import("std");
const roaring = @import("roaring");
const roaring64 = @import("roaring64");

const DataSet = struct {
    allocator: std.mem.Allocator,
    bitmaps32: []*roaring.Bitmap,
    bitmaps64: []*roaring64.Bitmap64,
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

fn buildBitmaps(allocator: std.mem.Allocator, all_numbers: [][]u32) !DataSet {
    var bitmaps = try allocator.alloc(*roaring.Bitmap, all_numbers.len);
    var bitmaps64 = try allocator.alloc(*roaring64.Bitmap64, all_numbers.len);
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

        bitmaps64[i] = try roaring64.Bitmap64.create();
        var j: usize = 0;
        while (j < nums.len) : (j += 1) {
            bitmaps64[i].add(nums[j]);
        }
        _ = bitmaps64[i].runOptimize();
    }
    return .{ .allocator = allocator, .bitmaps32 = bitmaps, .bitmaps64 = bitmaps64, .max_value = max_value, .max_cardinality = max_card };
}

fn freeBitmaps(ds: *DataSet) void {
    for (ds.bitmaps32) |bm| bm.free();
    for (ds.bitmaps64) |bm| bm.free();
    ds.allocator.free(ds.bitmaps32);
    ds.allocator.free(ds.bitmaps64);
}

fn runBenchmarks(allocator: std.mem.Allocator, ds: *const DataSet) !void {
    std.debug.print("data source: {s}\n", .{global_data_source orelse "(unspecified)"});
    std.debug.print("number of bitmaps: {d}\n", .{ds.bitmaps32.len});

    // List of benches: name, function pointer
    const Entry = struct { name: []const u8, func: *const fn (*const DataSet) u64 };
    const benches = [_]Entry{
        .{ .name = "SuccessiveIntersection", .func = bench_successive_intersection },
        .{ .name = "SuccessiveIntersection64", .func = bench_successive_intersection64 },
        .{ .name = "SuccessiveIntersectionCardinality", .func = bench_successive_intersection_cardinality },
        .{ .name = "SuccessiveIntersectionCardinality64", .func = bench_successive_intersection_cardinality64 },
        .{ .name = "SuccessiveUnionCardinality", .func = bench_successive_union_cardinality },
        .{ .name = "SuccessiveUnionCardinality64", .func = bench_successive_union_cardinality64 },
        .{ .name = "SuccessiveDifferenceCardinality", .func = bench_successive_difference_cardinality },
        .{ .name = "SuccessiveDifferenceCardinality64", .func = bench_successive_difference_cardinality64 },
        .{ .name = "SuccessiveUnion", .func = bench_successive_union },
        .{ .name = "SuccessiveUnion64", .func = bench_successive_union64 },
        .{ .name = "TotalUnion", .func = bench_total_union },
        .{ .name = "TotalUnionHeap", .func = bench_total_union_heap },
        .{ .name = "RandomAccess", .func = bench_random_access },
        .{ .name = "RandomAccess64", .func = bench_random_access64 },
        .{ .name = "ComputeCardinality", .func = bench_compute_cardinality },
        .{ .name = "ComputeCardinality64", .func = bench_compute_cardinality64 },
        .{ .name = "RankManySlow", .func = bench_rank_many_slow },
        .{ .name = "RankMany", .func = bench_rank_many },
        .{ .name = "ToArray", .func = bench_to_array },
        .{ .name = "ToArray64", .func = bench_to_array64 },
        .{ .name = "IterateAll", .func = bench_iterate_all },
        .{ .name = "IterateAll64", .func = bench_iterate_all64 },
    };

    std.debug.print("------------------------------------------------------------------------------\n", .{});
    std.debug.print("Benchmark                                    Time             CPU   Iterations\n", .{});
    std.debug.print("------------------------------------------------------------------------------\n", .{});

    for (benches) |b| {
        var total_ns: u64 = 0;
        var iterations: u64 = 0;
        var marker_sum: u64 = 0;
        const target_total_ns: u64 = 1_000_000_000; // 1s per benchmark

        // one warm-up
        marker_sum += b.func(ds);

        var timer = std.time.Timer.start() catch unreachable;
        while (true) {
            marker_sum += b.func(ds);
            iterations += 1;
            total_ns = timer.read();
            if (total_ns >= target_total_ns) break;
        }
        const avg_ns: u64 = if (iterations > 0) total_ns / iterations else 0;
        std.debug.print("{s:<42}{d:12} ns {d:12} ns {d:12}\n", .{ b.name, avg_ns, avg_ns, iterations });
        // prevent optimizer from removing work
        if (marker_sum == 0xDEADBEEFDEADBEEF) @panic("impossible");
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

fn bench_successive_intersection(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps32.len) : (i += 1) {
        var tmp = ds.bitmaps32[i]._and(ds.bitmaps32[i + 1]) catch unreachable;
        marker += tmp.cardinality();
        tmp.free();
    }
    return marker;
}

fn bench_successive_intersection64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps64.len) : (i += 1) {
        var tmp = ds.bitmaps64[i]._and(ds.bitmaps64[i + 1]) catch unreachable;
        marker += tmp.cardinality();
        tmp.free();
    }
    return marker;
}

fn bench_successive_intersection_cardinality64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps64.len) : (i += 1) {
        marker += ds.bitmaps64[i]._andCardinality(ds.bitmaps64[i + 1]);
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

fn bench_successive_union(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps32.len) : (i += 1) {
        var tmp = ds.bitmaps32[i]._or(ds.bitmaps32[i + 1]) catch unreachable;
        marker += tmp.cardinality();
        tmp.free();
    }
    return marker;
}

fn bench_successive_union64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps64.len) : (i += 1) {
        var tmp = ds.bitmaps64[i]._or(ds.bitmaps64[i + 1]) catch unreachable;
        marker += tmp.cardinality();
        tmp.free();
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

fn bench_random_access64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    const mv = ds.max_value;
    for (ds.bitmaps64) |bm| {
        if (bm.contains(mv / 4)) marker += 1;
        if (bm.contains(mv / 2)) marker += 1;
        if (bm.contains(mv - mv / 4)) marker += 1;
    }
    return marker;
}

extern fn cpp_random_access64(handle: ?*const anyopaque, maxvalue: u32) callconv(.c) u64;

fn bench_random_access64_cpp(ds: *const DataSet) u64 {
    return cpp_random_access64(ds.bitmaps64_cpp, ds.max_value);
}

fn bench_compute_cardinality(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    for (ds.bitmaps32) |bm| {
        marker += bm.cardinality();
    }
    return marker;
}

fn bench_compute_cardinality64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    for (ds.bitmaps64) |bm| {
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

fn bench_iterate_all64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    for (ds.bitmaps64) |bm| {
        var it = bm.iterator() catch unreachable;
        defer it.free();
        while (it.hasValue()) {
            marker += 1;
            _ = it.next();
        }
    }
    return marker;
}

fn bench_to_array(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    for (ds.bitmaps32) |bm| {
        const card = bm.cardinality();
        var tmp = std.heap.page_allocator.alloc(u32, @intCast(card)) catch unreachable;
        defer std.heap.page_allocator.free(tmp);
        // The direct to-array API is in CRoaring C; here we skip for parity.
        // Use iterator bulk read instead to simulate work
        var it = bm.iterator();
        var idx: usize = 0;
        while (it.hasValue()) {
            if (idx < tmp.len) tmp[idx] = it.currentValue();
            idx += 1;
            _ = it.next();
        }
        if (tmp.len > 0) marker += tmp[0];
    }
    return marker;
}

fn bench_to_array64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    for (ds.bitmaps64) |bm| {
        const card = bm.cardinality();
        var tmp = std.heap.page_allocator.alloc(u64, @intCast(card)) catch unreachable;
        defer std.heap.page_allocator.free(tmp);
        // No direct to-array in wrapper: iterate
        var it = bm.iterator() catch unreachable;
        defer it.free();
        var idx: usize = 0;
        while (it.hasValue()) {
            if (idx < tmp.len) tmp[idx] = it.currentValue();
            idx += 1;
            _ = it.next();
        }
        if (tmp.len > 0) marker += @intCast(tmp[0] & 0xffffffff);
    }
    return marker;
}

fn bench_total_union(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    const arr = ds.bitmaps32;
    var tmp = roaring.Bitmap._orMany(@ptrCast(@constCast(arr))) catch unreachable;
    marker = tmp.cardinality();
    tmp.free();
    return marker;
}

fn bench_total_union_heap(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    const arr = ds.bitmaps32;
    var tmp = roaring.Bitmap._orManyHeap(@ptrCast(@constCast(arr))) catch unreachable;
    marker = tmp.cardinality();
    tmp.free();
    return marker;
}

fn bench_successive_difference_cardinality64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps64.len) : (i += 1) {
        marker += ds.bitmaps64[i]._andnotCardinality(ds.bitmaps64[i + 1]);
    }
    return marker;
}

fn bench_successive_union_cardinality64(ds: *const DataSet) u64 {
    var marker: u64 = 0;
    var i: usize = 0;
    while (i + 1 < ds.bitmaps64.len) : (i += 1) {
        marker += ds.bitmaps64[i]._orCardinality(ds.bitmaps64[i + 1]);
    }
    return marker;
}

fn bench_rank_many_slow(ds: *const DataSet) u64 {
    var ranks: [5]u64 = .{0} ** 5;
    for (ds.bitmaps32) |bm| {
        ranks[0] = bm.rank(ds.max_value / 5);
        ranks[1] = bm.rank(2 * ds.max_value / 5);
        ranks[2] = bm.rank(3 * ds.max_value / 5);
        ranks[3] = bm.rank(4 * ds.max_value / 5);
        ranks[4] = bm.rank(ds.max_value);
    }
    return ranks[0];
}

fn bench_rank_many(ds: *const DataSet) u64 {
    var ranks: [5]u64 = .{0} ** 5;
    const input: [5]u32 = .{
        ds.max_value / 5, 2 * ds.max_value / 5, 3 * ds.max_value / 5, 4 * ds.max_value / 5, ds.max_value,
    };
    for (ds.bitmaps32) |bm| {
        // Use rank in a loop to simulate bulk; CRoaring uses rank_many API
        var i: usize = 0;
        while (i < input.len) : (i += 1) {
            ranks[i] = bm.rank(input[i]);
        }
    }
    return ranks[0];
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

    var ds = try buildBitmaps(allocator, numbers);
    defer {
        freeBitmaps(&ds);
        for (numbers) |arr| allocator.free(arr);
        allocator.free(numbers);
        if (global_data_source) |p| allocator.free(p);
    }

    try runBenchmarks(allocator, &ds);
}
