const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;
const heap = std.heap;

const roaring = @import("roaring.zig");
const Bitmap = roaring.Bitmap;

test "create + free" {
    var b = try Bitmap.create();
    b.free();
}

test "createWithCapacity + free" {
    var b = try Bitmap.createWithCapacity(100);
    b.free();
}

test "of + free" {
    // From tuple
    var b = try Bitmap.of(.{100, 200});
    b.free();

    // From array
    var arr = [_]u32{100, 200};
    var c = try Bitmap.of(arr);
    c.free();
}

test "add, remove" {
    var b = try Bitmap.create();
    b.add(6);
    b.add(7);
    try expect(b.contains(6));
    try expect(b.contains(7));
    b.remove(6);
    try expect(!b.contains(6));
    b.free();
}

test "and, or" {
    var a = try Bitmap.create();
    defer a.free();
    a.add(7);

    var b = try Bitmap.create();
    defer b.free();
    b.add(2);
    b.add(7);

    var andResult = try a._and(b);
    defer andResult.free();
    try expect(andResult.contains(7));
    try expect(andResult.cardinality() == 1);


    var orResult = try a._or(b);
    defer orResult.free();
    try expect(orResult.contains(2));
    try expect(orResult.contains(7));
    try expect(orResult.cardinality() == 2);
}

test "or many" {
    var bitmaps : [3]*const Bitmap = undefined;
    bitmaps[0] = try Bitmap.fromRange(1,      20, 1);
    bitmaps[1] = try Bitmap.fromRange(101,   120, 1);
    bitmaps[2] = try Bitmap.fromRange(1001, 1020, 1);

    const ret = try Bitmap._orMany(bitmaps[0..]);
    try expect(ret.contains(2));
    try expect(ret.contains(102));
    try expect(ret.contains(1002));
}

test "iterator" {
    var a = try Bitmap.create();
    defer a.free();
    a.add(7);
    a.add(17);
    a.add(27);
    a.add(37);

    var it = a.iterator();
    //while (it.next()) |val| {
        //print("iterator: {}\n", .{ val });
    //}
    try expect(it.next().? == 7);
    try expect(it.next().? == 17);
    try expect(it.next().? == 27);
    try expect(it.next().? == 37);
    try expect(it.next() == null);
    try expect(!it.hasValue());


    //// Let's try starting somewhere else and working backwards
    it = a.iterator();
    _ = it.moveEqualOrLarger(16);
    try expect(it.hasValue());
    try expect(it.previous().? == 17);
    try expect(it.previous().? == 7);
    try expect(it.previous() == null);
    try expect(!it.hasValue());
}

test "frozen" {
    var a = try Bitmap.create();
    defer a.free();
    a.add(7);
    a.add(17);
    a.add(27);
    a.add(37);

    const len = a.frozenSizeInBytes();
    var buf = try roaring.allocForFrozen(heap.page_allocator, len);
    a.frozenSerialize(buf);
    const b = try Bitmap.frozenView(buf[0..]);
    try expect(a.eql(b));
}

test "portable serialize/deserialize" {
    var a = try Bitmap.fromRange(0, 10, 1);
    defer a.free();

    var buf : [1024]u8 = undefined;
    const neededBytes = a.portableSizeInBytes();
    try expect(neededBytes < buf.len);
    try expect(neededBytes == a.portableSerialize(buf[0..]));
    const b = try Bitmap.portableDeserializeSafe(buf[0..]);
    defer b.free();
    try expect(a.eql(b));
}

test "lazy bitwise" {
    var a = try Bitmap.fromRange(0, 10, 1);
    defer a.free();
    var b = try Bitmap.fromRange(5, 15, 1);
    defer b.free();

    var c = try a._orLazy(b, false);
    c.repairAfterLazy();
    try expect(c.eql(try Bitmap.fromRange(0, 15, 1)));

    c._xorLazyInPlace(b);
    c.repairAfterLazy();
    try expect(c.eql(try Bitmap.fromRange(0, 5, 1)));
}

test "select, rank" {
    var a = try Bitmap.fromRange(1, 10, 1);
    defer a.free();

    var third : u32 = 0;
    try expect(a.select(2, &third)); // rank counting starts at 0
    try expect(third == 3);

    try expect(a.rank(3) == 3);
}

test "_andnot" {
    var a = try Bitmap.fromRange(0, 10, 1);
    defer a.free();
    var b = try Bitmap.fromRange(5, 15, 1);
    defer b.free();

    var res = try a._andnot(b);
    try expect(res.eql(try Bitmap.fromRange(0, 5, 1)));
}

test "min & max" {
    var a = try Bitmap.fromRange(0, 10, 1);
    defer a.free();
    try expect(0 == a.minimum());
    try expect(9 == a.maximum());
}

