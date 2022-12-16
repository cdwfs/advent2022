const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day15.txt");

const Vec2 = @Vector(2, i64);
const Sensor = struct {
    pos: Vec2,
    closest_beacon_pos: Vec2,
};

const Input = struct {
    allocator: std.mem.Allocator,
    sensors: std.BoundedArray(Sensor, 32),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .sensors = try std.BoundedArray(Sensor, 32).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            var nums = std.mem.tokenize(u8, line, "Sensor at x=, y=: closest beacon is at x=, y=");
            input.sensors.appendAssumeCapacity(Sensor{
                .pos = Vec2{
                    try std.fmt.parseInt(i64, nums.next().?, 10),
                    try std.fmt.parseInt(i64, nums.next().?, 10),
                },
                .closest_beacon_pos = Vec2{
                    try std.fmt.parseInt(i64, nums.next().?, 10),
                    try std.fmt.parseInt(i64, nums.next().?, 10),
                },
            });
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

inline fn manDist(a: Vec2, b: Vec2) i64 {
    //return (std.math.absInt(a[0] - b[0]) catch unreachable) + (std.math.absInt(a[1] - b[1]) catch unreachable);
    return @reduce(.Add, abs(a - b));
}

const RangeEndpoint = struct {
    p: i64,
    dlevel: i64,
};
fn endpointALessThanB(context: void, a: RangeEndpoint, b: RangeEndpoint) bool {
    _ = context;
    if (a.p < b.p)
        return true;
    if (a.p > b.p)
        return false;
    return a.dlevel > b.dlevel; // ensure starts come before ends
}

fn part1(input: Input, output: *output_type, y_target: i64) !void {
    var endpoints = try std.BoundedArray(RangeEndpoint, 32 * 3).init(0);
    for (input.sensors.constSlice()) |sensor| {
        const db = manDist(sensor.pos, sensor.closest_beacon_pos);
        const dy = try std.math.absInt(sensor.pos[1] - y_target);
        if (dy <= db) {
            const dx = db -% dy;
            endpoints.appendAssumeCapacity(RangeEndpoint{
                .p = sensor.pos[0] - dx,
                .dlevel = 1,
            });
            endpoints.appendAssumeCapacity(RangeEndpoint{
                .p = sensor.pos[0] + dx + 1,
                .dlevel = -1,
            });
        }
        if (sensor.closest_beacon_pos[1] == y_target) {
            endpoints.appendAssumeCapacity(RangeEndpoint{
                .p = sensor.closest_beacon_pos[0],
                .dlevel = 0,
            });
        }
    }
    std.sort.sort(RangeEndpoint, endpoints.slice(), {}, endpointALessThanB);
    std.debug.assert(endpoints.len > 0);
    std.debug.assert(endpoints.constSlice()[0].dlevel == 1);
    var count: i64 = 0;
    var level: i64 = 1;
    var x: i64 = endpoints.constSlice()[0].p;
    var bx: i64 = -1;
    for (endpoints.constSlice()[1..]) |ep| {
        if (level > 0) {
            count += (ep.p - x);
            // if an actual beacon appears inside a range, don't count it
            if (ep.dlevel == 0 and ep.p != bx) {
                count -= 1;
                bx = ep.p;
            }
        }
        x = ep.p;
        level += ep.dlevel;
    }
    std.debug.assert(level == 0);
    output.* = count;
}

fn part2(input: Input, output: *output_type, coord_max: i64) !void {
    // Brute-force all the rows!
    var y: i64 = 0;
    while (y <= coord_max) : (y += 1) {
        var endpoints = try std.BoundedArray(RangeEndpoint, 32 * 3).init(0);
        for (input.sensors.constSlice()) |sensor| {
            const db = manDist(sensor.pos, sensor.closest_beacon_pos);
            const dy = try std.math.absInt(sensor.pos[1] - y);
            if (dy <= db) {
                const dx = db -% dy;
                endpoints.appendAssumeCapacity(RangeEndpoint{
                    .p = sensor.pos[0] - dx,
                    .dlevel = 1,
                });
                endpoints.appendAssumeCapacity(RangeEndpoint{
                    .p = sensor.pos[0] + dx + 1,
                    .dlevel = -1,
                });
            }
        }
        std.sort.sort(RangeEndpoint, endpoints.slice(), {}, endpointALessThanB);
        std.debug.assert(endpoints.len > 0);
        std.debug.assert(endpoints.constSlice()[0].dlevel == 1);
        var level: i64 = 1;
        var x: i64 = endpoints.constSlice()[0].p;
        for (endpoints.constSlice()[1..]) |ep| {
            if (level == 0 and ep.p > x) {
                output.* = x * 4_000_000 + y;
                return;
            }
            x = ep.p;
            if (x >= coord_max)
                break;
            level += ep.dlevel;
        }
    }
    unreachable;
}

const test_data =
    \\Sensor at x=2, y=18: closest beacon is at x=-2, y=15
    \\Sensor at x=9, y=16: closest beacon is at x=10, y=16
    \\Sensor at x=13, y=2: closest beacon is at x=15, y=3
    \\Sensor at x=12, y=14: closest beacon is at x=10, y=16
    \\Sensor at x=10, y=20: closest beacon is at x=10, y=16
    \\Sensor at x=14, y=17: closest beacon is at x=10, y=16
    \\Sensor at x=8, y=7: closest beacon is at x=2, y=10
    \\Sensor at x=2, y=0: closest beacon is at x=2, y=10
    \\Sensor at x=0, y=11: closest beacon is at x=2, y=10
    \\Sensor at x=20, y=14: closest beacon is at x=25, y=17
    \\Sensor at x=17, y=20: closest beacon is at x=21, y=22
    \\Sensor at x=16, y=7: closest beacon is at x=15, y=3
    \\Sensor at x=14, y=3: closest beacon is at x=15, y=3
    \\Sensor at x=20, y=1: closest beacon is at x=15, y=3
;
const part1_test_solution: ?i64 = 26;
const part1_solution: ?i64 = 5_394_423;
const part2_test_solution: ?i64 = 56_000_011;
const part2_solution: ?i64 = 11_840_879_211_051;

// Just boilerplate below here, nothing to see

const solution_type: type = @TypeOf(part1_test_solution);
const output_type: type = if (solution_type == ?[]const u8) std.BoundedArray(u8, 256) else i64;
// TODO: in Zig 0.10.0 on the self-hosting compiler, function pointer types must be
// `*const fn(blah) void` instead of just `fn(blah) void`. But this AoC framework still uses stage1
// to avoid a bug with bitsets. For more info:
// https://ziglang.org/download/0.10.0/release-notes.html#Function-Pointers
const func_type: type = fn (input: Input, output: *output_type, arg: i64) anyerror!void;

fn aocTestSolution(
    comptime func: func_type,
    input_text: []const u8,
    expected_solution: solution_type,
    allocator: std.mem.Allocator,
    arg: i64,
) !void {
    const expected = expected_solution orelse return error.SkipZigTest;

    var timer = try std.time.Timer.start();
    var input = try Input.init(input_text, allocator);
    defer input.deinit();
    if (output_type == std.BoundedArray(u8, 256)) {
        var actual = try std.BoundedArray(u8, 256).init(0);
        try func(input, &actual, arg);
        try std.testing.expectEqualStrings(expected, actual.constSlice());
    } else {
        var actual: i64 = 0;
        try func(input, &actual, arg);
        try std.testing.expectEqual(expected, actual);
    }
    std.debug.print("{d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try aocTestSolution(part1, test_data, part1_test_solution, allocator, 10);
    try aocTestSolution(part1, data, part1_solution, allocator, 2_000_000);
    try aocTestSolution(part2, test_data, part2_test_solution, allocator, 20);
    try aocTestSolution(part2, data, part2_solution, allocator, 4_000_000);
}

test "day15_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator, 10);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator, 2_000_000);
}

test "day15_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator, 20);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator, 4_000_000);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
