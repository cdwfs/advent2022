const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day11.txt");

const Item = struct {
    mod2:i64,
    mod3:i64,
    mod5:i64,
    mod7:i64,
    mod11:i64,
    mod13:i64,
    mod17:i64,
    mod19:i64,
    mod23:i64,

    fn init(n:i64) @This() {
        return @This() {
            .mod2  = @mod(n,  2),
            .mod3  = @mod(n,  3),
            .mod5  = @mod(n,  5),
            .mod7  = @mod(n,  7),
            .mod11 = @mod(n, 11),
            .mod13 = @mod(n, 13),
            .mod17 = @mod(n, 17),
            .mod19 = @mod(n, 19),
            .mod23 = @mod(n, 23),
        };
    }

    fn increase(self:*@This(), op:u8, op_arg:i64) void {
        switch(op) {
            '+' => {
                self.mod2  = @mod(self.mod2  + op_arg,  2);
                self.mod3  = @mod(self.mod3  + op_arg,  3);
                self.mod5  = @mod(self.mod5  + op_arg,  5);
                self.mod7  = @mod(self.mod7  + op_arg,  7);
                self.mod11 = @mod(self.mod11 + op_arg, 11);
                self.mod13 = @mod(self.mod13 + op_arg, 13);
                self.mod17 = @mod(self.mod17 + op_arg, 17);
                self.mod19 = @mod(self.mod19 + op_arg, 19);
                self.mod23 = @mod(self.mod23 + op_arg, 23);
            },
            '*' => {
                self.mod2  = @mod(self.mod2  * if (op_arg == -1) self.mod2  else op_arg,  2);
                self.mod3  = @mod(self.mod3  * if (op_arg == -1) self.mod3  else op_arg,  3);
                self.mod5  = @mod(self.mod5  * if (op_arg == -1) self.mod5  else op_arg,  5);
                self.mod7  = @mod(self.mod7  * if (op_arg == -1) self.mod7  else op_arg,  7);
                self.mod11 = @mod(self.mod11 * if (op_arg == -1) self.mod11 else op_arg, 11);
                self.mod13 = @mod(self.mod13 * if (op_arg == -1) self.mod13 else op_arg, 13);
                self.mod17 = @mod(self.mod17 * if (op_arg == -1) self.mod17 else op_arg, 17);
                self.mod19 = @mod(self.mod19 * if (op_arg == -1) self.mod19 else op_arg, 19);
                self.mod23 = @mod(self.mod23 * if (op_arg == -1) self.mod23 else op_arg, 23);
            },
            else => unreachable,
        }
    }

    fn divisible(self:@This(), n:i64) bool {
        switch(n) {
            2  => return self.mod2  == 0,
            3  => return self.mod3  == 0,
            5  => return self.mod5  == 0,
            7  => return self.mod7  == 0,
            11 => return self.mod11 == 0,
            13 => return self.mod13 == 0,
            17 => return self.mod17 == 0,
            19 => return self.mod19 == 0,
            23 => return self.mod23 == 0,
            else => unreachable,
        }
    }
};

const Monkey = struct {
    items1: std.BoundedArray(i64,50),
    items2: std.BoundedArray(Item,50),
    op: u8,
    op_arg:i64,
    test_divisor: i64,
    true_dest: usize,
    false_dest: usize,
};

