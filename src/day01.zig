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

fn part1(input: Input, output: *output_type) !void {
    var current_calorie_count: i64 = 0;
    var max_calorie_count: i64 = -1;
    for (input.lines.constSlice()) |line| {
        if (line.len == 0) {
            if (current_calorie_count > max_calorie_count) {
                max_calorie_count = current_calorie_count;
            }
            current_calorie_count = 0;
        } else {
            current_calorie_count += try std.fmt.parseInt(i64, line, 10);
        }
    }
    // Once more for the last elf
    if (current_calorie_count > max_calorie_count) {
        max_calorie_count = current_calorie_count;
    }

    output.* = max_calorie_count;
}

fn part2(input: Input, output: *output_type) !void {
    var elf_totals = try std.BoundedArray(i64, 2500).init(0);

    var current_calorie_count: i64 = 0;
    for (input.lines.constSlice()) |line| {
        if (line.len == 0) {
            elf_totals.appendAssumeCapacity(current_calorie_count);
            current_calorie_count = 0;
        } else {
            current_calorie_count += try std.fmt.parseInt(i64, line, 10);
        }
    }
    // Once more for the last elf
    elf_totals.appendAssumeCapacity(current_calorie_count);

    var calories_per_elf = elf_totals.slice();
    std.sort.sort(i64, calories_per_elf, {}, comptime std.sort.desc(i64));
    output.* = calories_per_elf[0] + calories_per_elf[1] + calories_per_elf[2];
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
