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

    var boarding_passes = std.mem.tokenize(text.items, "\n");
    var highest_seat_id: ?u16 = null;
    while (boarding_passes.next()) |boarding_pass| {
        const seat_id = try readSeatId(boarding_pass);
        highest_seat_id = max(highest_seat_id, seat_id);
    }

    try std.io.getStdOut().writer().print("{}\n", .{highest_seat_id});
}

fn max(maybe_a: ?u16, b: u16) ?u16 {
    if (maybe_a) |a| if (a > b) return a;
    return b;
}

fn readSeatId(buf: []const u8) error{BadSeatId}!u16 {
    if (buf.len != 7 + 3) return error.BadSeatId;
    var seat_id: u16 = 0;
    for (buf[0..7]) |char| switch (char) {
        'F' => seat_id = (seat_id << 1 | 0),
        'B' => seat_id = (seat_id << 1 | 1),
        else => return error.BadSeatId,
    };
    for (buf[7..]) |char| switch (char) {
        'L' => seat_id = (seat_id << 1 | 0),
        'R' => seat_id = (seat_id << 1 | 1),
        else => return error.BadSeatId,
    };
    return seat_id;
}

test "readSeatId" {
    const expectEqual = std.testing.expectEqual;

    expectEqual(@as(u16, 357), try readSeatId("FBFBBFFRLR"));
    expectEqual(@as(u16, 567), try readSeatId("BFFFBBFRRR"));
    expectEqual(@as(u16, 119), try readSeatId("FFFBBBFRRR"));
    expectEqual(@as(u16, 820), try readSeatId("BBFFBBFRLL"));
}
