///
/// 64-bit Roaring Bitmap wrapper for CRoaring's `roaring64_bitmap_t`.
///
/// This module mirrors the public shape of `src/roaring.zig` where possible,
/// providing a `Bitmap64` type with methods that forward to the 64-bit C API
/// (functions prefixed with `roaring64_...`). Some APIs present in the 32-bit
/// wrapper do not exist in the 64-bit C surface (e.g., copy-on-write toggles,
/// lazy bitwise ops, or-many helpers), so they are intentionally omitted here.
///
/// Notes:
/// - `Bitmap64` is defined as `opaque` because `roaring64_bitmap_t` is opaque in
///   the public header. All methods operate via pointers and cast at comptime.
/// - Use `roaring.allocForFrozen` from `roaring.zig` to allocate 32-byte aligned
///   buffers for frozen serialization when needed.
/// - The iterator for 64-bit bitmaps allocates; you must call `Iterator.free()`.
///
const std = @import("std");
const roaring = @import("roaring.zig");
const c = @cImport({
    @cInclude("roaring.h");
});

/// Error set shared with 32-bit wrapper
pub const RoaringError = roaring.RoaringError;

/// Callback signature for 64-bit iteration (`roaring64_bitmap_iterate`)
pub const IteratorFunction = fn (u64, ?*anyopaque) callconv(.c) bool;

/// 64-bit statistics struct from CRoaring
pub const Statistics = c.roaring64_statistics_t;

