const std = @import("std");
const assert = std.debug.assert;
const sort = std.sort;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

const input = @embedFile("../input.txt");

pub fn main() !void {
    try parseInput();
    var day: usize = 0;
    while (day < 100) : (day += 1) try step();
    try std.io.getStdOut().writer().print("{}\n", .{flipped_tiles.items.len});
}

fn step() !void {
    if (flipped_tiles.items.len == 0) return;

    // Mapper
    try mapped_tiles.resize(0);
    try mapped_tiles.ensureCapacity(6 * flipped_tiles.items.len);
    for (flipped_tiles.items) |t| {
        try mapped_tiles.append(Tile{ .x = t.x + 1, .y = t.y + 0 });
        try mapped_tiles.append(Tile{ .x = t.x + 1, .y = t.y - 1 });
        try mapped_tiles.append(Tile{ .x = t.x + 0, .y = t.y - 1 });
        try mapped_tiles.append(Tile{ .x = t.x - 1, .y = t.y + 0 });
        try mapped_tiles.append(Tile{ .x = t.x - 1, .y = t.y + 1 });
        try mapped_tiles.append(Tile{ .x = t.x + 0, .y = t.y + 1 });
    }
    sort.sort(Tile, mapped_tiles.items, {}, Tile.lessThan);

    // Reducer
    try new_tiles.resize(0);
    var f: usize = 0;
    var m: usize = 0;
    while (m < mapped_tiles.items.len) {
        const tile = mapped_tiles.items[m];

        while ((f < flipped_tiles.items.len) and
            Tile.lessThan({}, flipped_tiles.items[f], tile))
        {
            f += 1;
        }
        const black = (f < flipped_tiles.items.len) and
            tile.equal(flipped_tiles.items[f]);

        var count: usize = 0;
        while ((m < mapped_tiles.items.len) and
            tile.equal(mapped_tiles.items[m]))
        {
            count += 1;
            m += 1;
        }

        if ((black and count == 1) or count == 2) {
            try new_tiles.append(tile);
        }
    }

    // Swap in the result
    const tmp = flipped_tiles;
    flipped_tiles = new_tiles;
    new_tiles = tmp;
}

const Tile = struct {
    x: isize,
    y: isize,

    fn equal(self: Tile, other: Tile) bool {
        return (self.x == other.x) and (self.y == other.y);
    }

    fn lessThan(context: void, lhs: Tile, rhs: Tile) bool {
        return (lhs.x < rhs.x) or ((lhs.x == rhs.x) and (lhs.y < rhs.y));
    }
};
var flipped_tiles = ArrayList(Tile).init(allocator);
var mapped_tiles = ArrayList(Tile).init(allocator);
var new_tiles = ArrayList(Tile).init(allocator);

fn flip(tile: Tile) !void {
    for (flipped_tiles.items) |t, i| {
        if (tile.equal(t)) {
            _ = flipped_tiles.swapRemove(i);
            return;
        }
    } else {
        try flipped_tiles.append(tile);
    }
}

fn parseInput() !void {
    var input_parser = InputParser{};
    while (!input_parser.done()) {
        const tile = try input_parser.parseLine();
        try flip(tile);
    }
    sort.sort(Tile, flipped_tiles.items, {}, Tile.lessThan);
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

    fn parseLine(self: *Self) Fail!Tile {
        const start = self.index;
        errdefer self.index = start;

        var x: isize = 0;
        var y: isize = 0;

        while (true) {
            if (self.parseLiteral("e")) {
                x += 1;
            } else |_| if (self.parseLiteral("se")) {
                x += 1;
                y -= 1;
            } else |_| if (self.parseLiteral("sw")) {
                y -= 1;
            } else |_| if (self.parseLiteral("w")) {
                x -= 1;
            } else |_| if (self.parseLiteral("nw")) {
                x -= 1;
                y += 1;
            } else |_| if (self.parseLiteral("ne")) {
                y += 1;
            } else |_| {
                try self.parseLiteral("\n");
                return Tile{ .x = x, .y = y };
            }
        }
    }
};
