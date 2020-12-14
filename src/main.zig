const std = @import("std");
const ArrayList = std.ArrayList;

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn abs(x: i32) i32 {
    return if (x < 0) -x else x;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var text = ArrayList(u8).init(&arena.allocator);
    defer text.deinit();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    // Start at the origin.
    var x: i32 = 0;
    var y: i32 = 0;

    // Facing east.
    var dx: i32 = 1;
    var dy: i32 = 0;

    var tokens = std.mem.tokenize(text.items, "\n");
    while (tokens.next()) |token| {
        const action = token[0];
        const value = try std.fmt.parseUnsigned(i32, token[1..], 10);
        switch (action) {
            'N' => y += value,
            'S' => y -= value,
            'E' => x += value,
            'W' => x -= value,
            'L', 'R' => {
                if (eql(token, "L90") or eql(token, "R270")) {
                    const new_dx = -dy;
                    dy = dx;
                    dx = new_dx;
                } else if (eql(token, "L180") or eql(token, "R180")) {
                    dx = -dx;
                    dy = -dy;
                } else if (eql(token, "L270") or eql(token, "R90")) {
                    const new_dx = dy;
                    dy = -dx;
                    dx = new_dx;
                } else return error.UnsupportedAngle;
            },
            'F' => {
                x += dx * value;
                y += dy * value;
            },
            else => return error.InvalidCharacter,
        }
    }

    try std.io.getStdOut().writer().print("{}\n", .{abs(x) + abs(y)});
}
