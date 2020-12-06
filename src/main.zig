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

    const sum = try sumCounts(text.items);
    try std.io.getStdOut().writer().print("{}\n", .{sum});
}

fn sumCounts(buf: []const u8) error{BadFormat}!u32 {
    var sum: u32 = 0;
    var groups = std.mem.split(buf, "\n\n");
    while (groups.next()) |group| {
        var group_qs: u26 = ~@as(u26, 0);
        var persons = std.mem.tokenize(group, "\n");
        while (persons.next()) |person| {
            var person_qs: u26 = 0;
            for (person) |char| switch (char) {
                'a'...'z' => person_qs |= @as(u26, 1) << @intCast(u5, char - 'a'),
                else => return error.BadFormat,
            };
            group_qs &= person_qs;
        }
        sum += @popCount(u26, group_qs);
    }
    return sum;
}

test "sumCounts" {
    const expectEqual = std.testing.expectEqual;
    const text =
        \\abc
        \\
        \\a
        \\b
        \\c
        \\
        \\ab
        \\ac
        \\
        \\a
        \\a
        \\a
        \\a
        \\
        \\b
    ;

    expectEqual(@as(u32, 6), try sumCounts(text));
}
