const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day16.txt");

const Valve = struct {
    name: []const u8,
    id: usize,
    flow_rate: u16,
    tunnels_to: std.BoundedArray(u6, 5),
};

const Input = struct {
    allocator: std.mem.Allocator,
    valves: std.BoundedArray(Valve, 64),
    valve_name_to_id: std.StringHashMap(usize),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .valves = try std.BoundedArray(Valve, 64).init(0),
            .valve_name_to_id = std.StringHashMap(usize).init(allocator),
        };
        errdefer input.deinit();

        // First pass to compute a valve name -> index map
        try input.valve_name_to_id.ensureTotalCapacity(64);
        while (lines.next()) |line| {
            var parts = std.mem.tokenize(u8, line, "=;");
            const name = parts.next().?[6..8];
            //std.debug.print("valve id={d} is {s} connects\n", .{input.valve_name_to_id.count(),name});
            input.valve_name_to_id.putAssumeCapacity(name, input.valve_name_to_id.count());
        }

        // Second pass to parse valves
        lines = std.mem.tokenize(u8, input_text, eol);
        while (lines.next()) |line| {
            var parts = std.mem.tokenize(u8, line, "=;");
            const name = parts.next().?[6..8];
            const id = input.valve_name_to_id.get(name).?;
            const flow_rate = try std.fmt.parseInt(u16, parts.next().?, 10);
            var tunnels = std.mem.tokenize(u8, parts.next().?[23..], "s, ");
            var valve = Valve{
                .name = name,
                .id = id,
                .flow_rate = flow_rate,
                .tunnels_to = try std.BoundedArray(u6, 5).init(0),
            };
            while (tunnels.next()) |tunnel| {
                valve.tunnels_to.appendAssumeCapacity(@truncate(u6, input.valve_name_to_id.get(tunnel).?));
            }
            input.valves.appendAssumeCapacity(valve);
        }
        return input;
    }
    pub fn deinit(self: *@This()) void {
        self.valve_name_to_id.deinit();
    }
};

const StateKey = struct {
    open_valves: std.StaticBitSet(64) = std.StaticBitSet(64).initEmpty(),
    tick: u5 = 0,
    loc_id: u6,
    loc2_id: u6,
};

const Action = union(enum) {
    move: u6,
    open: u6,
};

const State = struct {
    key: StateKey,
    flow_total: u16 = 0,
    flow_per_tick: u16 = 0,
    prev_loc_id: ?u6 = null,
    prev_loc2_id: ?u6 = null,

    fn withActions(input: Input, prev_state: State, action1: Action, action2: Action) State {
        var new_state = State {
            .key = StateKey{
                .open_valves = prev_state.key.open_valves,
                .tick = prev_state.key.tick + 1,
                .loc_id = prev_state.key.loc_id,
                .loc2_id = prev_state.key.loc2_id,
            },
            .flow_total = prev_state.flow_total + prev_state.flow_per_tick,
            .flow_per_tick = prev_state.flow_per_tick,
            .prev_loc_id = null,
            .prev_loc2_id = null,
        };
        switch(action1) {
            .open => |id| {
                new_state.key.open_valves.set(id);
                new_state.flow_per_tick += input.valves.get(prev_state.key.loc_id).flow_rate;
            },
            .move => |id| {
                new_state.key.loc_id = id;
                new_state.prev_loc_id = prev_state.key.loc_id;
            }
        }
        switch(action2) {
            .open => |id| {
                new_state.key.open_valves.set(id);
                new_state.flow_per_tick += input.valves.get(prev_state.key.loc_id).flow_rate;
            },
            .move => |id| {
                new_state.key.loc2_id = id;
                new_state.prev_loc2_id = prev_state.key.loc2_id;
            }
        }
        return new_state;
    }
};

