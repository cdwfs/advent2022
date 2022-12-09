const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day08.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    heights: [100][100]u8,
    dim_x: usize,
    dim_y: usize,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var input = Input{
            .allocator = allocator,
            .heights = undefined,
            .dim_x = 0,
            .dim_y = 0,
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            input.dim_x = line.len;
            std.mem.copy(u8, &input.heights[input.dim_y], line);
            input.dim_y += 1;
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Coord2 = struct {
    x: usize,
    y: usize,
};
fn part1(input: Input, output: *output_type) !void {
    var visible: [100][100]u8 = undefined;
    for (visible) |*row| {
        std.mem.set(u8, row, 0);
    }
    var visibleCount: i64 = 0;

    // find visibles in each row
    var y_range = util.range(usize, .{.end=input.dim_y});
    while (y_range.next()) |y| {
        var maxh: u8 = 0;
        //std.debug.print("checking row {d}...\n", .{y});
        var x_range = util.range(usize, .{.end=input.dim_x});
        while (x_range.next()) |x| {
            const h = input.heights[y][x];
            if (h > maxh) {
                maxh = h;
                if (visible[y][x] != 1) {
                    visibleCount += 1;
                    visible[y][x] = 1;
                    //std.debug.print("- [{d},{d}] h={d} is visible. count = {d}\n", .{y,x,h-'0',visibleCount});
                }
            }
        }
        // count again in the opposite direction
        maxh = 0;
        //std.debug.print("reverse-checking row {d}...\n", .{y});
        x_range = util.range(usize, .{.start=input.dim_x-1, .end=0, .step=-1});
        while (x_range.next()) |x| {
            const h = input.heights[y][x];
            if (h > maxh) {
                maxh = h;
                if (visible[y][x] != 1) {
                    visibleCount += 1;
                    visible[y][x] = 1;
                    //std.debug.print("- [{d},{d}] h={d} is visible. count = {d}\n", .{y,x,h-'0',visibleCount});
                }
            }
        }
    }
    // find visibles in each column
    var x_range = util.range(usize, .{.end=input.dim_x});
    while (x_range.next()) |x| {
        var maxh: u8 = 0;
        //std.debug.print("checking column {d}...\n", .{x});
        y_range = util.range(usize, .{.end=input.dim_y});
        while (y_range.next()) |y| {
            const h = input.heights[y][x];
            if (h > maxh) {
                maxh = h;
                if (visible[y][x] != 1) {
                    visibleCount += 1;
                    visible[y][x] = 1;
                    //std.debug.print("- [{d},{d}] h={d} is visible. count = {d}\n", .{y,x,h-'0',visibleCount});
                }
            }
        }
        // count again in the opposite direction
        maxh = 0;
        //std.debug.print("reverse-checking column {d}...\n", .{x});
        y_range = util.range(usize, .{.start=input.dim_y-1, .end=0, .step=-1});
        while (y_range.next()) |y| {
            const h = input.heights[y][x];
            if (h > maxh) {
                maxh = h;
                if (visible[y][x] != 1) {
                    visibleCount += 1;
                    visible[y][x] = 1;
                    //std.debug.print("- [{d},{d}] h={d} is visible. count = {d}\n", .{y,x,h-'0',visibleCount});
                }
            }
        }
    }

    //y=0;
    //while(y<input.dim_y) : (y+=1) {
    //    x=0;
    //    while(x<input.dim_x) : (x+=1) {
    //        std.debug.print("{d}", .{visible[y][x]});
    //    }
    //    std.debug.print("\n", .{});
    //}
    output.* = visibleCount;
}

fn part2(input: Input, output: *output_type) !void {
    var best_score: i64 = 0;
    var ty: usize = 0;
    while (ty < input.dim_y) : (ty += 1) {
        var tx: usize = 0;
        while (tx < input.dim_x) : (tx += 1) {
            const th = input.heights[ty][tx];
            // look west
            var wx = tx -% 1;
            var score_w: i64 = 0;
            while (wx < input.dim_x) : (wx -%= 1) {
                const h = input.heights[ty][wx];
                score_w += 1;
                if (h >= th)
                    break;
            }
            if (score_w == 0)
                continue;
            // look north
            var ny = ty -% 1;
            var score_n: i64 = 0;
            while (ny < input.dim_y) : (ny -%= 1) {
                const h = input.heights[ny][tx];
                score_n += 1;
                if (h >= th)
                    break;
            }
            if (score_n == 0)
                continue;
            // look east
            var ex = tx + 1;
            var score_e: i64 = 0;
            while (ex < input.dim_x) : (ex += 1) {
                const h = input.heights[ty][ex];
                score_e += 1;
                if (h >= th)
                    break;
            }
            if (score_e == 0)
                continue;
            // look south
            var sy = ty + 1;
            var score_s: i64 = 0;
            while (sy < input.dim_y) : (sy += 1) {
                const h = input.heights[sy][tx];
                score_s += 1;
                if (h >= th)
                    break;
            }
            if (score_s == 0)
                continue;

            best_score = std.math.max(best_score, score_w * score_n * score_e * score_s);
            //std.debug.print("[{d},{d}] h={d} score={d}*{d}*{d}*{d}={d}\n", .{ty,tx,th-'0', score_n, score_w, score_e, score_s, score_w * score_n * score_e * score_s});
        }
    }
    output.* = best_score;
}

const test_data =
    \\30373
    \\25512
    \\65332
    \\33549
    \\35390
;
const part1_test_solution: ?i64 = 21;
const part1_solution: ?i64 = 1832;
const part2_test_solution: ?i64 = 8;
const part2_solution: ?i64 = 157320;

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

test "day08_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day08_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
