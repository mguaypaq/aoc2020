const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

const base = 7;
const modulus = 20201227;
const public_keys = [_]u64{ 6930903, 19716708 };
const order = modulus - 1;
const factors = [_]u64{ 2, 3, 29, 116099 };

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    for (factors) |factor| {
        try writer.print("{}\n", .{pow(order / factor)});
    }
}

// Compute `base` ** `exponent` % `modulus`.
fn pow(exponent: u64) u64 {
    var result: u64 = 1;
    var cur_base: u64 = base;
    var cur_exp = exponent;
    while (cur_exp != 0) {
        if (cur_exp & 1 == 1)
            result = result * cur_base % modulus;
        cur_base = cur_base * cur_base % modulus;
        cur_exp >>= 1;
    }
    return result;
}
