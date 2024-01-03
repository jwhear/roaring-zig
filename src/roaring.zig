///
/// A note on the design of this binding: initially I built it with a
///  wrapper struct Bitmap that carried the *roaring_bitmap_t handle.
///  This fell apart however because we need to distinguish between const
///  and non-const bitmaps (e.g. frozen_view).  I could have used the
///  wrapper struct strictly in a pointer context but then we'd have
///  double-indirection purely for the sake of nice method style function
///  calling.
/// So here's what I did: I reimplement the roaring_bitmap_t type as
///  Bitmap (really easy, just a single member) and then do compile-time
///  @ptrCast calls (wrapped as from/to with const variants).
const c = @cImport({
    @cInclude("roaring.h");
});
const std = @import("std");

///
pub const RoaringError = error{
    ///
    allocation_failed,
    ///
    frozen_view_failed,
    ///
    deserialize_failed,
};

///
pub const IteratorFunction = fn (u32, ?*anyopaque) callconv(.C) bool;

/// Contains the following u32 fields:
///    n_containers               // number of containers
///    n_array_containers         // number of array containers
///    n_run_containers           // number of run containers
///    n_bitset_containers        // number of bitmap containers
///    n_values_array_containers  // number of values in array containers
///    n_values_run_containers    // number of values in run containers
///    n_values_bitset_containers // number of values in  bitmap containers
///    n_bytes_array_containers   // number of allocated bytes in array containers
///    n_bytes_run_containers     // number of allocated bytes in run containers
///    n_bytes_bitset_containers  // number of allocated bytes in  bitmap containers
///    max_value                  // the maximal value, undefined if cardinality is zero
///    min_value                  // the minimal value, undefined if cardinality is zero
///
/// And the following u64 fields:
///    sum_value   // the sum of all values (could be used to compute average)
///    cardinality // total number of values stored in the bitmap
pub const Statistics = c.roaring_statistics_t;

// Ensure 1:1 equivalence of roaring_bitmap_t and Bitmap
comptime {
    if (@sizeOf(Bitmap) != @sizeOf(c.roaring_bitmap_t)) {
        @compileError("Bitmap and roaring_bitmap_t are not the same size");
    }
}

