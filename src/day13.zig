const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day13.txt");

const NumOrList = struct {
    num: ?i64,
    list: ?std.ArrayList(NumOrList),

    fn initListFromInt(n: i64, allocator: std.mem.Allocator) !@This() {
        var list = try std.ArrayList(NumOrList).initCapacity(allocator, 1);
        try list.append(NumOrList{ .num = n, .list = null });
        return NumOrList{ .num = null, .list = list };
    }
    fn initFromNum(slice: []const u8, i: *usize) !@This() {
        // If slice starts at a number, we'll always find a closing bracket
        var parse_len: usize = std.mem.indexOf(u8, slice, "]").?;
        // If we find a comma first, the number ends there.
        if (std.mem.indexOf(u8, slice[0..parse_len], ",")) |num_len| {
            parse_len = std.math.min(num_len, parse_len);
        }
        const num = try std.fmt.parseInt(i64, slice[0..parse_len], 10);
        i.* += parse_len;
        return NumOrList{ .num = num, .list = null };
    }
    fn initFromList(slice: []const u8, allocator: std.mem.Allocator, i: *usize) anyerror!@This() {
        std.debug.assert(slice[0] == '[');
        var list = try std.ArrayList(NumOrList).initCapacity(allocator, slice.len);
        var j: usize = 1;
        while (slice[j] != ']') {
            const c = slice[j];
            if (c == '[') {
                // new recursive list
                try list.append(try NumOrList.initFromList(slice[j..], allocator, &j));
            } else if (c == ',') {
                j += 1;
            } else {
                std.debug.assert(c >= '0' and c <= '9');
                try list.append(try NumOrList.initFromNum(slice[j..], &j));
            }
        }
        i.* += j + 1;
        return NumOrList{
            .num = null,
            .list = list,
        };
    }

    fn deinit(self: @This()) void {
        if (self.list) |list| {
            for (list.items) |e| {
                e.deinit();
            }
            list.deinit();
        }
    }
};

const Input = struct {
    allocator: std.mem.Allocator,
    packets: std.BoundedArray(NumOrList, 500),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .packets = try std.BoundedArray(NumOrList, 500).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            var i: usize = 0;
            var packet1 = try NumOrList.initFromList(line, allocator, &i);
            input.packets.appendAssumeCapacity(packet1);

            const line2 = lines.next().?;
            i = 0;
            var packet2 = try NumOrList.initFromList(line2, allocator, &i);
            input.packets.appendAssumeCapacity(packet2);
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        for (self.packets.constSlice()) |packet| {
            packet.deinit();
        }
    }
};

fn inCorrectOrder(in1: NumOrList, in2: NumOrList, allocator: std.mem.Allocator) i64 {
    if (in1.num != null and in2.num != null) {
        const num1 = in1.num.?;
        const num2 = in2.num.?;
        // Both are integers -- compare numerically
        if (num1 < num2) {
            return -1;
        } else if (num1 > num2) {
            return 1;
        } else {
            return 0;
        }
    } else if (in1.list != null and in2.list != null) {
        const list1 = in1.list.?;
        const list2 = in2.list.?;
        var i: usize = 0;
        while (i < list1.items.len and i < list2.items.len) : (i += 1) {
            const cmp = inCorrectOrder(list1.items[i], list2.items[i], allocator);
            if (cmp != 0)
                return cmp;
        }
        if (i == list1.items.len and i < list2.items.len)
            return -1;
        if (i < list1.items.len and i == list2.items.len)
            return 1;
        return 0;
    } else if (in1.num != null and in2.list != null) {
        const in1_as_list = NumOrList.initListFromInt(in1.num.?, allocator) catch unreachable;
        defer in1_as_list.deinit();
        return inCorrectOrder(in1_as_list, in2, allocator);
    } else if (in2.num != null and in1.list != null) {
        const in2_as_list = NumOrList.initListFromInt(in2.num.?, allocator) catch unreachable;
        defer in2_as_list.deinit();
        return inCorrectOrder(in1, in2_as_list, allocator);
    }
    unreachable;
}

fn part1(input: Input, output: *output_type) !void {
    var i_pair: usize = 0;
    var sum: usize = 0;
    while (i_pair < input.packets.len / 2) : (i_pair += 1) {
        const packet1 = input.packets.constSlice()[2 * i_pair + 0];
        const packet2 = input.packets.constSlice()[2 * i_pair + 1];
        switch (inCorrectOrder(packet1, packet2, input.allocator)) {
            -1 => {
                sum += i_pair + 1;
            },
            1 => {},
            else => unreachable,
        }
    }
    output.* = @intCast(i64, sum);
}

fn packetLessThan(allocator: std.mem.Allocator, lhs: NumOrList, rhs: NumOrList) bool {
    return inCorrectOrder(lhs, rhs, allocator) == -1;
}

fn packetIsDivider(packet: NumOrList) bool {
    if (packet.list) |outer_list| {
        if (outer_list.items.len == 1) {
            if (outer_list.items[0].list) |inner_list| {
                if (inner_list.items.len == 1) {
                    if (inner_list.items[0].num) |num| {
                        return (num == 2 or num == 6);
                    }
                }
            }
        }
    }
    return false;
}

fn part2(input: Input, output: *output_type) !void {
    // get mutable copy of input packets
    var packets = input.packets;
    // append divider packets
    var i: usize = 0;
    var divider1 = try NumOrList.initFromList("[[2]]", input.allocator, &i);
    defer divider1.deinit();
    i = 0;
    var divider2 = try NumOrList.initFromList("[[6]]", input.allocator, &i);
    defer divider2.deinit();
    packets.appendAssumeCapacity(divider1);
    packets.appendAssumeCapacity(divider2);
    // sort the whole list
    std.sort.sort(NumOrList, packets.slice(), input.allocator, packetLessThan);
    output.* = 1;
    for (packets.constSlice()) |packet, index| {
        if (packetIsDivider(packet))
            output.* *= @intCast(i64, index + 1);
    }
}

const test_data =
    \\[1,1,3,1,1]
    \\[1,1,5,1,1]
    \\
    \\[[1],[2,3,4]]
    \\[[1],4]
    \\
    \\[9]
    \\[[8,7,6]]
    \\
    \\[[4,4],4,4]
    \\[[4,4],4,4,4]
    \\
    \\[7,7,7,7]
    \\[7,7,7]
    \\
    \\[]
    \\[3]
    \\
    \\[[[]]]
    \\[[]]
    \\
    \\[1,[2,[3,[4,[5,6,7]]]],8,9]
    \\[1,[2,[3,[4,[5,6,0]]]],8,9]
;
const part1_test_solution: ?i64 = 13;
const part1_solution: ?i64 = 6101;
const part2_test_solution: ?i64 = 140;
const part2_solution: ?i64 = 21909;

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

test "day13_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day13_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
