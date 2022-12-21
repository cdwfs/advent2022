const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day21.txt");

const Op = enum {
    add,
    mul,
    sub,
    div,
    num,
    eql,
    hum,
};

const Monkey = struct {
    id: u16,
    name: []const u8,
    op: Op,
    arg1: i64,
    arg2: i64,
    result: ?i64 = null,
};

const Input = struct {
    allocator: std.mem.Allocator,
    monkeys: std.BoundedArray(Monkey, 3000),
    root_id: u16 = undefined,
    humn_id: u16 = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .monkeys = try std.BoundedArray(Monkey, 3000).init(0),
        };
        errdefer input.deinit();

        // first pass to populate name-to-ID map
        var name_to_id = std.StringHashMap(u16).init(allocator);
        defer name_to_id.deinit();
        try name_to_id.ensureTotalCapacity(3000);
        while (lines.next()) |line| {
            name_to_id.putAssumeCapacity(line[0..4], @intCast(u16, name_to_id.count()));
            //std.debug.print("{s} -> {d}\n", .{line[0..4], name_to_id.get(line[0..4]).?});
        }
        input.root_id = name_to_id.get("root").?;
        input.humn_id = name_to_id.get("humn").?;

        // second pass to create monkeys
        lines = std.mem.tokenize(u8, input_text, eol);
        var seen_as_arg = std.StringHashMap(void).init(allocator);
        defer seen_as_arg.deinit();
        try seen_as_arg.ensureTotalCapacity(3000);
        while (lines.next()) |line| {
            var arg1: i64 = 0;
            var arg2: i64 = 0;
            var op: Op = undefined;
            if (line[6] >= '0' and line[6] <= '9') {
                op = .num;
                arg1 = try std.fmt.parseInt(i64, line[6..], 10);
            } else {
                op = switch (line[11]) {
                    '+' => .add,
                    '-' => .sub,
                    '*' => .mul,
                    '/' => .div,
                    else => unreachable,
                };

                const name1 = line[6..10];
                const name2 = line[13..17];
                if (seen_as_arg.contains(name1)) {
                    std.debug.print("{s} appears as an arg for >1 monkey!\n", .{name1});
                }
                arg1 = name_to_id.get(name1).?;
                seen_as_arg.putAssumeCapacity(name1, {});

                if (seen_as_arg.contains(name2)) {
                    std.debug.print("{s} appears as an arg for >1 monkey!\n", .{name2});
                }
                arg2 = name_to_id.get(name2).?;
                seen_as_arg.putAssumeCapacity(name2, {});
            }
            input.monkeys.appendAssumeCapacity(Monkey{
                .id = name_to_id.get(line[0..4]).?,
                .name = line[0..4],
                .op = op,
                .arg1 = arg1,
                .arg2 = arg2,
                .result = if (op == .num) arg1 else null,
            });
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn evaluate(monkeys: []Monkey, id: u16) ?i64 {
    if (monkeys[id].result == null) {
        if (monkeys[id].op == .hum) {
            return null;
        }
        var result1 = evaluate(monkeys, @intCast(u16, monkeys[id].arg1));
        var result2 = evaluate(monkeys, @intCast(u16, monkeys[id].arg2));
        if (result1 == null or result2 == null) {
            return null;
        }
        switch (monkeys[id].op) {
            .add => monkeys[id].result = result1.? + result2.?,
            .sub => monkeys[id].result = result1.? - result2.?,
            .mul => monkeys[id].result = result1.? * result2.?,
            .div => monkeys[id].result = std.math.divExact(i64, result1.?, result2.?) catch unreachable,
            .num => unreachable, // already handled in initialization, so their result is never null
            .eql => unreachable, // TODO for part 2
            .hum => unreachable, // TODO for part 2
        }
    }
    return monkeys[id].result.?;
}

fn inverse_evaluate(monkeys: []Monkey, id: u16) void {
    // "num" or hum nodes are leaves, and should not need any further processing
    if (monkeys[id].op == .num or monkeys[id].op == .hum) {
        std.debug.assert(monkeys[id].result != null);
        return;
    }
    const expected_result = monkeys[id].result.?;
    const id1 = @intCast(u16, monkeys[id].arg1);
    const id2 = @intCast(u16, monkeys[id].arg2);
    if (monkeys[id1].result == null) {
        // compute left child's result and recurse
        const result2 = monkeys[id2].result.?;
        switch (monkeys[id].op) {
            .add => monkeys[id1].result = expected_result - result2, // R1+R2=E -> R1=E-R2
            .sub => monkeys[id1].result = expected_result + result2, // R1-R2=E -> R1=E+R2
            .mul => monkeys[id1].result = std.math.divExact(i64, expected_result, result2) catch unreachable, // R1*R2=E -> R1=E/R2
            .div => monkeys[id1].result = expected_result * result2, // R1/R2=E -> E1=E*R2
            .num => unreachable, // leaf node; handled above
            .eql => monkeys[id1].result = result2,
            .hum => unreachable, // lead node; handled above
        }
        inverse_evaluate(monkeys, id1);
    } else {
        // compute right child's result and recurse
        const result1 = monkeys[id1].result.?;
        switch (monkeys[id].op) {
            .add => monkeys[id2].result = expected_result - result1, // R1+R2=E -> R2=E-R1
            .sub => monkeys[id2].result = result1 - expected_result, // R1-R2=E -> R1-E=R2
            .mul => monkeys[id2].result = std.math.divExact(i64, expected_result, result1) catch unreachable, // R1*R2=E -> R2=E/R1
            .div => monkeys[id2].result = std.math.divExact(i64, result1, expected_result) catch unreachable, // R1/R2=E -> R1/E=R2
            .num => unreachable, // leaf node; handled above
            .eql => monkeys[id2].result = result1,
            .hum => unreachable, // lead node; handled above
        }
        inverse_evaluate(monkeys, id2);
    }
}

fn part1(input: Input, output: *output_type) !void {
    var monkeys = input.monkeys;
    output.* = evaluate(monkeys.slice(), input.root_id).?;
}

fn part2(input: Input, output: *output_type) !void {
    var monkeys_arr = input.monkeys;
    var monkeys = monkeys_arr.slice();
    monkeys[input.root_id].op = .eql;
    monkeys[input.humn_id].op = .hum;
    monkeys[input.humn_id].result = null;
    // pass 1 to compute results where possible
    _ = evaluate(monkeys, input.root_id);
    // pass 2 to compute missing args given expected final result.
    monkeys[input.root_id].result = 0; // actual value doesn't matter, so long as it's non-null
    inverse_evaluate(monkeys, input.root_id);

    output.* = monkeys[input.humn_id].result.?;
}

const test_data =
    \\root: pppw + sjmn
    \\dbpl: 5
    \\cczh: sllz + lgvd
    \\zczc: 2
    \\ptdq: humn - dvpt
    \\dvpt: 3
    \\lfqf: 4
    \\humn: 5
    \\ljgn: 2
    \\sjmn: drzm * dbpl
    \\sllz: 4
    \\pppw: cczh / lfqf
    \\lgvd: ljgn * ptdq
    \\drzm: hmdt - zczc
    \\hmdt: 32
;
const part1_test_solution: ?i64 = 152;
const part1_solution: ?i64 = 291_425_799_367_130;
const part2_test_solution: ?i64 = 301;
const part2_solution: ?i64 = 3_219_579_395_609;

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

test "day21_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day21_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