/// This struct reimplements CRoaring's roaring_bitmap_t type
///  and can be @ptrCast to and from it.
/// (almost) all methods from the roaring_bitmap_t type should be available here.
pub const Bitmap = extern struct {
    high_low_container: c.roaring_array_t,

    //=========================== Type conversions ===========================//
    /// Performs conversions:
    ///  * *roaring_bitmap_t => *Bitmap
    ///  * *const roaring_bitmap_t => *const Bitmap
    ///  * *Bitmap => *roaring_bitmap_t
    ///  * *const Bitmap => *const roaring_bitmap_t
    /// This should be a pure type-system operation and not produce any
    ///  runtime instructions.
    /// You can use this function if you get a raw *roaring_bitmap_t from
    ///  somewhere and want to "convert" it into a *Bitmap. Or vice-versa.
    /// Important: this is simply casting the pointer, not producing any kind
    ///  of copy, make sure you own the memory and know what other pointers
    ///  to the same data are out there.
    pub fn conv(bitmap: anytype) convType(@TypeOf(bitmap)) {
        return @ptrCast(bitmap);
    }

    // Support function for conversion.  Given an input type, produces the
    //  appropriate target type.
    fn convType(comptime T: type) type {
        // We'll just grab the type info, swap out the child field and be done
        // This way const/non-const are handled automatically
        var info = @typeInfo(T);
        info.Pointer.child = switch (info.Pointer.child) {
            c.roaring_bitmap_t => Bitmap,
            Bitmap => c.roaring_bitmap_t,
            else => unreachable, // don't call this with anything else
        };
        return @Type(info); // turn the modified TypeInfo into a type
    }

    //============================= Create/free =============================//

    // Helper function to ensure null bitmaps turn into errors
    fn checkNewBitmap(bitmap: ?*c.roaring_bitmap_t) RoaringError!*Bitmap {
        if (bitmap) |b| {
            return conv(b);
        } else {
            return RoaringError.allocation_failed;
        }
    }

    /// Dynamically allocates a new bitmap (initially empty).
    /// Returns an error if the allocation fails.
    /// Client is responsible for calling `free()`.
    pub fn create() RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_create());
    }

    /// Dynamically allocates a new bitmap (initially empty).
    /// Returns an error if the allocation fails.
    /// Capacity is a performance hint for how many "containers" the data will need.
    /// Client is responsible for calling `free()`.
    pub fn createWithCapacity(capacity: u32) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_create_with_capacity(capacity));
    }

    /// Initialize a roaring bitmap structure in memory controlled by client.
    /// Capacity is a performance hint for how many "containers" the data will need.
    /// Can return false if auxiliary allocations fail when capacity greater than 0.
    ///
    /// Do not use `free` as the bitmap was not allocated by Roaring.  Use `clear`
    ///  to free the contents of the bitmap.
    pub fn initWithCapacity(a: *Bitmap, capacity: u32) RoaringError!void {
        if (!c.roaring_bitmap_init_with_capacity(conv(a), capacity)) return RoaringError.allocation_failed;
    }

    /// Initialize a roaring bitmap structure in memory controlled by client.
    /// The bitmap will be in a "clear" state, with no auxiliary allocations.
    /// Since this performs no allocations, the function will not fail.
    ///
    /// Do not use `free` as the bitmap was not allocated by Roaring.  Use `clear`
    ///  to free the contents of the bitmap.
    pub fn initCleared(a: *Bitmap) void {
        a.initWithCapacity(0) catch unreachable;
    }

    /// Frees the bitmap.  Only use with bitmaps allocated by Roaring. For bitmaps
    ///  allocated by caller, use `clear`.
    pub fn free(self: *Bitmap) void {
        c.roaring_bitmap_free(conv(self));
    }

    /// Create a Bitmap from a tuple or array of u32s
    pub fn of(tup: anytype) RoaringError!*Bitmap {
        const Tup = @TypeOf(tup);
        const isArray = @typeInfo(Tup) == .Array;
        if (comptime !std.meta.trait.isTuple(Tup) and !isArray) {
            @compileError("Bitmap.of takes a tuple or array of u32, got " ++ @typeName(Tup));
        }

        // Little trick to convert a tuple or array to a slice
        const arr: [tup.len]u32 = tup;
        return fromSlice(&arr);
    }

    ///
    pub fn fromRange(min: u64, max: u64, step: u32) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_from_range(min, max, step));
    }

    /// Creates a Bitmap and populates it with integers in `vals`.
    pub fn fromSlice(vals: []const u32) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_of_ptr(vals.len, vals.ptr));
    }

    ///
    pub fn getCopyOnWrite(self: *const Bitmap) bool {
        return c.roaring_bitmap_get_copy_on_write(conv(self));
    }

    /// Whether you want to use copy-on-write.
    /// Saves memory and avoids copies, but needs more care in a threaded context.
    /// Most users should ignore this flag.
    ///
    /// Note: If you do turn this flag to 'true', enabling COW, then ensure that you
    /// do so for all of your bitmaps, since interactions between bitmaps with and
    /// without COW is unsafe.
    pub fn setCopyOnWrite(self: *Bitmap, value: bool) void {
        c.roaring_bitmap_set_copy_on_write(conv(self), value);
    }

    /// Copies a bitmap (this does memory allocation).
    /// The caller is responsible for memory management.
    pub fn copy(self: *const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_copy(conv(self)));
    }

    /// Copies a bitmap from src to dest. It is assumed that the pointer dest
    /// is to an already allocated bitmap. The content of the dest bitmap is
    /// freed/deleted.
    ///
    /// It might be preferable and simpler to call roaring_bitmap_copy except
    /// that roaring_bitmap_overwrite can save on memory allocations.
    pub fn overwrite(dest: *Bitmap, src: *const Bitmap) bool {
        return c.roaring_bitmap_overwrite(conv(dest), conv(src));
    }

    /// Adds the value 'offset' to each and every value in the bitmap, generating
    ///  a new bitmap in the process. If offset + element is outside of the
    ///  range [0,2^32), that the element will be dropped.
    pub fn addOffset(self: *const Bitmap, offset: i64) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_add_offset(conv(self), offset));
    }

    //=========================== Add/remove/test ===========================//
    /// Adds `x` to the bitmap.
    pub fn add(self: *Bitmap, x: u32) void {
        c.roaring_bitmap_add(conv(self), x);
    }

    /// Adds all elements of `vals` to the bitmap.
    pub fn addMany(self: *Bitmap, vals: []u32) void {
        c.roaring_bitmap_add_many(conv(self), vals.len, vals.ptr);
    }

    /// Add value x
    /// Returns true if a new value was added, false if the value already existed.
    pub fn addChecked(self: *Bitmap, x: u32) bool {
        return c.roaring_bitmap_add_checked(conv(self), x);
    }

    /// Add all values in range [min, max]
    pub fn addRangeClosed(self: *Bitmap, start: u32, end: u32) void {
        c.roaring_bitmap_add_range_closed(conv(self), start, end);
    }

    /// Add all values in range [min, max)
    pub fn addRange(self: *Bitmap, start: u64, end: u64) void {
        c.roaring_bitmap_add_range(conv(self), start, end);
    }

    /// Removes `x` from the bitmap
    pub fn remove(self: *Bitmap, x: u32) void {
        c.roaring_bitmap_remove(conv(self), x);
    }

    /// Remove value `x`
    /// Returns true if a new value was removed, false if the value was not existing.
    pub fn removeChecked(self: *Bitmap, x: u32) bool {
        return c.roaring_bitmap_remove_checked(conv(self), x);
    }

    /// Remove multiple values
    pub fn removeMany(self: *Bitmap, vals: []u32) void {
        c.roaring_bitmap_remove_many(conv(self), vals.len, vals.ptr);
    }

    /// Remove all values in range [min, max)
    pub fn removeRange(self: *Bitmap, min: u64, max: u64) void {
        c.roaring_bitmap_remove_range(conv(self), min, max);
    }

    /// Remove all values in range [min, max]
    pub fn removeRangeClosed(self: *Bitmap, min: u32, max: u32) void {
        c.roaring_bitmap_remove_range_closed(conv(self), min, max);
    }

    /// Removes all values from the bitmap
    pub fn clear(self: *Bitmap) void {
        c.roaring_bitmap_clear(conv(self));
    }

    /// Returns true if the bitmap contains `x`
    pub fn contains(self: *const Bitmap, x: u32) bool {
        return c.roaring_bitmap_contains(conv(self), x);
    }

    /// Check whether a range of values from range_start (included)
    ///  to range_end (excluded) is present
    pub fn containsRange(self: *const Bitmap, start: u64, end: u64) bool {
        return c.roaring_bitmap_contains_range(conv(self), start, end);
    }

    /// Returns true if the bitmap contains no values
    pub fn empty(self: *const Bitmap) bool {
        return c.roaring_bitmap_is_empty(conv(self));
    }

    //========================== Bitwise operations ==========================//
    /// Returns a new bitmap representing the logical AND of `a` and `b`
    pub fn _and(a: *const Bitmap, b: *const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_and(conv(a), conv(b)));
    }

    /// Performs a logical AND of `a` and `b`, storing the result in `a`
    pub fn _andInPlace(a: *Bitmap, b: *const Bitmap) void {
        c.roaring_bitmap_and_inplace(conv(a), conv(b));
    }

    /// Returns the number of values in the result of ANDing `a` and `b`
    pub fn _andCardinality(a: *const Bitmap, b: *const Bitmap) u64 {
        return c.roaring_bitmap_and_cardinality(conv(a), conv(b));
    }

    /// Returns true if `a` and `b` intersect (share least one value)
    pub fn intersect(a: *const Bitmap, b: *const Bitmap) bool {
        return c.roaring_bitmap_intersect(conv(a), conv(b));
    }

    /// Check whether a bitmap and a closed range intersect, the range includes
    ///  x but not y.
    pub fn intersectWithRange(self: *const Bitmap, x: u64, y: u64) bool {
        return c.roaring_bitmap_intersect_with_range(conv(self), x, y);
    }

    /// Computes the Jaccard index between two bitmaps. (Also known as the Tanimoto
    ///  distance, or the Jaccard similarity coefficient)
    ///
    /// The Jaccard index is undefined if both bitmaps are empty.
    pub fn jaccardIndex(a: *const Bitmap, b: *const Bitmap) f64 {
        return c.roaring_bitmap_jaccard_index(conv(a), conv(b));
    }

    /// Returns a new bitmap representing the logical OR of `a` and `b`
    pub fn _or(a: *const Bitmap, b: *const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_or(conv(a), conv(b)));
    }

    /// Performs a logical OR of `a` and `b`, storing the result in `a`
    pub fn _orInPlace(a: *Bitmap, b: *const Bitmap) void {
        c.roaring_bitmap_or_inplace(conv(a), conv(b));
    }

    /// Performs a logical OR of all `bitmaps`, returning a new bitmap
    pub fn _orMany(bitmaps: []*const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_or_many(@as(u32, @intCast(bitmaps.len)), @as([*c][*c]const c.roaring_bitmap_t, @ptrCast(bitmaps.ptr))));
    }

    /// Compute the union of `bitmaps` using a heap. This can sometimes be
    ///  faster than `_orMany()` which uses a naive algorithm.
    pub fn _orManyHeap(bitmaps: []*const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_or_many_heap(@as(u32, @intCast(bitmaps.len)), @as([*c][*c]const c.roaring_bitmap_t, @ptrCast(bitmaps.ptr))));
    }

    /// Returns the number of values in the result of ORing `a` and `b`
    pub fn _orCardinality(a: *const Bitmap, b: *const Bitmap) usize {
        return c.roaring_bitmap_or_cardinality(conv(a), conv(b));
    }

    /// Returns a new bitmap representing the logical XOR between `a` and `b`
    pub fn _xor(a: *const Bitmap, b: *const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_xor(conv(a), conv(b)));
    }

    /// Performs a logical XOR of `a` and `b`, storing the result in `a`
    pub fn _xorInPlace(a: *Bitmap, b: *const Bitmap) void {
        c.roaring_bitmap_xor_inplace(conv(a), conv(b));
    }

    ///
    pub fn _xorCardinality(a: *const Bitmap, b: *const Bitmap) usize {
        return c.roaring_bitmap_xor_cardinality(conv(a), conv(b));
    }

    ///
    pub fn _xorMany(bitmaps: []*const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_xor_many(@as(u32, @intCast(bitmaps.len)), @as([*c][*c]const c.roaring_bitmap_t, @ptrCast(bitmaps.ptr))));
    }

    ///
    pub fn _andnot(a: *const Bitmap, b: *const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_andnot(conv(a), conv(b)));
    }

    ///
    pub fn _andnotInPlace(a: *Bitmap, b: *const Bitmap) void {
        c.roaring_bitmap_andnot_inplace(conv(a), conv(b));
    }

    ///
    pub fn _andnotCardinality(a: *const Bitmap, b: *const Bitmap) usize {
        return c.roaring_bitmap_andnot_cardinality(conv(a), conv(b));
    }

    ///
    pub fn flip(self: *const Bitmap, start: u64, end: u64) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_flip(conv(self), start, end));
    }

    ///
    pub fn flipInPlace(self: *Bitmap, start: u64, end: u64) void {
        c.roaring_bitmap_flip_inplace(conv(self), start, end);
    }

    //======================= Lazy bitwise operations =======================//
    /// (For expert users who seek high performance.)
    ///
    /// Computes the union between two bitmaps and returns new bitmap. The caller is
    /// responsible for memory management.
    ///
    /// The lazy version defers some computations such as the maintenance of the
    /// cardinality counts. Thus you must call `roaring_bitmap_repair_after_lazy()`
    /// after executing "lazy" computations.
    ///
    /// It is safe to repeatedly call roaring_bitmap_lazy_or_inplace on the result.
    ///
    /// `bitsetconversion` is a flag which determines whether container-container
    /// operations force a bitset conversion.
    pub fn _orLazy(a: *const Bitmap, b: *const Bitmap, convert: bool) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_lazy_or(conv(a), conv(b), convert));
    }

    /// (For expert users who seek high performance.)
    ///
    /// Inplace version of roaring_bitmap_lazy_or, modifies r1.
    ///
    /// `bitsetconversion` is a flag which determines whether container-container
    /// operations force a bitset conversion.
    pub fn _orLazyInPlace(a: *Bitmap, b: *const Bitmap, convert: bool) void {
        c.roaring_bitmap_lazy_or_inplace(conv(a), conv(b), convert);
    }

    /// Computes the symmetric difference between two bitmaps and returns new bitmap.
    /// The caller is responsible for memory management.
    ///
    /// The lazy version defers some computations such as the maintenance of the
    /// cardinality counts. Thus you must call `roaring_bitmap_repair_after_lazy()`
    /// after executing "lazy" computations.
    ///
    /// It is safe to repeatedly call `roaring_bitmap_lazy_xor_inplace()` on
    /// the result.
    pub fn _xorLazy(a: *const Bitmap, b: *const Bitmap) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_lazy_xor(conv(a), conv(b)));
    }

    /// (For expert users who seek high performance.)
    ///
    /// Inplace version of roaring_bitmap_lazy_xor, modifies r1. r1 != r2
    pub fn _xorLazyInPlace(a: *Bitmap, b: *const Bitmap) void {
        c.roaring_bitmap_lazy_xor_inplace(conv(a), conv(b));
    }

    /// (For expert users who seek high performance.)
    ///
    /// Execute maintenance on a bitmap created from `roaring_bitmap_lazy_or()`
    /// or modified with `roaring_bitmap_lazy_or_inplace()`.
    pub fn repairAfterLazy(a: *Bitmap) void {
        c.roaring_bitmap_repair_after_lazy(conv(a));
    }

    //============================ Serialization ============================//
    ///
    pub fn serialize(self: *const Bitmap, buf: []u8) usize {
        return c.roaring_bitmap_serialize(conv(self), buf.ptr);
    }

    /// Uses `roaring_bitmap_deserialize_safe` under the hood
    pub fn deserialize(buf: []const u8) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_deserialize_safe(buf.ptr, buf.len));
    }
    pub const deserializeSafe = deserialize;

    ///
    pub fn sizeInBytes(self: *const Bitmap) usize {
        return c.roaring_bitmap_size_in_bytes(conv(self));
    }

    /// Write a bitmap to a char buffer.  The output buffer should refer to at least
    /// `portableSizeInBytes()` bytes of allocated memory.
    ///
    /// Returns how many bytes were written which should match `portableSizeInBytes()`.
    ///
    /// This is meant to be compatible with the Java and Go versions:
    /// https://github.com/RoaringBitmap/RoaringFormatSpec
    pub fn portableSerialize(self: *const Bitmap, buf: []u8) usize {
        return c.roaring_bitmap_portable_serialize(conv(self), buf.ptr);
    }

    ///
    pub fn portableDeserialize(buf: []const u8) RoaringError!*Bitmap {
        return checkNewBitmap(c.roaring_bitmap_portable_deserialize(buf.ptr));
    }

    ///
    pub fn portableDeserializeSafe(buf: []const u8) RoaringError!*Bitmap {
        if (c.roaring_bitmap_portable_deserialize_safe(buf.ptr, buf.len)) |b| {
            return conv(b);
        } else {
            return RoaringError.deserialize_failed;
        }
    }

    /// Read bitmap from a serialized buffer.
    ///
    /// Bitmap returned by this function can be used in all readonly contexts.
    /// Bitmap must be freed as usual, by calling `free`.
    /// Underlying buffer must not be freed or modified while it backs any bitmaps.
    ///
    /// The function is unsafe in the following ways:
    /// 1) It may execute unaligned memory accesses.
    /// 2) A buffer overflow may occure if buf does not point to a valid serialized
    ///    bitmap.
    ///
    /// This is meant to be compatible with the Java and Go versions:
    /// https://github.com/RoaringBitmap/RoaringFormatSpec
    ///
    /// This function is endian-sensitive. If you have a big-endian system (e.g., a mainframe IBM s390x),
    /// the data format is going to be big-endian and not compatible with little-endian systems.
    pub fn portableDeserializeFrozen(buf: []const u8) RoaringError!*Bitmap {
        if (c.roaring_bitmap_portable_deserialize_frozen(buf.ptr)) |b| {
            return conv(b);
        } else {
            return RoaringError.deserialize_failed;
        }
    }

    ///
    pub fn portableDeserializeSize(buf: []const u8) usize {
        return c.roaring_bitmap_portable_deserialize_size(buf.ptr, buf.len);
    }

    ///
    pub fn portableSizeInBytes(self: *const Bitmap) usize {
        return c.roaring_bitmap_portable_size_in_bytes(conv(self));
    }

    //========================= Frozen functionality =========================//
    ///
    pub fn frozenSizeInBytes(self: *const Bitmap) usize {
        return c.roaring_bitmap_frozen_size_in_bytes(conv(self));
    }

    ///
    pub fn frozenSerialize(self: *const Bitmap, buf: []u8) void {
        c.roaring_bitmap_frozen_serialize(conv(self), buf.ptr);
    }

    /// Returns a read-only Bitmap, backed by the bytes in `buf`.  You must not
    ///  free or alter the bytes in `buf` while the view bitmap is alive.
    /// `buf` must be 32-byte aligned and exactly the length that was reported
    ///  by `frozenSizeInBytes`.
    pub fn frozenView(buf: []align(32) u8) RoaringError!*const Bitmap {
        return conv(c.roaring_bitmap_frozen_view(buf.ptr, buf.len) orelse return RoaringError.frozen_view_failed);
    }

    //============================== Comparison ==============================//
    /// Returns true if the two bitmaps contain exactly the same elements.
    pub fn eql(a: *const Bitmap, b: *const Bitmap) bool {
        return c.roaring_bitmap_equals(conv(a), conv(b));
    }

    /// Return true if all the elements of r1 are also in r2.
    pub fn isSubset(a: *const Bitmap, b: *const Bitmap) bool {
        return c.roaring_bitmap_is_subset(conv(a), conv(b));
    }

    /// Return true if all the elements of r1 are also in r2, and r2 is strictly
    ///  greater than r1.
    pub fn isStrictSubset(a: *const Bitmap, b: *const Bitmap) bool {
        return c.roaring_bitmap_is_strict_subset(conv(a), conv(b));
    }

    //============================ Miscellaneous ============================//
    ///
    pub fn cardinality(self: *const Bitmap) u64 {
        return c.roaring_bitmap_get_cardinality(conv(self));
    }

    /// Returns the number of elements in the range [range_start, range_end).
    pub fn cardinalityRange(self: *const Bitmap, start: u64, end: u64) u64 {
        return c.roaring_bitmap_range_cardinality(conv(self), start, end);
    }

    ///
    pub fn minimum(self: *const Bitmap) u32 {
        return c.roaring_bitmap_minimum(conv(self));
    }

    ///
    pub fn maximum(self: *const Bitmap) u32 {
        return c.roaring_bitmap_maximum(conv(self));
    }

    /// Selects the element at index 'rank' where the smallest element is at index 0.
    /// If the size of the roaring bitmap is strictly greater than rank, then this
    /// function returns true and sets element to the element of given rank.
    /// Otherwise, it returns false.
    pub fn select(self: *const Bitmap, rnk: u32, element: *u32) bool {
        return c.roaring_bitmap_select(conv(self), rnk, element);
    }

    /// Returns the number of integers that are smaller or equal to x.
    /// Thus if x is the first element, this function will return 1. If
    /// x is smaller than the smallest element, this function will return 0.
    ///
    /// The indexing convention differs between `select` and `rank`:
    ///  `select` refers to the smallest value as having index 0, whereas `rank`
    ///   returns 1 when ranking the smallest value.
    pub fn rank(self: *const Bitmap, x: u32) u64 {
        return c.roaring_bitmap_rank(conv(self), x);
    }

    /// Describe the inner structure of the bitmap.
    pub fn printfDescribe(self: *const Bitmap) void {
        c.roaring_bitmap_printf_describe(conv(self));
    }

    ///
    pub fn printf(self: *const Bitmap) void {
        c.roaring_bitmap_printf(conv(self));
    }

    /// (For advanced users.)
    /// Collect statistics about the bitmap, see roaring_types.h for a description
    ///  of roaring_statistics_t
    /// Writes statistics into `stat`.
    pub fn statistics(self: *const Bitmap) Statistics {
        var out: Statistics = undefined;
        c.roaring_bitmap_statistics(conv(self), &out);
        return out;
    }

    //============================= Optimization =============================//
    /// Remove run-length encoding even when it is more space efficient.
    /// Return whether a change was applied.
    pub fn removeRunCompression(self: *Bitmap) bool {
        return c.roaring_bitmap_remove_run_compression(conv(self));
    }

    /// Convert array and bitmap containers to run containers when it is more
    /// efficient; also convert from run containers when more space efficient.
    ///
    /// Returns true if the result has at least one run container.
    /// Additional savings might be possible by calling `shrinkToFit()`.
    pub fn runOptimize(self: *Bitmap) bool {
        return c.roaring_bitmap_run_optimize(conv(self));
    }

    /// If needed, reallocate memory to shrink the memory usage.
    /// Returns the number of bytes saved.
    pub fn shrinkToFit(self: *Bitmap) usize {
        return c.roaring_bitmap_shrink_to_fit(conv(self));
    }

    //============================== Iteration ==============================//
    ///
    const Iterator = struct {
        i: c.roaring_uint32_iterator_t,

        ///
        pub fn hasValue(self: Iterator) bool {
            return self.i.has_value;
        }

        ///
        pub fn currentValue(self: Iterator) u32 {
            return self.i.current_value;
        }

        ///
        pub fn next(self: *Iterator) ?u32 {
            // Advance after we've extracted the current value
            defer _ = c.roaring_advance_uint32_iterator(&self.i);
            return if (self.hasValue()) self.currentValue() else null;
        }

        ///
        pub fn previous(self: *Iterator) ?u32 {
            // Advance after we've extracted the current value
            defer _ = c.roaring_previous_uint32_iterator(&self.i);
            return if (self.hasValue()) self.currentValue() else null;
        }

        ///
        pub fn moveEqualOrLarger(self: *Iterator, x: u32) bool {
            return c.roaring_move_uint32_iterator_equalorlarger(&self.i, x);
        }

        /// Attempts to fill `buffer`.  Returns the number of elements read.
        pub fn read(self: *Iterator, buf: []u32) u32 {
            return c.roaring_read_uint32_iterator(&self.i, buf.ptr, @as(u32, @intCast(buf.len)));
        }
    };

    ///
    pub fn iterator(self: *const Bitmap) Iterator {
        var ret: Iterator = undefined;
        c.roaring_init_iterator(conv(self), &ret.i);
        return ret;
    }

    ///
    pub fn iterate(self: *const Bitmap, func: *const IteratorFunction, data: anytype) bool {
        return c.roaring_iterate(conv(self), func, data);
    }
};

