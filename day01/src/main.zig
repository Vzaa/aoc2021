const std = @import("std");

fn p1(text: []const u8) !usize {
    var incs: usize = 0;
    var iter = std.mem.tokenize(u8, text, "\n");
    var num_old = try std.fmt.parseInt(i32, iter.next().?, 10);

    while (iter.next()) |num_str| {
        const num = try std.fmt.parseInt(i32, num_str, 10);
        if (num > num_old) {
            incs += 1;
        }
        num_old = num;
    }

    return incs;
}

fn sumSlice(comptime T: type, dat: []const T) T {
    var sum: T = 0;
    for (dat) |val| {
        sum += val;
    }
    return sum;
}

fn p2(text: []const u8) !usize {
    var incs: usize = 0;
    var vals: [3]i32 = undefined;
    var iter = std.mem.tokenize(u8, text, "\n");

    for (vals) |_, i| {
        vals[i] = try std.fmt.parseInt(i32, iter.next().?, 10);
    }

    while (iter.next()) |num_str| {
        const num = try std.fmt.parseInt(i32, num_str, 10);
        const sum_old = sumSlice(i32, vals[0..]);
        vals[0] = num;
        const sum_new = sumSlice(i32, vals[0..]);
        std.mem.rotate(i32, vals[0..], 1);

        if (sum_new > sum_old) {
            incs += 1;
        }
    }

    return incs;
}

pub fn main() anyerror!void {
    const text = @embedFile("../input");
    std.debug.print("Part 1: {}\n", .{p1(text)});
    std.debug.print("Part 2: {}\n", .{p2(text)});
}

test "examples" {
    const text = @embedFile("../test");
    try std.testing.expectEqual(p1(text), 7);
    try std.testing.expectEqual(p2(text), 5);
}
