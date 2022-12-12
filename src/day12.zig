const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day12.txt");

const Vec2 = struct {
    x: usize,
    y: usize,
};

const Input = struct {
    allocator: std.mem.Allocator,
    heightfield: [66][66]u8,
    dim: Vec2,
    start: Vec2,
    goal: Vec2,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .heightfield = undefined,
            .dim = Vec2{ .x = 0, .y = 0 },
            .start = Vec2{ .x = 0, .y = 0 },
            .goal = Vec2{ .x = 0, .y = 0 },
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            input.dim.x = line.len;
            std.mem.copy(u8, &input.heightfield[input.dim.y], line);
            if (std.mem.indexOf(u8, line, "S")) |x| {
                input.start = Vec2{ .x = x, .y = input.dim.y };
                input.heightfield[input.dim.y][x] = 'a';
            }
            if (std.mem.indexOf(u8, line, "E")) |x| {
                input.goal = Vec2{ .x = x, .y = input.dim.y };
                input.heightfield[input.dim.y][x] = 'z';
            }
            input.dim.y += 1;
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const UNVISITED: i64 = std.math.maxInt(i64);

fn updateCandidateUp(lowest: *[66][66]i64, candidates: *std.BoundedArray(Vec2, 10000), input: Input, p: Vec2, current_height: u8, distance_to_p: i64) void {
    if (p.x >= input.dim.x or p.y >= input.dim.y)
        return; // out of bounds
    // Can we move there from here?
    if (input.heightfield[p.y][p.x] > current_height + 1)
        return; // p is too high
    if (lowest[p.y][p.x] == UNVISITED)
        candidates.appendAssumeCapacity(p);
    lowest[p.y][p.x] = std.math.min(lowest[p.y][p.x], distance_to_p);
}

fn updateCandidateDown(lowest: *[66][66]i64, candidates: *std.BoundedArray(Vec2, 10000), input: Input, p: Vec2, current_height: u8, distance_to_p: i64) void {
    if (p.x >= input.dim.x or p.y >= input.dim.y)
        return; // out of bounds
    // Can we move there from here?
    if (current_height > input.heightfield[p.y][p.x] + 1)
        return; // p is too high
    if (lowest[p.y][p.x] == UNVISITED)
        candidates.appendAssumeCapacity(p);
    lowest[p.y][p.x] = std.math.min(lowest[p.y][p.x], distance_to_p);
}

fn shortest_path_distance(input:Input, start:Vec2, goal:?Vec2) !i64 {
    var lowest = comptime blk: {
        @setEvalBranchQuota(10000);
        var a: [66][66]i64 = undefined;
        for (a) |*row| {
            for (row) |*v| {
                v.* = UNVISITED;
            }
        }
        break :blk a;
    };
    var candidates = try std.BoundedArray(Vec2, 10000).init(0);
    candidates.appendAssumeCapacity(start);
    lowest[start.y][start.x] = 0; // distance to the starting point is 0, we're already there
    while (candidates.len > 0) {
        // find the next candidate to explore.
        // Djikstra: pick the one with the minimum "lowest" value.
        // A*: include a heuristic of the estimated (Manhattan) distance to the goal.
        // Once again, Djikstra is faster?
        var min_d: i64 = UNVISITED;
        var min_d_index: usize = undefined;
        for (candidates.constSlice()) |c, i| {
            const ex = 0;//try std.math.absInt(@intCast(i64, goal.?.x) - @intCast(i64, c.x));
            const ey = 0;//try std.math.absInt(@intCast(i64, goal.?.y) - @intCast(i64, c.y));
            const manhattan_distance_to_goal = ex + ey;
            const estimated_distance_to_goal = lowest[c.y][c.x] + manhattan_distance_to_goal;
            if (estimated_distance_to_goal < min_d) {
                min_d = estimated_distance_to_goal;
                min_d_index = i;
            }
        }
        // Select the candidate with the lowest estimated distance.
        // We know for sure that its current lowest distance is correct.
        const c = candidates.swapRemove(min_d_index);
        //std.debug.print("Visited {d},{d} h={c} d={d}\n", .{ c.x, c.y, input.heightfield[c.y][c.x], min_d });
        if (goal) |g| {
            if (c.x == g.x and c.y == g.y) {
                return lowest[g.y][g.x];
            }
        } else {
            if (input.heightfield[c.y][c.x] == 'a') {
                return lowest[c.y][c.x];
            }
        }
        const distance_to_c = lowest[c.y][c.x];
        const ch = input.heightfield[c.y][c.x];
        if (goal) |_| {
            updateCandidateUp(&lowest, &candidates, input, Vec2{ .x = c.x, .y = c.y + 1 }, ch, distance_to_c + 1);
            updateCandidateUp(&lowest, &candidates, input, Vec2{ .x = c.x, .y = c.y -% 1 }, ch, distance_to_c + 1);
            updateCandidateUp(&lowest, &candidates, input, Vec2{ .x = c.x + 1, .y = c.y }, ch, distance_to_c + 1);
            updateCandidateUp(&lowest, &candidates, input, Vec2{ .x = c.x -% 1, .y = c.y }, ch, distance_to_c + 1);
        } else {
            updateCandidateDown(&lowest, &candidates, input, Vec2{ .x = c.x, .y = c.y + 1 }, ch, distance_to_c + 1);
            updateCandidateDown(&lowest, &candidates, input, Vec2{ .x = c.x, .y = c.y -% 1 }, ch, distance_to_c + 1);
            updateCandidateDown(&lowest, &candidates, input, Vec2{ .x = c.x + 1, .y = c.y }, ch, distance_to_c + 1);
            updateCandidateDown(&lowest, &candidates, input, Vec2{ .x = c.x -% 1, .y = c.y }, ch, distance_to_c + 1);
        }
    }
    unreachable;
}

fn part1(input: Input, output: *output_type) !void {
    output.* = try shortest_path_distance(input, input.start, input.goal);
}

fn part2(input: Input, output: *output_type) !void {
    output.* = try shortest_path_distance(input, input.goal, null);
}

const test_data =
    \\Sabqponm
    \\abcryxxl
    \\accszExk
    \\acctuvwj
    \\abdefghi
;
const part1_test_solution: ?i64 = 31;
const part1_solution: ?i64 = 370;
const part2_test_solution: ?i64 = 29;
const part2_solution: ?i64 = 363;

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

test "day12_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day12_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
