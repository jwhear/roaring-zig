# Zig-Roaring
This library implements Zig bindings for the [CRoaring library](https://github.com/RoaringBitmap/CRoaring).

## Naming
Any C function that begins with `roaring_bitmap_` is a method of the `Bitmap` struct, e.g. `roaring_bitmap_add` becomes `Bitmap.add`.  Because `and` and `or` are Zig keywords, the bitwise operators `and`, `or`, and `xor` are consistently prefixed with an underscore, e.g. `Bitmap._or` and `Bitmap._orCardinality`.