const Input = struct {
    allocator: std.mem.Allocator,
    monkeys: std.BoundedArray(Monkey,8),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var eol2_buffer:[5]u8 = undefined;
        const eol2 = try std.fmt.bufPrint(eol2_buffer[0..], "{s}{s}", .{eol,eol});
        var monkey_defs = std.mem.split(u8, input_text, eol2);
        var input = Input{
            .allocator = allocator,
            .monkeys = try std.BoundedArray(Monkey,8).init(0),
        };
        errdefer input.deinit();

        while(monkey_defs.next()) |def| {
            var lines = std.mem.split(u8, def, eol);
            _ = lines.next().?; // ignore monkey ID line
            var all_items1 = try std.BoundedArray(i64,50).init(0);
            var all_items2 = try std.BoundedArray(Item,50).init(0);
            var items = std.mem.split(u8, lines.next().?[18..], ", ");
            while(items.next()) |item| {
                const n = try std.fmt.parseInt(i64,item,10);
                all_items1.appendAssumeCapacity(n);
                all_items2.appendAssumeCapacity(Item.init(n));
            }
            var op_line = lines.next().?;
            var op = op_line[23];
            var op_arg = std.fmt.parseInt(i64, op_line[25..], 10) catch -1;
            var divisor = try std.fmt.parseInt(i64, lines.next().?[21..], 10);
            var true_dest = try std.fmt.parseInt(usize, lines.next().?[29..], 10);
            var false_dest = try std.fmt.parseInt(usize, lines.next().?[30..], 10);
            input.monkeys.appendAssumeCapacity(Monkey{
                .items1 = all_items1,
                .items2 = all_items2,
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

fn part1(input: Input, output: *output_type) !void {
    var round:usize = 0;
    var monkeys = input.monkeys; // need a mutable copy
    var inspect_counts_array = try std.BoundedArray(i64, 8).init(0);
    inspect_counts_array.appendNTimesAssumeCapacity(0, input.monkeys.len);
    var inspect_counts = inspect_counts_array.slice();
    while(round < 20) : (round += 1) {
        for(monkeys.slice()) |*monkey,monkey_index| {
            //std.debug.print("Monkey {d}:\n", .{monkey_index});
            for(monkey.items1.slice()) |*item| {
                //std.debug.print("  Monkey inspects an item with a worry level of {d}.\n", .{item.*});
                // Update worry level
                item.* = switch(monkey.op) {
                    '+' => item.* + monkey.op_arg,
                    '*' => item.* * if (monkey.op_arg == -1) item.* else monkey.op_arg,
                    else => unreachable,
                };
                //std.debug.print("  Worry level is increased to {d}.\n", .{item.*});
                // after inspection but before throwing, worry is divided by some factor
                item.* = @divFloor(item.*, 3);
                //std.debug.print("    Monkey gets bored with item. Worry level is divided by 3 to {d}\n", .{item.*});
                // Test worry level & throw
                const divisible = @rem(item.*, monkey.test_divisor) == 0;
                const dest_index = if (divisible) monkey.true_dest else monkey.false_dest;
                //std.debug.print("    Item with worry level {d} is thrown to monkey {d}\n", .{item.*, dest_index});
                monkeys.slice()[dest_index].items1.appendAssumeCapacity(item.*);
            }
            // Clear all thrown items at once
            inspect_counts[monkey_index] += @intCast(i64,monkey.items1.len);
            monkey.items1.resize(0) catch unreachable;
        }
    }
    // Sort monkeys by inspect counts
    std.sort.sort(i64, inspect_counts, {}, comptime std.sort.desc(i64));
    output.* = inspect_counts[0] * inspect_counts[1];
}

fn part2(input: Input, output: *output_type) !void {
    var round:usize = 0;
    var monkeys = input.monkeys; // need a mutable copy
    var inspect_counts_array = try std.BoundedArray(i64, 8).init(0);
    inspect_counts_array.appendNTimesAssumeCapacity(0, input.monkeys.len);
    var inspect_counts = inspect_counts_array.slice();
    while(round < 10000) : (round += 1) {
        for(monkeys.slice()) |*monkey,monkey_index| {
            //std.debug.print("Monkey {d}:\n", .{monkey_index});
            for(monkey.items2.slice()) |*item| {
                //std.debug.print("  Monkey inspects an item with a worry level of {d}.\n", .{item.*});
                // Update worry level
                item.*.increase(monkey.op, monkey.op_arg);
                //std.debug.print("    Monkey gets bored with item. Worry level is divided by 3 to {d}\n", .{item.*});
                // Test worry level & throw
                const divisible = item.divisible(monkey.test_divisor);
                const dest_index = if (divisible) monkey.true_dest else monkey.false_dest;
                //std.debug.print("    Item with worry level {d} is thrown to monkey {d}\n", .{item.*, dest_index});
                monkeys.slice()[dest_index].items2.appendAssumeCapacity(item.*);
            }
            // Clear all thrown items at once
            inspect_counts[monkey_index] += @intCast(i64,monkey.items2.len);
            monkey.items2.resize(0) catch unreachable;
        }
    }
    // Sort monkeys by inspect counts
    std.sort.sort(i64, inspect_counts, {}, comptime std.sort.desc(i64));
    output.* = inspect_counts[0] * inspect_counts[1];
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
const part1_test_solution: ?i64 = 10605;
const part1_solution: ?i64 = 113220;
const part2_test_solution: ?i64 = 2713310158;
const part2_solution: ?i64 = 0;

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
