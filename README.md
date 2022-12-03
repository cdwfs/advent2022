My [Advent of Code 2022](https://adventofcode.com/2022) solutions, implemented in
[Zig](https://www.ziglang.org/) and built using [VS Code](https://code.visualstudio.com/).

_Based on the [Zig AoC template](https://github.com/SpexGuy/Zig-AoC-Template) provided by [@SpexGuy](https://github.com/SpexGuy/).
Instructions to build and extend the template are [here](TEMPLATE.md)._

## TIL

A list of the puzzles, and what new language/tool features I learned each day:

### Useful VSCode settings (language-independent)
```
// "Suggestions" pops up a list of completions of the current word as you type.
// Arguably useful in code; definitely not useful in comments or strings.
"editor.quickSuggestions": {
    "other": true,
    "comments": false,
    "strings": false
},
// Suggestions are also automatically triggered when you type certain trigger characters such as '.' for struct fields.
// Again, great in code, not so great in comments. Ideally, this would be configurable at the same granularity
// as editor.quickSuggestions, but the best we can do is just disable it; not having suggestions pop up rampantly while
// typing comments outweights the convenience of typing "foo." to browse all members of "foo".
// You can still manually trigger suggestions with Ctrl+Space.
"editor.suggestOnTriggerCharacters": false,
// Change multi-cursor mode to my more familiar mode, where holding Alt lets you select in column mode. And Ctrl+click
// adds multiple cursors, but I don't use that too frequently.
"editor.multiCursorModifier": "ctrlCmd",
// Does what it says on the tin.
"debug.allowBreakpointsEverywhere": true,
```

### [Day 1: Calorie Counting](https://adventofcode.com/2022/day/1)
- Cobweb-clearing
- Use [`std.BoundedArray`](https://ziglang.org/documentation/master/std/#root;BoundedArray) for alloc-less [`std.ArrayList`](https://ziglang.org/documentation/master/std/#root;ArrayList) when a max capacity is known at compile time.
  - Use with `.appendAssumeCapacity()` for bounds-check-free (unsafe!) appending.
  - No `.deinit()` required
  - Use `.slice()` and `.constSlice()` for array-like access.
  - The line count of your `input.txt` file is a great max capacity for AoC problems :)
- This year, I'm returning `!i64` instead of `i64` from my `part1()` and `part2()` functions. An exception in either case means something
  has gone wrong. This way there's less hoop-jumping and `catch unreachable`s necessary.
- `std.mem.tokenize(u8, data, "\r\n")` to get a `TokenIterator` to iterate over lines in text data.
  `while(iter.next()) |str| {}` to process things from the iterator until it's empty.
  - But if you need to preserve empty lines in the input, use `std.mem.split(u8, data, "\n")`
- `std.fmt.parseInt(u8, str, 10)` to convert a string to a base-10 integer.
  - append `catch unreachable` to an error union to say "this can never fail, just give me the value".
- `std.sort.sort(i64, array, {}, comptime std.sort.desc(i64))` to sort a slice in descending order.

### [Day 2: Rock Paper Scissors](https://adventofcode.com/2022/day/2)
- Cobweb-clearing
- Don't try to guess what part 2 will be while solving part 1! (I speculatively over-generalized my part1 solution, and guessed wrong)
- Enums look like structs. You can give them an ordinal type, and access it with `@enumToInt(MyEnum.Value)`.
- You can't switch on tuples. I feel like that would've worked in Rust.
- I _almost_ had a use case for initializing a lookup table using a comptime function, but it was just too easy to do in my head & hard-code the values instead. Maybe next time.
