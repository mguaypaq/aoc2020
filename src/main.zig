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

    var order: u64 = modulus - 1;
    try writer.print("{} factors as 1", .{order});

    var factor: u64 = 2;
    while (factor * factor < order) {
        if (order % factor == 0) {
            order /= factor;
            try writer.print(" * {}", .{factor});
        } else {
            factor += 1;
        }
    } else {
        try writer.print(" * {}\n", .{order});
    }
}
