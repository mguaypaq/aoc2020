const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var text = ArrayList(u8).init(allocator);
    defer text.deinit();
    try file.reader().readAllArrayList(&text, 1024 * 1024);

    var parser = Parser.init(allocator, text.items);
    defer parser.deinit();

    const rules = try parser.parseRules();
    const shiny_count = try processRules(allocator, rules);
    try std.io.getStdOut().writer().print("{}\n", .{shiny_count});
}

test "example 1" {
    const allocator = std.testing.allocator;
    const text =
        \\light red bags contain 1 bright white bag, 2 muted yellow bags.
        \\dark orange bags contain 3 bright white bags, 4 muted yellow bags.
        \\bright white bags contain 1 shiny gold bag.
        \\muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
        \\shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
        \\dark olive bags contain 3 faded blue bags, 4 dotted black bags.
        \\vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
        \\faded blue bags contain no other bags.
        \\dotted black bags contain no other bags.
        \\
    ;

    var parser = Parser.init(allocator, text);
    defer parser.deinit();

    const rules = try parser.parseRules();
    const shiny_count = try processRules(allocator, rules);
    std.testing.expectEqual(@as(?u64, 32), shiny_count);
}

test "example 2" {
    const allocator = std.testing.allocator;
    const text =
        \\shiny gold bags contain 2 dark red bags.
        \\dark red bags contain 2 dark orange bags.
        \\dark orange bags contain 2 dark yellow bags.
        \\dark yellow bags contain 2 dark green bags.
        \\dark green bags contain 2 dark blue bags.
        \\dark blue bags contain 2 dark violet bags.
        \\dark violet bags contain no other bags.
        \\
    ;

    var parser = Parser.init(allocator, text);
    defer parser.deinit();

    const rules = try parser.parseRules();
    const shiny_count = try processRules(allocator, rules);
    std.testing.expectEqual(@as(?u64, 126), shiny_count);
}

fn processRules(allocator: *Allocator, rules: []Rule) !?u64 {
    var dict = std.StringHashMap(*Rule).init(allocator);
    defer dict.deinit();
    {
        @setRuntimeSafety(true);
        try dict.ensureCapacity(@intCast(u32, rules.len));
    }
    for (rules) |*rule| {
        const existing = try dict.fetchPut(rule.head, rule);
        if (existing != null) return error.RuleCollision;
    }

    var stack = try ArrayList(*Rule).initCapacity(allocator, rules.len);
    defer stack.deinit();
    for (rules) |*rule| try stack.append(rule);

    while (stack.popOrNull()) |rule| switch (rule.status) {
        .BeforeVisit => {
            rule.status = .DuringVisit;
            try stack.append(rule);
            for (rule.tail.items) |tail_item| {
                const child = dict.get(tail_item.colour) orelse return error.MissingRule;
                if (child.status == .BeforeVisit) try stack.append(child);
            }
        },
        .DuringVisit => {
            var bag_count: u64 = 1;
            for (rule.tail.items) |tail_item| {
                const child = dict.get(tail_item.colour) orelse unreachable;
                switch (child.status) {
                    .BeforeVisit => unreachable,
                    .DuringVisit => {
                        rule.bag_count = null;
                        break;
                    },
                    .AfterVisit => {
                        if (child.bag_count) |n| {
                            bag_count += tail_item.count * n;
                        } else {
                            rule.bag_count = null;
                            break;
                        }
                    },
                }
            }
            rule.status = .AfterVisit;
            rule.bag_count = bag_count;
        },
        .AfterVisit => continue,
    };

    const shiny_rule = dict.get("shiny gold") orelse return error.MissingRule;
    return if (shiny_rule.bag_count) |bag_count| (bag_count - 1) else null;
}

/// The relevant information for a rule, including its graph traversal state.
const Rule = struct {
    head: []const u8,
    tail: ArrayList(TailItem),
    status: Status,
    bag_count: ?u64,

    const TailItem = struct {
        count: u64,
        colour: []const u8,
    };

    const Status = enum {
        BeforeVisit,
        DuringVisit,
        AfterVisit,
    };

    fn init(allocator: *Allocator, head: []const u8) Rule {
        return Rule{
            .head = head,
            .tail = ArrayList(TailItem).init(allocator),
            .status = .BeforeVisit,
            .bag_count = undefined,
        };
    }

    fn deinit(self: Rule) void {
        self.tail.deinit();
    }
};

