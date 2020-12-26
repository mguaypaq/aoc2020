const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;
const input = @embedFile("../input.txt");

pub fn main() !void {
    var input_parser = InputParser{};
    const rules = try input_parser.parseRules();
    var tree = try Tree.init(rules);

    var valid: usize = 0;
    while (!input_parser.done()) {
        const message = try input_parser.parseMessage();
        if (try tree.parse(message)) valid += 1;
    }

    try std.io.getStdOut().writer().print("{}\n", .{valid});
}

const Rule = struct {
    const Id = u8;
    const Concat = []const Id;
    const Choice = []const Concat;
    const Body = union(enum) {
        literal: u8,
        composite: Choice,
    };
    const Line = struct {
        label: Id,
        body: Body,
    };
};

const InputParser = struct {
    const Self = @This();
    const Fail = error{ParseFail};

    index: usize = 0,

    fn done(self: Self) bool {
        return self.index == input.len;
    }

    fn parseChar(self: *Self) Fail!u8 {
        if (self.index < input.len) {
            const char = input[self.index];
            self.index += 1;
            return char;
        } else return error.ParseFail;
    }

    fn parseLiteral(self: *Self, literal: []const u8) Fail!void {
        const start = self.index;
        errdefer self.index = start;

        if (input.len < self.index + literal.len) return error.ParseFail;
        for (literal) |char| {
            if (char != input[self.index]) return error.ParseFail;
            self.index += 1;
        }
    }

    fn parseNumber(self: *Self, comptime T: type) Fail!T {
        const start = self.index;
        errdefer self.index = start;

        var result: T = 0;
        while (self.index < input.len) : (self.index += 1) {
            const char = input[self.index];
            if ('0' <= char and char <= '9') {
                if (@mulWithOverflow(T, result, 10, &result)) return error.ParseFail;
                if (@addWithOverflow(T, result, char - '0', &result)) return error.ParseFail;
            } else break;
        }
        if (start == self.index) return error.ParseFail;
        return result;
    }

    fn parseRuleLine(self: *Self) !Rule.Line {
        const start = self.index;
        errdefer self.index = start;

        const label = try self.parseNumber(Rule.Id);
        try self.parseLiteral(":");

        if (self.parseLiteral(" \"")) {
            const char = try self.parseChar();
            try self.parseLiteral("\"\n");
            return Rule.Line{
                .label = label,
                .body = .{ .literal = char },
            };
        } else |_| {}

        var choice = ArrayList(Rule.Concat).init(allocator);
        defer choice.deinit();
        var concat = ArrayList(Rule.Id).init(allocator);
        defer concat.deinit();

        while (self.parseLiteral(" ")) {
            if (self.parseNumber(Rule.Id)) |id| {
                try concat.append(id);
            } else |_| {
                try self.parseLiteral("|");
                try choice.append(concat.toOwnedSlice());
            }
        } else |_| {
            try self.parseLiteral("\n");
            try choice.append(concat.toOwnedSlice());
        }

        return Rule.Line{
            .label = label,
            .body = .{ .composite = choice.toOwnedSlice() },
        };
    }

    const Rules = []const ?Rule.Body;
    fn parseRules(self: *Self) !Rules {
        const start = self.index;
        errdefer self.index = start;

        var rules = try allocator.alloc(?Rule.Body, 256);
        errdefer allocator.free(rules);
        std.mem.set(?Rule.Body, rules, null);

        while (self.parseRuleLine()) |rule| {
            if (rules[rule.label] != null) return error.ParseFail;
            rules[rule.label] = rule.body;
        } else |_| {
            try self.parseLiteral("\n");
        }

        return rules;
    }

    const Message = []const u8;
    fn parseMessage(self: *Self) Fail!Message {
        const start = self.index;
        errdefer self.index = start;

        while (self.index < input.len) : (self.index += 1) {
            switch (input[self.index]) {
                'a'...'b' => continue,
                '\n' => {
                    const message = input[start..self.index];
                    self.index += 1;
                    return message;
                },
                else => return error.ParseFail,
            }
        } else return error.ParseFail;
    }
};

