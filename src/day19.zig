const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day19.txt");

const Blueprint = struct {
    id: i64,
    ore_for_ore_bot: i64,
    ore_for_cla_bot: i64,
    ore_for_obs_bot: i64,
    cla_for_obs_bot: i64,
    ore_for_geo_bot: i64,
    obs_for_geo_bot: i64,
};

const Input = struct {
    allocator: std.mem.Allocator,
    blueprints: std.BoundedArray(Blueprint, 30),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .blueprints = try std.BoundedArray(Blueprint, 30).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            var nums = std.mem.tokenize(u8, line, "Blueprint : Eachoebcs.ydg");
            input.blueprints.appendAssumeCapacity(Blueprint{
                .id = try std.fmt.parseInt(i64, nums.next().?, 10),
                .ore_for_ore_bot = try std.fmt.parseInt(i64, nums.next().?, 10),
                .ore_for_cla_bot = try std.fmt.parseInt(i64, nums.next().?, 10),
                .ore_for_obs_bot = try std.fmt.parseInt(i64, nums.next().?, 10),
                .cla_for_obs_bot = try std.fmt.parseInt(i64, nums.next().?, 10),
                .ore_for_geo_bot = try std.fmt.parseInt(i64, nums.next().?, 10),
                .obs_for_geo_bot = try std.fmt.parseInt(i64, nums.next().?, 10),
            });
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Action = enum(u3) {
    GeoBot,
    ObsBot,
    ClaBot,
    OreBot,
    Nothing,
};

const State = struct {
    ticks_left: i64,
    ore_bots: i64 = 1,
    cla_bots: i64 = 0,
    obs_bots: i64 = 0,
    geo_bots: i64 = 0,
    ore: i64 = 0,
    cla: i64 = 0,
    obs: i64 = 0,
    geo: i64 = 0,

    fn withAction(self: @This(), bp: Blueprint, action: Action) @This() {
        std.debug.assert(self.ticks_left > 0);
        var result = @This(){
            .ticks_left = self.ticks_left -| 1,
            .ore_bots = self.ore_bots,
            .cla_bots = self.cla_bots,
            .obs_bots = self.obs_bots,
            .geo_bots = self.geo_bots,
            .ore = self.ore,
            .cla = self.cla,
            .obs = self.obs,
            .geo = self.geo,
        };
        // Spend resources on new bot
        switch (action) {
            .GeoBot => {
                result.ore -= bp.ore_for_geo_bot;
                result.obs -= bp.obs_for_geo_bot;
            },
            .ObsBot => {
                result.ore -= bp.ore_for_obs_bot;
                result.cla -= bp.cla_for_obs_bot;
            },
            .ClaBot => {
                result.ore -= bp.ore_for_cla_bot;
            },
            .OreBot => {
                result.ore -= bp.ore_for_ore_bot;
            },
            .Nothing => {},
        }
        // Gather resources from existing bots
        result.geo += result.geo_bots;
        result.obs += result.obs_bots;
        result.cla += result.cla_bots;
        result.ore += result.ore_bots;
        // build a new bot
        switch (action) {
            .GeoBot => result.geo_bots += 1,
            .ObsBot => result.obs_bots += 1,
            .ClaBot => result.cla_bots += 1,
            .OreBot => result.ore_bots += 1,
            .Nothing => {},
        }
        return result;
    }

    fn estimateFutureGeodes(self: @This(), bp: Blueprint) i64 {
        // You've got what you've got
        var estimate = self.geo;
        if (self.ticks_left == 0)
            return estimate;
        // existing geobots will produce every tick.
        estimate += self.geo_bots *| self.ticks_left;
        // Account for geodes produces by geobots not yet built.
        if (self.ore >= bp.ore_for_geo_bot and self.obs >= bp.obs_for_geo_bot) {
            // If we can build a new geobot right now, assume we can build a new one
            // every tick.
            // ticks left: 1 2 3 4 5 6 -> new geodes 0 1 3 6 10 15
            estimate += @divExact(self.ticks_left *| (self.ticks_left -| 1), 2);
        } else if ((self.ore + self.ore_bots) >= bp.ore_for_geo_bot and (self.obs + self.obs_bots) >= bp.obs_for_geo_bot) {
            // Or, if we can build a new geobot next turn, assume we can build a new
            // one every tick after that.
            // ticks left: 1 2 3 4 5 6-> new geodes 0 0 1 3 6 10
            estimate += @divExact((self.ticks_left -| 1) *| (self.ticks_left -| 2), 2);
        } else {
            // Otherwise, assume we will build a new geobot every tick starting two ticks from now.
            // ticks left: 1 2 3 4 5 6-> new geodes 0 0 0 1 3 6
            estimate += @divExact((self.ticks_left -| 2) *| (self.ticks_left -| 3), 2);
        }

        return estimate;
    }
};

fn maxGeodes(bp: Blueprint, state: State, best: *i64) void {
    if (state.ticks_left == 0) {
        best.* = std.math.max(best.*, state.geo);
        return;
    }
    // determine possible actions, in the order most likely to maximize geodes (all else being equal)
    var actions = std.BoundedArray(Action, 5).init(0) catch unreachable;
    if (state.ore >= bp.ore_for_geo_bot and state.obs >= bp.obs_for_geo_bot)
        actions.appendAssumeCapacity(.GeoBot);
    if (state.ore >= bp.ore_for_obs_bot and state.cla >= bp.cla_for_obs_bot)
        actions.appendAssumeCapacity(.ObsBot);
    if (state.ore >= bp.ore_for_cla_bot)
        actions.appendAssumeCapacity(.ClaBot);
    if (state.ore >= bp.ore_for_ore_bot)
        actions.appendAssumeCapacity(.OreBot);
    actions.appendAssumeCapacity(.Nothing);
    // for each action, compute the new state
    for (actions.constSlice()) |a| {
        const new_state = state.withAction(bp, a);
        if (new_state.estimateFutureGeodes(bp) < best.*)
            continue;
        maxGeodes(bp, new_state, best);
    }
}

fn part1(input: Input, output: *output_type) !void {
    for (input.blueprints.constSlice()) |bp| {
        var state = State{ .ticks_left = 24 };
        var max_geodes: i64 = 0;
        maxGeodes(bp, state, &max_geodes);
        output.* += bp.id * max_geodes;
        std.debug.print("*", .{});
    }
}

fn part2(input: Input, output: *output_type) !void {
    const bp_count = std.math.min(input.blueprints.len, 3);
    output.* = 1;
    for (input.blueprints.constSlice()[0..bp_count]) |bp| {
        var state = State{ .ticks_left = 32 };
        var max_geodes: i64 = 0;
        maxGeodes(bp, state, &max_geodes);
        output.* *= max_geodes;
        std.debug.print("bp {d} max={d}\n", .{ bp.id, max_geodes });
    }
}

const test_data =
    \\Blueprint 1: Each ore robot costs 4 ore. Each clay robot costs 2 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 2 ore and 7 obsidian.
    \\Blueprint 2: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 8 clay. Each geode robot costs 3 ore and 12 obsidian.
;
const part1_test_solution: ?i64 = 33;
const part1_solution: ?i64 = null; //1192; // correct, but takes a long time to compute
const part2_test_solution: ?i64 = 56 * 62;
const part2_solution: ?i64 = null; //14725; // correct, but slow

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

test "day19_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day19_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
