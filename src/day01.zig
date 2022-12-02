const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day01.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    lines: std.BoundedArray([]const u8, 2500),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.split(u8, input_text, "\n");
        var input = Input{
            .allocator = allocator,
            .lines = try std.BoundedArray([]const u8, 2500).init(0),
        };
        errdefer input.deinit();
        while (lines.next()) |line| {
            input.lines.appendAssumeCapacity(std.mem.trim(u8, line, "\r"));
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input) !i64 {
    var currentCalorieCount: i64 = 0;
    var maxCalorieCount: i64 = -1;
    for (input.lines.constSlice()) |line| {
        if (line.len == 0) {
            if (currentCalorieCount > maxCalorieCount) {
                maxCalorieCount = currentCalorieCount;
            }
            currentCalorieCount = 0;
        } else {
            currentCalorieCount += try std.fmt.parseInt(i64, line, 10);
        }
    }
    // Once more for the last elf
    if (currentCalorieCount > maxCalorieCount) {
        maxCalorieCount = currentCalorieCount;
    }

    return maxCalorieCount;
}

fn part2(input: Input) !i64 {
    var elfTotals = try std.BoundedArray(i64, 2500).init(0);

    var currentCalorieCount: i64 = 0;
    for (input.lines.constSlice()) |line| {
        if (line.len == 0) {
            elfTotals.appendAssumeCapacity(currentCalorieCount);
            currentCalorieCount = 0;
        } else {
            currentCalorieCount += try std.fmt.parseInt(i64, line, 10);
        }
    }
    // Once more for the last elf
    elfTotals.appendAssumeCapacity(currentCalorieCount);

    var caloriesPerElf = elfTotals.slice();
    std.sort.sort(i64, caloriesPerElf, {}, comptime std.sort.desc(i64));
    return caloriesPerElf[0] + caloriesPerElf[1] + caloriesPerElf[2];
}

const test_data =
    \\1000
    \\2000
    \\3000
    \\
    \\4000
    \\
    \\5000
    \\6000
    \\
    \\7000
    \\8000
    \\9000
    \\
    \\10000
;
const part1_test_solution: ?i64 = 24000;
const part1_solution: ?i64 = 71300;
const part2_test_solution: ?i64 = 45000;
const part2_solution: ?i64 = 209691;

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

test "day01_part1" {
    try testPart1(std.testing.allocator);
}

test "day01_part2" {
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
