const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

const input = @embedFile("../input.txt");

/// Whether a given ingredient corresponds to a given allergen.
const State = enum { maybe, yes, no };
var equal: [][]State = undefined;

pub fn main() !void {
    try parseInput();
    try initEqual();
    applyLines();
    try deduce();

    var unsafe = try allocator.alloc(Pair, allergenWords.items.len);
    var index: usize = 0;
    for (equal) |row, ingredient| {
        for (row) |state, allergen| {
            if (state == .yes) {
                unsafe[index] = Pair{
                    .ingredient = ingredient,
                    .allergen = allergen,
                };
                index += 1;
            }
        }
    }
    assert(index == unsafe.len);

    std.sort.sort(Pair, unsafe, {}, Pair.lessThan);

    const writer = std.io.getStdOut().writer();
    for (unsafe) |pair, pos| {
        try writer.print("{}", .{ingredientWords.items[pair.ingredient]});
        if (pos < unsafe.len - 1) {
            try writer.print(",", .{});
        } else {
            try writer.print("\n", .{});
        }
    }
}

const Pair = struct {
    ingredient: usize,
    allergen: usize,

    fn lessThan(context: void, lhs: Pair, rhs: Pair) bool {
        return std.mem.lessThan(
            u8,
            allergenWords.items[lhs.allergen],
            allergenWords.items[rhs.allergen],
        );
    }
};

fn deduce() !void {
    var allergen_matched = try allocator.alloc(bool, allergenWords.items.len);
    defer allocator.free(allergen_matched);
    std.mem.set(bool, allergen_matched, false);

    var progress = true;
    while (progress) {
        progress = false;
        for (allergen_matched) |matched, allergen| {
            if (matched) continue;
            var unique_ingredient: ?usize = null;
            for (equal) |row, ingredient| {
                switch (row[allergen]) {
                    .maybe => if (unique_ingredient == null) {
                        unique_ingredient = ingredient;
                    } else {
                        unique_ingredient = null;
                        break;
                    },
                    .no => continue,
                    .yes => unreachable,
                }
            }
            if (unique_ingredient) |ingredient| {
                allergen_matched[allergen] = true;
                progress = true;
                for (equal[ingredient]) |*entry| {
                    assert(entry.* != .yes);
                    entry.* = .no;
                }
                equal[ingredient][allergen] = .yes;
            }
        }
    }
}

fn applyLines() void {
    for (lines.items) |line| {
        for (equal) |row, ingredient| {
            if (contains(line.ingredients, ingredient)) continue;
            for (line.allergens) |allergen| row[allergen] = .no;
        }
    }
}

fn contains(slice: []const usize, value: usize) bool {
    for (slice) |v| {
        if (v == value) return true;
    } else return false;
}

fn initEqual() !void {
    equal = try allocator.alloc([]State, ingredientWords.items.len);
    for (equal) |*row| {
        row.* = try allocator.alloc(State, allergenWords.items.len);
        std.mem.set(State, row.*, .maybe);
    }
}

const Word = []const u8;
var ingredientWords = ArrayList(Word).init(allocator);
var allergenWords = ArrayList(Word).init(allocator);

/// Find or add word to array_list and return the index.
fn find(array_list: *ArrayList(Word), word: Word) !usize {
    for (array_list.items) |entry, index|
        if (std.mem.eql(u8, word, entry)) return index;
    const index = array_list.items.len;
    try array_list.append(word);
    return index;
}

const Line = struct {
    ingredients: []usize,
    allergens: []usize,
};
var lines = ArrayList(Line).init(allocator);

/// Fills ingredientWords, allergenWords, lines.
fn parseInput() !void {
    var input_parser = InputParser{};
    while (!input_parser.done())
        try lines.append(try input_parser.parseLine());
}

const InputParser = struct {
    const Self = @This();
    const Fail = error{ParseFail};

    index: usize = 0,

    fn done(self: Self) bool {
        return self.index == input.len;
    }

    fn parseLiteral(self: *Self, literal: []const u8) Fail!void {
        const start = self.index;
        errdefer self.index = start;

        if (input.len < self.index + literal.len) return error.ParseFail;
        for (literal) |char| {
            if (char != input[self.index]) return error.ParseFail;
            self.index += 1;
        }
    }

    fn parseWord(self: *Self) Fail!Word {
        const start = self.index;
        errdefer self.index = start;

        while (self.index < input.len) : (self.index += 1) {
            switch (input[self.index]) {
                'a'...'z' => continue,
                else => break,
            }
        }
        if (self.index == start) return error.ParseFail;

        return input[start..self.index];
    }

    fn parseLine(self: *Self) !Line {
        const start = self.index;
        errdefer self.index = start;

        var ingredients = ArrayList(usize).init(allocator);
        defer ingredients.deinit();
        while (self.parseWord()) |word| {
            try ingredients.append(try find(&ingredientWords, word));
            try self.parseLiteral(" ");
        } else |_| {}
        if (ingredients.items.len == 0) return error.ParseFail;

        var allergens = ArrayList(usize).init(allocator);
        defer allergens.deinit();
        try self.parseLiteral("(contains ");
        var word = try self.parseWord();
        try allergens.append(try find(&allergenWords, word));
        while (self.parseLiteral(", ")) {
            word = try self.parseWord();
            try allergens.append(try find(&allergenWords, word));
        } else |_| {
            try self.parseLiteral(")\n");
        }

        return Line{
            .ingredients = ingredients.toOwnedSlice(),
            .allergens = allergens.toOwnedSlice(),
        };
    }
};
