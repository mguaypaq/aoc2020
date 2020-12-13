const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
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

    var even = try SeatingArea.init(allocator, text.items);
    defer even.deinit();
    var odd = try SeatingArea.init(allocator, text.items);
    defer odd.deinit();

    while (true) {
        even.updateInto(&odd);
        odd.updateInto(&even);
        if (std.mem.eql(u8, even.buf, odd.buf)) break;
    }

    var occupied: usize = 0;
    for (even.buf) |char| if (char == '#') {
        occupied += 1;
    };

    try std.io.getStdOut().writer().print("{}\n", .{ occupied });
}

test "a few rounds" {
    const round = [_]([]const u8){
        \\L.LL.LL.LL
        \\LLLLLLL.LL
        \\L.L.L..L..
        \\LLLL.LL.LL
        \\L.LL.LL.LL
        \\L.LLLLL.LL
        \\..L.L.....
        \\LLLLLLLLLL
        \\L.LLLLLL.L
        \\L.LLLLL.LL
        ,
        \\#.##.##.##
        \\#######.##
        \\#.#.#..#..
        \\####.##.##
        \\#.##.##.##
        \\#.#####.##
        \\..#.#.....
        \\##########
        \\#.######.#
        \\#.#####.##
        ,
        \\#.LL.LL.L#
        \\#LLLLLL.LL
        \\L.L.L..L..
        \\LLLL.LL.LL
        \\L.LL.LL.LL
        \\L.LLLLL.LL
        \\..L.L.....
        \\LLLLLLLLL#
        \\#.LLLLLL.L
        \\#.LLLLL.L#
    };
    var allocator = std.testing.allocator;
    var even = try SeatingArea.init(allocator, round[0]);
    defer even.deinit();
    var odd = try SeatingArea.init(allocator, round[0]);
    defer odd.deinit();

    even.updateInto(&odd);
    std.testing.expectEqualStrings(round[1], odd.buf);

    odd.updateInto(&even);
    std.testing.expectEqualStrings(round[2], even.buf);
}

const SeatingArea = struct {
    const Self = @This();

    allocator: *Allocator,
    buf: []u8,
    pos: [][]u8,

    fn init(allocator: *Allocator, buf: []const u8) !Self {
        var self = Self{
            .allocator = allocator,
            .buf = undefined,
            .pos = undefined,
        };

        self.buf = try allocator.alloc(u8, buf.len);
        errdefer allocator.free(self.buf);
        std.mem.copy(u8, self.buf, buf);

        var pos = ArrayList([]u8).init(allocator);
        defer pos.deinit();
        var index: usize = 0;
        while (true) {
            while (index < self.buf.len) : (index += 1) {
                if (self.buf[index] != '\n') break;
            } else break;
            const start = index;
            while (index < self.buf.len) : (index += 1) {
                switch (self.buf[index]) {
                    '.', 'L', '#' => continue,
                    '\n' => break,
                    else => return error.InvalidLayout,
                }
            }
            try pos.append(self.buf[start..index]);
        }
        self.pos = pos.toOwnedSlice();

        return self;
    }

    fn deinit(self: Self) void {
        self.allocator.free(self.pos);
        self.allocator.free(self.buf);
    }

    fn updateInto(self: Self, other: *Self) void {
        var row_index: isize = -1;
        for (self.pos) |row_data| {
            row_index += 1;
            var col_index: isize = -1;
            for (row_data) |char| {
                col_index += 1;
                other.pos[@intCast(usize, row_index)][@intCast(usize, col_index)] = switch (char) {
                    '.' => @as(u8, '.'),
                    'L' => if (self.occupiedNear(row_index, col_index) == 0) @as(u8, '#') else @as(u8, 'L'),
                    '#' => if (self.occupiedNear(row_index, col_index) >= 5) @as(u8, 'L') else @as(u8, '#'),
                    else => unreachable,
                };
            }
        }
    }

    fn occupiedNear(self: Self, row: isize, col: isize) u32 {
        const offsets = [3]isize{ -1, 0, 1 };
        var count: u32 = 0;
        for (offsets) |row_offset| for (offsets) |col_offset| {
            if (row_offset == 0 and col_offset == 0) continue;
            var r = row + row_offset;
            var c = col + col_offset;
            while (self.get(r, c)) |char| {
                switch (char) {
                    '.' => {},
                    'L' => break,
                    '#' => {
                        count += 1;
                        break;
                    },
                    else => unreachable,
                }
                r += row_offset;
                c += col_offset;
            }
        };
        return count;
    }

    fn get(self: Self, row: isize, col: isize) ?u8 {
        if (row < 0 or self.pos.len <= row) return null;
        const slice = self.pos[@intCast(usize, row)];
        if (col < 0 or slice.len <= col) return null;
        return slice[@intCast(usize, col)];
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        if (fmt.len != 0) @compileError("Unknown format character: '" ++ fmt ++ "'");
        try std.fmt.formatBuf(self.buf, options, writer);
    }
};