const Parser = struct {
    const Self = @This();

    buf: []const u8,
    index: usize = 0,
    rules: ArrayList(Rule),
    allocator: *Allocator,

    const Fail = error{ParseFail};

    fn init(allocator: *Allocator, buf: []const u8) Self {
        const rules = ArrayList(Rule).init(allocator);
        return Self{
            .buf = buf,
            .rules = rules,
            .allocator = allocator,
        };
    }

    fn deinit(self: Self) void {
        for (self.rules.items) |rule| rule.deinit();
        self.rules.deinit();
    }

    /// A non-empty string of lowercase letters.
    /// Returns the slice containing the word.
    fn parseWord(self: *Self) Fail![]const u8 {
        const start = self.index;
        errdefer self.index = start;

        while (self.index < self.buf.len) : (self.index += 1) {
            switch (self.buf[self.index]) {
                'a'...'z' => continue,
                else => break,
            }
        }
        if (start == self.index) return error.ParseFail;
        return self.buf[start..self.index];
    }

    /// A fixed string literal.
    /// Succeeds if the literal is present at the current index.
    fn parseLiteral(self: *Self, literal: []const u8) Fail!void {
        const start = self.index;
        errdefer self.index = start;

        if (self.buf.len < self.index + literal.len) return error.ParseFail;
        for (literal) |char| {
            if (char != self.buf[self.index]) return error.ParseFail;
            self.index += 1;
        }
    }

    /// An adjective followed by a colour.
    /// Returns the slice containing both words.
    fn parseColour(self: *Self) Fail![]const u8 {
        const start = self.index;
        errdefer self.index = start;

        _ = try self.parseWord();
        try self.parseLiteral(" ");
        _ = try self.parseWord();

        return self.buf[start..self.index];
    }

    /// An unsigned decimal number.
    fn parseNumber(self: *Self, comptime T: type) Fail!T {
        const start = self.index;
        errdefer self.index = start;

        var value: T = 0;
        while (self.index < self.buf.len) : (self.index += 1) {
            const char = self.buf[self.index];
            if ('0' <= char and char <= '9') {
                if (@mulWithOverflow(T, value, 10, &value)) return error.ParseFail;
                if (@addWithOverflow(T, value, char - '0', &value)) return error.ParseFail;
            } else break;
        }
        if (start == self.index) return error.ParseFail;
        return value;
    }

    /// A string like "1 bright white bag" or "2 muted yellow bags".
    /// Returns a TailItem containing the count and the colour.
    fn parseContent(self: *Self) Fail!Rule.TailItem {
        const start = self.index;
        errdefer self.index = start;

        const count = try self.parseNumber(u64);
        try self.parseLiteral(" ");
        const colour = try self.parseColour();
        try self.parseLiteral(if (count == 1) " bag" else " bags");

        return Rule.TailItem{ .count = count, .colour = colour };
    }

    /// An entire line containing a valid rule.
    /// On success, caller owns the allocated Rule.
    fn parseRule(self: *Self) !Rule {
        const start = self.index;
        errdefer self.index = start;

        const head = try self.parseColour();

        var rule = Rule.init(self.allocator, head);
        errdefer rule.deinit();

        try self.parseLiteral(" bags contain ");
        self.parseLiteral("no other bags.\n") catch while (true) {
            const tail_item = try self.parseContent();
            try rule.tail.append(tail_item);
            self.parseLiteral(", ") catch {
                try self.parseLiteral(".\n");
                break;
            };
        };
        return rule;
    }

    /// Parse a sequence of lines containing valid rules.
    /// Fails if there are leftover characters.
    fn parseRules(self: *Self) ![]Rule {
        const start = self.index;
        errdefer self.index = start;

        while (self.index < self.buf.len) {
            const rule = try self.parseRule();
            try self.rules.append(rule);
        }
        return self.rules.items;
    }
};
