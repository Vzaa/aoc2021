const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const mem = std.mem;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_impl.allocator;

fn p1(text: []const u8) !usize {
    var trimmed = std.mem.trim(u8, text, std.ascii.spaces[0..]);
    var num_iter = std.mem.tokenize(u8, trimmed, ",");

    var list = ArrayList(i32).init(gpa);
    defer list.deinit();

    while (num_iter.next()) |num_str| {
        const num = try std.fmt.parseInt(i32, num_str, 10);
        try list.append(num);
    }

    var i: usize = 0;
    while (i < 80) : (i += 1) {
        var new_fish: usize = 0;
        for (list.items) |*num| {
            switch (num.*) {
                0 => {
                    num.* = 6;
                    new_fish += 1;
                },
                else => {
                    num.* -= 1;
                },
            }
        }

        var j: usize = 0;
        while (j < new_fish) : (j += 1) {
            try list.append(8);
        }
    }

    return list.items.len;
}

fn p2(text: []const u8) !usize {
    var trimmed = std.mem.trim(u8, text, std.ascii.spaces[0..]);
    var num_iter = std.mem.tokenize(u8, trimmed, ",");

    var map = [9]usize{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    while (num_iter.next()) |num_str| {
        const num = try std.fmt.parseInt(usize, num_str, 10);
        map[num] += 1;
    }

    var i: usize = 0;
    while (i < 256) : (i += 1) {
        var new_fish = map[0];

        // rotate 0..=6
        std.mem.rotate(usize, map[0..7], 1);

        // add 7s to 6s
        map[6] += map[7];

        map[7] = map[8];
        map[8] = new_fish;
    }

    var sum: usize = 0;
    for (map) |cnt| {
        sum += cnt;
    }

    return sum;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../input");
    print("Part 1: {}\n", .{p1(text)});
    print("Part 2: {}\n", .{p2(text)});
}

test "examples" {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../test");
    try std.testing.expectEqual(p1(text), 5934);
    try std.testing.expectEqual(p2(text), 26984457539);
}
