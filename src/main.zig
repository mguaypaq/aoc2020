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

    var xmas = ArrayList(u64).init(allocator);
    defer xmas.deinit();
    var tokens = std.mem.tokenize(text.items, "\n");
    while (tokens.next()) |token| {
        const number = try std.fmt.parseUnsigned(u64, token, 10);
        try xmas.append(number);
    }

    try std.io.getStdOut().writer().print("{}\n", .{firstInvalid(xmas.items, 25)});
}

test "example" {
    const xmas = [_]u64{
        35,
        20,
        15,
        25,
        47,
        40,
        62,
        55,
        65,
        95,
        102,
        117,
        150,
        182,
        127,
        219,
        299,
        277,
        309,
        576,
    };
    std.testing.expectEqual(@as(?u64, 127), firstInvalid(&xmas, 5));
}

fn firstInvalid(xmas: []const u64, window_size: usize) ?u64 {
    for (xmas) |target, target_index| {
        if (target_index < window_size) continue;
        const window = xmas[(target_index - window_size)..target_index];
        search: for (window) |right, right_index| {
            for (window[0..right_index]) |left| {
                if (left + right == target) break :search;
            }
        } else return target;
    } else return null;
}
