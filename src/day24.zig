const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day24.txt");

const Vec2 = @Vector(2, i16);
const Map = struct {
    cells: [80][125]u8 = undefined,
    dim: Vec2 = undefined,
};
const Input = struct {
    allocator: std.mem.Allocator,
    map: Map = undefined,
    start: Vec2 = undefined,
    goal: Vec2 = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
        };
        errdefer input.deinit();

        var y: i16 = 0;
        while (lines.next()) |line| {
            std.mem.copy(u8, input.map.cells[@intCast(usize, y)][0..], line);
            input.map.dim[0] = @intCast(i16, line.len);
            y += 1;
        }
        input.map.dim[1] = y;
        input.start = Vec2{ @intCast(i16, std.mem.indexOf(u8, input.map.cells[0][0..], ".").?), 0 };
        input.goal = Vec2{ @intCast(i16, std.mem.indexOf(u8, input.map.cells[@intCast(usize, y - 1)][0..], ".").?), y - 1 };
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Blizzard = struct {
    pos: Vec2,
    dir: Vec2,
};

const GcdError = error{
    ArgumentOutOfRange,
};
fn gcd(a: usize, b: usize) GcdError!usize {
    if (a < 1 or b < 1)
        return GcdError.ArgumentOutOfRange;
    var rem: usize = 0;
    var aa = a;
    var bb = b;
    while (bb != 0) {
        rem = aa % bb;
        aa = bb;
        bb = rem;
    }
    return aa;
}
test "gcd" {
    try std.testing.expectEqual(@intCast(usize, 5), try gcd(25, 120));
    try std.testing.expectEqual(@intCast(usize, 5), try gcd(120, 25));
    try std.testing.expectEqual(@intCast(usize, 2), try gcd(6, 4));
    try std.testing.expectEqual(@intCast(usize, 2), try gcd(4, 6));
    try std.testing.expectError(GcdError.ArgumentOutOfRange, gcd(5, 0));
    try std.testing.expectError(GcdError.ArgumentOutOfRange, gcd(0, 7));
}

fn lcm(a: usize, b: usize) usize {
    if (a == 0 or b == 0)
        return 0;
    return (a * b) / (gcd(a, b) catch unreachable);
}
test "lcm" {
    try std.testing.expectEqual(@intCast(usize, 600), lcm(25, 120));
    try std.testing.expectEqual(@intCast(usize, 600), lcm(120, 25));
    try std.testing.expectEqual(@intCast(usize, 12), lcm(6, 4));
    try std.testing.expectEqual(@intCast(usize, 12), lcm(4, 6));
    try std.testing.expectEqual(@intCast(usize, 0), lcm(4, 0));
    try std.testing.expectEqual(@intCast(usize, 0), lcm(0, 6));
}

const State = struct {
    pos: Vec2,
    t: usize,
    dist: i16,
};

inline fn manhattanDistance(a: Vec2, b: Vec2) i16 {
    return (std.math.absInt(b[0] - a[0]) catch unreachable) + (std.math.absInt(b[1] - a[1]) catch unreachable);
}

fn tripleMap(map:*Map) void {
    // triple the map
    var src_row:usize = 0;
    var dst_row1:usize = 2*(@intCast(usize,map.dim[1]-1));
    var dst_row2:usize = dst_row1;
    while(src_row < map.dim[1]) : ({src_row += 1; dst_row1 -= 1; dst_row2 += 1;}) {
        //std.debug.print("row {d} -> {d} and {d}\n", .{src_row, dst_row1, dst_row2});
        std.mem.copy(u8, map.cells[dst_row2][0..], map.cells[src_row][0..]);
        if (dst_row1 != src_row and dst_row1 != dst_row2) {
            std.mem.copy(u8, map.cells[dst_row1][0..], map.cells[src_row][0..]);
        }
    }
    map.dim[1] = 3*map.dim[1] - 2;
    // Flip the vertical blizzards in the middle section
    //var row:usize = @intCast(usize,input.map.dim[1]);
    //const row_len = @intCast(usize,input.map.dim[0]);
    //while(row < 2*input.map.dim[1]-1) : (row += 1) {
    //    for(triple_map.cells[row][0..row_len]) |*c| {
    //        c.* = switch(c.*) {
    //            '^' => 'v',
    //            'v' => '^',
    //            else => c.*,
    //        };
    //    }
    //}
}

