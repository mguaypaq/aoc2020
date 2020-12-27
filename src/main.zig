const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const global_allocator = &gpa.allocator;

const Card = u8;
const Deck = []const Card;
const Decks = [2]Deck;
const History = ArrayList(Decks);
const Player = u1;
const Result = struct { winner: Player, deck: Deck };

fn game(initial_decks: Decks) mem.Allocator.Error!Result {
    var arena = std.heap.ArenaAllocator.init(global_allocator);
    defer arena.deinit();
    const local_allocator = &arena.allocator;

    var history = History.init(local_allocator);
    var decks = initial_decks;
    while (true) {
        // Check for empty decks
        for (decks) |deck, player| {
            if (deck.len == 0) {
                const winner: Player = @intCast(u1, 1 - player);
                const winning_deck = try global_allocator.alloc(Card, decks[winner].len);
                mem.copy(Card, winning_deck, decks[winner]);
                return Result{
                    .winner = winner,
                    .deck = winning_deck,
                };
            }
        }

        // Check for repeats
        for (history.items) |old_decks| {
            if (!mem.eql(Card, old_decks[0], decks[0])) continue;
            if (!mem.eql(Card, old_decks[1], decks[1])) continue;
            const deck = try global_allocator.alloc(Card, decks[0].len);
            mem.copy(Card, deck, decks[0]);
            return Result{
                .winner = 0,
                .deck = deck,
            };
        }
        try history.append(decks);

        const draws = [2]Card{ decks[0][0], decks[1][0] };
        const round_winner: Player = if (draws[0] < decks[0].len and
            draws[1] < decks[1].len)
        round_winner: {
            // Recursive game
            const result = try game(Decks{
                decks[0][1..(1 + draws[0])],
                decks[1][1..(1 + draws[1])],
            });
            global_allocator.free(result.deck);
            break :round_winner result.winner;
        } else if (draws[0] > draws[1])
            @as(Player, 0)
        else if (draws[0] < draws[1])
            @as(Player, 1)
        else
            unreachable;
        const round_loser: Player = 1 - round_winner;

        var new_decks: [2][]Card = undefined;

        new_decks[round_winner] = try local_allocator.alloc(Card, decks[round_winner].len + 1);
        mem.copy(Card, new_decks[round_winner], decks[round_winner][1..]);
        new_decks[round_winner][decks[round_winner].len - 1] = draws[round_winner];
        new_decks[round_winner][decks[round_winner].len] = draws[round_loser];

        new_decks[round_loser] = try local_allocator.alloc(Card, decks[round_loser].len - 1);
        mem.copy(Card, new_decks[round_loser], decks[round_loser][1..]);

        decks = new_decks;
    }
}

pub fn main() !void {
    const result = try game(input);
    defer global_allocator.free(result.deck);

    var score: usize = 0;
    for (result.deck) |card, index| {
        score += card * (result.deck.len - index);
    }

    try std.io.getStdOut().writer().print("{}\n", .{score});
}

const input = Decks{
    &[_]Card{ 47, 19, 22, 31, 24, 6, 10, 5, 1, 48, 46, 27, 8, 45, 16, 28, 33, 41, 42, 36, 50, 39, 30, 11, 17 },
    &[_]Card{ 4, 18, 21, 37, 34, 15, 35, 38, 20, 23, 9, 25, 32, 13, 26, 2, 12, 44, 14, 49, 3, 40, 7, 43, 29 },
};
