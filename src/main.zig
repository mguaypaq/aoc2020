const std = @import("std");
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
    var code = ArrayList(Instruction).init(allocator);
    defer code.deinit();

    try parse(&code, text.items);
    const acc = try run(code.items);

    try std.io.getStdOut().writer().print("{}\n", .{acc});
}

test "example" {
    const text =
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\jmp -4
        \\acc +6
        \\
    ;
    var code = ArrayList(Instruction).init(std.testing.allocator);
    defer code.deinit();
    try parse(&code, text);
    const acc = try run(code.items);
    std.testing.expectEqual(@as(i32, 5), acc);
}

const Instruction = struct { op: Operation, arg: i32, seen: bool = false };
const Operation = enum { acc, jmp, nop };

fn run(code: []Instruction) !i32 {
    var pc: usize = 0;
    var acc: i32 = 0;
    while (!code[pc].seen) {
        code[pc].seen = true;
        switch (code[pc].op) {
            .acc => {
                acc += code[pc].arg;
                pc += 1;
            },
            .jmp => {
                pc = @intCast(usize, @intCast(i32, pc) + code[pc].arg);
            },
            .nop => {
                pc += 1;
            },
        }
    }
    return acc;
}

fn parse(output: *ArrayList(Instruction), input: []const u8) !void {
    var parser = Parser{ .buf = input };
    try parser.parseCode(output);
}

const Parser = struct {
    buf: []const u8,
    idx: usize = 0,

    const Self = @This();
    const Fail = error{ParseFail};

    /// A fixed string literal.
    fn parseLiteral(self: *Self, literal: []const u8) Fail!void {
        const start = self.idx;
        errdefer self.idx = start;

        if (self.buf.len < self.idx + literal.len) return error.ParseFail;
        for (literal) |char| {
            if (char != self.buf[self.idx]) return error.ParseFail;
            self.idx += 1;
        }
    }

    /// A string of decimal digits.
    fn parseNumber(self: *Self, comptime T: type) Fail!T {
        const start = self.idx;
        errdefer self.idx = start;

        var number: T = 0;
        while (self.idx < self.buf.len) : (self.idx += 1) {
            const char = self.buf[self.idx];
            if ('0' <= char and char <= '9') {
                if (@mulWithOverflow(T, number, 10, &number)) return error.ParseFail;
                if (@addWithOverflow(T, number, char - '0', &number)) return error.ParseFail;
            } else break;
        }
        if (start == self.idx) return error.ParseFail;
        return number;
    }

    /// An instruction line.
    fn parseLine(self: *Self) Fail!Instruction {
        const start = self.idx;
        errdefer self.idx = start;

        const op = if (self.parseLiteral("acc"))
            Operation.acc
        else |_| if (self.parseLiteral("jmp"))
            Operation.jmp
        else |_| if (self.parseLiteral("nop"))
            Operation.nop
        else |_|
            return error.ParseFail;

        try self.parseLiteral(" ");
        const positive = if (self.parseLiteral("+"))
            true
        else |_| if (self.parseLiteral("-"))
            false
        else |_|
            return error.ParseFail;

        const number = try self.parseNumber(i32);
        try self.parseLiteral("\n");

        return Instruction{ .op = op, .arg = if (positive) number else -number };
    }

    /// The whole buffer of code.
    fn parseCode(self: *Self, array_list: *ArrayList(Instruction)) !void {
        const initial_len = array_list.items.len;
        errdefer array_list.resize(initial_len) catch unreachable;

        self.idx = 0;
        while (self.idx < self.buf.len) {
            try array_list.append(try self.parseLine());
        }
    }
};
