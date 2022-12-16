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

// Returns the end-of-line sequence for a block of text (either "\r\n" or "\n").
pub fn getLineEnding(text:[] const u8) ?[] const u8 {
    if (std.ascii.indexOfIgnoreCasePos(text, 0, "\n")) |index| {
        return if (index > 0 and text[index-1] == '\r') "\r\n" else "\n";
    } else {
        return null;
    }
}

// Absolute value variant for Vectors
// (courtesty of @interlinked on the Zig Discord)
fn abs(vector: anytype) @TypeOf(vector) {
  const info = @typeInfo(@TypeOf(vector)).Vector;
  const shr = @as(info.child, @bitSizeOf(info.child)) - 1;
  const m = vector >> @splat(info.len, shr);
  return (vector ^ m) -| m;
}

test "abs" {
    const v: @Vector(5, i32) = .{ std.math.minInt(i32), -1, 0, 1, std.math.maxInt(i32) };
    try std.testing.expectEqual(@Vector(5,i32){ 2147483647, 1, 0, 1, 2147483647 }, abs(v));
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
