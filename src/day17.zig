const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day17.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    jets: []const u8,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .jets = lines.next().?,
        };
        errdefer input.deinit();

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

// Pre-shifted to their horizontal starting position, and including a buffer of 1 bit on each side for the walls.
// Stored in reverse Y order, since that's how they're pushed onto the pit list.
const flipped_rock_masks = [_]u16{
    0b0_0011110_0,
    0b0_0000000_0,
    0b0_0000000_0,
    0b0_0000000_0,

    0b0_0001000_0,
    0b0_0011100_0,
    0b0_0001000_0,
    0b0_0000000_0,
    0b0_0011100_0, // note reverse Y order here!
    0b0_0000100_0,
    0b0_0000100_0,
    0b0_0000000_0,

    0b0_0010000_0,
    0b0_0010000_0,
    0b0_0010000_0,
    0b0_0010000_0,

    0b0_0011000_0,
    0b0_0011000_0,
    0b0_0000000_0,
    0b0_0000000_0,
};
const ROCK_TYPES = 5;
const rock_heights: [5]usize = .{ 1, 3, 3, 4, 2 };
const floor_mask: u16 = 0b1_1111111_1;
const wall_mask: u16 = 0b1_0000000_1;

fn drop_rocks(input: Input, pit: *std.BoundedArray(u16, 10_000), drops: usize, i_rock: *u8, i_jet: *u16, tower_height: *usize) void {
    var i_drop: usize = 0;
    while (i_drop < drops) : (i_drop += 1) {
        var rock: [4]u16 = undefined;
        for (flipped_rock_masks[4 * i_rock.* .. 4 * i_rock.* + 4]) |row, i| {
            rock[i] = row;
        }
        const rock_height = rock_heights[i_rock.*];
        var rock_y: usize = tower_height.* + 3;
        i_rock.* = (i_rock.* + 1) % ROCK_TYPES;

        // drop the thing
        drop: while (true) {
            // jet movement
            var new_rock = [_]u16{0} ** 4;
            var apply_jet = true;
            for (rock[0..rock_height]) |row, ri| {
                if (input.jets[i_jet.*] == '<') {
                    new_rock[ri] = row << 1;
                } else {
                    new_rock[ri] = row >> 1;
                }
                if ((new_rock[ri] & pit.get(rock_y + ri)) != 0) {
                    apply_jet = false;
                    break;
                }
            }
            if (apply_jet) {
                for (new_rock[0..rock_height]) |new_row, ri| {
                    rock[ri] = new_row;
                }
            }
            i_jet.* = (i_jet.* + 1) % @truncate(u16, input.jets.len);

            // fall movement
            for (rock[0..rock_height]) |row, ri| {
                if ((row & pit.get(rock_y + ri -| 1)) != 0) {
                    // rock comes to a rest.
                    for (rock[0..rock_height]) |row2, y| {
                        pit.set(rock_y + y, pit.get(rock_y + y) | row2);
                    }
                    tower_height.* = std.math.max(tower_height.*, rock_y + rock_height);
                    break :drop;
                }
            }
            rock_y -|= 1;
        }
    }
}

fn part1(input: Input, output: *output_type) !void {
    var pit = try std.BoundedArray(u16, 10_000).init(0);
    pit.appendAssumeCapacity(floor_mask);
    pit.appendNTimesAssumeCapacity(wall_mask, pit.buffer.len - 1);

    var tower_height: usize = 1; // includes floor
    var i_rock: u8 = 0;
    var i_jet: u16 = 0;
    const DROP_COUNT = 2022;
    drop_rocks(input, &pit, DROP_COUNT, &i_rock, &i_jet, &tower_height);
    // debug: print the pit
    //std.debug.print("Rock {d}:\n", .{i_drop});
    //var py:usize = tower_height-1;
    //while(py > 0) : (py -= 1) {
    //    std.debug.print("{b}\n", .{pit.get(py)});
    //}
    output.* = @intCast(i64, tower_height -| 1); // don't count the floor
}

const PreDropStats = struct {
    tower_height_without_floor: usize,
    i_rock: u8,
    i_jet: u16,
};

const CycleKey = struct {
    i_rock: u8,
    i_jet: u16,
};

const CycleStats = struct {
    tower_height_without_floor: usize,
    prev_diff: usize,
    first_drop_seen: usize,
    prev_rock: u8,
    prev_jet: u16,
};

const Cycle = struct {
    start: usize,
    len: usize,
    height: usize,
};