/// Helper function to get properly aligned and sized buffers for
///  frozenSerialize/frozenView
pub fn allocForFrozen(allocator: std.mem.Allocator, len: usize) ![]align(32) u8 {
    // The buffer must be 32-byte aligned and sized exactly
    return allocator.alignedAlloc(u8, 32, // alignment
        len);
}

/// Sets the global Roaring memory allocator.  Because of limitations in the CRoaring
///  API, you should generally only invoke this once.  Call `freeAllocator` to cleanup
///  related bookkeeping.
pub fn setAllocator(allocator: std.mem.Allocator) void {
    global_roaring_allocator = allocator;
    c.roaring_init_memory_hook(.{
        .malloc = roaringMalloc,
        .realloc = roaringRealloc,
        .calloc = roaringCalloc,
        .free = roaringFree,
        .aligned_malloc = roaringAlignedMalloc,
        .aligned_free = roaringFree, // don't need a special implementation
    });
}

/// The global Roaring allocator is used for bookkeeping; this function frees
///  that memory.  The C API does not expose a way to reset memory functions to
///  their defaults, so you only use this when you're done using Bitmaps.
pub fn freeAllocator() void {
    if (global_roaring_allocator) |ally| {
        allocations.deinit(ally);
    }
}

/// Roaring only supports a single, global allocator
var global_roaring_allocator: ?std.mem.Allocator = null;

