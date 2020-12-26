const std = @import("std");
const assert = std.debug.assert;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

const input = @embedFile("../input.txt");
const sea_monster = [3][20]u8{
    "                  # ",
    "#    ##    ##    ###",
    " #  #  #  #  #  #   ",
};

var tiles: [144]Tile = undefined;
var edges = [_][2]?usize{[_]?usize{null} ** 2} ** 1024;

//var image: [96][96]u8 = undefined;
var image: [120][120]u8 = undefined;

pub fn main() !void {
    try parseInput();
    assembleImage();

    for (image) |row| {
        for (row) |char| {
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }

    try std.io.getStdOut().writer().print("{}\n", .{null});
}

fn assembleImage() void {
    var vertical_edge: ?usize = null;
    var horizontal_edges = [_]?usize{null} ** 12;

    // Find top left corner.
    var index: usize = for (tiles) |tile, index| {
        var unique_edges: u8 = 0;
        for (tile.edges()) |edge| {
            if (uniqueEdge(edge)) unique_edges += 1;
        }
        if (unique_edges == 2) break index;
    } else unreachable;
    tiles[index].orient(vertical_edge, horizontal_edges[0]);
    vertical_edge = tiles[index].right();
    horizontal_edges[0] = tiles[index].bot();
    deregisterEdges(index);
    putTile(0, 0, tiles[index]);

    // fill first row
    var col: usize = 1;
    while (col < 12) : (col += 1) {
        index = edges[vertical_edge.?][0] orelse unreachable;
        tiles[index].orient(vertical_edge, horizontal_edges[col]);
        vertical_edge = tiles[index].right();
        horizontal_edges[col] = tiles[index].bot();
        deregisterEdges(index);
        putTile(0, col, tiles[index]);
    }

    // fill subsequent rows
    var row: usize = 1;
    while (row < 12) : (row += 1) {
        col = 0;
        vertical_edge = null;
        while (col < 12) : (col += 1) {
            index = edges[horizontal_edges[col].?][0] orelse unreachable;
            tiles[index].orient(vertical_edge, horizontal_edges[col]);
            vertical_edge = tiles[index].right();
            horizontal_edges[col] = tiles[index].bot();
            deregisterEdges(index);
            putTile(row, col, tiles[index]);
        }
    }
}

//fn putTile(row: usize, col: usize, tile: Tile) void {
//    var i: usize = 0;
//    while (i < 8) : (i += 1) {
//        var j: usize = 0;
//        while (j < 8) : (j += 1) {
//            image[8 * row + i][8 * col + j] = switch (tile.pixels[1 + i][1 + j]) {
//                true => '#',
//                false => '.',
//            };
//        }
//    }
//}
fn putTile(row: usize, col: usize, tile: Tile) void {
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        var j: usize = 0;
        while (j < 10) : (j += 1) {
            image[10 * row + i][10 * col + j] = switch (tile.pixels[i][j]) {
                true => '#',
                false => '.',
            };
        }
    }
}

fn uniqueEdge(edge: usize) bool {
    return edges[edge][1] == null;
}

const Tile = struct {
    const Id = u64;

    id: Id,
    pixels: [10][10]bool,

    fn top(self: Tile) usize {
        var edge: u10 = 0;
        for (self.pixels[0]) |bit| edge = edge << 1 | @boolToInt(bit);
        return normalize(edge);
    }

    fn bot(self: Tile) usize {
        var edge: u10 = 0;
        for (self.pixels[9]) |bit| edge = edge << 1 | @boolToInt(bit);
        return normalize(edge);
    }

    fn left(self: Tile) usize {
        var edge: u10 = 0;
        for (self.pixels) |row| edge = edge << 1 | @boolToInt(row[0]);
        return normalize(edge);
    }

    fn right(self: Tile) usize {
        var edge: u10 = 0;
        for (self.pixels) |row| edge = edge << 1 | @boolToInt(row[9]);
        return normalize(edge);
    }

    fn edges(self: Tile) [4]usize {
        return [4]usize{ self.top(), self.bot(), self.left(), self.right() };
    }

    fn normalize(edge: u10) usize {
        const reverse = @bitReverse(u10, edge);
        assert(edge != reverse);
        return @as(usize, if (edge < reverse) edge else reverse);
    }

    /// Flips top edge and bottom edge.
    fn flip(self: *Tile) void {
        var tmp: [10]bool = undefined;
        var i: usize = 0;
        while (i < 5) : (i += 1) {
            tmp = self.pixels[i];
            self.pixels[i] = self.pixels[9 - i];
            self.pixels[9 - i] = tmp;
        }
    }

    /// Flips top edge and left edge.
    fn flop(self: *Tile) void {
        var tmp: bool = undefined;
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            var j: usize = 0;
            while (j < 10) : (j += 1) {
                if (i < j) {
                    tmp = self.pixels[i][j];
                    self.pixels[i][j] = self.pixels[j][i];
                    self.pixels[j][i] = tmp;
                }
            }
        }
    }

    fn match(unique_or_edge: ?usize, edge: usize) bool {
        return if (unique_or_edge) |e|
            (edge == e)
        else
            uniqueEdge(edge);
    }

    /// Rotates and flips the tile to match top edge and left edge constraints.
    fn orient(self: *Tile, left_edge: ?usize, top_edge: ?usize) void {
        while (true) {
            if (match(left_edge, self.left()) and match(top_edge, self.top())) break;
            self.flip();
            if (match(left_edge, self.left()) and match(top_edge, self.top())) break;
            self.flop();
        }
    }
};

fn registerEdges(index: usize) void {
    const tile = tiles[index];
    for (tile.edges()) |edge| {
        for (edges[edge]) |*backref| {
            assert(backref.* != index);
            if (backref.* == null) {
                backref.* = index;
                break;
            }
        } else unreachable;
    }
}

fn deregisterEdges(index: usize) void {
    const tile = tiles[index];
    for (tile.edges()) |edge| {
        const pair = &edges[edge];
        if (pair[0] == index) pair[0] = pair[1];
        pair[1] = null;
    }
}

fn parseInput() !void {
    var input_parser = InputParser{};
    for (tiles) |*tile, index| {
        tile.* = try input_parser.parseTile();
        registerEdges(index);
    }
    assert(input_parser.done());
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
