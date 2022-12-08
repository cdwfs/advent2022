const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("data/day07.txt");

const Input = struct {
    allocator: std.mem.Allocator,
    terminal_lines: std.BoundedArray([]const u8, 1100),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var input = Input{
            .allocator = allocator,
            .terminal_lines = try std.BoundedArray([]const u8, 1100).init(0),
        };
        errdefer input.deinit();

        while (lines.next()) |line| {
            input.terminal_lines.appendAssumeCapacity(line);
        }
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const File = struct {
    name: []const u8,
    size: i64,
};
const Dir = struct {
    name: []const u8,
    parent: ?*Dir,
    files: std.ArrayList(File),
    dirs: std.ArrayList(Dir), // TODO: tried to make this a list of pointers, and that didn't work. how to initialize a pointer to some memory as an object?
    total_size: i64,
    pub fn init(name: []const u8, parent: ?*Dir, allocator: std.mem.Allocator) @This() {
        var self = @This(){
            .name = name,
            .parent = parent,
            .files = std.ArrayList(File).init(allocator),
            .dirs = std.ArrayList(Dir).init(allocator),
            .total_size = 0,
        };
        errdefer self.deinit();
        return self;
    }

    pub fn generate_from_commands(input: Input) !Dir {
        var root_dir = Dir.init("", null, input.allocator);
        errdefer root_dir.deinit();
        var current_dir: *Dir = undefined;
        for (input.terminal_lines.constSlice()) |line| {
            if (line[0] != '$') { // ls output
                if (std.mem.eql(u8, line[0..3], "dir")) {
                    const dir_name = line[4..];
                    // Create a directory record here, if it doesn't already exist
                    for (current_dir.dirs.items) |*child_dir| {
                        if (std.mem.eql(u8, child_dir.name, dir_name)) {
                            break; // directory already exists, nothing to do
                        }
                    } else {
                        try current_dir.dirs.append(Dir.init(dir_name, current_dir, input.allocator));
                    }
                } else {
                    // file listing
                    var tokens = std.mem.split(u8, line, " ");
                    var size: i64 = try std.fmt.parseInt(i64, tokens.next().?, 10);
                    var file_name = tokens.next().?;
                    // Create a file record here, if it doesn't already exist
                    for (current_dir.files.items) |*f| {
                        if (std.mem.eql(u8, f.name, file_name)) {
                            break; // record already exists, nothing to do
                        }
                    } else {
                        try current_dir.files.append(File{ .name = file_name, .size = size });
                    }
                }
            } else if (line[2] == 'c') { // cd
                const target = line[5..];
                if (target[0] == '/') {
                    current_dir = &root_dir;
                } else if (std.mem.eql(u8, target, "..")) {
                    current_dir = current_dir.parent.?;
                } else {
                    for (current_dir.dirs.items) |*child_dir| {
                        if (std.mem.eql(u8, child_dir.name, target)) {
                            current_dir = child_dir;
                            break;
                        }
                    } else {
                        std.debug.print("ERROR: '{s}` -- 'no such directory {s}\n", .{ line, target });
                    }
                }
            } else if (line[2] == 'l') { // ls
                // nothing to do, but expect output next.
            }
        }

        root_dir.compute_dir_sizes();
        return root_dir;
    }

    pub fn compute_dir_sizes(self: *@This()) void {
        self.total_size = 0;
        for (self.dirs.items) |*dir| {
            dir.compute_dir_sizes();
            self.total_size += dir.total_size;
        }
        for (self.files.items) |file| {
            self.total_size += file.size;
        }
    }

    pub fn total_sizes_less_than_threshold(self: @This(), threshold: i64) i64 {
        var result: i64 = 0;
        for (self.dirs.items) |dir| {
            result += dir.total_sizes_less_than_threshold(threshold);
        }
        if (self.total_size <= threshold)
            result += self.total_size;
        return result;
    }

    pub fn size_of_smallest_dir_above_threshold(self: @This(), threshold: i64) ?i64 {
        if (self.total_size < threshold)
            return null; // directory is not large enough to free enough space, so skip it and its children.

        var result: i64 = self.total_size;
        for (self.dirs.items) |dir| {
            if (dir.size_of_smallest_dir_above_threshold(threshold)) |child_size| {
                result = std.math.min(result, child_size);
            }
        }
        return result;
    }

    pub fn deinit(self: @This()) void {
        for (self.dirs.items) |dir| {
            dir.deinit();
        }
        self.dirs.deinit();
        self.files.deinit();
    }
};

fn part1(input: Input, output: *output_type) !void {
    var root_dir: Dir = try Dir.generate_from_commands(input);
    defer root_dir.deinit();

    output.* = root_dir.total_sizes_less_than_threshold(100_000);
}

fn part2(input: Input, output: *output_type) !void {
    var root_dir: Dir = try Dir.generate_from_commands(input);
    defer root_dir.deinit();

    const total_disk_space: i64 = 70_000_000;
    const target_free_space: i64 = 30_000_000;
    const current_free_space: i64 = total_disk_space - root_dir.total_size;
    output.* = root_dir.size_of_smallest_dir_above_threshold(target_free_space - current_free_space).?;
}

const test_data =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;
const part1_test_solution: ?i64 = 95437;
const part1_solution: ?i64 = 1611443;
const part2_test_solution: ?i64 = 24933642;
const part2_solution: ?i64 = 2086088;

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

test "day07_part1" {
    try aocTestSolution(part1, test_data, part1_test_solution, std.testing.allocator);
    try aocTestSolution(part1, data, part1_solution, std.testing.allocator);
}

test "day07_part2" {
    try aocTestSolution(part2, test_data, part2_test_solution, std.testing.allocator);
    try aocTestSolution(part2, data, part2_solution, std.testing.allocator);
}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
