const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day04.txt");

const RangePair = struct {
    min0: i164,
    max0: i164,
    min1: i164,
    max1: i164,
};

const Input = struct {
    allocator: std.mem.Allocator,
    range_pairs: std.BoundedArray(RangePair, 1000),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var input = Input{
            .allocator = allocator,
            .range_pairs = try std.BoundedArray(RangePair, 1000).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            var nums = std.mem.tokenize(u8, line, "-,");
            input.range_pairs.appendAssumeCapacity(RangePair{
                .min0 = try std.fmt.parseInt(u8, nums.next().?, 10),
                .max0 = try std.fmt.parseInt(u8, nums.next().?, 10),
                .min1 = try std.fmt.parseInt(u8, nums.next().?, 10),
                .max1 = try std.fmt.parseInt(u8, nums.next().?, 10),
            });
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input) !i64 {
    var count: i64 = 0;
    for (input.range_pairs.constSlice()) |range_pair| {
        if ((range_pair.min0 >= range_pair.min1 and range_pair.max0 <= range_pair.max1) or
            (range_pair.min1 >= range_pair.min0 and range_pair.max1 <= range_pair.max0))
        {
            count += 1;
        }
    }
    return count;
}

fn part2(input: Input) !i64 {
    var count: i64 = 0;
    for (input.range_pairs.constSlice()) |range_pair| {
        // Checking for overlapping ranges is simpler than testing for range subsets :)
        // The ranges don't overlap if either min is greater than the other max
        //   overlaps = !((min0 > max1) or (min1 > max0))
        // A>B is equivalent to !(A<=B)
        //   overlaps = !(!(min0 <= max1) or !(min1 <= max0))
        // By DeMorgan's Law, !(!A || !B) is equivalent to A && B
        //   overlaps = (min0 <= max1 and min1 <= max0)
        if (range_pair.min0 <= range_pair.max1 and range_pair.min1 <= range_pair.max0)
        {
            count += 1;
        }
    }
    return count;
}

const test_data =
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
;
const part1_test_solution: ?i64 = 2;
const part1_solution: ?i64 = 540;
const part2_test_solution: ?i64 = 4;
const part2_solution: ?i64 = 872;

// Just boilerplate below here, nothing to see

fn testPart1(allocator: std.mem.Allocator) !void {
    var test_input = try Input.init(test_data, allocator);
    defer test_input.deinit();
    if (part1_test_solution) |solution| {
        try std.testing.expectEqual(solution, try part1(test_input));
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, allocator);
    defer input.deinit();
    if (part1_solution) |solution| {
        try std.testing.expectEqual(solution, try part1(input));
        print("part1 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

fn testPart2(allocator: std.mem.Allocator) !void {
    var test_input = try Input.init(test_data, allocator);
    defer test_input.deinit();
    if (part2_test_solution) |solution| {
        try std.testing.expectEqual(solution, try part2(test_input));
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, allocator);
    defer input.deinit();
    if (part2_solution) |solution| {
        try std.testing.expectEqual(solution, try part2(input));
        print("part2 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try testPart1(allocator);
    try testPart2(allocator);
}

test "day04_part1" {
    try testPart1(std.testing.allocator);
}

test "day04_part2" {
    try testPart2(std.testing.allocator);
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
const expect = std.testing.expect;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