fn part2(input: Input, output: *output_type) !void {
    var pit = try std.BoundedArray(u16, 10_000).init(0);
    pit.appendAssumeCapacity(floor_mask);
    pit.appendNTimesAssumeCapacity(wall_mask, pit.buffer.len - 1);

    // Track stats *before* each drop
    var drop_stats2 = try std.ArrayList(PreDropStats).initCapacity(input.allocator, 10_000);
    defer drop_stats2.deinit();

    // Cycle-tracking
    var cycle_stats = std.AutoHashMap(CycleKey, CycleStats).init(input.allocator);
    defer cycle_stats.deinit();
    try cycle_stats.ensureTotalCapacity(@truncate(u32, input.jets.len * ROCK_TYPES));

    var tower_height: usize = 1; // includes floor
    var i_rock: u8 = 0;
    var i_jet: u16 = 0;
    var prev_rock = i_rock;
    var prev_jet = i_jet;
    const DROP_COUNT = input.jets.len * 5;
    var i_drop: usize = 0;
    const cycle = cycle_search: while (i_drop < DROP_COUNT) : (i_drop += 1) {
        try drop_stats2.append(PreDropStats{
            .tower_height_without_floor = tower_height - 1, // don't count the floor
            .i_rock = i_rock,
            .i_jet = i_jet,
        });
        // Track stats on the current rock/jet so we can identify cycles
        const cycle_key = CycleKey{ .i_rock = i_rock, .i_jet = i_jet };
        var map_result = cycle_stats.getOrPutAssumeCapacity(cycle_key);
        if (map_result.found_existing) {
            if (map_result.value_ptr.prev_rock == prev_rock and map_result.value_ptr.prev_jet == prev_jet) {
                // potential cycle! See if it checks out
                const diff = (tower_height - 1) - map_result.value_ptr.tower_height_without_floor;
                if (diff == map_result.value_ptr.prev_diff) {
                    const cycle = Cycle{
                        .start = map_result.value_ptr.first_drop_seen,
                        .len = (i_drop - map_result.value_ptr.first_drop_seen) / 2,
                        .height = map_result.value_ptr.prev_diff,
                    };
                    // std.debug.print("WINNER! cycle starts at drop={d:6} rock={d:1} jet={d:5}\n", .{ cycle.start, i_rock, i_jet });
                    // std.debug.print("        cycle length={d:6} drops, cycle_height{d:7}\n", .{ cycle.len, map_result.value_ptr.prev_diff });
                    // We may have a winner; validate the cycle using the drop_stats array.
                    const start_rock = drop_stats2.items[cycle.start].i_rock;
                    const start_jet = drop_stats2.items[cycle.start].i_jet;
                    var j_drop: usize = cycle.start;
                    while (j_drop < cycle.start + cycle.len) : (j_drop += 1) {
                        const s1 = drop_stats2.items[j_drop];
                        const s2 = drop_stats2.items[j_drop + cycle.len];
                        if (s1.tower_height_without_floor + cycle.height != s2.tower_height_without_floor or s1.i_rock != s2.i_rock or s1.i_jet != s2.i_jet) {
                            std.debug.print("Cycle error (start={d:6} length={d:4} height={d:7})\n", .{ cycle.start, cycle.len, cycle.height });
                            std.debug.print("  s1 drop={d:6} height={d:7} rock={d:1} jet={d:5}\n", .{ j_drop, s1.tower_height_without_floor, s1.i_rock, s1.i_jet });
                            std.debug.print("  s2 drop={d:6} height={d:7} rock={d:1} jet={d:5}\n", .{ j_drop + cycle.len, s2.tower_height_without_floor, s2.i_rock, s2.i_jet });
                            unreachable;
                        }
                        if (j_drop > cycle.start and s1.i_rock == start_rock and s1.i_jet == start_jet) {
                            std.debug.print("Cycle within cycle? check drop={d:6}\n", .{j_drop});
                            unreachable;
                        }
                    }
                    break :cycle_search cycle;
                }
                //std.debug.print("drop={d:6} cycle? rock={d:1} jet={d:5} height={d:7} diff={d:7} prev_diff={d:7}\n",
                //    .{i_drop, i_rock, i_jet, tower_height, diff, map_result.value_ptr.prev_diff});
                map_result.value_ptr.tower_height_without_floor = tower_height - 1;
                map_result.value_ptr.prev_diff = diff;
            } else {
                // not a cycle. log it anyway.
                //std.debug.print("drop={d:6} revisited rock={d:1} jet={d:5} but prev state doesn't match\n",
                //    .{i_drop, i_rock, i_jet});
                map_result.value_ptr.* = CycleStats{
                    .tower_height_without_floor = tower_height - 1,
                    .prev_diff = 0,
                    .first_drop_seen = i_drop,
                    .prev_rock = prev_rock,
                    .prev_jet = prev_jet,
                };
            }
        } else {
            map_result.value_ptr.* = CycleStats{
                .tower_height_without_floor = tower_height - 1,
                .prev_diff = 0,
                .first_drop_seen = i_drop,
                .prev_rock = prev_rock,
                .prev_jet = prev_jet,
            };
        }
        // Drop a new rock
        prev_rock = i_rock;
        prev_jet = i_jet;
        drop_rocks(input, &pit, 1, &i_rock, &i_jet, &tower_height);
    } else unreachable;

    // Armed with a cycle, let's do this.
    const target_drops: usize = 1_000_000_000_000;
    const num_cycles = (target_drops - cycle.start) / cycle.len;
    const suffix_drops = (target_drops - cycle.start) % cycle.len;
    const total_height = (drop_stats2.items[cycle.start].tower_height_without_floor) +
        (num_cycles * cycle.height) +
        (drop_stats2.items[cycle.start + suffix_drops].tower_height_without_floor - drop_stats2.items[cycle.start].tower_height_without_floor);

    output.* = @intCast(i64, total_height);
}

const test_data = ">>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>";
const part1_test_solution: ?i64 = 3068;
const part1_solution: ?i64 = 3191;
const part2_test_solution: ?i64 = 1_514_285_714_288;
const part2_solution: ?i64 = 1_572_093_023_267;

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

test "day17_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day17_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
