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
fn part1(input: Input, output: *output_type) !void {
    var total_score: i64 = 0;
    const opponent_move_map: [3]Move = .{ Move.R, Move.P, Move.S };
    const my_move_map: [3]Move = .{ Move.R, Move.P, Move.S };
    for (input.rounds.constSlice()) |round| {
        const opponent_move = opponent_move_map[round.opponent_move_code];
        const my_move = my_move_map[round.my_move_code];
        total_score += move_scores[@enumToInt(my_move)] + result_scores[@enumToInt(opponent_move) * 3 + @enumToInt(my_move)];
    }
    output.* = total_score;
}

const move_for_result: [9]Move = .{
    Move.S, Move.R, Move.P, // R/L, R/D, R/W
    Move.R, Move.P, Move.S, // P/L, P,D, P/W
    Move.P, Move.S, Move.R, // S/L, S/D, S/W
};

fn part2(input: Input, output: *output_type) !void {
    var total_score: i64 = 0;
    const opponent_move_map: [3]Move = .{ Move.R, Move.P, Move.S };
    for (input.rounds.constSlice()) |round| {
        const opponent_move = opponent_move_map[round.opponent_move_code];
        const desired_result = round.my_move_code;
        const my_move = move_for_result[@enumToInt(opponent_move) * 3 + desired_result];
        total_score += move_scores[@enumToInt(my_move)] + result_scores[@enumToInt(opponent_move) * 3 + @enumToInt(my_move)];
    }
    output.* = total_score;
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
