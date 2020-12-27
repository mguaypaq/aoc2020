const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

pub fn main() !void {
    var hands = [2]Hand{ Hand{}, Hand{} };
    for (hands) |*hand, player|
        for (input[player]) |card|
            hand.append(card);

    var draws: [2]Card = undefined;
    while (!hands[0].empty() and !hands[1].empty()) {
        for (hands) |*hand, player|
            draws[player] = hand.draw();
        if (draws[0] < draws[1]) {
            hands[1].append(draws[1]);
            hands[1].append(draws[0]);
        } else if (draws[1] < draws[0]) {
            hands[0].append(draws[0]);
            hands[0].append(draws[1]);
        } else unreachable;
    }

    const winner = for (hands) |hand, player| {
        if (!hand.empty()) break player;
    } else unreachable;

    var score: u32 = 0;
    var value: u32 = deck_size;
    while (value > 0) : (value -= 1) {
        score += value * hands[winner].draw();
    }

    try std.io.getStdOut().writer().print("{}\n", .{score});
}

const input = [_][]const Card{
    &[_]Card{ 47, 19, 22, 31, 24, 6, 10, 5, 1, 48, 46, 27, 8, 45, 16, 28, 33, 41, 42, 36, 50, 39, 30, 11, 17 },
    &[_]Card{ 4, 18, 21, 37, 34, 15, 35, 38, 20, 23, 9, 25, 32, 13, 26, 2, 12, 44, 14, 49, 3, 40, 7, 43, 29 },
};

const deck_size = sum: {
    var size: usize = 0;
    for (input) |hand| size += hand.len;
    break :sum size;
};

const Card = u8;
const Hand = struct {
    buf: [deck_size + 1]Card = undefined,
    head: usize = 0,
    tail: usize = 0,

    fn empty(self: Hand) bool {
        return (self.head == self.tail);
    }

    fn append(self: *Hand, card: Card) void {
        self.buf[self.tail] = card;
        self.tail = (self.tail + 1) % self.buf.len;
        assert(!self.empty());
    }

    fn draw(self: *Hand) Card {
        assert(!self.empty());
        const card = self.buf[self.head];
        self.head = (self.head + 1) % self.buf.len;
        return card;
    }
};
