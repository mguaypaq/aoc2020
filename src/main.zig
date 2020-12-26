const std = @import("std");
const assert = std.debug.assert;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;
const input = @embedFile("../input.txt");

pub fn main() !void {
    var input_parser = InputParser{};

    var tiles = std.ArrayList(Tile).init(allocator);
    while (!input_parser.done()) {
        try tiles.append(try input_parser.parseTile());
    }

    var edge_mult = std.AutoHashMap(u32, u8).init(allocator);
    for (tiles.items) |tile| {
        for (tile.edges()) |edge| {
            const entry = try edge_mult.getOrPutValue(normalize(edge), 0);
            entry.value += 1;
        }
    }

    var potential_corners: u8 = 0;
    var product: u64 = 1;
    for (tiles.items) |tile| {
        var unique_edges: u8 = 0;
        for (tile.edges()) |edge| {
            const mult = edge_mult.get(normalize(edge)) orelse unreachable;
            if (mult == 1) unique_edges += 1;
        }
        if (unique_edges == 2) {
            potential_corners += 1;
            product *= tile.id;
        }
    }
    assert(potential_corners == 4);

    try std.io.getStdOut().writer().print("{}\n", .{product});
}

const Tile = struct {
    const Id = u64;

    id: Id,
    pixels: [10][10]bool,

    fn edges(self: Tile) [4]u10 {
        return [4]u10{
            top: {
                var edge: u10 = 0;
                for (self.pixels[0]) |bit| edge = edge << 1 | @boolToInt(bit);
                break :top edge;
            },
            bot: {
                var edge: u10 = 0;
                for (self.pixels[9]) |bit| edge = edge << 1 | @boolToInt(bit);
                break :bot edge;
            },
            left: {
                var edge: u10 = 0;
                for (self.pixels) |row| edge = edge << 1 | @boolToInt(row[0]);
                break :left edge;
            },
            right: {
                var edge: u10 = 0;
                for (self.pixels) |row| edge = edge << 1 | @boolToInt(row[9]);
                break :right edge;
            },
        };
    }
};

fn normalize(edge: u10) u32 {
    const reverse = @bitReverse(u10, edge);
    return @as(u32, if (edge < reverse) edge else reverse);
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

    fn parseNumber(self: *Self, comptime T: type) Fail!T {
        const start = self.index;
        errdefer self.index = start;

        var result: T = 0;
        while (self.index < input.len) : (self.index += 1) {
            const char = input[self.index];
            if ('0' <= char and char <= '9') {
                if (@mulWithOverflow(T, result, 10, &result)) return error.ParseFail;
                if (@addWithOverflow(T, result, char - '0', &result)) return error.ParseFail;
            } else break;
        }
        if (start == self.index) return error.ParseFail;
        return result;
    }

    fn parseTile(self: *Self) Fail!Tile {
        var tile = Tile{ .id = undefined, .pixels = undefined };

        try self.parseLiteral("Tile ");
        tile.id = try self.parseNumber(Tile.Id);
        try self.parseLiteral(":\n");

        for (tile.pixels) |*row| {
            for (row) |*pixel| {
                pixel.* = if (self.parseLiteral("#"))
                    true
                else |_| if (self.parseLiteral("."))
                    false
                else |_|
                    return error.ParseFail;
            }
            try self.parseLiteral("\n");
        }
        try self.parseLiteral("\n");

        return tile;
    }
};
