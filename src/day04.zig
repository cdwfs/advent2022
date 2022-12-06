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

fn part1(input: Input, output: *output_type) !void {
    var count: i64 = 0;
    for (input.range_pairs.constSlice()) |range_pair| {
        if ((range_pair.min0 >= range_pair.min1 and range_pair.max0 <= range_pair.max1) or
            (range_pair.min1 >= range_pair.min0 and range_pair.max1 <= range_pair.max0))
        {
            count += 1;
        }
    }
    output.* = count;
}

fn part2(input: Input, output: *output_type) !void {
    var count: i64 = 0;
    for (input.range_pairs.constSlice()) |range_pair| {
        // Checking for overlapping ranges is simpler than testing for range subsets :)
        // The ranges don't overlap if either min is greater than the other max
        //   overlaps = !((min0 > max1) or (min1 > max0))
        // A>B is equivalent to !(A<=B)
        //   overlaps = !(!(min0 <= max1) or !(min1 <= max0))
        // By DeMorgan's Law, !(!A || !B) is equivalent to A && B
        //   overlaps = (min0 <= max1 and min1 <= max0)
        if (range_pair.min0 <= range_pair.max1 and range_pair.min1 <= range_pair.max0) {
            count += 1;
        }
    }
    output.* = count;
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

const solution_type: type = @TypeOf(part1_test_solution);
const output_type: type = if (solution_type == ?[]const u8) std.BoundedArray(u8, 256) else i64;

fn aocTestSolution(
    func: *const fn (input: Input, output: *output_type) anyerror!void,
    input_text: []const u8,
    expected_solution: solution_type,
    allocator: std.mem.Allocator,
) !void {
    const expected = expected_solution orelse return error.SkipZigTest;

    var timer = try std.time.Timer.start();
    var input = try Input.init(input_text, allocator);
    defer input.deinit();
    if (output_type == std.BoundedArray(u8, 256)) {
        var actual = try std.BoundedArray(u8, 256).init(0);
        try func(input, &actual);
        try std.testing.expectEqualStrings(expected, actual.constSlice());
    } else {
        var actual: i64 = 0;
        try func(input, &actual);
        try std.testing.expectEqual(expected, actual);
    }
    std.debug.print("{d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try aocTestSolution(part1, test_data, part1_test_solution, allocator);
    try aocTestSolution(part1, data, part1_solution, allocator);
    try aocTestSolution(part2, test_data, part2_test_solution, allocator);
    try aocTestSolution(part2, data, part2_solution, allocator);
}

test "day05_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day05_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
