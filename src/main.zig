const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

const base = 7;
const modulus = 20201227;
const public_keys = .{ 6930903, 19716708 };

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    assert(modulus < 10_000 * 10_000);
    var factor: u64 = 2;
    while (factor < 10_000) : (factor += 1) {
        if (modulus % factor == 0) {
            try writer.print("{} is divisible by {}\n", .{modulus, factor});
            break;
        }
    } else {
        try writer.print("{} is prime\n", .{modulus});
    }
}