test "catch 'em all" {
    var a = try Bitmap.create();
    defer a.free();
    var b = try Bitmap.createWithCapacity(100);
    defer b.free();

    var c = try Bitmap.fromRange(10, 20, 2);
    defer c.free();

    var vals = [_]u32{ 6, 2, 4 };
    var d = try Bitmap.fromSlice(vals[0..]);
    defer d.free();

    try expect(d.getCopyOnWrite() == false);
    d.setCopyOnWrite(true);
    try expect(d.getCopyOnWrite() == true);

    var e = try d.copy();
    defer e.free();

    _ = e.overwrite(c);

    a.add(17);

    b.addMany(vals[0..]);

    try expect(b.addChecked(13));
    try expect(!b.addChecked(13));

    b.addRangeClosed(20, 30);
    b.addRange(100, 200);

    b.remove(100);
    try expect(!b.removeChecked(200));
    try expect(b.removeChecked(199));

    b.removeMany(vals[0..]);

    b.removeRange(110, 120);
    b.removeRangeClosed(0, 1000);

    b.clear();
    try expect(!b.contains(100));
    try expect(c.contains(12));

    try expect(!c.containsRange(10, 20));

    try expect(b.empty());

    (try a._and(b)).free();
    a._andInPlace(b);
    _ = a._andCardinality(b);

    _ = a.intersect(b);
    _ = a.jaccardIndex(b);

    (try a._or(b)).free();
    a._orInPlace(b);
    (try Bitmap._orMany(&[_]*Bitmap{b, c, d})).free();
    (try Bitmap._orManyHeap(&[_]*Bitmap{b, c, d})).free();
    _ = a._orCardinality(b);


    (try a._xor(b)).free();
    a._xorInPlace(b);
    _ = a._xorCardinality(b);
    (try Bitmap._xorMany(&[_]*Bitmap{b, c, d})).free();

    (try a._andnot(b)).free();
    a._andnotInPlace(b);
    _ = a._andnotCardinality(b);

    (try a.flip(0, 10)).free();
    a.flipInPlace(0, 10);

    (try a._orLazy(b, false)).free();
    a._orLazyInPlace(b, false);
    (try a._xorLazy(b)).free();
    a._xorLazyInPlace(b);
    a.repairAfterLazy();


    var buf: [1024]u8 align(32) = undefined;
    try expect(c.sizeInBytes() <= buf.len);
    var len = c.serialize(buf[0..]);
    var cPrime = try Bitmap.deserialize(buf[0..len]);
    cPrime.free();

    try expect(c.portableSizeInBytes() <= buf.len);
    len = c.portableSerialize(buf[0..]);
    cPrime = try Bitmap.portableDeserialize(buf[0..len]);
    cPrime.free();

    cPrime = try Bitmap.portableDeserializeSafe(buf[0..len]);
    cPrime.free();

    try expect(Bitmap.portableDeserializeSize(buf[0..]) < buf.len);


    len = c.frozenSizeInBytes();
    try expect(len < buf.len);
    c.frozenSerialize(buf[0..]);
    var view : *const Bitmap = try Bitmap.frozenView(buf[0..len]);
    try expect(c.eql(view));

    var f = try Bitmap.fromRange(10, 50, 1);
    defer f.free();
    var g = try Bitmap.fromRange(20, 40, 1);
    defer g.free();
    try expect(g.isSubset(f));
    try expect(g.isStrictSubset(f));

    _ = a.cardinality();
    _ = a.cardinalityRange(0, 100);
    _ = a.minimum();
    _ = a.maximum();

    var el: u32 = 0;
    _ = a.select(3, &el);
    _ = a.rank(3);

    a.printfDescribe();
    a.printf();

    _ = a.removeRunCompression();
    _ = a.runOptimize();
    _ = a.shrinkToFit();

    var it = c.iterator();
    while (it.hasValue()) {
        _ = it.currentValue();
        _ = it.next();
        _ = it.previous();
        _ = it.next();
    }
    _ = it.moveEqualOrLarger(10);
    _ = it.read(vals[0..]);
}


fn iterate_sum(value: u32, data: ?*anyopaque) callconv(.C) bool {
    @ptrCast(*u32, @alignCast(@alignOf(u32), data)).* += value;
    return true;
}

test "iterate" {
    var b = try Bitmap.of(.{1, 2, 3});
    defer b.free();

    var sum: u32 = 0;
    _=b.iterate(iterate_sum, &sum);
    try expect(sum == 6);
}

test "addOffset" {
    var b = try Bitmap.of(.{1, 2, 3});
    defer b.free();

    var c = try b.addOffset(10);
    defer c.free();

    try expect(!c.contains(1));
    try expect(!c.contains(2));
    try expect(!c.contains(3));
    try expect(c.contains(11));
    try expect(c.contains(12));
    try expect(c.contains(13));
}

test "intersectWithRange" {
    var b = try Bitmap.of(.{1, 30, 100});
    defer b.free();

    try expect(!b.intersectWithRange(0, 1));
    try expect(b.intersectWithRange(0, 2));
    try expect(b.intersectWithRange(1, 10));
    try expect(!b.intersectWithRange(2, 10));
    try expect(b.intersectWithRange(1, 100));
}

test "init variants" {
    var a: Bitmap = undefined;
    try a.initWithCapacity(10);
    a.add(450);
    try expect(a.contains(450));
    a.clear();

    a.initCleared();
    a.add(450);
    try expect(a.contains(450));
    a.clear();
}

test "statistics" {
    var a = try Bitmap.of(.{7, 12, 200});
    const stats = a.statistics();
    //std.debug.print("{}\n", .{stats});
    _=stats;
}

test "portableDeserializeFrozen" {
    var a = try Bitmap.fromRange(0, 10, 1);
    defer a.free();

    var buf : [1024]u8 = undefined;
    const neededBytes = a.portableSizeInBytes();
    try expect(neededBytes < buf.len);
    try expect(neededBytes == a.portableSerialize(buf[0..]));
    const b = try Bitmap.portableDeserializeFrozen(buf[0..]);
    defer b.free();
    try expect(a.eql(b));
}

// Run this test last: it sets and then unsets the memory allocator
test "custom allocator" {
    roaring.setAllocator(std.testing.allocator);
    defer roaring.freeAllocator();

    var b = try Bitmap.create();
    b.add(6);
    b.add(7);
    try expect(b.contains(6));
    try expect(b.contains(7));
    b.remove(6);
    try expect(!b.contains(6));
    b.free();
}


