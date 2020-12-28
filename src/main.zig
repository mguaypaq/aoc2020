const std = @import("std");
const assert = std.debug.assert;

const input = "974618352"; // Manually translated to "cycle".

fn prev(cup: usize) usize {
    return if (cup == 1) 1_000_000 else (cup - 1);
}

const writer = std.io.getStdOut().writer();

pub fn main() !void {
    var cycle = try std.heap.page_allocator.alloc(usize, 1_000_001);
    cycle[9] = 7;
    cycle[7] = 4;
    cycle[4] = 6;
    cycle[6] = 1;
    cycle[1] = 8;
    cycle[8] = 3;
    cycle[3] = 5;
    cycle[5] = 2;
    cycle[2] = 10;
    var i: usize = 10;
    while (i < 1_000_000) : (i += 1) {
        cycle[i] = i + 1;
    }
    cycle[1_000_000] = 9;

    var current: usize = 9; // From the input.
    i = 0;
    while (i < 10_000_000) : (i += 1) {
        var destination = current;
        var third: usize = undefined;
        while (true) {
            destination = prev(destination);
            third = cycle[current];
            if (destination == third) continue;
            third = cycle[third];
            if (destination == third) continue;
            third = cycle[third];
            if (destination == third) continue;
            break;
        }

        cycle[0] = cycle[current];
        cycle[current] = cycle[third];
        cycle[third] = cycle[destination];
        cycle[destination] = cycle[0];

        current = cycle[current];
    }

    try std.io.getStdOut().writer().print("{}\n", .{cycle[1] * cycle[cycle[1]]});
}