fn shortest_path(input:Input, tripled:bool) !i64 {
    var goal = input.goal;
    var empty_map = input.map;
    // Extract blizzards
    var blizzards = try std.BoundedArray(Blizzard, 125*100).init(0);
    for (empty_map.cells[0..]) |*row, y| {
        inner: for (row) |*c, x| {
            const p = Vec2{ @intCast(i16, x), @intCast(i16, y) };
            switch (c.*) {
                '<' => blizzards.appendAssumeCapacity(Blizzard{ .pos = p, .dir = Vec2{ -1, 0 } }),
                '>' => blizzards.appendAssumeCapacity(Blizzard{ .pos = p, .dir = Vec2{ 1, 0 } }),
                '^' => blizzards.appendAssumeCapacity(Blizzard{ .pos = p, .dir = Vec2{ 0, -1 } }),
                'v' => blizzards.appendAssumeCapacity(Blizzard{ .pos = p, .dir = Vec2{ 0, 1 } }),
                else => continue :inner,
            }
            c.* = '.';
        }
    }
    // Precalculate all possible maps
    const min_p = Vec2{ 1, 1 };
    const max_p = Vec2{ empty_map.dim[0] - 2, empty_map.dim[1] - 2 };
    var map_count = lcm(@intCast(usize, max_p[0]), @intCast(usize, max_p[1]));
    std.debug.print("{d}x{d} map interior -> {d} possible permutations\n", .{ max_p[0], max_p[1], map_count });
    var maps = try std.ArrayList(Map).initCapacity(input.allocator, map_count);
    defer maps.deinit();
    maps.appendNTimesAssumeCapacity(empty_map, map_count);
    for (maps.items) |*m| {
        for (blizzards.slice()) |*b| {
            const x: usize = @intCast(usize, b.pos[0]);
            const y: usize = @intCast(usize, b.pos[1]);
            m.cells[y][x] = '#';
            b.pos += b.dir;
            if (b.pos[0] < min_p[0]) {
                b.pos[0] = max_p[0];
            } else if (b.pos[0] > max_p[0]) {
                b.pos[0] = min_p[0];
            }
            if (b.pos[1] < min_p[1]) {
                b.pos[1] = max_p[1];
            } else if (b.pos[1] > max_p[1]) {
                b.pos[1] = min_p[1];
            }
        }
        if (tripled)
            tripleMap(m);
    }
    if (tripled) {
        tripleMap(&empty_map);
        goal[1] = empty_map.dim[1]-1;
    }
    // TODO: make one extra map iteration, and validate that the first & last maps are identical.

    // A* it up
    var prev_state = std.AutoHashMap(State, State).init(input.allocator);
    defer prev_state.deinit();
    const state_capacity: u32 = 1000 * @intCast(u32, empty_map.dim[0] - 2) * @intCast(u32, empty_map.dim[1] - 2);
    try prev_state.ensureTotalCapacity(state_capacity);

    var candidates = try std.ArrayList(State).initCapacity(input.allocator, 1000);
    defer candidates.deinit();
    try candidates.append(State{ .pos = input.start, .t = 0, .dist = manhattanDistance(input.start, goal) });
    prev_state.putAssumeCapacity(candidates.items[0], candidates.items[0]);
    const final_state = search: while (true) {
        // Find candidate with lowest distance
        var best_candidate_index: usize = 0;
        for (candidates.items) |c, i| {
            if (c.t < candidates.items[best_candidate_index].t) {
                best_candidate_index = i;
            } else if (c.t == candidates.items[best_candidate_index].t and c.dist < candidates.items[best_candidate_index].dist) {
                best_candidate_index = i;
            }
        }
        const state = candidates.swapRemove(best_candidate_index);

        // When adding next moves, search the next tick's map.
        const next_map_index = (state.t + 1) % maps.items.len;
        const x = @intCast(usize, state.pos[0]);
        const y = @intCast(usize, state.pos[1]);
        var new_positions = try std.BoundedArray(Vec2, 5).init(0);
        if (maps.items[next_map_index].cells[y][x + 1] != '#') { // E
            new_positions.appendAssumeCapacity(Vec2{ state.pos[0] + 1, state.pos[1] });
        }
        if (maps.items[next_map_index].cells[y + 1][x] != '#') { // S
            new_positions.appendAssumeCapacity(Vec2{ state.pos[0], state.pos[1] + 1 });
        }
        if (maps.items[next_map_index].cells[y][x] != '#') { // wait
            new_positions.appendAssumeCapacity(state.pos);
        }
        if (y > 0 and maps.items[next_map_index].cells[y - 1][x] != '#') { // N
            new_positions.appendAssumeCapacity(Vec2{ state.pos[0], state.pos[1] - 1 });
        }
        if (x > 0 and maps.items[next_map_index].cells[y][x - 1] != '#') { // W
            new_positions.appendAssumeCapacity(Vec2{ state.pos[0] - 1, state.pos[1] });
        }
        for (new_positions.constSlice()) |new_pos| {
            const new_dist = manhattanDistance(new_pos, goal);
            const new_state = State{ .pos = new_pos, .t = state.t + 1, .dist = new_dist };
            var map_result = prev_state.getOrPut(new_state) catch unreachable;
            if (!map_result.found_existing) {
                map_result.value_ptr.* = state;
                try candidates.append(new_state);
                if (new_state.dist == 0) {
                    break :search new_state;
                }
            }
        }
    } else unreachable;
    // print the path
    //var path_states = try std.ArrayList(State).initCapacity(input.allocator, @intCast(usize,output.*+1));
    //defer path_states.deinit();
    //var s = final_state;
    //while(s.t > 0) {
    //    path_states.appendAssumeCapacity(s);
    //    s = prev_state.get(s).?;
    //}
    //std.mem.reverse(State, path_states.items);
    //const row_len = @intCast(usize, input.map.dim[0]);
    //for(path_states.items) |state| {
    //    std.debug.print("Minute {d} pos={d},{d} dist={d}\n", .{state.t, state.pos[0], state.pos[1], state.dist});
    //    var row:usize=0;
    //    while(row < @intCast(usize,input.map.dim[1])) : (row += 1) {
    //        for(maps.items[state.t % maps.items.len].cells[row][0..row_len]) |c,x| {
    //            const cc = if (row == state.pos[1] and x == state.pos[0]) 'E' else c;
    //            std.debug.print("{c}", .{cc});
    //        }
    //        std.debug.print("\n", .{});
    //    }
    //    std.debug.print("\n", .{});
    //}
    return @intCast(i64, final_state.t);
}

fn part1(input: Input, output: *output_type) !void {
    output.* = try shortest_path(input, false);
}

fn part2(input: Input, output: *output_type) !void {
    output.* = try shortest_path(input, true);
}

const test_data =
    \\#.######
    \\#>>.<^<#
    \\#.<..<<#
    \\#>v.><>#
    \\#<^v^^>#
    \\######.#
;
const part1_test_solution: ?i64 = 18;
const part1_solution: ?i64 = 274;
const part2_test_solution: ?i64 = 54;
const part2_solution: ?i64 = 839;

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

test "day24_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day24_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
