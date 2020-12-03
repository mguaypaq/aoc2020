const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var reader = std.io.bufferedReader(file.reader()).reader();

    const State = enum {
        start_of_line,
        in_first_number,
        after_dash,
        in_second_number,
        before_policy_char,
        after_policy_char_1,
        after_policy_char_2,
        in_password,
    };

    var parsing_state = State.start_of_line;
    var policy_low: u8 = undefined;
    var policy_high: u8 = undefined;
    var policy_char: u8 = undefined;
    var policy_char_count: u8 = undefined;
    var valid_count: u32 = 0;

    while (reader.readByte()) |char| switch (parsing_state) {
        State.start_of_line => switch (char) {
            '0'...'9' => {
                policy_low = char - '0';
                parsing_state = State.in_first_number;
            },
            else => return error.BadFormat,
        },
        State.in_first_number => switch (char) {
            '0'...'9' => {
                policy_low *= 10;
                policy_low += char - '0';
            },
            '-' => {
                parsing_state = State.after_dash;
            },
            else => return error.BadFormat,
        },
        State.after_dash => switch (char) {
            '0'...'9' => {
                policy_high = char - '0';
                parsing_state = State.in_second_number;
            },
            else => return error.BadFormat,
        },
        State.in_second_number => switch (char) {
            '0'...'9' => {
                policy_high *= 10;
                policy_high += char - '0';
            },
            ' ' => {
                parsing_state = State.before_policy_char;
            },
            else => return error.BadFormat,
        },
        State.before_policy_char => {
            policy_char = char;
            parsing_state = State.after_policy_char_1;
        },
        State.after_policy_char_1 => {
            if (char != ':') return error.BadFormat;
            parsing_state = State.after_policy_char_2;
        },
        State.after_policy_char_2 => {
            if (char != ' ') return error.BadFormat;
            policy_char_count = 0;
            parsing_state = State.in_password;
        },
        State.in_password => switch (char) {
            'a'...'z' => {
                if (char == policy_char) policy_char_count += 1;
            },
            '\n' => {
                if (policy_low <= policy_char_count and policy_char_count <= policy_high) valid_count += 1;
                policy_low = undefined;
                policy_high = undefined;
                policy_char = undefined;
                policy_char_count = undefined;
                parsing_state = State.start_of_line;
            },
            else => return error.BadFormat,
        },
    } else |err| {
        if (err != error.EndOfStream) return err;
        if (parsing_state != State.start_of_line) return error.BadFormat;
    }

    try stdout.print("{}\n", .{valid_count});
}
