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

    try std.io.getStdOut().writer().print("{}\n", .{encryptionWeakness(xmas.items, 36845998)});
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
    std.testing.expectEqual(@as(u64, 62), encryptionWeakness(&xmas, 127));
}

fn encryptionWeakness(xmas: []const u64, target: u64) u64 {
    var left: usize = 0;
    var right: usize = 1;
    var sum: u64 = xmas[0] + xmas[1];
    while (sum != target) if (sum < target) {
        right += 1;
        sum += xmas[right];
    } else {
        sum -= xmas[left];
        left += 1;
        std.debug.assert(left < right);
    };

    var min = xmas[right];
    for (xmas[left..right]) |val| {
        if (min > val) min = val;
    }

    var max = xmas[right];
    for (xmas[left..right]) |val| {
        if (max < val) max = val;
    }

    return min + max;
}