/// 64-bit Roaring Bitmap. Opaque; only used via `*Bitmap64` pointers.
pub const Bitmap64 = opaque {
    //=========================== Type conversions ============================//
    /// Performs conversions:
    ///  * *roaring64_bitmap_t => *Bitmap64
    ///  * *const roaring64_bitmap_t => *const Bitmap64
    ///  * *Bitmap64 => *roaring64_bitmap_t
    ///  * *const Bitmap64 => *const roaring64_bitmap_t
    /// This is a compile-time only pointer cast without runtime cost.
    pub fn conv(bitmap: anytype) convType(@TypeOf(bitmap)) {
        return @ptrCast(bitmap);
    }

    // Support function for conversion. Given an input pointer type, produces the
    // appropriate target pointer type.
    fn convType(comptime T: type) type {
        var info = @typeInfo(T);
        switch (info) {
            .pointer => |*ptr_info| {
                ptr_info.child = switch (ptr_info.child) {
                    c.roaring64_bitmap_t => Bitmap64,
                    Bitmap64 => c.roaring64_bitmap_t,
                    else => @compileError("Bitmap64.conv: unexpected pointee type"),
                };
            },
            else => @compileError("Bitmap64.conv: only pointers are supported"),
        }
        return @Type(info);
    }

    // Helper to convert null bitmaps into allocation_failed errors
    fn checkNewBitmap(bitmap: ?*c.roaring64_bitmap_t) RoaringError!*Bitmap64 {
        if (bitmap) |b| {
            return conv(b);
        } else {
            return RoaringError.allocation_failed;
        }
    }

    //================================ Create/free ============================//

    /// Dynamically allocates a new 64-bit bitmap (initially empty).
    /// Client is responsible for calling `free()`.
    pub fn create() RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_create());
    }

    /// Copies a bitmap (does allocation). Caller frees the result with `free`.
    pub fn copy(self: *const Bitmap64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_copy(conv(self)));
    }

    /// Frees the bitmap. Only use with bitmaps allocated by CRoaring.
    pub fn free(self: *Bitmap64) void {
        c.roaring64_bitmap_free(conv(self));
    }

    /// Create a Bitmap64 from a tuple or array of u64s
    pub fn of(tup: anytype) RoaringError!*Bitmap64 {
        const Tup = @TypeOf(tup);
        const type_info = @typeInfo(Tup);

        const supported = comptime switch (type_info) {
            .array => |info| info.child == u64 or info.child == usize,
            .@"struct" => |info| info.is_tuple and blk: {
                for (std.meta.fields(Tup)) |field| {
                    if (field.type != u64 and field.type != comptime_int) break :blk false;
                }
                break :blk true;
            },
            .pointer => |info| info.size == .slice and info.child == u64,
            else => false,
        };

        if (supported) {
            const arr: [tup.len]u64 = tup;
            return fromSlice(&arr);
        }

        @compileError("Bitmap64.of takes a tuple or array of u64, got " ++ @typeName(Tup));
    }

    /// Creates a Bitmap64 and populates it with integers in `vals`.
    pub fn fromSlice(vals: []const u64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_of_ptr(vals.len, vals.ptr));
    }

    /// Creates a Bitmap64 with integers in [min, max) at the given step.
    pub fn fromRange(min: u64, max: u64, step: u64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_from_range(min, max, step));
    }

    //============================= Add/remove/test ===========================//

    /// Adds `x` to the bitmap.
    pub fn add(self: *Bitmap64, x: u64) void {
        c.roaring64_bitmap_add(conv(self), x);
    }

    /// Adds all elements of `vals` to the bitmap.
    pub fn addMany(self: *Bitmap64, vals: []u64) void {
        c.roaring64_bitmap_add_many(conv(self), vals.len, vals.ptr);
    }

    /// Add value `x`. Returns true if a new value was added.
    pub fn addChecked(self: *Bitmap64, x: u64) bool {
        return c.roaring64_bitmap_add_checked(conv(self), x);
    }

    /// Add all values in range [start, end)
    pub fn addRange(self: *Bitmap64, start: u64, end: u64) void {
        c.roaring64_bitmap_add_range(conv(self), start, end);
    }

    /// Add all values in range [start, end]
    pub fn addRangeClosed(self: *Bitmap64, start: u64, end: u64) void {
        c.roaring64_bitmap_add_range_closed(conv(self), start, end);
    }

    /// Removes `x` from the bitmap
    pub fn remove(self: *Bitmap64, x: u64) void {
        c.roaring64_bitmap_remove(conv(self), x);
    }

    /// Remove value `x`. Returns true if a value was removed.
    pub fn removeChecked(self: *Bitmap64, x: u64) bool {
        return c.roaring64_bitmap_remove_checked(conv(self), x);
    }

    /// Remove multiple values
    pub fn removeMany(self: *Bitmap64, vals: []u64) void {
        c.roaring64_bitmap_remove_many(conv(self), vals.len, vals.ptr);
    }

    /// Remove all values in range [min, max)
    pub fn removeRange(self: *Bitmap64, min: u64, max: u64) void {
        c.roaring64_bitmap_remove_range(conv(self), min, max);
    }

    /// Remove all values in range [min, max]
    pub fn removeRangeClosed(self: *Bitmap64, min: u64, max: u64) void {
        c.roaring64_bitmap_remove_range_closed(conv(self), min, max);
    }

    /// Removes all values from the bitmap
    pub fn clear(self: *Bitmap64) void {
        c.roaring64_bitmap_clear(conv(self));
    }

    //============================= Optimization =============================//

    /// Convert array/bitmap containers to runs when more efficient; may also convert back.
    /// Returns true if the result has at least one run container.
    pub fn runOptimize(self: *Bitmap64) bool {
        return c.roaring64_bitmap_run_optimize(conv(self));
    }

    /// If needed, reallocate memory to shrink usage. Returns number of bytes saved.
    pub fn shrinkToFit(self: *Bitmap64) usize {
        return c.roaring64_bitmap_shrink_to_fit(conv(self));
    }

    /// Returns true if the bitmap contains `x`
    pub fn contains(self: *const Bitmap64, x: u64) bool {
        return c.roaring64_bitmap_contains(conv(self), x);
    }

    /// Check whether a range [start, end) is fully present
    pub fn containsRange(self: *const Bitmap64, start: u64, end: u64) bool {
        return c.roaring64_bitmap_contains_range(conv(self), start, end);
    }

    /// Returns true if the bitmap contains no values
    pub fn empty(self: *const Bitmap64) bool {
        return c.roaring64_bitmap_is_empty(conv(self));
    }

    //========================== Bitwise operations ===========================//

    /// Returns a new bitmap representing the logical AND of `a` and `b`
    pub fn _and(a: *const Bitmap64, b: *const Bitmap64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_and(conv(a), conv(b)));
    }

    /// Performs a logical AND of `a` and `b`, storing the result in `a`
    pub fn _andInPlace(a: *Bitmap64, b: *const Bitmap64) void {
        c.roaring64_bitmap_and_inplace(conv(a), conv(b));
    }

    /// Returns the number of values in the result of ANDing `a` and `b`
    pub fn _andCardinality(a: *const Bitmap64, b: *const Bitmap64) u64 {
        return c.roaring64_bitmap_and_cardinality(conv(a), conv(b));
    }

    /// Returns true if `a` and `b` intersect
    pub fn intersect(a: *const Bitmap64, b: *const Bitmap64) bool {
        return c.roaring64_bitmap_intersect(conv(a), conv(b));
    }

    /// Check whether a bitmap and a closed range intersect, range includes x but not y
    pub fn intersectWithRange(self: *const Bitmap64, x: u64, y: u64) bool {
        return c.roaring64_bitmap_intersect_with_range(conv(self), x, y);
    }

    /// Jaccard index between two bitmaps
    pub fn jaccardIndex(a: *const Bitmap64, b: *const Bitmap64) f64 {
        return c.roaring64_bitmap_jaccard_index(conv(a), conv(b));
    }

    /// Returns a new bitmap representing the logical OR of `a` and `b`
    pub fn _or(a: *const Bitmap64, b: *const Bitmap64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_or(conv(a), conv(b)));
    }

    /// Performs a logical OR of `a` and `b`, storing the result in `a`
    pub fn _orInPlace(a: *Bitmap64, b: *const Bitmap64) void {
        c.roaring64_bitmap_or_inplace(conv(a), conv(b));
    }

    /// Returns the number of values in the result of ORing `a` and `b`
    pub fn _orCardinality(a: *const Bitmap64, b: *const Bitmap64) u64 {
        return c.roaring64_bitmap_or_cardinality(conv(a), conv(b));
    }

    /// Returns a new bitmap representing the logical XOR of `a` and `b`
    pub fn _xor(a: *const Bitmap64, b: *const Bitmap64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_xor(conv(a), conv(b)));
    }

    /// Performs a logical XOR of `a` and `b`, storing the result in `a`
    pub fn _xorInPlace(a: *Bitmap64, b: *const Bitmap64) void {
        c.roaring64_bitmap_xor_inplace(conv(a), conv(b));
    }

    /// Returns the number of values in the result of XORing `a` and `b`
    pub fn _xorCardinality(a: *const Bitmap64, b: *const Bitmap64) u64 {
        return c.roaring64_bitmap_xor_cardinality(conv(a), conv(b));
    }

    /// Returns a new bitmap representing `a` AND NOT `b`
    pub fn _andnot(a: *const Bitmap64, b: *const Bitmap64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_andnot(conv(a), conv(b)));
    }

    /// Performs a logical AND NOT of `a` and `b`, storing the result in `a`
    pub fn _andnotInPlace(a: *Bitmap64, b: *const Bitmap64) void {
        c.roaring64_bitmap_andnot_inplace(conv(a), conv(b));
    }

    /// Returns the number of values in the result of AND NOT of `a` and `b`
    pub fn _andnotCardinality(a: *const Bitmap64, b: *const Bitmap64) u64 {
        return c.roaring64_bitmap_andnot_cardinality(conv(a), conv(b));
    }

    /// Flip bits in [start, end) and return a new bitmap
    pub fn flip(self: *const Bitmap64, start: u64, end: u64) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_flip(conv(self), start, end));
    }

    /// In-place flip of bits in [start, end)
    pub fn flipInPlace(self: *Bitmap64, start: u64, end: u64) void {
        c.roaring64_bitmap_flip_inplace(conv(self), start, end);
    }

    //============================= Serialization =============================//

    /// Number of bytes required for portable serialization
    pub fn portableSizeInBytes(self: *const Bitmap64) usize {
        return c.roaring64_bitmap_portable_size_in_bytes(conv(self));
    }

    /// Write a bitmap to a char buffer using the portable format.
    /// The output buffer should refer to at least `portableSizeInBytes()` bytes.
    pub fn portableSerialize(self: *const Bitmap64, buf: []u8) usize {
        return c.roaring64_bitmap_portable_serialize(conv(self), buf.ptr);
    }

    /// Determine the number of bytes required to deserialize a bitmap from `buf`.
    pub fn portableDeserializeSize(buf: []const u8) usize {
        return c.roaring64_bitmap_portable_deserialize_size(buf.ptr, buf.len);
    }

    /// Read a bitmap from a portable-serialized buffer, with size checks.
    pub fn portableDeserializeSafe(buf: []const u8) RoaringError!*Bitmap64 {
        return checkNewBitmap(c.roaring64_bitmap_portable_deserialize_safe(buf.ptr, buf.len));
    }

    /// Read a bitmap from a portable-serialized buffer. Equivalent to `portableDeserializeSafe` in Zig.
    pub fn portableDeserialize(buf: []const u8) RoaringError!*Bitmap64 {
        return portableDeserializeSafe(buf);
    }

    //========================== Frozen functionality =========================//

    /// Returns the byte size needed for a frozen view of the bitmap.
    pub fn frozenSizeInBytes(self: *const Bitmap64) usize {
        return c.roaring64_bitmap_frozen_size_in_bytes(conv(self));
    }

    /// Write the bitmap to a buffer in a format usable by `frozenView`.
    /// The buffer must be exactly `frozenSizeInBytes()` bytes and 32-byte aligned.
    pub fn frozenSerialize(self: *const Bitmap64, buf: []u8) void {
        _ = c.roaring64_bitmap_frozen_serialize(conv(self), buf.ptr);
    }

    /// Returns a read-only frozen view backed by `buf`. The buffer must be
    /// 32-byte aligned and exactly the length reported by `frozenSizeInBytes()`.
    pub fn frozenView(buf: []align(32) u8) RoaringError!*const Bitmap64 {
        if (c.roaring64_bitmap_frozen_view(buf.ptr, buf.len)) |b| {
            return conv(b);
        } else {
            return RoaringError.frozen_view_failed;
        }
    }

    //=============================== Comparison ==============================//

    /// Returns true if two bitmaps contain exactly the same elements.
    pub fn eql(a: *const Bitmap64, b: *const Bitmap64) bool {
        return c.roaring64_bitmap_equals(conv(a), conv(b));
    }

    /// Return true if all the elements of `a` are also in `b`.
    pub fn isSubset(a: *const Bitmap64, b: *const Bitmap64) bool {
        return c.roaring64_bitmap_is_subset(conv(a), conv(b));
    }

    /// Return true if `a` is a strict subset of `b`.
    pub fn isStrictSubset(a: *const Bitmap64, b: *const Bitmap64) bool {
        return c.roaring64_bitmap_is_strict_subset(conv(a), conv(b));
    }

    //=============================== Miscellaneous ===========================//

    /// Total number of values stored in the bitmap.
    pub fn cardinality(self: *const Bitmap64) u64 {
        return c.roaring64_bitmap_get_cardinality(conv(self));
    }

    /// Number of elements in the range [start, end).
    pub fn cardinalityRange(self: *const Bitmap64, start: u64, end: u64) u64 {
        return c.roaring64_bitmap_range_cardinality(conv(self), start, end);
    }

    /// Minimum value (undefined if empty).
    pub fn minimum(self: *const Bitmap64) u64 {
        return c.roaring64_bitmap_minimum(conv(self));
    }

    /// Maximum value (undefined if empty).
    pub fn maximum(self: *const Bitmap64) u64 {
        return c.roaring64_bitmap_maximum(conv(self));
    }

    /// Select the element at index `rnk` where the smallest element is at index 0.
    /// Returns true and writes the element if found.
    pub fn select(self: *const Bitmap64, rnk: u64, element: *u64) bool {
        return c.roaring64_bitmap_select(conv(self), rnk, element);
    }

    /// Number of integers that are smaller or equal to `x`.
    /// Note: indexing convention differs from `select` (see 32-bit docs).
    pub fn rank(self: *const Bitmap64, x: u64) u64 {
        return c.roaring64_bitmap_rank(conv(self), x);
    }

    /// Collect statistics about the bitmap.
    pub fn statistics(self: *const Bitmap64) Statistics {
        var out: Statistics = undefined;
        c.roaring64_bitmap_statistics(conv(self), &out);
        return out;
    }

    //================================ Iteration ===============================//

    /// Iterate with a callback. Returns true if the callback returned true throughout.
    pub fn iterate(self: *const Bitmap64, func: *const IteratorFunction, data: anytype) bool {
        return c.roaring64_bitmap_iterate(conv(self), func, data);
    }

    /// Allocating iterator over 64-bit values. Call `free()` when done.
    const Iterator = struct {
        i: *c.roaring64_iterator_t,

        /// Whether the iterator currently points to a value.
        pub fn hasValue(self: *const Iterator) bool {
            return c.roaring64_iterator_has_value(self.i);
        }

        /// Current value (valid only if `hasValue()` is true).
        pub fn currentValue(self: *const Iterator) u64 {
            return c.roaring64_iterator_value(self.i);
        }

        /// Advance and return the previously current value, or null when exhausted.
        pub fn next(self: *Iterator) ?u64 {
            if (!self.hasValue()) return null;
            const v = self.currentValue();
            _ = c.roaring64_iterator_advance(self.i);
            return v;
        }

        /// Move backwards and return the previously current value, or null when exhausted.
        pub fn previous(self: *Iterator) ?u64 {
            if (!self.hasValue()) return null;
            const v = self.currentValue();
            _ = c.roaring64_iterator_previous(self.i);
            return v;
        }

        /// Attempt to move to the first value >= x. Returns true if positioned on a value.
        pub fn moveEqualOrLarger(self: *Iterator, x: u64) bool {
            return c.roaring64_iterator_move_equalorlarger(self.i, x);
        }

        /// Attempt to fill `buf`. Returns the number of elements written.
        pub fn read(self: *Iterator, buf: []u64) u64 {
            return c.roaring64_iterator_read(self.i, buf.ptr, @as(u64, @intCast(buf.len)));
        }

        /// Free the underlying iterator. Must be called exactly once.
        pub fn free(self: *Iterator) void {
            c.roaring64_iterator_free(self.i);
        }
    };

    /// Create a forward iterator. Returns allocation_failed on OOM.
    pub fn iterator(self: *const Bitmap64) RoaringError!Iterator {
        if (c.roaring64_iterator_create(conv(self))) |it| {
            return Iterator{ .i = it };
        } else {
            return RoaringError.allocation_failed;
        }
    }
};
