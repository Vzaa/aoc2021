const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const mem = std.mem;
const math = std.math;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

fn p1(text: []const u8) !i32 {
    var trimmed = mem.trim(u8, text, std.ascii.spaces[0..]);
    var num_iter = mem.tokenize(u8, trimmed, ",");

    var list = ArrayList(i32).init(gpa);
    defer list.deinit();

    while (num_iter.next()) |num_str| {
        const num = try std.fmt.parseInt(i32, num_str, 10);
        try list.append(num);
    }

    var min = mem.min(i32, list.items);
    var max = mem.max(i32, list.items);

    var min_fuel: i32 = math.maxInt(i32);

    var i = min;
    while (i <= max) : (i += 1) {
        var sum: i32 = 0;
        for (list.items) |v| {
            var abs = try std.math.absInt(v - i);
            sum += abs;
        }
        min_fuel = math.min(sum, min_fuel);
    }

    return min_fuel;
}

fn gauss(v: i32) i32 {
    return @divFloor(v * (v + 1), 2);
}

fn p2(text: []const u8) !i32 {
    var trimmed = mem.trim(u8, text, std.ascii.spaces[0..]);
    var num_iter = mem.tokenize(u8, trimmed, ",");

    var list = ArrayList(i32).init(gpa);
    defer list.deinit();

    while (num_iter.next()) |num_str| {
        const num = try std.fmt.parseInt(i32, num_str, 10);
        try list.append(num);
    }

    var min = mem.min(i32, list.items);
    var max = mem.max(i32, list.items);

    var min_fuel: i32 = math.maxInt(i32);

    var i = min;
    while (i <= max) : (i += 1) {
        var sum: i32 = 0;
        for (list.items) |v| {
            var abs = try std.math.absInt(v - i);
            sum += gauss(abs);
        }
        min_fuel = math.min(sum, min_fuel);
    }

    return min_fuel;
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
    try std.testing.expectEqual(p1(text), 37);
    try std.testing.expectEqual(p2(text), 168);
}
