const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day22.txt");

const Vec2 = @Vector(2, i64);

const Input = struct {
    allocator: std.mem.Allocator,
    map: [300][200]u8,
    commands: []const u8,
    dim: Vec2 = undefined,
    // min/max valid cell for each row and column. values are inclusive.
    row_min: [300]i64 = undefined,
    row_max: [300]i64 = undefined,
    col_min: [200]i64 = undefined,
    col_max: [200]i64 = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var input = Input{
            .allocator = allocator,
            .map = undefined,
            .commands = undefined,
        };
        errdefer input.deinit();

        var eol2_buffer: [5]u8 = undefined;
        const eol2 = try std.fmt.bufPrint(eol2_buffer[0..], "{s}{s}", .{ eol, eol });
        var sections = std.mem.split(u8, input_text, eol2);
        const map_text = sections.next().?;
        input.commands = std.mem.trim(u8, sections.next().?, eol);

        var map_lines = std.mem.tokenize(u8, map_text, eol);
        var y: usize = 0;
        var x: usize = 0;
        while (map_lines.next()) |line| {
            std.mem.set(u8, input.map[y][0..], ' ');
            std.mem.copy(u8, input.map[y][0..], line);
            x = std.math.max(x, line.len);
            // find row min/max bounds
            input.row_min[y] = @intCast(i64, std.mem.indexOfAny(u8, line, ".#").?);
            input.row_max[y] = @intCast(i64, std.mem.lastIndexOfAny(u8, line, ".#").?);
            y += 1;
        }
        input.dim = Vec2{ @intCast(i64, x), @intCast(i64, y) };
        // find column min/max bounds
        x = 0;
        while (x < input.dim[0]) : (x += 1) {
            y = 0;
            input.col_min[x] = 0;
            input.col_max[x] = input.dim[1] - 1;
            var found_min = false;
            while (y < input.dim[1]) : (y += 1) {
                if (!found_min and input.map[y][x] != ' ') {
                    found_min = true;
                    input.col_min[x] = @intCast(i64, y);
                } else if (found_min and input.map[y][x] == ' ') {
                    input.col_max[x] = @intCast(i64, y - 1);
                    break;
                }
            }
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const move_for_dir = [4]Vec2{
    Vec2{ 1, 0 }, // east
    Vec2{ 0, 1 }, // south
    Vec2{ -1, 0 }, // west
    Vec2{ 0, -1 }, // north
};

fn move(input: Input, pos: *Vec2, dir: *u2, pc: *usize) void {
    if (input.commands[pc.*] == 'R') {
        //std.debug.print("R ",.{});
        dir.* +%= 1;
        pc.* += 1;
    } else if (input.commands[pc.*] == 'L') {
        //std.debug.print("L ",.{});
        dir.* -%= 1;
        pc.* += 1;
    } else {
        var num: usize = 0;
        while (pc.* < input.commands.len) : (pc.* += 1) {
            const c = @intCast(usize, input.commands[pc.*]);
            if (c >= '0' and c <= '9') { // TODO: isDigit rides again?
                num = (num * 10) + (c - '0');
            } else {
                break;
            }
        }
        //std.debug.print("{d} ",.{num});
        if (num == 0)
            @breakpoint();
        while (num > 0) : (num -= 1) {
            var new_pos = pos.* + move_for_dir[dir.*];
            switch (dir.*) {
                0 => { // east -- check new pos vs row max
                    if (new_pos[0] > input.row_max[@intCast(usize, new_pos[1])])
                        new_pos[0] = input.row_min[@intCast(usize, new_pos[1])];
                },
                1 => { // south -- check new pos vs col max
                    if (new_pos[1] > input.col_max[@intCast(usize, new_pos[0])])
                        new_pos[1] = input.col_min[@intCast(usize, new_pos[0])];
                },
                2 => { // west -- check new pos vs row min
                    if (new_pos[0] < input.row_min[@intCast(usize, new_pos[1])])
                        new_pos[0] = input.row_max[@intCast(usize, new_pos[1])];
                },
                3 => { // north -- check new pos vs col min
                    if (new_pos[1] < input.col_min[@intCast(usize, new_pos[0])])
                        new_pos[1] = input.col_max[@intCast(usize, new_pos[0])];
                },
            }
            // Don't move if the new pos is a wall
            if (input.map[@intCast(usize, new_pos[1])][@intCast(usize, new_pos[0])] == '#')
                break;
            pos.* = new_pos;
        }
    }
    //std.debug.print("new pos=[{d},{d}] dir={d}\n", .{pos.*[0], pos.*[1], dir.*});
}

fn part1(input: Input, output: *output_type) !void {
    var pos = Vec2{ input.row_min[0], 0 };
    var dir: u2 = 0;
    var pc: usize = 0;
    while (pc < input.commands.len) {
        move(input, &pos, &dir, &pc);
    }
    output.* = 1000 * (pos[1] + 1) + 4 * (pos[0] + 1) + @intCast(i64, dir);
}

const Cube = [6][300][200]u8;
const Face = enum(u3) {
    A = 0,
    B = 1,
    C = 2,
    D = 3,
    E = 4,
    F = 5,
};
const FacePos = struct {
    face: Face,
    pos: Vec2,
};
const Wrap = struct {
    face: Face,
    turn: u2,
};

// Naughty input-specific lookup table to handle face-wrapping
const test_wraps: [6][4]Wrap = .{
    .{
        Wrap{ .face = .F, .turn = 2 },
        Wrap{ .face = .D, .turn = 0 },
        Wrap{ .face = .C, .turn = 3 },
        Wrap{ .face = .B, .turn = 2 },
    },
    .{
        Wrap{ .face = .C, .turn = 0 },
        Wrap{ .face = .E, .turn = 2 },
        Wrap{ .face = .F, .turn = 1 },
        Wrap{ .face = .A, .turn = 2 },
    },
    .{
        Wrap{ .face = .D, .turn = 0 },
        Wrap{ .face = .E, .turn = 3 },
        Wrap{ .face = .B, .turn = 0 },
        Wrap{ .face = .A, .turn = 1 },
    },
    .{
        Wrap{ .face = .F, .turn = 1 },
        Wrap{ .face = .E, .turn = 0 },
        Wrap{ .face = .C, .turn = 0 },
        Wrap{ .face = .A, .turn = 0 },
    },
    .{
        Wrap{ .face = .F, .turn = 0 },
        Wrap{ .face = .B, .turn = 2 },
        Wrap{ .face = .C, .turn = 1 },
        Wrap{ .face = .D, .turn = 0 },
    },
    .{
        Wrap{ .face = .A, .turn = 2 },
        Wrap{ .face = .B, .turn = 3 },
        Wrap{ .face = .E, .turn = 0 },
        Wrap{ .face = .D, .turn = 3 },
    },
};
const real_wraps: [6][4]Wrap = .{
    .{ // A
        Wrap{ .face = .B, .turn = 0 },
        Wrap{ .face = .C, .turn = 0 },
        Wrap{ .face = .D, .turn = 2 },
        Wrap{ .face = .F, .turn = 1 },
    },
    .{ // B
        Wrap{ .face = .E, .turn = 2 },
        Wrap{ .face = .C, .turn = 1 },
        Wrap{ .face = .A, .turn = 0 },
        Wrap{ .face = .F, .turn = 0 },
    },
    .{ // C
        Wrap{ .face = .B, .turn = 3 },
        Wrap{ .face = .E, .turn = 0 },
        Wrap{ .face = .D, .turn = 3 },
        Wrap{ .face = .A, .turn = 0 },
    },
    .{ // D
        Wrap{ .face = .E, .turn = 0 },
        Wrap{ .face = .F, .turn = 0 },
        Wrap{ .face = .A, .turn = 2 },
        Wrap{ .face = .C, .turn = 1 },
    },
    .{ // E
        Wrap{ .face = .B, .turn = 2 },
        Wrap{ .face = .F, .turn = 1 },
        Wrap{ .face = .D, .turn = 0 },
        Wrap{ .face = .C, .turn = 0 },
    },
    .{ // F
        Wrap{ .face = .E, .turn = 3 },
        Wrap{ .face = .B, .turn = 0 },
        Wrap{ .face = .A, .turn = 3 },
        Wrap{ .face = .D, .turn = 0 },
    },
};

// Naughty input-specific lookup table to convert between map coords and face coords
const test_face_offests: [6]Vec2 = .{
    Vec2{ 8, 0 },
    Vec2{ 0, 4 },
    Vec2{ 4, 4 },
    Vec2{ 8, 4 },
    Vec2{ 8, 8 },
    Vec2{ 12, 8 },
};
const real_face_offests: [6]Vec2 = .{
    Vec2{ 50, 0 },
    Vec2{ 100, 0 },
    Vec2{ 50, 50 },
    Vec2{ 0, 100 },
    Vec2{ 50, 100 },
    Vec2{ 0, 150 },
};

fn rotate_face_pos(pos: Vec2, turn: u2, cube_dim: i64) Vec2 {
    const max = cube_dim - 1;
    return switch (turn) {
        0 => pos,
        1 => Vec2{ max - pos[1], pos[0] },
        2 => Vec2{ max - pos[0], max - pos[1] },
        3 => Vec2{ pos[1], max - pos[0] },
    };
}

fn cube_move(input: Input, face_pos: *FacePos, dir: *u2, pc: *usize, cube: Cube, cube_dim: i64) void {
    if (input.commands[pc.*] == 'R') {
        //std.debug.print("turn R\n", .{});
        dir.* +%= 1;
        pc.* += 1;
    } else if (input.commands[pc.*] == 'L') {
        //std.debug.print("turn L\n", .{});
        dir.* -%= 1;
        pc.* += 1;
    } else {
        var num: usize = 0;
        while (pc.* < input.commands.len) : (pc.* += 1) {
            const c = @intCast(usize, input.commands[pc.*]);
            if (c >= '0' and c <= '9') { // TODO: isDigit rides again?
                num = (num * 10) + (c - '0');
            } else {
                break;
            }
        }
        //std.debug.print("move {d}\n", .{num});
        const wraps = if (cube_dim == 4) test_wraps else real_wraps;
        while (num > 0) : (num -= 1) {
            var new_dir = dir.*;
            var new_pos = face_pos.*;
            new_pos.pos += move_for_dir[dir.*];
            var wrapped = false;
            switch (dir.*) {
                0 => { // east
                    if (new_pos.pos[0] >= cube_dim) {
                        new_pos.pos[0] = 0;
                        wrapped = true;
                    }
                },
                1 => { // south
                    if (new_pos.pos[1] >= cube_dim) {
                        new_pos.pos[1] = 0;
                        wrapped = true;
                    }
                },
                2 => { // west
                    if (new_pos.pos[0] < 0) {
                        new_pos.pos[0] = cube_dim - 1;
                        wrapped = true;
                    }
                },
                3 => { // north
                    if (new_pos.pos[1] < 0) {
                        new_pos.pos[1] = cube_dim - 1;
                        wrapped = true;
                    }
                },
            }
            if (wrapped) {
                const w = wraps[@enumToInt(face_pos.face)][dir.*];
                new_pos.face = w.face;
                new_dir +%= w.turn;
                //const pre_pos = new_pos;
                new_pos.pos = rotate_face_pos(new_pos.pos, w.turn, cube_dim);
                //std.debug.print("- Wrapped from {s} to {s}, rotated new pos from [{d},{d}] to [{d},{d}] and dir from {d} to {d}\n", .{ @tagName(face_pos.face), @tagName(w.face), pre_pos.pos[0], pre_pos.pos[1], new_pos.pos[0], new_pos.pos[1], dir.*, new_dir });
            }
            // Stop moving if the new pos is a wall
            if (cube[@enumToInt(new_pos.face)][@intCast(usize, new_pos.pos[1])][@intCast(usize, new_pos.pos[0])] == '#')
                break;
            face_pos.* = new_pos;
            dir.* = new_dir;
        }
    }
    //std.debug.print("- ended move at face={s} pos=[{d},{d}] dir={d}\n", .{ @tagName(face_pos.face), face_pos.pos[0], face_pos.pos[1], dir.* });
}

fn part2(input: Input, output: *output_type) !void {
    // Convert map to cube
    var cube: Cube = undefined;
    var cube_dim: i64 = undefined;
    var col: usize = 0;
    if (input.dim[0] == 16) {
        cube_dim = 4;
        while (col < cube_dim) : (col += 1) {
            std.mem.copy(u8, cube[@enumToInt(Face.A)][col][0..], input.map[col + 0][8..12]);
            std.mem.copy(u8, cube[@enumToInt(Face.B)][col][0..], input.map[col + 4][0..4]);
            std.mem.copy(u8, cube[@enumToInt(Face.C)][col][0..], input.map[col + 4][4..8]);
            std.mem.copy(u8, cube[@enumToInt(Face.D)][col][0..], input.map[col + 4][8..12]);
            std.mem.copy(u8, cube[@enumToInt(Face.E)][col][0..], input.map[col + 8][8..12]);
            std.mem.copy(u8, cube[@enumToInt(Face.F)][col][0..], input.map[col + 8][12..16]);
        }
    } else {
        cube_dim = 50;
        while (col < cube_dim) : (col += 1) {
            std.mem.copy(u8, cube[@enumToInt(Face.A)][col][0..], input.map[col + 0][50..100]);
            std.mem.copy(u8, cube[@enumToInt(Face.B)][col][0..], input.map[col + 0][100..150]);
            std.mem.copy(u8, cube[@enumToInt(Face.C)][col][0..], input.map[col + 50][50..100]);
            std.mem.copy(u8, cube[@enumToInt(Face.D)][col][0..], input.map[col + 100][0..50]);
            std.mem.copy(u8, cube[@enumToInt(Face.E)][col][0..], input.map[col + 100][50..100]);
            std.mem.copy(u8, cube[@enumToInt(Face.F)][col][0..], input.map[col + 150][0..50]);
        }
    }
    var pos: FacePos = FacePos{ .face = .A, .pos = Vec2{ 0, 0 } };
    var dir: u2 = 0;
    var pc: usize = 0;
    while (pc < input.commands.len) {
        cube_move(input, &pos, &dir, &pc, cube, cube_dim);
    }
    const face_offsets = if (cube_dim == 4) test_face_offests else real_face_offests;
    const face_offset = face_offsets[@enumToInt(pos.face)];
    const map_pos = Vec2{ pos.pos[0] + face_offset[0], pos.pos[1] + face_offset[1] };
    output.* = 1000 * (map_pos[1] + 1) + 4 * (map_pos[0] + 1) + @intCast(i64, dir);
}

const test_data =
    \\        ...#
    \\        .#..
    \\        #...
    \\        ....
    \\...#.......#
    \\........#...
    \\..#....#....
    \\..........#.
    \\        ...#....
    \\        .....#..
    \\        .#......
    \\        ......#.
    \\
    \\10R5L5R10L4R5L5
;
const part1_test_solution: ?i64 = 6032;
const part1_solution: ?i64 = 3590;
const part2_test_solution: ?i64 = 5031;
const part2_solution: ?i64 = 86382;

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

test "day22_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day22_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
