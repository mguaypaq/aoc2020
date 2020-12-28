const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

const input = @embedFile("../input.txt");

pub fn main() !void {
    try parseInput();
    try std.io.getStdOut().writer().print("{}\n", .{flipped_tiles.items.len});
}

const Tile = struct { x: isize, y: isize };
var flipped_tiles = ArrayList(Tile).init(allocator);

fn flip(tile: Tile) !void {
    for (flipped_tiles.items) |t, i| {
        if (tile.x == t.x and tile.y == t.y) {
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
