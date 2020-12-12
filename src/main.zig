const std = @import("std");
const ArrayList = std.ArrayList;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var text = ArrayList(u8).init(allocator);
    defer text.deinit();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    var adapters = ArrayList(u8).init(allocator);
    defer adapters.deinit();
    var tokens = std.mem.tokenize(text.items, "\n");
    while (tokens.next()) |token| {
        const number = try std.fmt.parseUnsigned(u8, token, 10);
        try adapters.append(number);
    }

    std.sort.sort(u8, adapters.items, {}, struct {
        fn lessThan(context: void, lhs: u8, rhs: u8) bool {
            return lhs < rhs;
        }
    }.lessThan);

    var ways = [_]u64{0} ** 256;
    ways[0] = 1;
    for (adapters.items) |joltage| {
        if (joltage >= 3) ways[joltage] += ways[joltage - 3];
        if (joltage >= 2) ways[joltage] += ways[joltage - 2];
        if (joltage >= 1) ways[joltage] += ways[joltage - 1];
    }
    const max_joltage = adapters.items[adapters.items.len - 1];

    try std.io.getStdOut().writer().print("{}\n", .{ways[max_joltage]});
}