// Returns the best score we can get from the input state, *starting from 0.*
// Stores the best score found so far in global_best.
fn best_pressure(input: Input, score_for_state: *std.AutoHashMap(StateKey, u16), state_stack: *std.BoundedArray(State, 32), global_best: *u16) u16 {
    const state = state_stack.get(state_stack.len - 1);
    // If we already have a score for this state, return it
    if (score_for_state.get(state.key)) |score| {
        return score;
    }
    // Beyond this point we can assume that we do NOT know the best score for the current state, and all code paths
    // must store it before they return.

    // If we're out of time, report the best
    if (state.key.tick >= 30) {
        if (state.flow_total > global_best.*) {
            std.debug.print("new best: {d}\n", .{state.flow_total});
            //if (state.flow_total == 1651) {
            //    for(state_stack.constSlice()[1..]) |s| {
            //        if (s.prev_valve_id == null) { // we opened a valve
            //            const prev_flow_rate = s.flow_per_tick - input.valves.get(s.key.loc_id).flow_rate;
            //            std.debug.print("{d}: {d} pressure released, opened {s}\n", .{s.key.tick, prev_flow_rate, input.valves.get(s.key.loc_id).name});
            //        } else {
            //            std.debug.print("{d}: {d} pressure released, moved to {s}\n", .{s.key.tick, s.flow_per_tick, input.valves.get(s.key.loc_id).name});
            //        }
            //    }
            //}
            global_best.* = state.flow_total;
        }
        score_for_state.put(state.key, 0) catch unreachable;
        return 0;
    }
    var best_next_state_score: u16 = 0;
    // If all valves are open, just run down the clock. Fake this with a move to the current valve.
    if (state.key.open_valves.count() == input.valves.len) {
        state_stack.*.appendAssumeCapacity(State.withActions(input, state, Action{.move = state.key.loc_id}, Action{.move = state.key.loc2_id}));
        best_next_state_score = std.math.max(best_next_state_score, best_pressure(input, score_for_state, state_stack, global_best));
        _ = state_stack.pop();
        global_best.* = std.math.max(global_best.*, state.flow_per_tick + best_next_state_score);
    } else {
        // If the current location's valve is closed, try opening it
        if (!state.key.open_valves.isSet(state.key.loc_id)) {
            state_stack.*.appendAssumeCapacity(State.withActions(input, state, Action{.open = state.key.loc_id}, Action{.move = state.key.loc2_id}));
            best_next_state_score = std.math.max(best_next_state_score, best_pressure(input, score_for_state, state_stack, global_best));
            _ = state_stack.pop();
            global_best.* = std.math.max(global_best.*, state.flow_per_tick + best_next_state_score);
        }
        // Try moving to each neighboring valve.
        // TODO: sort tunnels at each node by which is the most promising, somehow?
        for (input.valves.get(state.key.loc_id).tunnels_to.constSlice()) |dest_loc_id| {
            // If we just moved here from a neighbor, skip checking the pointless move back to our old location on the very next turn
            if (dest_loc_id == state.prev_loc_id)
                continue;
            state_stack.*.appendAssumeCapacity(State.withActions(input, state, Action{.move = dest_loc_id}, Action{.move = state.key.loc2_id}));
            best_next_state_score = std.math.max(best_next_state_score, best_pressure(input, score_for_state, state_stack, global_best));
            _ = state_stack.pop();
            global_best.* = std.math.max(global_best.*, state.flow_total + best_next_state_score);
        }
    }
    const this_state_score = state.flow_per_tick + best_next_state_score;
    score_for_state.put(state.key, this_state_score) catch unreachable;
    return this_state_score;
}

fn part1(input: Input, output: *output_type) !void {
    var initial_state = State{
        .key = StateKey{
            .loc_id = @truncate(u6, input.valve_name_to_id.get("AA").?),
            .loc2_id = @truncate(u6, input.valve_name_to_id.get("AA").?),
        },
    };
    // A bunch of the valves have a flow rate of 0. Opening them is pointless. So, let's just pretend they're all
    // open to begin with.
    for (input.valves.constSlice()) |valve, id| {
        if (valve.flow_rate == 0)
            initial_state.key.open_valves.set(id);
    }
    // TODO: all valves with flow-rate = 0 are connected to exactly 2 other valves.
    // So in theory we could draw a much simpler graph. But since I'm already filtering backtracking, I'm not sure
    // how much that would buy.

    var score_for_state = std.AutoHashMap(StateKey, u16).init(input.allocator);
    defer score_for_state.deinit();
    // preallocating the hash map storage isn't buying us THAT much, it turns out.
    try score_for_state.ensureTotalCapacity(1_000_000); //32768 * 64 * 30);

    var state_stack = try std.BoundedArray(State, 32).init(0);
    state_stack.appendAssumeCapacity(initial_state);

    // Find the best!
    var best_score: u16 = 0;
    output.* = best_pressure(input, &score_for_state, &state_stack, &best_score);
    std.debug.print("{d} scores stored\n", .{score_for_state.count()});
    std.debug.assert(output.* == best_score);
}

fn part2(input: Input, output: *output_type) !void {
    _ = input;
    _ = output;
}

const test_data =
    \\Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
    \\Valve BB has flow rate=13; tunnels lead to valves CC, AA
    \\Valve CC has flow rate=2; tunnels lead to valves DD, BB
    \\Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
    \\Valve EE has flow rate=3; tunnels lead to valves FF, DD
    \\Valve FF has flow rate=0; tunnels lead to valves EE, GG
    \\Valve GG has flow rate=0; tunnels lead to valves FF, HH
    \\Valve HH has flow rate=22; tunnel leads to valve GG
    \\Valve II has flow rate=0; tunnels lead to valves AA, JJ
    \\Valve JJ has flow rate=21; tunnel leads to valve II
;
const part1_test_solution: ?i64 = 1651;
const part1_solution: ?i64 = 1653;
const part2_test_solution: ?i64 = null; //1707;
const part2_solution: ?i64 = null;

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

test "day16_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day16_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
