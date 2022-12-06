const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day06.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    datastream: []const u8,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var input = Input{
            .allocator = allocator,
            .datastream = input_text,
        };
        errdefer input.deinit();

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input, output: *output_type) !void {
    const count = input.datastream.len;
    var i: usize = 0;
    while (i < count - 3) : (i += 1) {
        var bits = std.StaticBitSet(26).initEmpty();
        bits.set(input.datastream[i + 0] - 'a');
        bits.set(input.datastream[i + 1] - 'a');
        bits.set(input.datastream[i + 2] - 'a');
        bits.set(input.datastream[i + 3] - 'a');
        if (bits.count() == 4) {
            break;
        }
    }
    output.* = @intCast(i64, i + 4);
}

fn part2(input: Input, output: *output_type) !void {
    const count = input.datastream.len;
    var i: usize = 0;
    while (i < count - 14) : (i += 1) {
        var bits = std.StaticBitSet(26).initEmpty();
        bits.set(input.datastream[i + 0] - 'a');
        bits.set(input.datastream[i + 1] - 'a');
        bits.set(input.datastream[i + 2] - 'a');
        bits.set(input.datastream[i + 3] - 'a');
        bits.set(input.datastream[i + 4] - 'a');
        bits.set(input.datastream[i + 5] - 'a');
        bits.set(input.datastream[i + 6] - 'a');
        bits.set(input.datastream[i + 7] - 'a');
        bits.set(input.datastream[i + 8] - 'a');
        bits.set(input.datastream[i + 9] - 'a');
        bits.set(input.datastream[i + 10] - 'a');
        bits.set(input.datastream[i + 11] - 'a');
        bits.set(input.datastream[i + 12] - 'a');
        bits.set(input.datastream[i + 13] - 'a');
        if (bits.count() == 14) {
            break;
        }
    }
    output.* = @intCast(i64, i + 14);
}

const test_data = "mjqjpqmgbljsphdztnvjfqwrcgsmlb";

const part1_test_solution: ?i64 = 7;
const part1_solution: ?i64 = 1658;
const part2_test_solution: ?i64 = 19;
const part2_solution: ?i64 = 2260;

// Extra test cases
const test_data2 = "bvwbjplbgvbhsrlpgdmjqwftvncz";
const test_data3 = "nppdvjthqldpwncqszvftbrmjlhg";
const test_data4 = "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg";
const test_data5 = "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw";
const part1_test_solution2: ?i64 = 5;
const part1_test_solution3: ?i64 = 6;
const part1_test_solution4: ?i64 = 10;
const part1_test_solution5: ?i64 = 11;
const part2_test_solution2: ?i64 = 23;
const part2_test_solution3: ?i64 = 23;
const part2_test_solution4: ?i64 = 29;
const part2_test_solution5: ?i64 = 26;

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
    try aocTestSolution(part1, test_data2, part1_test_solution2, allocator);
    try aocTestSolution(part1, test_data3, part1_test_solution3, allocator);
    try aocTestSolution(part1, test_data4, part1_test_solution4, allocator);
    try aocTestSolution(part1, test_data5, part1_test_solution5, allocator);
    try aocTestSolution(part1, data, part1_solution, allocator);
    try aocTestSolution(part2, test_data, part2_test_solution, allocator);
    try aocTestSolution(part2, test_data2, part2_test_solution2, allocator);
    try aocTestSolution(part2, test_data3, part2_test_solution3, allocator);
    try aocTestSolution(part2, test_data4, part2_test_solution4, allocator);
    try aocTestSolution(part2, test_data5, part2_test_solution5, allocator);
    try aocTestSolution(part2, data, part2_solution, allocator);
}

test "day06_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, test_data2, part1_test_solution2, std.testing.allocator);
    try aocTestSolution(part1, test_data3, part1_test_solution3, std.testing.allocator);
    try aocTestSolution(part1, test_data4, part1_test_solution4, std.testing.allocator);
    try aocTestSolution(part1, test_data5, part1_test_solution5, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day06_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, test_data2, part2_test_solution2, std.testing.allocator);
    try aocTestSolution(part2, test_data3, part2_test_solution3, std.testing.allocator);
    try aocTestSolution(part2, test_data4, part2_test_solution4, std.testing.allocator);
    try aocTestSolution(part2, test_data5, part2_test_solution5, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
