const std = @import("std");
const ArrayList = std.ArrayList;

const input = [_]usize{ 14, 1, 17, 0, 3, 20 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var spoken = ArrayList(usize).init(&arena.allocator);
    defer spoken.deinit();

    for (input) |number| try spoken.append(number);
    while (spoken.items.len < 2020) {
        var index = spoken.items.len - 1;
        const last = spoken.items[index];
        try spoken.append(while (index > 0) {
            index -= 1;
            if (spoken.items[index] == last) break (spoken.items.len - 1 - index);
        } else 0);
    }

    try std.io.getStdOut().writer().print("{}\n", .{spoken.items[2020 - 1]});
}
