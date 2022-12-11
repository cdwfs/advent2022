const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day10.txt");

const Instruction = union(enum) {
    noop: void,
    addx: Addx,

    const Addx = struct {
        arg:i64,
    };
};

const Input = struct {
    allocator: std.mem.Allocator,
    instructions: std.BoundedArray(Instruction,150),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .instructions = try std.BoundedArray(Instruction,150).init(0),
        };
        errdefer input.deinit();

        while(lines.next()) |line| {
            const inst = if (line[0] == 'n')
                Instruction{.noop = {}}
            else
                Instruction{.addx = Instruction.Addx{.arg = try std.fmt.parseInt(i64, line[5..], 10)}};
            input.instructions.appendAssumeCapacity(inst);
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input, output: *output_type) !void {
    var x:i64 = 1;
    var t:i64 = 0;
    var threshold:i64 = 20;
    var result:i64 = 0;
    for(input.instructions.constSlice()) |inst| {
        switch(inst) {
            .noop => t += 1,
            .addx => t += 2,
        }
        if (t >= threshold) {
            const signal_strength = threshold * x;
            result += signal_strength;
            threshold += 40;
            if (threshold > 220)
                break;
        }
        switch(inst) {
            .noop => {},
            .addx => |addx| x += addx.arg,
        }
    }
    output.* = result;
}

fn drawPixel(x:i64,t:i64) void {
    const px:i64 = @mod(t, 40);
    if (px == 0)
        std.debug.print("\n", .{});
    const d:i64 = std.math.absInt(px-x) catch unreachable;
    const c:u8 = if (d <= 1) '#' else '.';
    std.debug.print("{c}", .{c});
}

fn part2(input: Input, output: *output_type) !void {
    var x:i64 = 1;
    var t:i64 = 0;
    for(input.instructions.constSlice()) |inst| {
        switch(inst) {
            .noop => {
                drawPixel(x,t);
                t += 1;
            },
            .addx => {
                drawPixel(x,t);
                t += 1;
                drawPixel(x,t);
                t += 1;
            },
        }
        if (t >= 240) {
            break;
        }
        switch(inst) {
            .noop => {},
            .addx => |addx| x += addx.arg,
        }
    }
    output.* = -1;
}

const test_data =
    \\addx 15
    \\addx -11
    \\addx 6
    \\addx -3
    \\addx 5
    \\addx -1
    \\addx -8
    \\addx 13
    \\addx 4
    \\noop
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx -35
    \\addx 1
    \\addx 24
    \\addx -19
    \\addx 1
    \\addx 16
    \\addx -11
    \\noop
    \\noop
    \\addx 21
    \\addx -15
    \\noop
    \\noop
    \\addx -3
    \\addx 9
    \\addx 1
    \\addx -3
    \\addx 8
    \\addx 1
    \\addx 5
    \\noop
    \\noop
    \\noop
    \\noop
    \\noop
    \\addx -36
    \\noop
    \\addx 1
    \\addx 7
    \\noop
    \\noop
    \\noop
    \\addx 2
    \\addx 6
    \\noop
    \\noop
    \\noop
    \\noop
    \\noop
    \\addx 1
    \\noop
    \\noop
    \\addx 7
    \\addx 1
    \\noop
    \\addx -13
    \\addx 13
    \\addx 7
    \\noop
    \\addx 1
    \\addx -33
    \\noop
    \\noop
    \\noop
    \\addx 2
    \\noop
    \\noop
    \\noop
    \\addx 8
    \\noop
    \\addx -1
    \\addx 2
    \\addx 1
    \\noop
    \\addx 17
    \\addx -9
    \\addx 1
    \\addx 1
    \\addx -3
    \\addx 11
    \\noop
    \\noop
    \\addx 1
    \\noop
    \\addx 1
    \\noop
    \\noop
    \\addx -13
    \\addx -19
    \\addx 1
    \\addx 3
    \\addx 26
    \\addx -30
    \\addx 12
    \\addx -1
    \\addx 3
    \\addx 1
    \\noop
    \\noop
    \\noop
    \\addx -9
    \\addx 18
    \\addx 1
    \\addx 2
    \\noop
    \\noop
    \\addx 9
    \\noop
    \\noop
    \\noop
    \\addx -1
    \\addx 2
    \\addx -37
    \\addx 1
    \\addx 3
    \\noop
    \\addx 15
    \\addx -21
    \\addx 22
    \\addx -6
    \\addx 1
    \\noop
    \\addx 2
    \\addx 1
    \\noop
    \\addx -10
    \\noop
    \\noop
    \\addx 20
    \\addx 1
    \\addx 2
    \\addx 2
    \\addx -6
    \\addx -11
    \\noop
    \\noop
    \\noop
;
const part1_test_solution: ?i64 = 13140;
const part1_solution: ?i64 = 13740;
const part2_test_solution: ?i64 = -1;
const part2_solution: ?i64 = -1; // ZUPRFECL

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

test "day10_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day10_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
