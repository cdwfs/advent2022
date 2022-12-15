const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day13.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    packets: std.BoundedArray([]const u8, 400),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .packets = try std.BoundedArray([]const u8, 400).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            input.packets.appendAssumeCapacity(line);
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn isDigit(n:u8) callconv(.Inline) bool {
    return (n & 0xF0) == 0x30;
}
fn readInt(p:[]const u8, i:*usize) callconv(.Inline) i64 {
    var n:i64 = 0;
    while(isDigit(p[i.*])) : (i.* += 1) {
        n = n*10 + (p[i.*] - '0');
    }
    return n;
}
fn comparePackets(pA: []const u8, pB: []const u8) std.math.Order {
    var iA:usize = 0;
    var iB:usize = 0;
    var balance:i64 = 0; // +1 for each list A is simulating, -1 for each list B is simulating
    while(iA < pA.len and iB < pB.len) {
        if (isDigit(pA[iA]) and isDigit(pB[iB])) { // parse and compare integers
            const nA = readInt(pA, &iA);
            const nB = readInt(pB, &iB);
            if (nA < nB) return .lt;
            if (nA > nB) return .gt;
            while(balance > 0) : ({balance -= 1; iB += 1;}) {
                if (pB[iB] != ']')
                    return .lt;
            }
            while(balance < 0) : ({balance += 1; iA += 1;}) {
                if (pA[iA] != ']')
                    return .gt;
            }
        } else if (pA[iA] == pB[iB]) { // both '[', ',', or ']' -- just advance
            iA += 1;
            iB += 1;
        } else if (pA[iA] == '[' and isDigit(pB[iB])) { // A is list, B is digit: treat B's digit as list
            iA += 1;
            balance -= 1;
        } else if (isDigit(pA[iA]) and pB[iB] == '[') { // A is digit, B is list: treat A's digit as list
            iB += 1;
            balance += 1;
        } else if (pA[iA] == ']') { // A's list ended early
            return .lt;
        } else if (pB[iB] == ']') { // B's list ended early
            return .gt;
        }
    }
    unreachable;
}

fn part1(input: Input, output: *output_type) !void {
    var i_pair: usize = 0;
    var sum: usize = 0;
    const packets = input.packets.constSlice();
    while (i_pair < input.packets.len / 2) : (i_pair += 1) {
        if (comparePackets(packets[2*i_pair+0], packets[2*i_pair+1]) == std.math.Order.lt) {
            sum += i_pair + 1;
        }
    }
    output.* = @intCast(i64, sum);
}

fn part2(input: Input, output: *output_type) !void {
    var lt2: usize = 1; // indices are 1-based
    var lt6: usize = 2; // ...and [[6]] is greater than [[2]], even though we never compare them directly
    for(input.packets.constSlice()) |packet| {
        if (comparePackets(packet, "[[2]]") == std.math.Order.lt) {
            lt2 += 1;
        }
        if (comparePackets(packet, "[[6]]") == std.math.Order.lt) {
            lt6 += 1;
        }
    }
    output.* = @intCast(i64, lt2*lt6);
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
