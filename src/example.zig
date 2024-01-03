// This is a port of [C example in the CRoaring project](https://github.com/RoaringBitmap/CRoaring#example-c)

const std = @import("std");
const roaring = @import("roaring.zig");
const Bitmap = roaring.Bitmap;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var allocator = std.heap.c_allocator;

    // create a new empty bitmap
    var r1 = try Bitmap.create();
    // then we can add values
    var i: u32 = 100;
    while (i < 1000) : (i += 1) r1.add(i);
    // check whether a value is contained
    assert(r1.contains(500));
    // compute how many bits there are:
    const cardinality = r1.cardinality();
    print("Cardinality = {} \n", .{cardinality});

    // if your bitmaps have long runs, you can compress them by calling
    // run_optimize
    const expected_size_basic = r1.portableSizeInBytes();
    _ = r1.runOptimize();
    const expected_size_run = r1.portableSizeInBytes();
    print("size before run optimize {} bytes, and after {} bytes\n", .{ expected_size_basic, expected_size_run });

    // create a new bitmap containing the values {1,2,3,5,6}
    var r2 = try Bitmap.of(.{ 5, 1, 2, 3, 5, 6 });
    r2.printf(); // print it

    // we can also create a bitmap from a slice of 32-bit integers
    const somevalues = [_]u32{ 2, 3, 4 };
    var r3 = try Bitmap.fromSlice(&somevalues);

    // NOTE that these functions are not wrapped due to not being memory-safe:
    //   roaring_bitmap_to_uint32_array
    //   roaring_bitmap_range_uint32_array
    // You can invoke them directly and pass `Bitmap.conv(r1)`

    // we can copy and compare bitmaps
    var z = try r3.copy();
    assert(r3.eql(z)); // what we recover is equal
    z.free();

    // we can compute union two-by-two
    var r1_2_3 = try r1._or(r2);
    r1_2_3._orInPlace(r3);

    // we can compute a big union
    var all_my_bitmaps = [_]*const Bitmap{ r1, r2, r3 };
    var big_union = try Bitmap._orMany(&all_my_bitmaps);
    assert(r1_2_3.eql(big_union)); // what we recover is equal
    // can also do the big union with a heap
    var big_union_heap = try Bitmap._orManyHeap(&all_my_bitmaps);
    assert(r1_2_3.eql(big_union_heap));

    r1_2_3.free();
    big_union.free();
    big_union_heap.free();

    // we can compute intersection two-by-two
    var i1_2 = try r1._and(r2);
    i1_2.free();

    // we can write a bitmap to a pointer and recover it later
    const expected_size = r1.portableSizeInBytes();
    var serialized_bytes = try allocator.alloc(u8, expected_size);
    const written_size = r1.portableSerialize(serialized_bytes);
    assert(written_size == expected_size);
    var t = try Bitmap.portableDeserialize(serialized_bytes);
    assert(r1.eql(t)); // what we recover is equal
    t.free();
    // we can also check whether there is a bitmap at a memory location without
    // reading it
    const size_of_bitmap = Bitmap.portableDeserializeSize(serialized_bytes);
    assert(size_of_bitmap ==
        expected_size); // size_of_bitmap would be zero if no bitmap were found
    // we can also read the bitmap "safely" by specifying a byte size limit:
    // Note that in Zig this effectively the same as the "unsafe" version because
    //  both use slices instead of pointers
    t = try Bitmap.portableDeserializeSafe(serialized_bytes);
    assert(r1.eql(t)); // what we recover is equal
    t.free();

    allocator.free(serialized_bytes);

    // we can iterate over all values using custom functions
    var counter: usize = 0;
    _ = r1.iterate(roaring_iterator_sumall, &counter);

    // we can also create iterator structs
    counter = 0;
    var it = r1.iterator();
    while (it.next()) |val| {
        counter += val;
    }
    // you can skip over values and move the iterator with
    // it.previous() or it.moveEqualOrLarger(some_value)

    // In Zig no need to free iterator
    //roaring_free_uint32_iterator(it);

    // for greater speed, you can iterate over the data in bulk
    it = r1.iterator();
    var buffer: [256]u32 = undefined;
    while (true) {
        const ret = it.read(&buffer);
        for (buffer[0..ret]) |el| {
            counter += el;
        }
        if (ret < 256) {
            break;
        }
    }
    // In Zig no need to free iterator
    //roaring_free_uint32_iterator(it);

    r1.free();
    r2.free();
    r3.free();
}

export fn roaring_iterator_sumall(value: u32, param: ?*anyopaque) bool {
    var ptr: *u32 = @ptrCast(@alignCast(param));
    ptr.* += value;
    return true; // iterate till the end
}
