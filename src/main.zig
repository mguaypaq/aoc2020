const std = @import("std");
const ArrayList = std.ArrayList;

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn abs(x: i32) i32 {
    return if (x < 0) -x else x;
}

const Vec = struct { x: i32, y: i32 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var text = ArrayList(u8).init(&arena.allocator);
    defer text.deinit();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    var ship = Vec{ .x = 0, .y = 0 };
    var waypoint = Vec{ .x = 10, .y = 1 };

    var tokens = std.mem.tokenize(text.items, "\n");
    while (tokens.next()) |token| {
        const action = token[0];
        const value = try std.fmt.parseUnsigned(i32, token[1..], 10);
        switch (action) {
            'N' => waypoint.y += value,
            'S' => waypoint.y -= value,
            'E' => waypoint.x += value,
            'W' => waypoint.x -= value,
            'L', 'R' => {
                const new_waypoint = if (eql(token, "L90") or eql(token, "R270"))
                    Vec{
                        .x = -waypoint.y,
                        .y = waypoint.x,
                    }
                else if (eql(token, "L180") or eql(token, "R180"))
                    Vec{
                        .x = -waypoint.x,
                        .y = -waypoint.y,
                    }
                else if (eql(token, "L270") or eql(token, "R90"))
                    Vec{
                        .x = waypoint.y,
                        .y = -waypoint.x,
                    }
                else
                    return error.UnsupportedAngle;
                waypoint = new_waypoint;
            },
            'F' => {
                ship.x += waypoint.x * value;
                ship.y += waypoint.y * value;
            },
            else => return error.InvalidCharacter,
        }
    }

    try std.io.getStdOut().writer().print("{}\n", .{abs(ship.x) + abs(ship.y)});
}