const Tree = struct {
    const Tree = @This();

    root: *TreeNode,
    rules: InputParser.Rules,

    fn init(rules: InputParser.Rules) !Tree {
        const root = try allocator.create(TreeNode);
        root.rule_id = 0;
        return Tree{ .root = root, .rules = rules };
    }

    fn grow(self: Tree, node: *TreeNode) !void {
        if (node.rule_id) |rule_id| {
            node.rule_id = null;
            if (self.rules[rule_id]) |body| switch (body) {
                .literal => |char| {
                    node.actor = .{ .Literal = .{ .char = char } };
                },
                .composite => |choice| {
                    node.actor = .{ .Choice = .{ .end = choice.len } };
                    node.children = try allocator.alloc(TreeNode, choice.len);
                    for (node.children) |*child, child_id| {
                        const concat = choice[child_id];
                        child.parent = .{ .node = node, .child_id = child_id };
                        child.actor = .{ .Concat = .{ .end = concat.len } };
                        child.children = try allocator.alloc(TreeNode, concat.len);
                        for (child.children) |*grandchild, grandchild_id| {
                            grandchild.parent = .{ .node = child, .child_id = grandchild_id };
                            grandchild.rule_id = concat[grandchild_id];
                        }
                    }
                },
            } else return error.MissingRule;
        } else return error.UnplannedGrowth;
    }

    fn parse(self: Tree, text: []const u8) !bool {
        var node = self.root;
        var inbox: TreeNode.Inbox = .{ .src = null, .message = text };
        while (true) {
            if (node.actor) |*actor| {
                const outbox = actor.step(inbox);
                if (outbox.dst) |dst| {
                    node = &node.children[dst];
                    inbox = .{ .src = null, .message = outbox.message };
                } else if (node.parent) |parent| {
                    node = parent.node;
                    inbox = .{ .src = parent.child_id, .message = outbox.message };
                } else if (outbox.message) |slice| {
                    if (slice.len == 0) return true;
                    inbox = .{ .src = null, .message = null };
                } else {
                    return false;
                }
            } else {
                try self.grow(node);
            }
        }
    }
};

const TreeNode = struct {
    const TreeNode = @This();

    const ChildId = usize;
    const Slice = []const u8;
    const Inbox = struct { src: ?ChildId, message: ?Slice };
    const Outbox = struct { dst: ?ChildId, message: ?Slice };

    parent: ?struct { node: *TreeNode, child_id: ChildId } = null,
    rule_id: ?Rule.Id = null,
    children: []TreeNode = &[0]TreeNode{},
    actor: ?union(enum) {
        const Actor = @This();

        fn step(self: *Actor, inbox: Inbox) Outbox {
            return switch (self.*) {
                .Literal => |literal| literal.step(inbox),
                .Choice => |*choice| choice.step(inbox),
                .Concat => |concat| concat.step(inbox),
            };
        }

        Literal: struct {
            const Literal = @This();

            char: u8,

            fn step(self: Literal, inbox: Inbox) Outbox {
                assert(inbox.src == null);
                return Outbox{
                    .dst = null,
                    .message = if (inbox.message) |slice|
                        if (slice.len > 0 and slice[0] == self.char)
                            slice[1..]
                        else
                            null
                    else
                        null,
                };
            }
        },

        Choice: struct {
            const Choice = @This();

            end: ChildId,
            active: ChildId = undefined,
            slice: Slice = undefined,

            fn step(self: *Choice, inbox: Inbox) Outbox {
                if (inbox.src) |src| {
                    assert(src == self.active);
                    if (inbox.message) |slice| {
                        return Outbox{ .dst = null, .message = slice };
                    } else {
                        self.active += 1;
                    }
                } else {
                    if (inbox.message) |slice| {
                        self.active = 0;
                        self.slice = slice;
                    } else {
                        return Outbox{ .dst = self.active, .message = null };
                    }
                }
                return if (self.active < self.end)
                    Outbox{ .dst = self.active, .message = self.slice }
                else
                    Outbox{ .dst = null, .message = null };
            }
        },

        Concat: struct {
            const Concat = @This();

            end: ChildId,

            fn next(self: Concat, id: ?ChildId) ?ChildId {
                const child = if (id) |i| (i + 1) else 0;
                return if (child < self.end) child else null;
            }

            fn prev(self: Concat, id: ?ChildId) ?ChildId {
                const child = id orelse self.end;
                return if (child > 0) (child - 1) else null;
            }

            fn step(self: Concat, inbox: Inbox) Outbox {
                return Outbox{
                    .dst = if (inbox.message != null)
                        self.next(inbox.src)
                    else
                        self.prev(inbox.src),
                    .message = inbox.message,
                };
            }
        },
    },
};
