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

    var singles: usize = 0;
    var triples: usize = 1;
    var input_joltage: u8 = 0;
    for (adapters.items) |output_joltage| {
        switch (output_joltage - input_joltage) {
            1 => singles += 1,
            2 => {},
            3 => triples += 1,
            else => return error.WrongJoltage,
        }
        input_joltage = output_joltage;
    }

    try std.io.getStdOut().writer().print("{}\n", .{singles * triples});
}
