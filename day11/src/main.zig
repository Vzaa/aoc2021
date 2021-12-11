const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const mem = std.mem;
const math = std.math;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;
const OctoMap = AutoHashMap(Point, i32);
const FlashMap = AutoHashMap(Point, void);

fn flash(map: *OctoMap, fmap: *FlashMap, p: Point) void {
    const x = p[0];
    const y = p[1];

    fmap.put(p, {}) catch {};

    const neighbors = [_]Point{
        .{ x - 1, y },
        .{ x + 1, y },
        .{ x, y - 1 },
        .{ x, y + 1 },

        .{ x - 1, y - 1 },
        .{ x + 1, y - 1 },
        .{ x - 1, y + 1 },
        .{ x + 1, y + 1 },
    };

    for (neighbors) |n| {
        if (map.getPtr(n)) |v| {
            v.* += 1;
            if (v.* > 9 and !fmap.contains(n)) {
                flash(map, fmap, n);
            }
        }
    }
}

fn p1(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var map = OctoMap.init(gpa);
    defer map.deinit();

    var y: i32 = 0;
    while (line_iter.next()) |line| {
        var x: i32 = 0;
        for (line) |c| {
            const num = try std.fmt.charToDigit(c, 10);
            try map.put(.{ x, y }, num);
            x += 1;
        }
        y += 1;
    }

    var flashes: usize = 0;

    var i: usize = 0;

    while (i < 100) : (i += 1) {
        var fmap = FlashMap.init(gpa);
        defer fmap.deinit();

        var kiter = map.keyIterator();
        while (kiter.next()) |k| {
            var v = map.getPtr(k.*).?;
            v.* += 1;
            if (v.* > 9 and !fmap.contains(k.*)) {
                flash(&map, &fmap, k.*);
            }
        }

        flashes += fmap.count();
        var viter = map.valueIterator();
        while (viter.next()) |v| {
            if (v.* > 9) v.* = 0;
        }
    }

    return flashes;
}

fn p2(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var map = OctoMap.init(gpa);
    defer map.deinit();

    var y: i32 = 0;
    while (line_iter.next()) |line| {
        var x: i32 = 0;
        for (line) |c| {
            const num = try std.fmt.charToDigit(c, 10);
            try map.put(.{ x, y }, num);
            x += 1;
        }
        y += 1;
    }

    var i: usize = 1;
    while (true) : (i += 1) {
        var fmap = FlashMap.init(gpa);
        defer fmap.deinit();

        var kiter = map.keyIterator();
        while (kiter.next()) |k| {
            var v = map.getPtr(k.*).?;
            v.* += 1;
            if (v.* > 9 and !fmap.contains(k.*)) {
                flash(&map, &fmap, k.*);
            }
        }

        if (fmap.count() == map.count()) return i;

        var viter = map.valueIterator();
        while (viter.next()) |v| {
            if (v.* > 9) v.* = 0;
        }
    }
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
    try std.testing.expectEqual(p1(text), 1656);
    try std.testing.expectEqual(p2(text), 195);
}
