const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day03.txt");

const Rucksack = struct {
    compartments: [2][]const u8,
};

const Input = struct {
    allocator: std.mem.Allocator,
    rucksacks: std.BoundedArray(Rucksack, 300),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var input = Input{
            .allocator = allocator,
            .rucksacks = try std.BoundedArray(Rucksack, 300).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            std.debug.assert(line.len % 2 == 0);
            input.rucksacks.appendAssumeCapacity(Rucksack{
                .compartments = .{
                    line[0 .. line.len / 2],
                    line[line.len / 2 .. line.len],
                },
            });
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input, output: *output_type) !void {
    var priority_sum: i64 = 0;
    for (input.rucksacks.constSlice()) |sack| {
        var items_in_comp1 = std.StaticBitSet(256).initEmpty();
        for (sack.compartments[0]) |item| {
            items_in_comp1.set(item);
        }
        for (sack.compartments[1]) |item| {
            if (items_in_comp1.isSet(item)) {
                priority_sum += if (item <= 'Z')
                    @as(i64, item - 'A' + 27)
                else
                    @as(i64, item - 'a' + 1);
                break;
            }
        }
    }
    output.* = priority_sum;
}

fn part2(input: Input, output: *output_type) !void {
    var priority_sum: i64 = 0;
    var i: usize = 0;
    const sacks = input.rucksacks.constSlice();
    while (i < sacks.len) : (i += 3) {
        var items_in_sack1 = std.StaticBitSet(256).initEmpty();
        var items_in_sack2 = std.StaticBitSet(256).initEmpty();
        var sack1_items = sacks[i + 0].compartments[0];
        var sack2_items = sacks[i + 1].compartments[0];
        var sack3_items = sacks[i + 2].compartments[0];
        sack1_items.len *= 2;
        sack2_items.len *= 2;
        sack3_items.len *= 2;
        for (sack1_items) |item| {
            items_in_sack1.set(item);
        }
        for (sack2_items) |item| {
            items_in_sack2.set(item);
        }
        for (sack3_items) |item| {
            if (items_in_sack1.isSet(item) and items_in_sack2.isSet(item)) {
                priority_sum += if (item <= 'Z')
                    @as(i64, item - 'A' + 27)
                else
                    @as(i64, item - 'a' + 1);
                break;
            }
        }
    }
    output.* = priority_sum;
}

const test_data =
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;
const part1_test_solution: ?i64 = 157;
const part1_solution: ?i64 = 8053;
const part2_test_solution: ?i64 = 70;
const part2_solution: ?i64 = 2425;

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
