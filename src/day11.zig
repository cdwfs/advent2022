const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day11.txt");

const Monkey = struct {
    items: std.BoundedArray(i64, 50),
    op: u8,
    op_arg: i64,
    test_divisor: i64,
    true_dest: usize,
    false_dest: usize,
};

const Input = struct {
    allocator: std.mem.Allocator,
    monkeys: std.BoundedArray(Monkey, 8),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var eol2_buffer: [5]u8 = undefined;
        const eol2 = try std.fmt.bufPrint(eol2_buffer[0..], "{s}{s}", .{ eol, eol });
        var monkey_defs = std.mem.split(u8, input_text, eol2);
        var input = Input{
            .allocator = allocator,
            .monkeys = try std.BoundedArray(Monkey, 8).init(0),
        };
        errdefer input.deinit();

        while (monkey_defs.next()) |def| {
            var lines = std.mem.split(u8, def, eol);
            _ = lines.next().?; // ignore monkey ID line
            var all_items = try std.BoundedArray(i64, 50).init(0);
            var items = std.mem.split(u8, lines.next().?[18..], ", ");
            while (items.next()) |item| {
                const n = try std.fmt.parseInt(i64, item, 10);
                all_items.appendAssumeCapacity(n);
            }
            var op_line = lines.next().?;
            var op = op_line[23];
            var op_arg = std.fmt.parseInt(i64, op_line[25..], 10) catch -1;
            var divisor = try std.fmt.parseInt(i64, lines.next().?[21..], 10);
            var true_dest = try std.fmt.parseInt(usize, lines.next().?[29..], 10);
            var false_dest = try std.fmt.parseInt(usize, lines.next().?[30..], 10);
            input.monkeys.appendAssumeCapacity(Monkey{
                .items = all_items,
                .op = op,
                .op_arg = op_arg,
                .test_divisor = divisor,
                .true_dest = true_dest,
                .false_dest = false_dest,
            });
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn compute_monkey_business(input: Input, rounds: usize, div3: bool) i64 {
    var round: usize = 0;
    var monkeys = input.monkeys; // need a mutable copy
    var inspect_counts_array = std.BoundedArray(i64, 8).init(0) catch unreachable;
    inspect_counts_array.appendNTimesAssumeCapacity(0, input.monkeys.len);
    var inspect_counts = inspect_counts_array.slice();
    while (round < rounds) : (round += 1) {
        for (monkeys.slice()) |*monkey, monkey_index| {
            //std.debug.print("Monkey {d}:\n", .{monkey_index});
            for (monkey.items.slice()) |*item| {
                //std.debug.print("  Monkey inspects an item with a worry level of {d}.\n", .{item.*});
                // Update worry level
                item.* = switch (monkey.op) {
                    '+' => item.* + monkey.op_arg,
                    '*' => item.* * if (monkey.op_arg == -1) item.* else monkey.op_arg,
                    else => unreachable,
                };
                //std.debug.print("  Worry level is increased to {d}.\n", .{item.*});
                // after inspection but before throwing, worry is divided by some factor
                item.* = if (div3) @divFloor(item.*, 3) else @rem(item.*, 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23);
                //std.debug.print("    Monkey gets bored with item. Worry level is divided by 3 to {d}\n", .{item.*});
                // Test worry level & throw
                const divisible = @rem(item.*, monkey.test_divisor) == 0;
                const dest_index = if (divisible) monkey.true_dest else monkey.false_dest;
                //std.debug.print("    Item with worry level {d} is thrown to monkey {d}\n", .{item.*, dest_index});
                monkeys.slice()[dest_index].items.appendAssumeCapacity(item.*);
            }
            // Clear all thrown items at once
            inspect_counts[monkey_index] += @intCast(i64, monkey.items.len);
            monkey.items.resize(0) catch unreachable;
        }
    }
    // Sort monkeys by inspect counts
    std.sort.sort(i64, inspect_counts, {}, comptime std.sort.desc(i64));
    return inspect_counts[0] * inspect_counts[1];
}

fn part1(input: Input, output: *output_type) !void {
    output.* = compute_monkey_business(input, 20, true);
}

fn part2(input: Input, output: *output_type) !void {
    output.* = compute_monkey_business(input, 10_000, false);
}

const test_data =
    \\Monkey 0:
    \\  Starting items: 79, 98
    \\  Operation: new = old * 19
    \\  Test: divisible by 23
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 3
    \\
    \\Monkey 1:
    \\  Starting items: 54, 65, 75, 74
    \\  Operation: new = old + 6
    \\  Test: divisible by 19
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 0
    \\
    \\Monkey 2:
    \\  Starting items: 79, 60, 97
    \\  Operation: new = old * old
    \\  Test: divisible by 13
    \\    If true: throw to monkey 1
    \\    If false: throw to monkey 3
    \\
    \\Monkey 3:
    \\  Starting items: 74
    \\  Operation: new = old + 3
    \\  Test: divisible by 17
    \\    If true: throw to monkey 0
    \\    If false: throw to monkey 1
;
const part1_test_solution: ?i64 = 10_605;
const part1_solution: ?i64 = 113_220;
const part2_test_solution: ?i64 = 2_713_310_158;
const part2_solution: ?i64 = 30_599_555_965;

// Just boilerplate below here, nothing to see

const solution_type: type = @TypeOf(part1_test_solution);
const output_type: type = if (solution_type == ?[]const u8) std.BoundedArray(u8, 256) else i64;
// TODO: in Zig 0.10.0 on the self-hosting compiler, function pointer types must be
// `*const fn(blah) void` instead of just `fn(blah) void`. But this AoC framework still uses stage1
// to avoid a bug with bitsets. For more info:
// https://ziglang.org/download/0.10.0/release-notes.html#Function-Pointers
const func_type: type = fn (input: Input, output: *output_type) anyerror!void;

fn aocTestSolution(
    comptime func: func_type,
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

test "day11_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day11_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
