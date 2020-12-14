const std = @import("std");
const math = std.math;

fn ModClass(comptime T: type) type {
    return struct {
        const Self = @This();

        remainder: T,
        divisor: T,

        fn init(remainder: T, divisor: T) !Self {
            return Self{
                .remainder = try math.mod(T, remainder, divisor),
                .divisor = divisor,
            };
        }

        fn intersectWith(self: *Self, other: Self) !void {
            // These vectors maintain the following two invariants:
            // vec[0] == vec[1] * self.divisor + vec[2] * other.divisor
            // abs(current[1] * previous[2] - current[2] * previous[1]) == 1
            var previous = [3]T{ self.divisor, 1, 0 };
            var current = [3]T{ other.divisor, 0, 1 };
            while (current[0] != 0) {
                const quotient = try math.divFloor(T, previous[0], current[0]);
                var next = [3]T{
                    previous[0] - quotient * current[0],
                    previous[1] - quotient * current[1],
                    previous[2] - quotient * current[2],
                };
                previous = current;
                current = next;
            }
            // At this point, previous[0] is the greatest common divisor,
            // and previous[1], previous[2] are the Bézout coefficients.
            self.remainder += previous[1] * self.divisor * try math.divExact(T, other.remainder - self.remainder, previous[0]);
            self.divisor *= try math.divExact(T, other.divisor, previous[0]);
            self.remainder = try math.mod(T, self.remainder, self.divisor);
        }
    };
}

pub fn main() !void {
    var coincidence = try ModClass(i128).init(0, 1);
    for (buses) |bus, offset| if (bus) |id| {
        const constraint = try ModClass(i128).init(-@as(i128, offset), id);
        try coincidence.intersectWith(constraint);
    };

    try std.io.getStdOut().writer().print("{}\n", .{coincidence.remainder});
}

const earliest = 1002460;
const buses = [_]?i32{
    29,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    41,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    601,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    23,
    null,
    null,
    null,
    null,
    13,
    null,
    null,
    null,
    17,
    null,
    19,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    463,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    37,
};
