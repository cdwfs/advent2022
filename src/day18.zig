const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day18.txt");

const Vec3 = @Vector(3, i64);

const Input = struct {
    allocator: std.mem.Allocator,
    cubes: std.BoundedArray(Vec3, 2100),
    dim: Vec3,
    cell_count: u32,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        const eol = util.getLineEnding(input_text).?;
        var lines = std.mem.tokenize(u8, input_text, eol);
        var input = Input{
            .allocator = allocator,
            .cubes = try std.BoundedArray(Vec3, 2100).init(0),
            .dim = Vec3{ 0, 0, 0 },
            .cell_count = 0,
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            var coords = std.mem.tokenize(u8, line, ",");
            const c = Vec3{
                try std.fmt.parseInt(i64, coords.next().?, 10),
                try std.fmt.parseInt(i64, coords.next().?, 10),
                try std.fmt.parseInt(i64, coords.next().?, 10),
            };
            input.cubes.appendAssumeCapacity(c);
            input.dim = @max(input.dim, c);
        }
        input.dim += Vec3{ 1, 1, 1 }; // dim should be 1+ the max coordinate we found
        input.cell_count = @intCast(u32, @reduce(.Mul, input.dim));
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

inline fn neighbors(c:Vec3) [6]Vec3 {
    return [6]Vec3{
        Vec3{ c[0] - 1, c[1], c[2] },
        Vec3{ c[0] + 1, c[1], c[2] },
        Vec3{ c[0], c[1] - 1, c[2] },
        Vec3{ c[0], c[1] + 1, c[2] },
        Vec3{ c[0], c[1], c[2] - 1 },
        Vec3{ c[0], c[1], c[2] + 1 },
    };
}

fn part1(input: Input, output: *output_type) !void {
    var cells = std.AutoHashMap(Vec3, void).init(input.allocator);
    defer cells.deinit();
    try cells.ensureTotalCapacity(input.cell_count);
    for (input.cubes.constSlice()) |c| {
        cells.putAssumeCapacity(c, {});
    }
    output.* = 0;
    for (input.cubes.constSlice()) |c| {
        for(neighbors(c)) |n| {
            if (!cells.contains(n)) {
                output.* += 1;
            }
        }
    }
}

fn visit(input:Input, cell:Vec3, count:*i64, cells:std.AutoHashMap(Vec3, void), visited:*std.AutoHashMap(Vec3, void)) void {
    if (isOutOfBounds(cell, input.dim) or visited.contains(cell) or cells.contains(cell)) {
        return;
    }
    // This is an empty, unvisited, in-bounds cell.
    visited.putAssumeCapacity(cell, {});
    for(neighbors(cell)) |n| {
        if (cells.contains(n)) {
            count.* += 1;
        } else {
            visit(input, n, count, cells, visited);
        }
    }
}

inline fn isOutOfBounds(c:Vec3, dim:Vec3) bool {
    return
        c[0] < 0 or c[0] >= dim[0] or
        c[1] < 0 or c[1] >= dim[1] or
        c[2] < 0 or c[2] >= dim[2];
}

fn part2(input: Input, output: *output_type) !void {
    var visited = std.AutoHashMap(Vec3, void).init(input.allocator);
    defer visited.deinit();
    try visited.ensureTotalCapacity(input.cell_count);
    var cells = std.AutoHashMap(Vec3, void).init(input.allocator);
    defer cells.deinit();
    try cells.ensureTotalCapacity(input.cell_count);
    for (input.cubes.constSlice()) |c| {
        cells.putAssumeCapacity(c, {});
        visited.putAssumeCapacity(c, {});
    }
    // flood-fill
    var z:i64 = 0;
    output.* = 0;
    while (z < input.dim[2]) : (z += 1) {
        var y:i64 = 0;
        while (y < input.dim[1]) : (y += 1) {
            var x:i64 = 0;
            while (x < input.dim[0]) : (x += 1) {
                if (z == 0 or z == input.dim[2] - 1 or
                    y == 0 or y == input.dim[1] - 1 or
                    x == 0 or x == input.dim[0] - 1)
                {
                    const c = Vec3{x,y,z};
                    if (cells.contains(c)) {
                        // For filled cells on the exterior, count their exterior-facing faces
                        for(neighbors(c)) |n| {
                            if (isOutOfBounds(n, input.dim)) {
                                output.* += 1;
                            }
                        }
                    } else {
                        // For empty and unvisited cells on the exterior, flood-fill to count
                        // all reachable faces.
                        visit(input, Vec3{x,y,z}, output, cells, &visited);
                    }
                }
            }
        }
    }
}

const test_data =
    \\2,2,2
    \\1,2,2
    \\3,2,2
    \\2,1,2
    \\2,3,2
    \\2,2,1
    \\2,2,3
    \\2,2,4
    \\2,2,6
    \\1,2,5
    \\3,2,5
    \\2,1,5
    \\2,3,5
;
const part1_test_solution: ?i64 = 64;
const part1_solution: ?i64 = 3610;
const part2_test_solution: ?i64 = 58;
const part2_solution: ?i64 = 2082;

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

test "day18_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day18_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
