const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day25.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    snafu_nums: std.BoundedArray([]const u8, 125),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text) orelse "\n";
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .snafu_nums = try std.BoundedArray([]const u8, 125).init(0),
        };
        errdefer input.deinit();

        while(lines.next()) |line| {
            input.snafu_nums.appendAssumeCapacity(line);
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn from_snafu(snafu:[]const u8) i64 {
    var result:i64 = 0;
    var i:usize = snafu.len-1;
    var pow5:i64 = 1;
    while(i < snafu.len) : (i -%= 1) {
        result += pow5 * switch(snafu[i]) {
            '0' => @intCast(i64,0),
            '1' => @intCast(i64,1),
            '2' => @intCast(i64,2),
            '-' => @intCast(i64,-1),
            '=' => @intCast(i64,-2),
            else => unreachable,
        };
        pow5 *= 5;
    }
    return result;
}

fn print_as_snafu(n:i64) void {
    var pow5:[22]i64 = undefined;
    for(pow5[0..]) |*p5,i| {
        p5.* = std.math.pow(i64,5,@intCast(i64,i));
    }
    //std.mem.reverse(i64, pow5[0..]);
    for(pow5[0..]) |p5,i| {
        std.debug.print("{d} = {d}\n", .{i,p5});
    }
    _ = n;
}

fn part1(input: Input, output: *output_type) !void {
    var sum:i64 = 0;
    for(input.snafu_nums.constSlice()) |s| {
        sum += from_snafu(s);
    }
    std.debug.print("sum is {d}\n", .{sum});
    std.debug.print(" so is {d}\n", .{from_snafu("2-2--02=1---1200=0-1")});
    print_as_snafu(sum);
    // sum for part 2 is 35_677_038_780_996

    output.appendSliceAssumeCapacity("2=-1=0");
}

fn part2(input: Input, output: *output_type) !void {
    _ = input;
    _ = output;
}

const test_data =
    \\1=-0-2
    \\12111
    \\2=0=
    \\21
    \\2=01
    \\111
    \\20012
    \\112
    \\1=-1=
    \\1-12
    \\12
    \\1=
    \\122
;
const part1_test_solution: ?[]const u8 = "2=-1=0";
const part1_solution: ?[]const u8 = "";
const part2_test_solution: ?[]const u8 = null;
const part2_solution: ?[]const u8 = null;

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

test "day25_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day25_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