// The roaring_resize function uses pointers instead of slices, making functions
//  like `realloc` tricky as the Allocator interface expects slices.  This means
//  that we have to track the lengths associated with allocations somehow.
// A relatively cheap implementation would prefix allocations with a header to
//  store the length, but this makes aligned allocations really challenging.
// This implementation uses a hash map where the pointers are the keys and the
//  values are the lengths.
var allocations = std.AutoHashMapUnmanaged(?*anyopaque, usize){};

fn setAllocation(mem: []u8) ?*anyopaque {
    if (global_roaring_allocator) |ally| {
        const ptr = @as(?*anyopaque, @ptrCast(mem.ptr));
        allocations.put(ally, ptr, mem.len) catch return null;
        return ptr;
    }
    @panic("global_roaring_allocator is not set");
}

fn getAllocation(ptr: ?*anyopaque) []u8 {
    var len = allocations.get(ptr) orelse @panic("getAllocation cannot find pointer");
    return @as([*]u8, @ptrCast(ptr))[0..len];
}

fn getRemoveAllocation(ptr: ?*anyopaque) []u8 {
    var kv = allocations.fetchRemove(ptr) orelse @panic("removeAllocationn cannot find pointer");
    return @as([*c]u8, @ptrCast(ptr))[0..kv.value];
}

