const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day09.txt");

const Move = struct {
    dir: u8,
    steps: i8,
};

const Input = struct {
    allocator: std.mem.Allocator,
    moves: std.BoundedArray(Move, 2000),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var input = Input{
            .allocator = allocator,
            .moves = try std.BoundedArray(Move, 2000).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            input.moves.appendAssumeCapacity(Move{ .dir = line[0], .steps = try std.fmt.parseInt(i8, line[2..], 10) });
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Vec2 = struct {
    x:i64,
    y:i64,
};
const moves_for_offset:[5][5]?Vec2 = .{
    .{Vec2{.x=-1,.y=-1}, Vec2{.x=-1,.y=-1}, Vec2{.x= 0,.y=-1}, Vec2{.x= 1,.y=-1}, Vec2{.x= 1,.y=-1}},
    .{Vec2{.x=-1,.y=-1}, Vec2{.x= 0,.y= 0}, Vec2{.x= 0,.y= 0}, Vec2{.x= 0,.y= 0}, Vec2{.x= 1,.y=-1}},
    .{Vec2{.x=-1,.y= 0}, Vec2{.x= 0,.y= 0}, Vec2{.x= 0,.y= 0}, Vec2{.x= 0,.y= 0}, Vec2{.x= 1,.y= 0}},
    .{Vec2{.x=-1,.y= 1}, Vec2{.x= 0,.y= 0}, Vec2{.x= 0,.y= 0}, Vec2{.x= 0,.y= 0}, Vec2{.x= 1,.y= 1}},
    .{Vec2{.x=-1,.y= 1}, Vec2{.x=-1,.y= 1}, Vec2{.x= 0,.y= 1}, Vec2{.x= 1,.y= 1}, Vec2{.x= 1,.y= 1}},
};
fn moveTail(head:Vec2, tail:*Vec2) !void {
    const offset = Vec2{.x=head.x - tail.x, .y=head.y - tail.y};
    const tail_move = moves_for_offset[@intCast(usize,2 + offset.y)][@intCast(usize, 2 + offset.x)].?;
    tail.x += tail_move.x;
    tail.y += tail_move.y;
}

fn part1(input: Input, output: *output_type) !void {
    var head = Vec2{.x=0, .y=0};
    var tail = Vec2{.x=0, .y=0};
    var visited = std.AutoHashMap(Vec2, void).init(input.allocator);
    defer visited.deinit();
    try visited.ensureTotalCapacity(@intCast(u32, input.moves.len*3));
    visited.putAssumeCapacity(tail, {});
    for(input.moves.constSlice()) |m| {
        var i:i64 = 0;
        while(i < m.steps) : (i += 1) {
            switch(m.dir) {
                'R' => head.x += 1,
                'L' => head.x -= 1,
                'U' => head.y += 1,
                'D' => head.y -= 1,
                else => {},
            }
            try moveTail(head, &tail);
            visited.putAssumeCapacity(tail, {});
        }
    }
    output.* = @intCast(i64, visited.count());
}

fn part2(input: Input, output: *output_type) !void {
    var segments:[10]Vec2 = .{Vec2{.x=0,.y=0}} ** 10;
    var visited = std.AutoHashMap(Vec2, void).init(input.allocator);
    defer visited.deinit();
    try visited.ensureTotalCapacity(@intCast(u32, input.moves.len*4));
    visited.putAssumeCapacity(segments[9], {});
    for(input.moves.constSlice()) |m| {
        var i:i64 = 0;
        while(i < m.steps) : (i += 1) {
            switch(m.dir) {
                'R' => segments[0].x += 1,
                'L' => segments[0].x -= 1,
                'U' => segments[0].y += 1,
                'D' => segments[0].y -= 1,
                else => {},
            }
            var j:usize=1;
            while(j < 10) : (j+=1) {
                //std.debug.print("seg{d}=[{d},{d}] seg{d}={d},{d}\n", .{j-1, segments[j-1].x, segments[j-1].y, j, segments[j].x, segments[j].y});
                try moveTail(segments[j-1], &segments[j]);
            }
            visited.putAssumeCapacity(segments[9], {});
        }
    }
    output.* = @intCast(i64, visited.count());
}

const test_data =
    \\R 4
    \\U 4
    \\L 3
    \\D 1
    \\R 4
    \\D 1
    \\L 5
    \\R 2
;
const part1_test_solution: ?i64 = 13;
const part1_solution: ?i64 = 6503;
const part2_test_solution: ?i64 = 1;
const part2_solution: ?i64 = 2724;

const test_data2 =
    \\R 5
    \\U 8
    \\L 8
    \\D 3
    \\R 17
    \\D 10
    \\L 25
    \\U 20
;
const part2_test_solution2: ?i64 = 36;

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
    try aocTestSolution(part2, test_data2, part2_test_solution2, allocator);
    try aocTestSolution(part2, data, part2_solution, allocator);
}

test "day09_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day09_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, test_data2, part2_test_solution2, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
