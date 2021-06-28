pub usingnamespace @import("std").c.builtins;
const enum_unnamed_1 = extern enum(c_int) {
    ROARING_VERSION_MAJOR = 0,
    ROARING_VERSION_MINOR = 3,
    ROARING_VERSION_REVISION = 1,
    _,
};
pub const ROARING_VERSION_MAJOR = @enumToInt(enum_unnamed_1.ROARING_VERSION_MAJOR);
pub const ROARING_VERSION_MINOR = @enumToInt(enum_unnamed_1.ROARING_VERSION_MINOR);
pub const ROARING_VERSION_REVISION = @enumToInt(enum_unnamed_1.ROARING_VERSION_REVISION);
pub const __u_char = u8;
pub const __u_short = c_ushort;
pub const __u_int = c_uint;
pub const __u_long = c_ulong;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_long;
pub const __uint64_t = c_ulong;
pub const __int_least8_t = __int8_t;
pub const __uint_least8_t = __uint8_t;
pub const __int_least16_t = __int16_t;
pub const __uint_least16_t = __uint16_t;
pub const __int_least32_t = __int32_t;
pub const __uint_least32_t = __uint32_t;
pub const __int_least64_t = __int64_t;
pub const __uint_least64_t = __uint64_t;
pub const __quad_t = c_long;
pub const __u_quad_t = c_ulong;
pub const __intmax_t = c_long;
pub const __uintmax_t = c_ulong;
pub const __dev_t = c_ulong;
pub const __uid_t = c_uint;
pub const __gid_t = c_uint;
pub const __ino_t = c_ulong;
pub const __ino64_t = c_ulong;
pub const __mode_t = c_uint;
pub const __nlink_t = c_ulong;
pub const __off_t = c_long;
pub const __off64_t = c_long;
pub const __pid_t = c_int;
pub const __fsid_t = extern struct {
    __val: [2]c_int,
};
pub const __clock_t = c_long;
pub const __rlim_t = c_ulong;
pub const __rlim64_t = c_ulong;
pub const __id_t = c_uint;
pub const __time_t = c_long;
pub const __useconds_t = c_uint;
pub const __suseconds_t = c_long;
pub const __suseconds64_t = c_long;
pub const __daddr_t = c_int;
pub const __key_t = c_int;
pub const __clockid_t = c_int;
pub const __timer_t = ?*c_void;
pub const __blksize_t = c_long;
pub const __blkcnt_t = c_long;
pub const __blkcnt64_t = c_long;
pub const __fsblkcnt_t = c_ulong;
pub const __fsblkcnt64_t = c_ulong;
pub const __fsfilcnt_t = c_ulong;
pub const __fsfilcnt64_t = c_ulong;
pub const __fsword_t = c_long;
pub const __ssize_t = c_long;
pub const __syscall_slong_t = c_long;
pub const __syscall_ulong_t = c_ulong;
pub const __loff_t = __off64_t;
pub const __caddr_t = [*c]u8;
pub const __intptr_t = c_long;
pub const __socklen_t = c_uint;
pub const __sig_atomic_t = c_int;
pub const int_least8_t = __int_least8_t;
pub const int_least16_t = __int_least16_t;
pub const int_least32_t = __int_least32_t;
pub const int_least64_t = __int_least64_t;
pub const uint_least8_t = __uint_least8_t;
pub const uint_least16_t = __uint_least16_t;
pub const uint_least32_t = __uint_least32_t;
pub const uint_least64_t = __uint_least64_t;
pub const int_fast8_t = i8;
pub const int_fast16_t = c_long;
pub const int_fast32_t = c_long;
pub const int_fast64_t = c_long;
pub const uint_fast8_t = u8;
pub const uint_fast16_t = c_ulong;
pub const uint_fast32_t = c_ulong;
pub const uint_fast64_t = c_ulong;
pub const intmax_t = __intmax_t;
pub const uintmax_t = __uintmax_t;
pub const struct_roaring_array_s = extern struct {
    size: i32,
    allocation_size: i32,
    containers: [*c]?*c_void,
    keys: [*c]u16,
    typecodes: [*c]u8,
    flags: u8,
};
pub const roaring_array_t = struct_roaring_array_s;
pub const roaring_iterator = ?fn (u32, ?*c_void) callconv(.C) bool;
pub const roaring_iterator64 = ?fn (u64, ?*c_void) callconv(.C) bool;
pub const struct_roaring_statistics_s = extern struct {
    n_containers: u32,
    n_array_containers: u32,
    n_run_containers: u32,
    n_bitset_containers: u32,
    n_values_array_containers: u32,
    n_values_run_containers: u32,
    n_values_bitset_containers: u32,
    n_bytes_array_containers: u32,
    n_bytes_run_containers: u32,
    n_bytes_bitset_containers: u32,
    max_value: u32,
    min_value: u32,
    sum_value: u64,
    cardinality: u64,
};
pub const roaring_statistics_t = struct_roaring_statistics_s;
pub const ptrdiff_t = c_long;
pub const wchar_t = c_int;
pub const max_align_t = extern struct {
    __clang_max_align_nonce1: c_longlong align(8),
    __clang_max_align_nonce2: c_longdouble align(16),
};
pub const struct_roaring_bitmap_s = extern struct {
    high_low_container: roaring_array_t,
};
pub const roaring_bitmap_t = struct_roaring_bitmap_s;
pub extern fn roaring_bitmap_create_with_capacity(cap: u32) [*c]roaring_bitmap_t;
pub fn roaring_bitmap_create() callconv(.C) [*c]roaring_bitmap_t {
    return roaring_bitmap_create_with_capacity(@bitCast(u32, @as(c_int, 0)));
}
pub extern fn roaring_bitmap_init_with_capacity(r: [*c]roaring_bitmap_t, cap: u32) bool;
pub fn roaring_bitmap_init_cleared(arg_r: [*c]roaring_bitmap_t) callconv(.C) void {
    var r = arg_r;
    _ = roaring_bitmap_init_with_capacity(r, @bitCast(u32, @as(c_int, 0)));
}
pub extern fn roaring_bitmap_from_range(min: u64, max: u64, step: u32) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_of_ptr(n_args: usize, vals: [*c]const u32) [*c]roaring_bitmap_t;
pub fn roaring_bitmap_get_copy_on_write(arg_r: [*c]const roaring_bitmap_t) callconv(.C) bool {
    var r = arg_r;
    return (@bitCast(c_int, @as(c_uint, r.*.high_low_container.flags)) & @as(c_int, 1)) != 0;
}
pub fn roaring_bitmap_set_copy_on_write(arg_r: [*c]roaring_bitmap_t, arg_cow: bool) callconv(.C) void {
    var r = arg_r;
    var cow = arg_cow;
    if (cow) {
        r.*.high_low_container.flags |= @bitCast(u8, @truncate(i8, @as(c_int, 1)));
    } else {
        r.*.high_low_container.flags &= @bitCast(u8, @truncate(i8, ~@as(c_int, 1)));
    }
}
pub extern fn roaring_bitmap_printf_describe(r: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_of(n: usize, ...) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_copy(r: [*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_overwrite(dest: [*c]roaring_bitmap_t, src: [*c]const roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_printf(r: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_and(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_and_cardinality(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) u64;
pub extern fn roaring_bitmap_intersect(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_jaccard_index(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) f64;
pub extern fn roaring_bitmap_or_cardinality(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) u64;
pub extern fn roaring_bitmap_andnot_cardinality(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) u64;
pub extern fn roaring_bitmap_xor_cardinality(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) u64;
pub extern fn roaring_bitmap_and_inplace(r1: [*c]roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_or(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_or_inplace(r1: [*c]roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_or_many(number: usize, rs: [*c][*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_or_many_heap(number: u32, rs: [*c][*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_xor(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_xor_inplace(r1: [*c]roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_xor_many(number: usize, rs: [*c][*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_andnot(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_andnot_inplace(r1: [*c]roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_free(r: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_add_many(r: [*c]roaring_bitmap_t, n_args: usize, vals: [*c]const u32) void;
pub extern fn roaring_bitmap_add(r: [*c]roaring_bitmap_t, x: u32) void;
pub extern fn roaring_bitmap_add_checked(r: [*c]roaring_bitmap_t, x: u32) bool;
pub extern fn roaring_bitmap_add_range_closed(r: [*c]roaring_bitmap_t, min: u32, max: u32) void;
pub fn roaring_bitmap_add_range(arg_r: [*c]roaring_bitmap_t, arg_min: u64, arg_max: u64) callconv(.C) void {
    var r = arg_r;
    var min = arg_min;
    var max = arg_max;
    if (max == min) return;
    roaring_bitmap_add_range_closed(r, @bitCast(u32, @truncate(c_uint, min)), @bitCast(u32, @truncate(c_uint, max -% @bitCast(c_ulong, @as(c_long, @as(c_int, 1))))));
}
pub extern fn roaring_bitmap_remove(r: [*c]roaring_bitmap_t, x: u32) void;
pub extern fn roaring_bitmap_remove_range_closed(r: [*c]roaring_bitmap_t, min: u32, max: u32) void;
pub fn roaring_bitmap_remove_range(arg_r: [*c]roaring_bitmap_t, arg_min: u64, arg_max: u64) callconv(.C) void {
    var r = arg_r;
    var min = arg_min;
    var max = arg_max;
    if (max == min) return;
    roaring_bitmap_remove_range_closed(r, @bitCast(u32, @truncate(c_uint, min)), @bitCast(u32, @truncate(c_uint, max -% @bitCast(c_ulong, @as(c_long, @as(c_int, 1))))));
}
pub extern fn roaring_bitmap_remove_many(r: [*c]roaring_bitmap_t, n_args: usize, vals: [*c]const u32) void;
pub extern fn roaring_bitmap_remove_checked(r: [*c]roaring_bitmap_t, x: u32) bool;
pub extern fn roaring_bitmap_contains(r: [*c]const roaring_bitmap_t, val: u32) bool;
pub extern fn roaring_bitmap_contains_range(r: [*c]const roaring_bitmap_t, range_start: u64, range_end: u64) bool;
pub extern fn roaring_bitmap_get_cardinality(r: [*c]const roaring_bitmap_t) u64;
pub extern fn roaring_bitmap_range_cardinality(r: [*c]const roaring_bitmap_t, range_start: u64, range_end: u64) u64;
pub extern fn roaring_bitmap_is_empty(r: [*c]const roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_clear(r: [*c]roaring_bitmap_t) void;
pub extern fn roaring_bitmap_to_uint32_array(r: [*c]const roaring_bitmap_t, ans: [*c]u32) void;
pub extern fn roaring_bitmap_range_uint32_array(r: [*c]const roaring_bitmap_t, offset: usize, limit: usize, ans: [*c]u32) bool;
pub extern fn roaring_bitmap_remove_run_compression(r: [*c]roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_run_optimize(r: [*c]roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_shrink_to_fit(r: [*c]roaring_bitmap_t) usize;
pub extern fn roaring_bitmap_serialize(r: [*c]const roaring_bitmap_t, buf: [*c]u8) usize;
pub extern fn roaring_bitmap_deserialize(buf: ?*const c_void) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_size_in_bytes(r: [*c]const roaring_bitmap_t) usize;
pub extern fn roaring_bitmap_portable_deserialize(buf: [*c]const u8) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_portable_deserialize_safe(buf: [*c]const u8, maxbytes: usize) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_portable_deserialize_size(buf: [*c]const u8, maxbytes: usize) usize;
pub extern fn roaring_bitmap_portable_size_in_bytes(r: [*c]const roaring_bitmap_t) usize;
pub extern fn roaring_bitmap_portable_serialize(r: [*c]const roaring_bitmap_t, buf: [*c]u8) usize;
pub extern fn roaring_bitmap_frozen_size_in_bytes(r: [*c]const roaring_bitmap_t) usize;
pub extern fn roaring_bitmap_frozen_serialize(r: [*c]const roaring_bitmap_t, buf: [*c]u8) void;
pub extern fn roaring_bitmap_frozen_view(buf: [*c]const u8, length: usize) [*c]const roaring_bitmap_t;
pub extern fn roaring_iterate(r: [*c]const roaring_bitmap_t, iterator: roaring_iterator, ptr: ?*c_void) bool;
pub extern fn roaring_iterate64(r: [*c]const roaring_bitmap_t, iterator: roaring_iterator64, high_bits: u64, ptr: ?*c_void) bool;
pub extern fn roaring_bitmap_equals(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_is_subset(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_is_strict_subset(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) bool;
pub extern fn roaring_bitmap_lazy_or(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t, bitsetconversion: bool) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_lazy_or_inplace(r1: [*c]roaring_bitmap_t, r2: [*c]const roaring_bitmap_t, bitsetconversion: bool) void;
pub extern fn roaring_bitmap_repair_after_lazy(r1: [*c]roaring_bitmap_t) void;
pub extern fn roaring_bitmap_lazy_xor(r1: [*c]const roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_lazy_xor_inplace(r1: [*c]roaring_bitmap_t, r2: [*c]const roaring_bitmap_t) void;
pub extern fn roaring_bitmap_flip(r1: [*c]const roaring_bitmap_t, range_start: u64, range_end: u64) [*c]roaring_bitmap_t;
pub extern fn roaring_bitmap_flip_inplace(r1: [*c]roaring_bitmap_t, range_start: u64, range_end: u64) void;
pub extern fn roaring_bitmap_select(r: [*c]const roaring_bitmap_t, rank: u32, element: [*c]u32) bool;
pub extern fn roaring_bitmap_rank(r: [*c]const roaring_bitmap_t, x: u32) u64;
pub extern fn roaring_bitmap_minimum(r: [*c]const roaring_bitmap_t) u32;
pub extern fn roaring_bitmap_maximum(r: [*c]const roaring_bitmap_t) u32;
pub extern fn roaring_bitmap_statistics(r: [*c]const roaring_bitmap_t, stat: [*c]roaring_statistics_t) void;
pub const struct_roaring_uint32_iterator_s = extern struct {
    parent: [*c]const roaring_bitmap_t,
    container_index: i32,
    in_container_index: i32,
    run_index: i32,
    current_value: u32,
    has_value: bool,
    container: ?*const c_void,
    typecode: u8,
    highbits: u32,
};
pub const roaring_uint32_iterator_t = struct_roaring_uint32_iterator_s;
pub extern fn roaring_init_iterator(r: [*c]const roaring_bitmap_t, newit: [*c]roaring_uint32_iterator_t) void;
pub extern fn roaring_init_iterator_last(r: [*c]const roaring_bitmap_t, newit: [*c]roaring_uint32_iterator_t) void;
pub extern fn roaring_create_iterator(r: [*c]const roaring_bitmap_t) [*c]roaring_uint32_iterator_t;
pub extern fn roaring_advance_uint32_iterator(it: [*c]roaring_uint32_iterator_t) bool;
pub extern fn roaring_previous_uint32_iterator(it: [*c]roaring_uint32_iterator_t) bool;
pub extern fn roaring_move_uint32_iterator_equalorlarger(it: [*c]roaring_uint32_iterator_t, val: u32) bool;
pub extern fn roaring_copy_uint32_iterator(it: [*c]const roaring_uint32_iterator_t) [*c]roaring_uint32_iterator_t;
pub extern fn roaring_free_uint32_iterator(it: [*c]roaring_uint32_iterator_t) void;
pub extern fn roaring_read_uint32_iterator(it: [*c]roaring_uint32_iterator_t, buf: [*c]u32, count: u32) u32;
pub const __INTMAX_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // (no file):62:9
pub const __UINTMAX_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_unsigned"); // (no file):66:9
pub const __PTRDIFF_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // (no file):73:9
pub const __INTPTR_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // (no file):77:9
pub const __SIZE_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_unsigned"); // (no file):81:9
pub const __UINTPTR_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_unsigned"); // (no file):96:9
pub const __INT64_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // (no file):159:9
pub const __UINT64_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_unsigned"); // (no file):187:9
pub const __INT_LEAST64_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // (no file):225:9
pub const __UINT_LEAST64_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_unsigned"); // (no file):229:9
pub const __INT_FAST64_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // (no file):265:9
pub const __UINT_FAST64_TYPE__ = @compileError("unable to translate C expr: unexpected token .Keyword_unsigned"); // (no file):269:9
pub const ROARING_VERSION = @compileError("unable to translate C expr: unexpected token .Equal"); // croaring/roaring.h:26:9
pub const __GLIBC_USE = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/features.h:179:9
pub const __NTH = @compileError("unable to translate C expr: unexpected token .Identifier"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:57:11
pub const __NTHNL = @compileError("unable to translate C expr: unexpected token .Identifier"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:58:11
pub const __CONCAT = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:109:9
pub const __STRING = @compileError("unable to translate C expr: unexpected token .Hash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:110:9
pub const __warnattr = @compileError("unable to translate C expr: unexpected token .Eof"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:144:10
pub const __errordecl = @compileError("unable to translate C expr: unexpected token .Keyword_extern"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:145:10
pub const __flexarr = @compileError("unable to translate C expr: unexpected token .LBracket"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:153:10
pub const __REDIRECT = @compileError("unable to translate C expr: unexpected token .Hash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:184:10
pub const __REDIRECT_NTH = @compileError("unable to translate C expr: unexpected token .Hash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:191:11
pub const __REDIRECT_NTHNL = @compileError("unable to translate C expr: unexpected token .Hash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:193:11
pub const __ASMNAME2 = @compileError("unable to translate C expr: unexpected token .Identifier"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:197:10
pub const __attribute_alloc_size__ = @compileError("unable to translate C expr: unexpected token .Eof"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:229:10
pub const __extern_inline = @compileError("unable to translate C expr: unexpected token .Keyword_extern"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:356:11
pub const __extern_always_inline = @compileError("unable to translate C expr: unexpected token .Keyword_extern"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:357:11
pub const __attribute_copy__ = @compileError("unable to translate C expr: unexpected token .Eof"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:451:10
pub const __LDBL_REDIR2_DECL = @compileError("unable to translate C expr: unexpected token .Eof"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:522:10
pub const __LDBL_REDIR_DECL = @compileError("unable to translate C expr: unexpected token .Eof"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:523:10
pub const __glibc_macro_warning1 = @compileError("unable to translate C expr: unexpected token .Hash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:537:10
pub const __attr_access = @compileError("unable to translate C expr: unexpected token .Eof"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/sys/cdefs.h:569:11
pub const __S16_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:109:9
pub const __U16_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:110:9
pub const __SLONGWORD_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:113:9
pub const __ULONGWORD_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:114:9
pub const __SQUAD_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:128:10
pub const __UQUAD_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:129:10
pub const __SWORD_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:130:10
pub const __UWORD_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:131:10
pub const __S64_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:134:10
pub const __U64_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_int"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:135:10
pub const __STD_TYPE = @compileError("unable to translate C expr: unexpected token .Keyword_typedef"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/bits/types.h:137:10
pub const __FSID_T_TYPE = @compileError("unable to translate C expr: expected Identifier instead got: LBrace"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/x86_64-linux-gnu/bits/typesizes.h:73:9
pub const __INT64_C = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/stdint.h:106:11
pub const __UINT64_C = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/stdint.h:107:11
pub const INT64_C = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/stdint.h:252:11
pub const UINT32_C = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/stdint.h:260:10
pub const UINT64_C = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/stdint.h:262:11
pub const INTMAX_C = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/stdint.h:269:11
pub const UINTMAX_C = @compileError("unable to translate C expr: unexpected token .HashHash"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/libc/include/generic-glibc/stdint.h:270:11
pub const offsetof = @compileError("TODO implement function '__builtin_offsetof' in std.c.builtins"); // /home/justin/system/zig-linux-x86_64-0.8.0/lib/include/stddef.h:104:9
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 12);
pub const __clang_minor__ = @as(c_int, 0);
pub const __clang_patchlevel__ = @as(c_int, 1);
pub const __clang_version__ = "12.0.1 (git@github.com:ziglang/zig-bootstrap.git 8cc2870e09320a390cafe4e23624e8ed40bd363c)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 12.0.1 (git@github.com:ziglang/zig-bootstrap.git 8cc2870e09320a390cafe4e23624e8ed40bd363c)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __OPTIMIZE__ = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WINT_MAX__ = @import("std").meta.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INTMAX_MAX__ = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __SIZE_MAX__ = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_MAX__ = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __PTRDIFF_MAX__ = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_MAX__ = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __UINTPTR_MAX__ = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_FMTd__ = "ld";
pub const __INTMAX_FMTi__ = "li";
pub const __INTMAX_C_SUFFIX__ = L;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __UINTMAX_C_SUFFIX__ = UL;
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_FMTd__ = "ld";
pub const __PTRDIFF_FMTi__ = "li";
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_FMTd__ = "ld";
pub const __INTPTR_FMTi__ = "li";
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZE_FMTo__ = "lo";
pub const __SIZE_FMTu__ = "lu";
pub const __SIZE_FMTx__ = "lx";
pub const __SIZE_FMTX__ = "lX";
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_TYPE__ = c_int;
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_TYPE__ = c_uint;
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __SIG_ATOMIC_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_FMTo__ = "lo";
pub const __UINTPTR_FMTu__ = "lu";
pub const __UINTPTR_FMTx__ = "lx";
pub const __UINTPTR_FMTX__ = "lX";
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = 4.9406564584124654e-324;
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = 2.2204460492503131e-16;
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = 1.7976931348623157e+308;
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = 2.2250738585072014e-308;
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __INT64_C_SUFFIX__ = L;
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = U;
pub const __UINT32_MAX__ = @import("std").meta.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = UL;
pub const __UINT64_MAX__ = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").meta.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_MAX__ = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_FMTd__ = "ld";
pub const __INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_MAX__ = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_LEAST64_FMTo__ = "lo";
pub const __UINT_LEAST64_FMTu__ = "lu";
pub const __UINT_LEAST64_FMTx__ = "lx";
pub const __UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").meta.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_MAX__ = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_FMTd__ = "ld";
pub const __INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_MAX__ = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_FAST64_FMTo__ = "lo";
pub const __UINT_FAST64_FMTu__ = "lu";
pub const __UINT_FAST64_FMTx__ = "lx";
pub const __UINT_FAST64_FMTX__ = "lX";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = __attribute__(address_space(@as(c_int, 256)));
pub const __seg_fs = __attribute__(address_space(@as(c_int, 257)));
pub const __corei7 = @as(c_int, 1);
pub const __corei7__ = @as(c_int, 1);
pub const __tune_corei7__ = @as(c_int, 1);
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __SGX__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const __ELF__ = @as(c_int, 1);
pub const __gnu_linux__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const _DEBUG = @as(c_int, 1);
pub const bool_2 = bool;
pub const true_3 = @as(c_int, 1);
pub const false_4 = @as(c_int, 0);
pub const __bool_true_false_are_defined = @as(c_int, 1);
pub const _STDINT_H = @as(c_int, 1);
pub const _FEATURES_H = @as(c_int, 1);
pub inline fn __GNUC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    return ((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub inline fn __glibc_clang_prereq(maj: anytype, min: anytype) @TypeOf(((__clang_major__ << @as(c_int, 16)) + __clang_minor__) >= ((maj << @as(c_int, 16)) + min)) {
    return ((__clang_major__ << @as(c_int, 16)) + __clang_minor__) >= ((maj << @as(c_int, 16)) + min);
}
pub const _DEFAULT_SOURCE = @as(c_int, 1);
pub const __GLIBC_USE_ISOC2X = @as(c_int, 0);
pub const __USE_ISOC11 = @as(c_int, 1);
pub const __USE_ISOC99 = @as(c_int, 1);
pub const __USE_ISOC95 = @as(c_int, 1);
pub const __USE_POSIX_IMPLICITLY = @as(c_int, 1);
pub const _POSIX_SOURCE = @as(c_int, 1);
pub const _POSIX_C_SOURCE = @as(c_long, 200809);
pub const __USE_POSIX = @as(c_int, 1);
pub const __USE_POSIX2 = @as(c_int, 1);
pub const __USE_POSIX199309 = @as(c_int, 1);
pub const __USE_POSIX199506 = @as(c_int, 1);
pub const __USE_XOPEN2K = @as(c_int, 1);
pub const __USE_XOPEN2K8 = @as(c_int, 1);
pub const _ATFILE_SOURCE = @as(c_int, 1);
pub const __USE_MISC = @as(c_int, 1);
pub const __USE_ATFILE = @as(c_int, 1);
pub const __USE_FORTIFY_LEVEL = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_GETS = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_SCANF = @as(c_int, 0);
pub const _STDC_PREDEF_H = @as(c_int, 1);
pub const __STDC_IEC_559__ = @as(c_int, 1);
pub const __STDC_IEC_559_COMPLEX__ = @as(c_int, 1);
pub const __STDC_ISO_10646__ = @as(c_long, 201706);
pub const __GNU_LIBRARY__ = @as(c_int, 6);
pub const __GLIBC__ = @as(c_int, 2);
pub const __GLIBC_MINOR__ = @as(c_int, 33);
pub inline fn __GLIBC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    return ((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub const _SYS_CDEFS_H = @as(c_int, 1);
pub const __THROW = __attribute__(__nothrow__ ++ __LEAF);
pub const __THROWNL = __attribute__(__nothrow__);
pub inline fn __glibc_clang_has_extension(ext: anytype) @TypeOf(__has_extension(ext)) {
    return __has_extension(ext);
}
pub inline fn __P(args: anytype) @TypeOf(args) {
    return args;
}
pub inline fn __PMT(args: anytype) @TypeOf(args) {
    return args;
}
pub const __ptr_t = ?*c_void;
pub inline fn __bos(ptr: anytype) @TypeOf(__builtin_object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1))) {
    return __builtin_object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1));
}
pub inline fn __bos0(ptr: anytype) @TypeOf(__builtin_object_size(ptr, @as(c_int, 0))) {
    return __builtin_object_size(ptr, @as(c_int, 0));
}
pub inline fn __glibc_objsize0(__o: anytype) @TypeOf(__bos0(__o)) {
    return __bos0(__o);
}
pub inline fn __glibc_objsize(__o: anytype) @TypeOf(__bos(__o)) {
    return __bos(__o);
}
pub const __glibc_c99_flexarr_available = @as(c_int, 1);
pub inline fn __ASMNAME(cname: anytype) @TypeOf(__ASMNAME2(__USER_LABEL_PREFIX__, cname)) {
    return __ASMNAME2(__USER_LABEL_PREFIX__, cname);
}
pub const __attribute_malloc__ = __attribute__(__malloc__);
pub const __attribute_pure__ = __attribute__(__pure__);
pub const __attribute_const__ = __attribute__(__const__);
pub const __attribute_used__ = __attribute__(__used__);
pub const __attribute_noinline__ = __attribute__(__noinline__);
pub const __attribute_deprecated__ = __attribute__(__deprecated__);
pub inline fn __attribute_deprecated_msg__(msg: anytype) @TypeOf(__attribute__(__deprecated__(msg))) {
    return __attribute__(__deprecated__(msg));
}
pub inline fn __attribute_format_arg__(x: anytype) @TypeOf(__attribute__(__format_arg__(x))) {
    return __attribute__(__format_arg__(x));
}
pub inline fn __attribute_format_strfmon__(a: anytype, b: anytype) @TypeOf(__attribute__(__format__(__strfmon__, a, b))) {
    return __attribute__(__format__(__strfmon__, a, b));
}
pub inline fn __nonnull(params: anytype) @TypeOf(__attribute__(__nonnull__ ++ params)) {
    return __attribute__(__nonnull__ ++ params);
}
pub const __attribute_warn_unused_result__ = __attribute__(__warn_unused_result__);
pub const __always_inline = __inline ++ __attribute__(__always_inline__);
pub const __fortify_function = __extern_always_inline ++ __attribute_artificial__;
pub const __restrict_arr = __restrict;
pub inline fn __glibc_unlikely(cond: anytype) @TypeOf(__builtin_expect(cond, @as(c_int, 0))) {
    return __builtin_expect(cond, @as(c_int, 0));
}
pub inline fn __glibc_likely(cond: anytype) @TypeOf(__builtin_expect(cond, @as(c_int, 1))) {
    return __builtin_expect(cond, @as(c_int, 1));
}
pub inline fn __glibc_has_attribute(attr: anytype) @TypeOf(__has_attribute(attr)) {
    return __has_attribute(attr);
}
pub const __WORDSIZE = @as(c_int, 64);
pub const __WORDSIZE_TIME64_COMPAT32 = @as(c_int, 1);
pub const __SYSCALL_WORDSIZE = @as(c_int, 64);
pub const __LDOUBLE_REDIRECTS_TO_FLOAT128_ABI = @as(c_int, 0);
pub inline fn __LDBL_REDIR1(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto) {
    return name ++ proto;
}
pub inline fn __LDBL_REDIR(name: anytype, proto: anytype) @TypeOf(name ++ proto) {
    return name ++ proto;
}
pub inline fn __LDBL_REDIR1_NTH(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto ++ __THROW) {
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR_NTH(name: anytype, proto: anytype) @TypeOf(name ++ proto ++ __THROW) {
    return name ++ proto ++ __THROW;
}
pub inline fn __REDIRECT_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT(name, proto, alias)) {
    return __REDIRECT(name, proto, alias);
}
pub inline fn __REDIRECT_NTH_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT_NTH(name, proto, alias)) {
    return __REDIRECT_NTH(name, proto, alias);
}
pub inline fn __glibc_macro_warning(message: anytype) @TypeOf(__glibc_macro_warning1(GCC ++ warning ++ message)) {
    return __glibc_macro_warning1(GCC ++ warning ++ message);
}
pub const __HAVE_GENERIC_SELECTION = @as(c_int, 1);
pub const __attribute_returns_twice__ = __attribute__(__returns_twice__);
pub const __USE_EXTERN_INLINES = @as(c_int, 1);
pub const __GLIBC_USE_LIB_EXT2 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT_C2X = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT_C2X = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_TYPES_EXT = @as(c_int, 0);
pub const _BITS_TYPES_H = @as(c_int, 1);
pub const __TIMESIZE = __WORDSIZE;
pub const __S32_TYPE = c_int;
pub const __U32_TYPE = c_uint;
pub const __SLONG32_TYPE = c_int;
pub const __ULONG32_TYPE = c_uint;
pub const _BITS_TYPESIZES_H = @as(c_int, 1);
pub const __SYSCALL_SLONG_TYPE = __SLONGWORD_TYPE;
pub const __SYSCALL_ULONG_TYPE = __ULONGWORD_TYPE;
pub const __DEV_T_TYPE = __UQUAD_TYPE;
pub const __UID_T_TYPE = __U32_TYPE;
pub const __GID_T_TYPE = __U32_TYPE;
pub const __INO_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __INO64_T_TYPE = __UQUAD_TYPE;
pub const __MODE_T_TYPE = __U32_TYPE;
pub const __NLINK_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSWORD_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF64_T_TYPE = __SQUAD_TYPE;
pub const __PID_T_TYPE = __S32_TYPE;
pub const __RLIM_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __RLIM64_T_TYPE = __UQUAD_TYPE;
pub const __BLKCNT_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __BLKCNT64_T_TYPE = __SQUAD_TYPE;
pub const __FSBLKCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSBLKCNT64_T_TYPE = __UQUAD_TYPE;
pub const __FSFILCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSFILCNT64_T_TYPE = __UQUAD_TYPE;
pub const __ID_T_TYPE = __U32_TYPE;
pub const __CLOCK_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __TIME_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __USECONDS_T_TYPE = __U32_TYPE;
pub const __SUSECONDS_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __SUSECONDS64_T_TYPE = __SQUAD_TYPE;
pub const __DADDR_T_TYPE = __S32_TYPE;
pub const __KEY_T_TYPE = __S32_TYPE;
pub const __CLOCKID_T_TYPE = __S32_TYPE;
pub const __TIMER_T_TYPE = ?*c_void;
pub const __BLKSIZE_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __SSIZE_T_TYPE = __SWORD_TYPE;
pub const __CPU_MASK_TYPE = __SYSCALL_ULONG_TYPE;
pub const __OFF_T_MATCHES_OFF64_T = @as(c_int, 1);
pub const __INO_T_MATCHES_INO64_T = @as(c_int, 1);
pub const __RLIM_T_MATCHES_RLIM64_T = @as(c_int, 1);
pub const __STATFS_MATCHES_STATFS64 = @as(c_int, 1);
pub const __KERNEL_OLD_TIMEVAL_MATCHES_TIMEVAL64 = @as(c_int, 1);
pub const __FD_SETSIZE = @as(c_int, 1024);
pub const _BITS_TIME64_H = @as(c_int, 1);
pub const __TIME64_T_TYPE = __TIME_T_TYPE;
pub const _BITS_WCHAR_H = @as(c_int, 1);
pub const __WCHAR_MAX = __WCHAR_MAX__;
pub const __WCHAR_MIN = -__WCHAR_MAX - @as(c_int, 1);
pub const _BITS_STDINT_INTN_H = @as(c_int, 1);
pub const _BITS_STDINT_UINTN_H = @as(c_int, 1);
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT32_MIN = -@import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT64_MIN = -__INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = __INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = @import("std").meta.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = @import("std").meta.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT64_MAX = __UINT64_C(@import("std").meta.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_LEAST8_MIN = -@as(c_int, 128);
pub const INT_LEAST16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT_LEAST32_MIN = -@import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_LEAST64_MIN = -__INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_LEAST8_MAX = @as(c_int, 127);
pub const INT_LEAST16_MAX = @as(c_int, 32767);
pub const INT_LEAST32_MAX = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT_LEAST64_MAX = __INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_LEAST8_MAX = @as(c_int, 255);
pub const UINT_LEAST16_MAX = @import("std").meta.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST32_MAX = @import("std").meta.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST64_MAX = __UINT64_C(@import("std").meta.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_FAST8_MIN = -@as(c_int, 128);
pub const INT_FAST16_MIN = -@import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST32_MIN = -@import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST64_MIN = -__INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_FAST8_MAX = @as(c_int, 127);
pub const INT_FAST16_MAX = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST32_MAX = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST64_MAX = __INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_FAST8_MAX = @as(c_int, 255);
pub const UINT_FAST16_MAX = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST32_MAX = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_MAX = __UINT64_C(@import("std").meta.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INTPTR_MIN = -@import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INTPTR_MAX = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const UINTPTR_MAX = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const INTMAX_MIN = -__INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INTMAX_MAX = __INT64_C(@import("std").meta.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINTMAX_MAX = __UINT64_C(@import("std").meta.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const PTRDIFF_MIN = -@import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const PTRDIFF_MAX = @import("std").meta.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const SIG_ATOMIC_MIN = -@import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const SIG_ATOMIC_MAX = @import("std").meta.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const SIZE_MAX = @import("std").meta.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const WCHAR_MIN = __WCHAR_MIN;
pub const WCHAR_MAX = __WCHAR_MAX;
pub const WINT_MIN = @as(c_uint, 0);
pub const WINT_MAX = @import("std").meta.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub inline fn INT8_C(c: anytype) @TypeOf(c) {
    return c;
}
pub inline fn INT16_C(c: anytype) @TypeOf(c) {
    return c;
}
pub inline fn INT32_C(c: anytype) @TypeOf(c) {
    return c;
}
pub inline fn UINT8_C(c: anytype) @TypeOf(c) {
    return c;
}
pub inline fn UINT16_C(c: anytype) @TypeOf(c) {
    return c;
}
pub const ROARING_CONTAINER_T = c_void;
pub const MAX_CONTAINERS = @import("std").meta.promoteIntLiteral(c_int, 65536, .decimal);
pub const SERIALIZATION_ARRAY_UINT32 = @as(c_int, 1);
pub const SERIALIZATION_CONTAINER = @as(c_int, 2);
pub const ROARING_FLAG_COW = UINT8_C(@as(c_int, 0x1));
pub const ROARING_FLAG_FROZEN = UINT8_C(@as(c_int, 0x2));
pub const NULL = @import("std").meta.cast(?*c_void, @as(c_int, 0));
pub const roaring_array_s = struct_roaring_array_s;
pub const roaring_statistics_s = struct_roaring_statistics_s;
pub const roaring_bitmap_s = struct_roaring_bitmap_s;
pub const roaring_uint32_iterator_s = struct_roaring_uint32_iterator_s;
