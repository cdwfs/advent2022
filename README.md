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

### [Day 12: Hill Climbing Algorithm](https://adventofcode.com/2022/day/12)
- Once again (same as 2021 day 15), A* was actually slower than Djikstra's. The "visited node" counts were nearly identical, so I assume it's because the shortest path to the goal is so windy that there isn't actually much benefit to a guided search over a simple Djikstra's, and the extra overhead of the heuristic is just wasted.
- The hacks to make part2 work are ugly but serviceable. In retrospect, implementing part1 in reverse (search outwards from the goal until you find the shortest path to the start) would have made part2 trivial (search outwards from the goal until you finding the shortest path to _any_ `a` cell).

### [Day 13: Distress Signal](https://adventofcode.com/2022/day/13)
- Parsing was _extremely_ fiddly. I'm sure there's a better way.
- I got the correct answers the first time the code compiled and ran, and for that I am eternally grateful.
- I came back later with some hints from the Zig Discord and implemented parse-free comparisons, and they were literally 500x faster (and half the code).
- `callconv(.Inline)` is apparently now just an `inline` keyword on the function. And `zig format` fixes it automatically!

### [Day 14: Regolith Reservoir](https://adventofcode.com/2022/day/14)
- I wonder if using a hashmap of cell contents would be faster than a sparse 2D array?

### [Day 15: Beacon Exclusion Zone](https://adventofcode.com/2022/day/15)
- I figured any representation that stored >0 data per cell would be impractical at this scale, so instead I implemented a per-row check for part 1 that just looked at the endpoints of the coverage range for each sensor.
- For part 2, the first thing I checked was how long it took to run my part 1 single-row solution 4 million times (around 20 seconds in debug), so I knew it was feasible to just tweak the loop to look for holes instead of count covered cells. And that's what I did! I'm sure there's a smarter way, though.

### [Day 16: Proboscidea Volcanium](https://adventofcode.com/2022/day/16)
- What a disaster.
- The key word today was "graph reduction". Reduce the current state to as little data as possible, use it to create a hash table of previously-visited states and their results, and then refer to that table on future iterations to avoid needlessly recomputing work. I was able to get a correct solution for day 1 without this, but when I added it retroactively it was about 100x speedup.
- For part 2, even that wasn't enough; my solver ran for 5-10 minutes before running out of memory (Zig hash tables are limited to 4GB). I added a few low-hanging early outs to reduce the number of states I was caching, but in the end what saved me was reversing the order of my tunnels (so I visit a different set of states before I OOM). This happened to be enough to get me a correct solution, but I hate it.
- The way to make this run in O(milliseconds) instead of O(minutes) seems to be some sort of pruning to early-out if you can be confident there's no way to beat to current best score from your current state. I didn't implement this because all the heuristics I thought of seemed way too conservative, but maybe "way too conservative" is better than "nothing at all".

### [Day 17: Pyroclastic Flow](https://adventofcode.com/2022/day/17)
- Cycle detection!
- VSCode doesn't do well inspecting Zig's weird-sized integers in the debugger. A `[4]u9` was rendered very strangely.
- I'm reasonable happy with the cycle-detection and -validation logic, but my scourge in the end was off-by-one errors.
- Something to internalize for the future: Zig will happily cast unsigned integers to `usize` when indexing arrays, so you don't need to make every unsigned variable a `usize` just in case it's an array index. _Signed_ integers must still be converted, however.

### [Day 18: Boiling Boulders](https://adventofcode.com/2022/day/18)
- I screw up nested for loops in Zig _every single time_.
- Other than that, today was pretty nice.

### [Day 19: Not Enough Minerals](https://adventofcode.com/2022/day/19)
- Yet another "huge search space" problem where my pruning is _just barely_ good enough to get a solution in a timely fashion, but clearly plenty of room for improvement based on some of the other times I'm seeing.
- Revisit me after day 25!

### [Day 20: Grove Positioning System](https://adventofcode.com/2022/day/20)
- The trick today was figuring out how to turn large move distances into equivalent smaller ones.
- Note that "equivalent" has a different meaning when you're moving an item in the list by N spaces and when you're peeking ahead by N items. Off-by-one errors aplenty!

### [Day 21: Monkey Math](https://adventofcode.com/2022/day/21)
- It's taken me this long to realize that I don't need to pass `std.BoundingArray(WhateverTheHell,capacity)` into functions if they're just reading the array contents. Just have the function take a slice.

### [Day 22: Monkey Map](https://adventofcode.com/2022/day/22)
- Hey, this problem [seems familiar](https://github.com/cdwfs/t3p)...
- I like having access to enum tags as strings out of the box.
- I don't like the constant struggle of wondering whether a given integer field should be signed or unsigned, and which is likely to result in fewer readability-killing typecasts.