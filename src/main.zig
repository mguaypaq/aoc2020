const std = @import("std");

const required_fields = init: {
    var fields = [_][]const u8{"byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid"};
    for (fields) |prefix, index| fields[index] = prefix ++ ":";
    break :init fields;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var text = std.ArrayList(u8).init(allocator);
    defer text.deinit();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    var passports = std.mem.split(text.items, "\n\n");
    var valid_count: u32 = 0;
    while (passports.next()) |passport| {
        var kv_pairs = std.mem.tokenize(passport, " \n");
        var seen = [_]bool{false} ** required_fields.len;
        while (kv_pairs.next()) |kv_pair| {
            inline for (required_fields) |prefix, index| {
                if (std.mem.startsWith(u8, kv_pair, prefix)) {
                    seen[index] = true;
                }
            }
        }
        if (std.mem.allEqual(bool, &seen, true)) valid_count += 1;
    }

    try std.io.getStdOut().writer().print("{}\n", .{valid_count});
}
