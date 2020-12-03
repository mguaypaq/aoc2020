const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var text = std.ArrayList(u8).init(allocator);
    defer text.deinit();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    var product: u32 = 1;
    product *= tree_count(text.items, 1, 1);
    product *= tree_count(text.items, 3, 1);
    product *= tree_count(text.items, 5, 1);
    product *= tree_count(text.items, 7, 1);
    product *= tree_count(text.items, 1, 2);

    try std.io.getStdOut().writer().print("{}\n", .{product});
}

fn tree_count(buffer: []const (u8), right: u32, down: u32) u32 {
    var row: u32 = 0;
    var count: u32 = 0;
    var lines = std.mem.tokenize(buffer, "\n");
    while (lines.next()) |line| : (row += 1) {
        if (row % down != 0) continue;
        if (line[row / down * right % line.len] == '#') count += 1;
    }
    return count;
}
