const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

const generator = 7;
const modulus = 20201227;
const public_keys = [_]u64{ 6930903, 19716708 };

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var private: u64 = 0;
    var public: u64 = 1;
    while (public != public_keys[0]) {
        private += 1;
        public = public * generator % modulus;
    }
    try writer.print("{}\n", .{pow(public_keys[1], private)});
}

// Compute `base` ** `exponent` % `modulus`.
fn pow(base: u64, exponent: u64) u64 {
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
