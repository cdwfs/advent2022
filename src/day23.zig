const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day23.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    initial_cells: [73][73]u8 = undefined,
    initial_dim: usize = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            // fields init here
        };
        errdefer input.deinit();

        var y: usize = 0;
        while (lines.next()) |line| {
            std.mem.copy(u8, input.initial_cells[y][0..], line);
            y += 1;
        }
        input.initial_dim = y;
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Dir = enum(u2) {
    N,
    S,
    W,
    E,
};

const Vec2 = @Vector(2, i8);
const ElfMap = std.AutoArrayHashMap(Vec2, void);
const MoveMap = std.AutoArrayHashMap(Vec2, ?Vec2);
fn process_round(input: Input, map: *ElfMap, start_dir: u2) bool {
    var proposed_moves = MoveMap.init(input.allocator);
    defer proposed_moves.deinit();
    proposed_moves.ensureTotalCapacity(map.count()) catch unreachable;
    // part 1: propose moves
    const dirs = [4]u2{ start_dir, start_dir +% 1, start_dir +% 2, start_dir +% 3 };
    elf_loop: for (map.keys()) |p| {
        const n = Vec2{ p[0], p[1] - 1 };
        const s = Vec2{ p[0], p[1] + 1 };
        const w = Vec2{ p[0] - 1, p[1] };
        const e = Vec2{ p[0] + 1, p[1] };
        const empty_n = !map.contains(n);
        const empty_s = !map.contains(s);
        const empty_w = !map.contains(w);
        const empty_e = !map.contains(e);
        const empty_nw = !map.contains(Vec2{ w[0], n[1] });
        const empty_ne = !map.contains(Vec2{ e[0], n[1] });
        const empty_sw = !map.contains(Vec2{ w[0], s[1] });
        const empty_se = !map.contains(Vec2{ e[0], s[1] });
        //std.debug.print("- elf at {d},{d} ", .{p[0], p[1]});
        if (empty_n and empty_s and empty_w and empty_e and empty_nw and empty_ne and empty_sw and empty_se) {
            //std.debug.print("does nothing (no neighbors)\n", .{});
            continue;
        }
        for (dirs) |dir| {
            switch (@intToEnum(Dir, dir)) {
                .N => {
                    if (empty_nw and empty_ne and empty_n) {
                        //std.debug.print("wants to move N to {d},{d}\n", .{n[0],n[1]});
                        var map_result = proposed_moves.getOrPut(n) catch unreachable;
                        map_result.value_ptr.* = if (map_result.found_existing) null else p;
                        continue :elf_loop;
                    }
                },
                .S => {
                    if (empty_sw and empty_se and empty_s) {
                        //std.debug.print("wants to move S to {d},{d}\n", .{s[0],s[1]});
                        var map_result = proposed_moves.getOrPut(s) catch unreachable;
                        map_result.value_ptr.* = if (map_result.found_existing) null else p;
                        continue :elf_loop;
                    }
                },
                .W => {
                    if (empty_nw and empty_sw and empty_w) {
                        //std.debug.print("wants to move W to {d},{d}\n", .{w[0],w[1]});
                        var map_result = proposed_moves.getOrPut(w) catch unreachable;
                        map_result.value_ptr.* = if (map_result.found_existing) null else p;
                        continue :elf_loop;
                    }
                },
                .E => {
                    if (empty_ne and empty_se and empty_e) {
                        //std.debug.print("wants to move E to {d},{d}\n", .{e[0],e[1]});
                        var map_result = proposed_moves.getOrPut(e) catch unreachable;
                        map_result.value_ptr.* = if (map_result.found_existing) null else p;
                        continue :elf_loop;
                    }
                },
            }
        }
    }
    // part 2: process moves
    var moves = proposed_moves.iterator();
    var elves_moved = false;
    while (moves.next()) |entry| {
        //const to = entry.key_ptr.*;
        if (entry.value_ptr.*) |from| {
            //std.debug.print("- elf at {d},{d} moves to {d},{d}\n", .{from[0],from[1],to[0],to[1]});
            _ = map.swapRemove(from);
            map.putAssumeCapacity(entry.key_ptr.*, {});
            elves_moved = true;
        } else {
            //std.debug.print("- nobody moves to {d},{d}\n", .{to[0],to[1]});
        }
    }
    return elves_moved;
}

