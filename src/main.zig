const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var text = std.ArrayList(u8).init(std.heap.page_allocator);
    defer text.deinit();
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    var lines = std.mem.tokenize(text.items, "\n");
    var stack = std.ArrayList(Thunk).init(std.heap.page_allocator);
    defer stack.deinit();
    var sum: Num = 0;
    while (lines.next()) |line| {
        sum += try eval(&stack, line);
    }

    try std.io.getStdOut().writer().print("{}\n", .{sum});
}

fn eval(stack: *std.ArrayList(Thunk), buf: []const u8) !Num {
    assert(stack.items.len == 0);
    var expecting: enum { Num, Op } = .Num;
    var mul: Num = 1;
    var add: Num = 0;
    for (buf) |char| switch (expecting) {
        .Num => switch (char) {
            '0'...'9' => {
                const num: Num = char - '0';
                add += num;
                expecting = .Op;
            },
            '(' => {
                try stack.append(.{ .mul = mul, .add = add });
                mul = 1;
                add = 0;
                expecting = .Num;
            },
            ' ' => {},
            else => return error.InvalidCharacter,
        },
        .Op => switch (char) {
            '+' => {
                expecting = .Num;
            },
            '*' => {
                mul *= add;
                add = 0;
                expecting = .Num;
            },
            ')' => {
                const thunk = stack.popOrNull() orelse return error.StackUnderflow;
                add = thunk.add + (mul * add);
                mul = thunk.mul;
                expecting = .Op;
            },
            ' ' => {},
            else => return error.InvalidCharacter,
        },
    };
    if (expecting != .Op) return error.IncompleteExpression;
    if (stack.items.len != 0) return error.IncompleteExpression;
    return (mul * add);
}

const Num = u64;

// A Thunk represents the computation "mul * (add + _)".
const Thunk = struct { mul: Num, add: Num };
