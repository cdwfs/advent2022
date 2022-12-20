const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day20.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    numbers: std.BoundedArray(i64, 5000),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .numbers = try std.BoundedArray(i64, 5000).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            input.numbers.appendAssumeCapacity(try std.fmt.parseInt(i64, line, 10));
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const ListNode = struct {
    value: i64,
    prev: u16,
    next: u16,
};

fn optimizeDistance(dist: i64, list_len: i16) i16 {
    var d = @truncate(i16, @mod(dist, list_len)); // wrap distance to list length
    if (d != 0) {
        // convert long forward movements to shorter backwards movements
        if (d > @divTrunc(list_len, 2)) {
            d = (d - list_len);
        }
    }
    return d;
}

test "optimizeDistance" {
    // even lengths
    // small moves should be unchanged
    try std.testing.expectEqual(@intCast(i16, 1), optimizeDistance(1, 6));
    try std.testing.expectEqual(@intCast(i16, -1), optimizeDistance(-1, 6));
    // larger moves should wrap
    try std.testing.expectEqual(@intCast(i16, 0), optimizeDistance(60, 6));
    try std.testing.expectEqual(@intCast(i16, 1), optimizeDistance(61, 6));
    try std.testing.expectEqual(@intCast(i16, 0), optimizeDistance(-60, 6));
    try std.testing.expectEqual(@intCast(i16, -1), optimizeDistance(-61, 6));
    // Large positive moves should become small negative moves
    try std.testing.expectEqual(@intCast(i16, -2), optimizeDistance(4, 6));
    try std.testing.expectEqual(@intCast(i16, 2), optimizeDistance(-4, 6));
    try std.testing.expectEqual(@intCast(i16, 3), optimizeDistance(-3, 6));

    // odd lengths
    // small moves should be unchanged
    try std.testing.expectEqual(@intCast(i16, 1), optimizeDistance(1, 7));
    try std.testing.expectEqual(@intCast(i16, -1), optimizeDistance(-1, 7));
    // larger moves should wrap
    try std.testing.expectEqual(@intCast(i16, 0), optimizeDistance(70, 7));
    try std.testing.expectEqual(@intCast(i16, 1), optimizeDistance(71, 7));
    try std.testing.expectEqual(@intCast(i16, 0), optimizeDistance(-70, 7));
    try std.testing.expectEqual(@intCast(i16, -1), optimizeDistance(-71, 7));
    // Large positive moves should become small negative moves
    try std.testing.expectEqual(@intCast(i16, -2), optimizeDistance(5, 7));
    try std.testing.expectEqual(@intCast(i16, 2), optimizeDistance(-5, 7));
    try std.testing.expectEqual(@intCast(i16, 3), optimizeDistance(-4, 7));
    try std.testing.expectEqual(@intCast(i16, -3), optimizeDistance(4, 7));
}

fn advance(list: []ListNode, index: *u16, dist: i16) void {
    var i = index.*;
    var d = dist;
    if (d < 0) {
        while (d < 0) : (d += 1) {
            i = list[i].prev;
        }
    } else {
        while (d > 0) : (d -= 1) {
            i = list[i].next;
        }
    }
    index.* = i;
}

fn print_list(list: []ListNode, i_zero: u16) void {
    var di = i_zero;
    std.debug.print("   ", .{});
    for (list) |_| {
        std.debug.print("{d}, ", .{list[di].value});
        advance(list, &di, 1);
    }
    std.debug.print("\n", .{});
}

fn mix(list: *[]ListNode, i_zero: u16, iterations: usize) void {
    var count = iterations;
    const list_len = @intCast(i16, list.len);
    while (count > 0) : (count -= 1) {
        _ = i_zero;
        //std.debug.print("Initial state:\n", .{});
        //print_list(list.*, i_zero);
        var i: u16 = 0;
        while (i < list.len) : (i += 1) {
            // When moving elements, the list effectively has one fewer element
            var dist: i16 = optimizeDistance(list.*[i].value, list_len - 1);
            // locate destination
            const i_prev_old = list.*[i].prev;
            const i_next_old = list.*[i].next;
            var i_next_new: u16 = i;
            var i_prev_new: u16 = i;
            if (dist < 0) {
                advance(list.*, &i_next_new, dist);
                i_prev_new = list.*[i_next_new].prev;
            } else {
                advance(list.*, &i_prev_new, dist);
                i_next_new = list.*[i_prev_new].next;
            }
            //std.debug.print("Moving {d} by distance {d} between {d} and {d}\n",
            //    .{list.*[i].value, dist, list.*[i_prev_new].value, list.*[i_next_new].value});
            if (dist != 0) {
                // transplant
                list.*[i_prev_old].next = i_next_old;
                list.*[i_next_old].prev = i_prev_old;
                list.*[i].prev = i_prev_new;
                list.*[i].next = i_next_new;
                list.*[i_prev_new].next = i;
                list.*[i_next_new].prev = i;
            }
            //print_list(list.*, i_zero);
        }
    }
}

fn part1(input: Input, output: *output_type) !void {
    var list_array = try std.BoundedArray(ListNode, 5000).init(input.numbers.len);
    var list = list_array.slice();
    const list_len = @intCast(i16, list.len);
    var i_zero: u16 = 0;
    for (input.numbers.constSlice()) |n, i| {
        list[i] = ListNode{
            .value = n,
            .prev = @intCast(u16, @mod(@intCast(i16, i) - 1, list_len)),
            .next = @intCast(u16, @mod(@intCast(i16, i) + 1, list_len)),
        };
        if (n == 0) {
            i_zero = @truncate(u16, i);
        }
    }

    // mix
    mix(&list, i_zero, 1);
    // Find grove coordinates
    output.* = 0;
    var i = i_zero;
    // When looking "N elements ahead", we use the full list length.
    const d1000 = optimizeDistance(1000, list_len);
    advance(list, &i, d1000);
    output.* += list[i].value;
    advance(list, &i, d1000);
    output.* += list[i].value;
    advance(list, &i, d1000);
    output.* += list[i].value;
}

fn part2(input: Input, output: *output_type) !void {
    var list_array = try std.BoundedArray(ListNode, 5000).init(input.numbers.len);
    var list = list_array.slice();
    const list_len = @intCast(i16, list.len);
    var i_zero: u16 = 0;
    for (input.numbers.constSlice()) |n, i| {
        list[i] = ListNode{
            .value = n * 811589153,
            .prev = @intCast(u16, @mod(@intCast(i16, i) - 1, list_len)),
            .next = @intCast(u16, @mod(@intCast(i16, i) + 1, list_len)),
        };
        if (n == 0) {
            i_zero = @truncate(u16, i);
        }
    }

    // mix
    mix(&list, i_zero, 10);
    // Find grove coordinates
    output.* = 0;
    var i = i_zero;
    // When looking "N elements ahead", we use the full list length.
    const d1000 = optimizeDistance(1000, list_len);
    advance(list, &i, d1000);
    output.* += list[i].value;
    advance(list, &i, d1000);
    output.* += list[i].value;
    advance(list, &i, d1000);
    output.* += list[i].value;
}

const test_data =
    \\1
    \\2
    \\-3
    \\3
    \\-2
    \\0
    \\4
;
const part1_test_solution: ?i64 = 3;
const part1_solution: ?i64 = 18257;
const part2_test_solution: ?i64 = 1_623_178_306;
const part2_solution: ?i64 = 4_148_032_160_983;

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

test "day20_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day20_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
