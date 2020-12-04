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

    var passports = std.mem.split(text.items, "\n\n");
    var valid_count: u32 = 0;
    while (passports.next()) |passport| {
        var kv_pairs = std.mem.tokenize(passport, " \n");
        var seen = [_]bool{false} ** required_fields.len;
        while (kv_pairs.next()) |kv_pair| {
            inline for (required_fields) |field, index| {
                const prefix = field.name ++ ":";
                if (std.mem.startsWith(u8, kv_pair, prefix)) {
                    const value = kv_pair[(prefix.len)..];
                    if (field.validate(value)) seen[index] = true;
                }
            }
        }
        if (std.mem.allEqual(bool, &seen, true)) valid_count += 1;
    }

    try std.io.getStdOut().writer().print("{}\n", .{valid_count});
}

const RequiredField = struct {
    name: []const u8,
    validate: fn (value: []const u8) bool,
};

const required_fields = [_]RequiredField{
    .{ .name = "byr", .validate = byrValidate },
    .{ .name = "iyr", .validate = iyrValidate },
    .{ .name = "eyr", .validate = eyrValidate },
    .{ .name = "hgt", .validate = hgtValidate },
    .{ .name = "hcl", .validate = hclValidate },
    .{ .name = "ecl", .validate = eclValidate },
    .{ .name = "pid", .validate = pidValidate },
};

fn byrValidate(buf: []const u8) bool {
    if (buf.len != 4) return false;
    const num = std.fmt.parseUnsigned(u32, buf, 10) catch return false;
    return (1920 <= num and num <= 2002);
}

fn iyrValidate(buf: []const u8) bool {
    if (buf.len != 4) return false;
    const num = std.fmt.parseUnsigned(u32, buf, 10) catch return false;
    return (2010 <= num and num <= 2020);
}

fn eyrValidate(buf: []const u8) bool {
    if (buf.len != 4) return false;
    const num = std.fmt.parseUnsigned(u32, buf, 10) catch return false;
    return (2020 <= num and num <= 2030);
}

fn hgtValidate(buf: []const u8) bool {
    if (std.mem.endsWith(u8, buf, "cm")) {
        const num = std.fmt.parseUnsigned(u32, buf[0..(buf.len - 2)], 10) catch return false;
        return (150 <= num and num <= 193);
    } else if (std.mem.endsWith(u8, buf, "in")) {
        const num = std.fmt.parseUnsigned(u32, buf[0..(buf.len - 2)], 10) catch return false;
        return (59 <= num and num <= 76);
    } else return false;
}

fn hclValidate(buf: []const u8) bool {
    if (buf.len != 7) return false;
    if (buf[0] != '#') return false;
    for (buf[1..]) |char| switch (char) {
        '0'...'9' => continue,
        'a'...'f' => continue,
        else => return false,
    }
    else return true;
}

fn eclValidate(buf: []const u8) bool {
    const colors = [_][]const u8{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };
    for (colors) |color| if (std.mem.eql(u8, buf, color)) return true;
    return false;
}

fn pidValidate(buf: []const u8) bool {
    if (buf.len != 9) return false;
    for (buf) |char| if (char < '0' or '9' < char) return false;
    return true;
}
