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

    var row: u32 = 0;
    var tree_count: u32 = 0;
    var lines = std.mem.tokenize(text.items, "\n");
    while (lines.next()) |line| : (row += 1) {
        if (line[3 * row % line.len] == '#') tree_count += 1;
    }
    try std.io.getStdOut().writer().print("{}\n", .{tree_count});
}
