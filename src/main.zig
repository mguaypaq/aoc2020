const std = @import("std");
const assert = std.debug.assert;

const input = "974618352"; // Manually translated to "cycle".
var cycle = [10]usize{ undefined, 8, 9, 5, 6, 2, 1, 4, 3, 7 };

fn prev(cup: usize) usize {
    return if (cup == 1) 9 else (cup - 1);
}

const writer = std.io.getStdOut().writer();

fn print() !void {
    var current: usize = 1;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        current = cycle[current];
        try writer.print("{d}", .{current});
    } else {
        try writer.print("\n", .{});
    }
}

pub fn main() !void {
    var current: usize = 9; // From the input.
    var i: usize = 0;
    while (i < 100) : (i += 1) {
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

    try print();
}
