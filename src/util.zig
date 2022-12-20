const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

// Add utility functions here

// Returns the signed variant of an integer type (or the type itself, if it's already signed
fn Signed(comptime IntOrFloat: type) type {
    return switch(@typeInfo(IntOrFloat)) {
        .Int => @Type(.{ .Int = .{
                .signedness = .signed,
                .bits = @typeInfo(IntOrFloat).Int.bits,
            } }),
        .Float => IntOrFloat,
        else => unreachable, // Signed(T) only supports Int or Float types
    };
}

test "Signed" {
    try std.testing.expectEqual(Signed(u8), i8);
    try std.testing.expectEqual(Signed(i32), i32);
    try std.testing.expectEqual(Signed(f32), f32);
    //try std.testing.expectError(Signed(void), anyerror);
}

// Returns an iterator that returns values from [start..end), incrementing by step.
pub fn range(comptime T: type, args: struct { start: T = 0, end: T, step: Signed(T) = 1 }) RangeIterator(T) {
    return .{
        .current = args.start,
        .end = args.end,
        .step = args.step,
    };
}
fn RangeIterator(comptime T: type) type {
    return struct {
        current: T,
        end: T,
        step: Signed(T),

        const Self = @This();

        pub fn next(self: *Self) ?T {
            if (self.step >= 0) {
                if (self.current >= self.end) {
                    return null;
                }
            } else {
                if (self.current <= self.end) {
                    return null;
                }
            }
            const result = self.current;
            self.current = switch (@typeInfo(T)) {
                // The casting here is necessary to support signed steps with unsigned start/end,
                // but implicitly limits the range of useful values to the intersection of signed & unsigned ranges.
                .Int => @intCast(T, @intCast(Signed(T), self.current) +% self.step),

                .Float => self.current + self.step,
                else => self.current,
            };
            return result;
        }
    };
}

test "test_range" {
    // Test end-only (implicit start=0, step=1)
    var sum1: i64 = 0;
    var count1: usize = 0;
    var loop1_range = range(i64, .{ .end = 5 });
    while (loop1_range.next()) |i| {
        count1 += 1;
        sum1 += i;
    }
    try std.testing.expectEqual(@intCast(usize, 5), count1);
    try std.testing.expectEqual(@intCast(i64, 0 + 1 + 2 + 3 + 4), sum1);

    // Test start-and-end only (implicit step=1)
    var sum2: i64 = 0;
    var count2: usize = 0;
    var loop2_range = range(i64, .{ .start = 2, .end = 5 });
    while (loop2_range.next()) |i| {
        count2 += 1;
        sum2 += i;
    }
    try std.testing.expectEqual(@intCast(usize, 3), count2);
    try std.testing.expectEqual(@intCast(i64, 2 + 3 + 4), sum2);

    // Test explicit start/end/step
    var sum3: i64 = 0;
    var count3: usize = 0;
    var loop3_range = range(i64, .{ .end = 10, .step = 2 });
    while (loop3_range.next()) |i| {
        count3 += 1;
        sum3 += i;
    }
    try std.testing.expectEqual(@intCast(usize, 5), count3);
    try std.testing.expectEqual(@intCast(i64, 0 + 2 + 4 + 6 + 8), sum3);

    // Test range over floats
    var sum4: f32 = 0;
    var count4: usize = 0;
    var loop4_range = range(f32, .{ .end = 10, .step = 2 });
    while (loop4_range.next()) |i| {
        count4 += 1;
        sum4 += i;
    }
    try std.testing.expectEqual(@intCast(usize, 5), count4);
    try std.testing.expectEqual(@floatCast(f32, 0 + 2 + 4 + 6 + 8), sum4);

    // Test negative step
    var sum5: u32 = 0;
    var count5: usize = 0;
    var loop5_range = range(u32, .{ .start = 5, .end = 0, .step = -1 });
    while (loop5_range.next()) |i| {
        count5 += 1;
        sum5 += i;
    }
    try std.testing.expectEqual(@intCast(usize, 5), count5); // does _not_ process 0!
    try std.testing.expectEqual(@intCast(u32, 5 + 4 + 3 + 2 + 1), sum5);
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
