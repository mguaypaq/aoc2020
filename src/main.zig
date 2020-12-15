const std = @import("std");

const input = [_]usize{ 14, 1, 17, 0, 3, 20 };
const target: usize = 30_000_000;

pub fn main() !void {
    var last_spoken = try std.heap.page_allocator.alloc(?usize, target);
    defer std.heap.page_allocator.free(last_spoken);
    std.mem.set(?usize, last_spoken, null);

    var time: usize = 0;
    while (time < input.len - 1) : (time += 1) {
        last_spoken[input[time]] = time;
    }
    var next_number = input[time];
    while (time < target - 1) {
        if (last_spoken[next_number]) |last_time| {
            last_spoken[next_number] = time;
            next_number = time - last_time;
            time += 1;
        } else {
            last_spoken[next_number] = time;
            next_number = 0;
            time += 1;
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{next_number});
}