export fn roaringMalloc(size: usize) ?*anyopaque {
    if (global_roaring_allocator) |ally| {
        return setAllocation(ally.alloc(u8, size) catch return null);
    }
    return null;
}

export fn roaringRealloc(ptr: ?*anyopaque, size: usize) ?*anyopaque {
    //NOTE: from `man realloc`:
    // If ptr is NULL, then the call is equivalent to malloc(size), for all
    //  values of size; if size is equal to zero, and ptr is not NULL, then
    //  the call is equivalent to free(ptr)

    if (ptr == null) {
        return roaringMalloc(size);
    } else if (size == 0) {
        roaringFree(ptr);
        return null;
    } else if (global_roaring_allocator) |ally| {
        const old = getAllocation(ptr);
        return setAllocation(ally.realloc(old, size) catch return null);
    } else return null;
}

export fn roaringCalloc(n_memb: usize, memb_size: usize) ?*anyopaque {
    const size = n_memb * memb_size;
    const ret = roaringMalloc(size);
    if (ret != null) {
        var slice = @as([*]u8, @ptrCast(ret));
        @memset(slice[0..size], 0);
    }
    return ret;
}

export fn roaringFree(ptr: ?*anyopaque) void {
    // Freeing the null pointer is OK, roaring does it
    if (ptr == null) return;

    if (global_roaring_allocator) |ally| {
        ally.free(getRemoveAllocation(ptr));
    } else @panic("roaringFree was called but global_roaring_allocator is not set");
}

export fn roaringAlignedMalloc(ptr_align: usize, size: usize) ?*anyopaque {
    if (global_roaring_allocator) |ally| {
        return setAllocation(
        // Allocator's alignment parameter has to be comptime known, so we
        //  have to do this somewhat awkward transform:
        switch (ptr_align) {
            8 => ally.alignedAlloc(u8, 8, size),
            16 => ally.alignedAlloc(u8, 16, size),
            // This appears to be the only value that is actually used in roaring.c
            32 => ally.alignedAlloc(u8, 32, size),
            else => @panic("Unexpected alignment size"),
        } catch return null);
    }
    return null;
}
