const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day02.txt");

const Round = struct {
    opponent_move_code: u8,
    my_move_code: u8,
};

const Input = struct {
    allocator: std.mem.Allocator,
    rounds: std.BoundedArray(Round, 2500),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var input = Input{
            .allocator = allocator,
            .rounds = try std.BoundedArray(Round, 2500).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            input.rounds.appendAssumeCapacity(Round{ .opponent_move_code = line[0] - 'A', .my_move_code = line[2] - 'X' });
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Move = enum(u4) {
    R,
    P,
    S,
};

const move_scores: [3]i64 = .{ 1, 2, 3 };
const result_scores: [9]i64 = .{
    3, 6, 0, // R/R, R/P, R/S
    0, 3, 6, // P/R, P,P, P/S
    6, 0, 3, // S/R, S/P, S/S
};
fn part1(input: Input) !i64 {
    var total_score: i64 = 0;
    const opponent_move_map: [3]Move = .{ Move.R, Move.P, Move.S };
    const my_move_map: [3]Move = .{ Move.R, Move.P, Move.S };
    for (input.rounds.constSlice()) |round| {
        const opponent_move = opponent_move_map[round.opponent_move_code];
        const my_move = my_move_map[round.my_move_code];
        total_score += move_scores[@enumToInt(my_move)] + result_scores[@enumToInt(opponent_move) * 3 + @enumToInt(my_move)];
    }
    return total_score;
}

const move_for_result: [9]Move = .{
    Move.S, Move.R, Move.P, // R/L, R/D, R/W
    Move.R, Move.P, Move.S, // P/L, P,D, P/W
    Move.P, Move.S, Move.R, // S/L, S/D, S/W
};

fn part2(input: Input) !i64 {
    var total_score: i64 = 0;
    const opponent_move_map: [3]Move = .{ Move.R, Move.P, Move.S };
    for (input.rounds.constSlice()) |round| {
        const opponent_move = opponent_move_map[round.opponent_move_code];
        const desired_result = round.my_move_code;
        const my_move = move_for_result[@enumToInt(opponent_move) * 3 + desired_result];
        total_score += move_scores[@enumToInt(my_move)] + result_scores[@enumToInt(opponent_move) * 3 + @enumToInt(my_move)];
    }
    return total_score;
}

const test_data =
    \\A Y
    \\B X
    \\C Z
;
const part1_test_solution: ?i64 = 15;
const part1_solution: ?i64 = 11873;
const part2_test_solution: ?i64 = 12;
const part2_solution: ?i64 = 12014;

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

test "day02_part1" {
    try testPart1(std.testing.allocator);
}

test "day02_part2" {
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
