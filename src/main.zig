const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const input = [_][]const u8{
    "#......#",
    "##.#..#.",
    "#.#.###.",
    ".##.....",
    ".##.#...",
    "##.#....",
    "#####.#.",
    "##.#.###",
};

const Pocket = [20][20][13][13]bool;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var pockets = try allocator.alloc(Pocket, 2);
    defer allocator.free(pockets);

    var even: *Pocket = &pockets[0];
    var odd: *Pocket = &pockets[1];

    for (even) |*volume| {
        for (volume) |*plane| {
            for (plane) |*line| {
                for (line) |*point| {
                    point.* = false;
                }
            }
        }
    }
    for (input) |row, x| {
        for (row) |char, y| {
            even[6 + x][6 + y][6][6] = (char == '#');
        }
    }

    step(even, odd);
    step(odd, even);
    step(even, odd);
    step(odd, even);
    step(even, odd);
    step(odd, even);

    var count: usize = 0;
    for (even) |volume| for (volume) |plane| for (plane) |line| for (line) |active| {
        if (active) count += 1;
    };

    try std.io.getStdOut().writer().print("{}\n", .{count});
}

fn step(prev: *const Pocket, next: *Pocket) void {
    for (prev) |volume, x| {
        for (volume) |plane, y| {
            for (plane) |line, z| {
                for (line) |active, w| {
                    const count = neighbours(prev, x, y, z, w);
                    next[x][y][z][w] = (count == 3) or (active and (count == 4));
                }
            }
        }
    }
}

fn neighbours(pocket: *const Pocket, x: usize, y: usize, z: usize, w: usize) usize {
    const xs = switch (x) {
        0 => &[2]usize{ 0, 1 },
        19 => &[2]usize{ 18, 19 },
        else => &[3]usize{ x - 1, x, x + 1 },
    };
    const ys = switch (y) {
        0 => &[2]usize{ 0, 1 },
        19 => &[2]usize{ 18, 19 },
        else => &[3]usize{ y - 1, y, y + 1 },
    };
    const zs = switch (z) {
        0 => &[2]usize{ 0, 1 },
        12 => &[2]usize{ 11, 12 },
        else => &[3]usize{ z - 1, z, z + 1 },
    };
    const ws = switch (w) {
        0 => &[2]usize{ 0, 1 },
        12 => &[2]usize{ 11, 12 },
        else => &[3]usize{ w - 1, w, w + 1 },
    };
    var count: usize = 0;
    for (xs) |xx| for (ys) |yy| for (zs) |zz| for (ws) |ww| {
        if (pocket[xx][yy][zz][ww]) count += 1;
    };
    return count;
}
