const std = @import("std");
const expect = std.testing.expect;
const heap = std.heap;

const roaring = @import("roaring.zig");
const roaring64 = @import("roaring64.zig");
const Bitmap64 = roaring64.Bitmap64;

fn runCommonSuite() !void {
    // Basic create/add/remove/contains
    var a = try Bitmap64.create();
    defer a.free();
    a.add(6);
    a.add(7);
    try expect(a.contains(6));
    try expect(a.contains(7));
    a.remove(6);
    try expect(!a.contains(6));

    // Bitwise and/or/xor with ranges
    var r1 = try Bitmap64.fromRange(0, 10, 1);
    defer r1.free();
    var r2 = try Bitmap64.fromRange(5, 15, 1);
    defer r2.free();

    var andResult = try r1._and(r2);
    defer andResult.free();
    try expect(andResult.contains(5));

    var orResult = try r1._or(r2);
    defer orResult.free();
    try expect(orResult.contains(2));
    try expect(orResult.contains(12));

    var xorResult = try r1._xor(r2);
    defer xorResult.free();
    try expect(xorResult.contains(2));
    try expect(!xorResult.contains(7));

    // andnot
    var andnotResult = try r1._andnot(r2);
    defer andnotResult.free();
    try expect(andnotResult.contains(0));
    try expect(!andnotResult.contains(7));

    // Min/max/select/rank
    try expect(0 == r1.minimum());
    try expect(9 == r1.maximum());
    var third: u64 = 0;
    _ = r1.select(2, &third);
    try expect(third == 2);
    _ = r1.rank(3);

    // Intersect with range
    try expect(r1.intersectWithRange(0, 2));
    try expect(!r1.intersectWithRange(10, 12));

    // Portable serialization (safe)
    var buf: [4096]u8 = undefined;
    const neededBytes = r2.portableSizeInBytes();
    try expect(neededBytes <= buf.len);
    try expect(neededBytes == r2.portableSerialize(buf[0..]));
    var deser = try Bitmap64.portableDeserializeSafe(buf[0..]);
    defer deser.free();
    try expect(r2.eql(deser));
    try expect(Bitmap64.portableDeserializeSize(buf[0..]) == neededBytes);

    // Frozen view (requires shrink_to_fit first per CRoaring docs)
    _ = r2.shrinkToFit();
    const frozenLen = r2.frozenSizeInBytes();
    var frozenBuf = try roaring.allocForFrozen(heap.page_allocator, frozenLen);
    defer heap.page_allocator.free(frozenBuf);
    r2.frozenSerialize(frozenBuf[0..]);
    const view = try Bitmap64.frozenView(frozenBuf[0..]);
    try expect(r2.eql(view));

    // Iterator bulk read
    var it = try r1.iterator();
    defer it.free();
    var tmp: [128]u64 = undefined;
    var counter: u128 = 0;
    while (true) {
        const n = it.read(tmp[0..]);
        var i: usize = 0;
        while (i < n) : (i += 1) counter += tmp[i];
        if (n < tmp.len) break;
    }
    if (counter == 0) {
        // no-op
    }
}

test "Bitmap64 common suite" {
    try runCommonSuite();
}
