const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day05.txt");

const Move = struct {
    count:usize,
    from:usize,
    to:usize,
};

const Input = struct {
    allocator: std.mem.Allocator,
    initial_stacks: [9]std.BoundedArray(u8,100),
    moves: std.BoundedArray(Move,600),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var input = Input{
            .allocator = allocator,
            .initial_stacks = .{try std.BoundedArray(u8,100).init(0)} ** 9,
            .moves = try std.BoundedArray(Move,600).init(0),
        };
        errdefer input.deinit();

        while(lines.next()) |line| {
            // Crate contents are letters. The first line that has a number 1 where we expect a crate
            // is the end of the stacks (and can be skipped)
            if (line[1] == '1')
                break;
            // The stacks are helpfully padded with spaces, so we can use the line length to
            // determine how many stacks are present.
            const stack_count = (line.len+1)/4;
            var stack_index:usize = 0;
            while(stack_index < stack_count) : (stack_index += 1) {
                const c = line[4*stack_index + 1];
                if (c != ' ')
                    input.initial_stacks[stack_index].appendAssumeCapacity(c);
            }
        }
        // Now we're parsing moves of the form "move N from X to Y"
        while(lines.next()) |line| {
            var fields = std.mem.tokenize(u8, line, "move from to");
            input.moves.appendAssumeCapacity(Move{
                .count = try parseInt(usize, fields.next().?, 10),
                .from = try parseInt(usize, fields.next().?, 10),
                .to = try parseInt(usize, fields.next().?, 10),
            });
        }

        // The stacks are all reversed, because we built them top-down. Reverse them in-place.
        for(input.initial_stacks) |*stack| {
            std.mem.reverse(u8, stack.slice());
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input, output:*part1_solution_type) !void {
    // create mutable stacks
    var stacks:@TypeOf(input.initial_stacks) = undefined;
    for(input.initial_stacks) |in_stack,i| {
        stacks[i] = in_stack;
    }

    for(input.moves.constSlice()) |move| {
        var i:usize = 0;
        while(i < move.count) : (i += 1) {
            stacks[move.to-1].appendAssumeCapacity(stacks[move.from-1].pop());
        }
    }
    for(stacks) |stack| {
        if (stack.len > 0)
            output.appendAssumeCapacity(stack.get(stack.len-1));
    }
}

fn part2(input: Input, output:*part2_solution_type) !void {
    // create mutable stacks
    var stacks:@TypeOf(input.initial_stacks) = undefined;
    for(input.initial_stacks) |in_stack,i| {
        stacks[i] = in_stack;
    }

    for(input.moves.constSlice()) |move| {
        const srcStackBasePtr = stacks[move.from-1].slice().ptr;
        const srcStackSize = stacks[move.from-1].len;
        stacks[move.to-1].appendSliceAssumeCapacity(srcStackBasePtr[srcStackSize-move.count..srcStackSize]);
        stacks[move.from-1].len -= move.count;
    }
    for(stacks) |stack| {
        if (stack.len > 0)
            output.appendAssumeCapacity(stack.get(stack.len-1));
    }
}

const test_data =
    \\    [D]    
    \\[N] [C]    
    \\[Z] [M] [P]
    \\ 1   2   3 
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
;
const part1_test_solution: ?[]const u8 = "CMZ";
const part1_solution: ?[]const u8 = "VCTFTJQCG";
const part2_test_solution: ?[]const u8 = "MCD";
const part2_solution: ?[]const u8 = "GCFGLDNJZ";

// Just boilerplate below here, nothing to see

const part1_solution_type = if (@TypeOf(part1_test_solution) == ?[]const u8) std.BoundedArray(u8,256) else i64;
const part2_solution_type = if (@TypeOf(part2_test_solution) == ?[]const u8) std.BoundedArray(u8,256) else i64;

fn testPart1(allocator: std.mem.Allocator) !void {
    if (part1_test_solution == null and part1_solution == null)
        return error.SkipZigTest;

    var test_input = try Input.init(test_data, allocator);
    defer test_input.deinit();
    if (part1_test_solution) |expected_solution| {
        if (part1_solution_type == std.BoundedArray(u8,256))
        {
            var actual_solution = try std.BoundedArray(u8,256).init(0);
            try part1(test_input, &actual_solution);
            try std.testing.expectEqualStrings(expected_solution, actual_solution.constSlice());
        }
        else
        {
            var actual_solution:i64 = 0;
            try part1(test_input, &actual_solution);
            try std.testing.expectEqual(expected_solution, actual_solution);
        }
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, allocator);
    defer input.deinit();
    if (part1_solution) |expected_solution| {
        if (part1_solution_type == std.BoundedArray(u8,256))
        {
            var actual_solution = try std.BoundedArray(u8,256).init(0);
            try part1(input, &actual_solution);
            try std.testing.expectEqualStrings(expected_solution, actual_solution.constSlice());
        }
        else
        {
            var actual_solution:i64 = 0;
            try part1(input, &actual_solution);
            try std.testing.expectEqual(expected_solution, actual_solution);
        }
        print("part1 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

fn testPart2(allocator: std.mem.Allocator) !void {
    if (part2_test_solution == null and part2_solution == null)
        return error.SkipZigTest;

    var test_input = try Input.init(test_data, allocator);
    defer test_input.deinit();
    if (part2_test_solution) |expected_solution| {
        if (part2_solution_type == std.BoundedArray(u8,256))
        {
            var actual_solution = try std.BoundedArray(u8,256).init(0);
            try part2(test_input, &actual_solution);
            try std.testing.expectEqualStrings(expected_solution, actual_solution.constSlice());
        }
        else
        {
            var actual_solution:i64 = 0;
            try part2(test_input, &actual_solution);
            try std.testing.expectEqual(expected_solution, actual_solution);
        }
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, allocator);
    defer input.deinit();
    if (part2_solution) |expected_solution| {
        if (part2_solution_type == std.BoundedArray(u8,256))
        {
            var actual_solution = try std.BoundedArray(u8,256).init(0);
            try part2(input, &actual_solution);
            try std.testing.expectEqualStrings(expected_solution, actual_solution.constSlice());
        }
        else
        {
            var actual_solution:i64 = 0;
            try part2(input, &actual_solution);
            try std.testing.expectEqual(expected_solution, actual_solution);
        }
        print("part2 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try testPart1(allocator);
    try testPart2(allocator);
}

test "day05_part1" {
    try testPart1(std.testing.allocator);
}

test "day05_part2" {
    try testPart2(std.testing.allocator);
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const expect = std.testing.expect;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