fn draw_map(map: ElfMap) void {
    var min: Vec2 = Vec2{ std.math.maxInt(i8), std.math.maxInt(i8) };
    var max: Vec2 = Vec2{ std.math.minInt(i8), std.math.minInt(i8) };
    for (map.keys()) |p| {
        min = @min(min, p);
        max = @max(max, p);
    }
    var y: i8 = min[1] - 1;
    while (y <= max[1] + 1) : (y += 1) {
        var x: i8 = min[0] - 1;
        while (x <= max[0] + 1) : (x += 1) {
            const c: u8 = if (map.contains(Vec2{ x, y })) '#' else '.';
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}

fn part1(input: Input, output: *output_type) !void {
    // Populate map
    var elf_map = ElfMap.init(input.allocator);
    defer elf_map.deinit();
    try elf_map.ensureTotalCapacity(input.initial_dim * input.initial_dim);
    for (input.initial_cells) |row, y| {
        for (row) |c, x| {
            if (c == '#') {
                elf_map.putAssumeCapacity(Vec2{ @intCast(i8, x), @intCast(i8, y) }, {});
            }
        }
    }
    const elf_count = elf_map.count();
    // Simulate movement rounds
    var round: usize = 1;
    var start_dir: u2 = 0;
    //std.debug.print("Initial state:\n", .{});
    //draw_map(elf_map);
    const num_rounds: usize = if (elf_count == 5) 4 else 10;
    while (round <= num_rounds) : (round += 1) {
        _ = process_round(input, &elf_map, start_dir);
        std.debug.assert(elf_map.count() == elf_count);
        start_dir +%= 1;
        //std.debug.print("After round {d}:\n", .{round});
        //draw_map(elf_map);
    }
    // Calculate bounding box
    var min: Vec2 = Vec2{ std.math.maxInt(i8), std.math.maxInt(i8) };
    var max: Vec2 = Vec2{ std.math.minInt(i8), std.math.minInt(i8) };
    for (elf_map.keys()) |p| {
        min = @min(min, p);
        max = @max(max, p);
    }
    output.* = @intCast(i64, max[0] - min[0] + 1) * @intCast(i64, max[1] - min[1] + 1) - @intCast(i64, elf_map.count());
}

fn part2(input: Input, output: *output_type) !void {
    // Populate map
    var elf_map = ElfMap.init(input.allocator);
    defer elf_map.deinit();
    try elf_map.ensureTotalCapacity(input.initial_dim * input.initial_dim);
    for (input.initial_cells) |row, y| {
        for (row) |c, x| {
            if (c == '#') {
                elf_map.putAssumeCapacity(Vec2{ @intCast(i8, x), @intCast(i8, y) }, {});
            }
        }
    }
    const elf_count = elf_map.count();
    // Simulate movement rounds until the simulation stabilizes
    var round: usize = 1;
    var start_dir: u2 = 0;
    //std.debug.print("Initial state:\n", .{});
    //draw_map(elf_map);
    while (true) : (round += 1) {
        const elves_moved = process_round(input, &elf_map, start_dir);
        if (!elves_moved) {
            output.* = @intCast(i64, round);
            return;
        }
        std.debug.assert(elf_map.count() == elf_count);

        start_dir +%= 1;
        //std.debug.print("After round {d}:\n", .{round});
        //draw_map(elf_map);
    }
}

const test_data =
    \\....#..
    \\..###.#
    \\#...#.#
    \\.#...##
    \\#.###..
    \\##.#.##
    \\.#..#..
;
const part1_test_solution: ?i64 = 110;
const part1_solution: ?i64 = 4218;
const part2_test_solution: ?i64 = 20;
const part2_solution: ?i64 = 976;

const test_data2 =
    \\.....
    \\..##.
    \\..#..
    \\.....
    \\..##.
    \\.....
;
const part1_test2_solution: ?i64 = 25;
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
    try aocTestSolution(part1, test_data2, part1_test2_solution, allocator);
    try aocTestSolution(part1, test_data, part1_test_solution, allocator);
    try aocTestSolution(part1, data, part1_solution, allocator);
    try aocTestSolution(part2, test_data, part2_test_solution, allocator);
    try aocTestSolution(part2, data, part2_solution, allocator);
}

test "day23_part1" {
    try aocTestSolution(part1, test_data2, part1_test2_solution, std.testing.allocator);
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day23_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
