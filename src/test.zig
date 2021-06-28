const Bitmap = @import("roaring.zig").Bitmap;
const expect = @import("std").testing.expect;
const print = @import("std").debug.print;
const heap = @import("std").heap;

pub fn main() void {
}

test "create + free" {
    var b = try Bitmap.create();
    b.free();
}

test "createWithCapacity + free" {
    var b = try Bitmap.createWithCapacity(100);
    b.free();
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
    //while (it.hasValue()) {
        //print("iterator: {}\n", .{ it.currentValue() });
        //_ = it.next();
    //}
    try expect(it.hasValue());
    try expect(it.currentValue() == 7);
    try expect(it.next());
    try expect(it.hasValue());
    try expect(it.currentValue() == 17);
    try expect(it.next());
    try expect(it.hasValue());
    try expect(it.currentValue() == 27);
    try expect(it.next());
    try expect(it.hasValue());
    try expect(it.currentValue() == 37);
    try expect(!it.next());
    try expect(!it.hasValue());


    //// Let's try starting somewhere else and working backwards
    it = a.iterator();
    _ = it.moveEqualOrLarger(16);
    try expect(it.hasValue());
    try expect(it.currentValue() == 17);
    try expect(it.previous());
    try expect(it.hasValue());
    try expect(it.currentValue() == 7);
    try expect(!it.previous());
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
    var buf = try heap.page_allocator.alloc(u8, len);
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

