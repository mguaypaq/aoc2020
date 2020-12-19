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
    var lhs: Num = 0;
    var op: Op = add;
    for (buf) |char| switch (expecting) {
        .Num => switch (char) {
            '0'...'9' => {
                const rhs = char - '0';
                lhs = op(lhs, rhs);
                expecting = .Op;
            },
            '(' => {
                try stack.append(.{ .lhs = lhs, .op = op });
                lhs = 0;
                op = add;
                expecting = .Num;
            },
            ' ' => {},
            else => return error.InvalidCharacter,
        },
        .Op => switch (char) {
            '+' => {
                op = add;
                expecting = .Num;
            },
            '*' => {
                op = mul;
                expecting = .Num;
            },
            ')' => {
                const thunk = stack.popOrNull() orelse return error.StackUnderflow;
                lhs = thunk.op(thunk.lhs, lhs);
                expecting = .Op;
            },
            ' ' => {},
            else => return error.InvalidCharacter,
        },
    };
    if (expecting != .Op) return error.IncompleteExpression;
    if (stack.items.len != 0) return error.IncompleteExpression;
    return lhs;
}

const Num = u64;
const Op = fn (lhs: Num, rhs: Num) Num;
const Thunk = struct { lhs: Num, op: Op };

fn add(lhs: Num, rhs: Num) Num {
    return lhs + rhs;
}
fn mul(lhs: Num, rhs: Num) Num {
    return lhs * rhs;
}
