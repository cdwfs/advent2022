const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day14.txt");

const Vec2 = @Vector(2, usize);
const MAX = Vec2{ 700, 180 };
const Input = struct {
    allocator: std.mem.Allocator,
    cells: [MAX[1]][MAX[0]]u8,
    y_abyss: usize,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .cells = undefined,
            .y_abyss = 0,
        };
        errdefer input.deinit();

        for (input.cells) |*row| {
            for (row.*) |*cell| {
                cell.* = '.';
            }
        }
        while (lines.next()) |line| {
            var first: bool = true;
            var pt0: Vec2 = undefined;
            var points = std.mem.split(u8, line, " -> ");
            while (points.next()) |point| {
                var coords = std.mem.split(u8, point, ",");
                const pt1 = Vec2{ try std.fmt.parseInt(usize, coords.next().?, 10), try std.fmt.parseInt(usize, coords.next().?, 10) };
                if (!first) {
                    if (pt0[0] == pt1[0]) {
                        const x = pt0[0];
                        const y0 = std.math.min(pt0[1], pt1[1]);
                        const y1 = std.math.max(pt0[1], pt1[1]);
                        var y: usize = y0;
                        while (y <= y1) : (y += 1) {
                            input.cells[y][x] = '#';
                        }
                    } else {
                        const y = pt0[1];
                        const x0 = std.math.min(pt0[0], pt1[0]);
                        const x1 = std.math.max(pt0[0], pt1[0]);
                        var x: usize = x0;
                        while (x <= x1) : (x += 1) {
                            input.cells[y][x] = '#';
                        }
                    }
                }
                pt0 = pt1;
                input.y_abyss = std.math.max(input.y_abyss, pt0[1] + 1);
                first = false;
            }
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const SAND_SOURCE = Vec2{ 500, 0 };

fn equilibrium_count(y_abyss: usize, cells: *[MAX[1]][MAX[0]]u8) i64 {
    var sand_path = std.BoundedArray(Vec2, MAX[1]).init(0) catch unreachable;
    sand_path.appendAssumeCapacity(SAND_SOURCE);
    var count: i64 = 0;
    while (true) {
        // Start at the end of the previous path
        var i: usize = sand_path.len - 1;
        var p = sand_path.constSlice()[i];
        var pn: Vec2 = Vec2{ p[0], p[1] + 1 };
        if (pn[1] >= y_abyss)
            break; // the path now leads to the abyss, and we're done
        // where would sand fall from p?
        if (cells[pn[1]][pn[0]] == '.') {
            // no change, pn is already correct
        } else if (cells[pn[1]][p[0] - 1] == '.') {
            pn[0] -%= 1;
        } else if (cells[pn[1]][p[0] + 1] == '.') {
            pn[0] +%= 1;
        } else {
            // at rest
            count += 1;
            cells[p[1]][p[0]] = 'o';
            // back the path up one step
            _ = sand_path.pop();
            if (p[0] == SAND_SOURCE[0] and p[1] == SAND_SOURCE[1])
                break; // part 2 success criteria
            continue;
        }
        // extend path
        sand_path.appendAssumeCapacity(pn);
    }
    return count;
}

fn part1(input: Input, output: *output_type) !void {
    var cells = input.cells; // need mutable copy
    output.* = equilibrium_count(input.y_abyss, &cells);
}

fn part2(input: Input, output: *output_type) !void {
    var cells = input.cells; // need mutable copy
    const y_floor = input.y_abyss + 1;
    std.mem.set(u8, &cells[y_floor], '#');
    output.* = equilibrium_count(y_floor + 1, &cells);
}

const test_data =
    \\498,4 -> 498,6 -> 496,6
    \\503,4 -> 502,4 -> 502,9 -> 494,9
;
const part1_test_solution: ?i64 = 24;
const part1_solution: ?i64 = 799;
const part2_test_solution: ?i64 = 93;
const part2_solution: ?i64 = 29076;

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

test "day14_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day14_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
