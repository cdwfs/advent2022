My [Advent of Code 2022](https://adventofcode.com/2022) solutions, implemented in
[Zig](https://www.ziglang.org/) and built using [VS Code](https://code.visualstudio.com/).
They are not pretty. They are not elegant. They probably look like I checked in the very
first version that produced the correct answer, because that's more or less exactly what I did.
I'm not here to code-golf.

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

### [Day 3: Rucksack Reorganization](https://adventofcode.com/2022/day/3)
- Hitting my stride again
- I'm reminded again that there is no `for(int i=0; i<count; ++i) {}` equivalent in Zig. The closest approximation is
  `var i:usize = 0; while(i < count) : (i += 1) {}`.
- Directly manipulating slice lengths was useful here, even if it feels naughty.
- I hit my first instance of "expression accidentally treated as `comptime`", and had to bust out the `@as(i64, expr)` workaround.
- To initialize an array to zero: `var array:[256]u8 = [_]u8{0} ** 256;`
- The ternary operator looks like `var foo = if (condition) a else b;`
- [`std.StaticBitSet()`](https://ziglang.org/documentation/master/std/#root;StaticBitSet) for efficient bitsets of any size, automatically routing to either a single-int or array-based implementation.

### [Day 4: Camp Cleanup](https://adventofcode.com/2022/day/4)
- Nothing new today, really. That wasn't so bad.

### [Day 5: Supply Stacks](https://adventofcode.com/2022/day/5)
- Oh, now solutions can be strings? I'll have to update the template to accomodate that!
- Some functions that might be useful for parsing: `std.mem.sliceBackwards()`, the `.rest()` method on a slice iterator
  (returns the entire remainder of the slice), `std.mem.reverse()`.
- Line endings are a pain. The `dayNN.txt` files I save use `\r\n` endings, but the unit test input I embed in my source
  code just uses `\n`. `std.mem.tokenize()` is fine with this, since it takes a _set_ of delimiters and splits by any number
  of any of them in a row. `std.mem.split()` is _not_ fine with this; it takes a specific byte sequence as a delimiter.
  But `std.mem.split()` gives you empty ranges, while `std.mem.tokenize()` quietly skips right over them.
  - I should add a function to util.zig that scans the input and returns the appropriate EOL delimiter

### [Day 6: Tuning Trouble](https://adventofcode.com/2022/day/6)
- Brute-forced it with bit sets as a first pass.

### [Day 7: No Space Left On Device](https://adventofcode.com/2022/day/7)
- Function pointer syntax [changed](https://ziglang.org/download/0.10.0/release-notes.html#Function-Pointers) in Zig 0.10.0, but only for the self-hosting/stage2 compiler. And this framework still uses stage1. Left myself a TODO to fix later.
- My initial pass tried to store lists of pointers-to-`*Dir`/`*File` at each directory, but I guess that means I'd need an "init this memory in-place as a `Dir`/`File` method? I just stuck to lists of `Dir`/`File` values instead, but this feels like a weak point I should revisit.
- In retrospect, I could have used `std.StringHashMap` to store the dirs/files at each level instead of a flat list. It would've made the code a bit cleaner, but probably not any faster.
  - 3x slower, in fact! And not _that_ much simpler.
- It turns out I don't remember how to actually return an error when an error occurs. I should fix that.

### [Day 8: Treetop Tree House](https://adventofcode.com/2022/day/8)
- Virtually all my bugs today were related to forgetting to re-initialize loop indices to zero before the loop. Let's make a range utility.
- Fixed-size 2D arrays plus a `dim_x`/`dim_y` parameter seemed to work just fine.

### [Day 9: Rope Bridge](https://adventofcode.com/2022/day/9)
- `std.AutoArrayHashMap` with a `void` key type was a perfectly reasonable hash set.
  - ...but `std.AutoHashMap` with a more aggressive max capacity ran about twice as fast!
  - I wonder if I could do better with a custom hash function?

### [Day 10: Cathode-Ray Tube](https://adventofcode.com/2022/day/10)
- I made a [tagged union](https://ziglang.org/documentation/0.10.0/#Tagged-union)!
- I wrote a quick utility to find the EOL character(s) for a given block of text, which should help me work around the LF/CRLF issues from day 5.

### [Day 11: Monkey in the Middle](https://adventofcode.com/2022/day/11)
- Squaring a number 10,000 times gets very large!
- No fancy new language features. Just math.
