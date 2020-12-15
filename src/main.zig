const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var text = ArrayList(u8).init(allocator);
    defer text.deinit();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    var memory = AutoHashMap(u64, u64).init(allocator);
    defer memory.deinit();

    var or_mask: u36 = 0;
    var float_mask: u36 = 0;

    var lines = mem.tokenize(text.items, "\n");
    while (lines.next()) |line| {
        if (mem.startsWith(u8, line, "mask = ")) {
            assert(line.len == 7 + 36);
            or_mask = 0;
            float_mask = 0;
            for (line[7..]) |char| {
                or_mask <<= 1;
                float_mask <<= 1;
                switch (char) {
                    '0' => {},
                    '1' => or_mask ^= 1,
                    'X' => float_mask ^= 1,
                    else => unreachable,
                }
            }
        } else if (mem.startsWith(u8, line, "mem[")) {
            const index = mem.indexOfPos(u8, line, 4, "] = ").?;
            var address = try fmt.parseUnsigned(u36, line[4..index], 10);
            const value = try fmt.parseUnsigned(u36, line[(index + 4)..], 10);

            address |= or_mask;
            address &= ~float_mask;
            var float = float_mask;
            while (true) {
                try memory.put(address | float, value);
                if (float == 0) break;
                float = (float - 1) & float_mask;
            }
        } else unreachable;
    }

    var sum: u64 = 0;
    var entries = memory.iterator();
    while (entries.next()) |entry| {
        sum += entry.value;
    }

    try std.io.getStdOut().writer().print("{}\n", .{sum});
}
