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
            assert(line.len % 2 == 0);
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

fn part1(input: Input) !i64 {
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
    return priority_sum;
}

fn part2(input: Input) !i64 {
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
    return priority_sum;
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

test "day03_part1" {
    try testPart1(std.testing.allocator);
}

test "day03_part2" {
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
