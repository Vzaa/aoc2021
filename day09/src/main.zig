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
const CaveMap = AutoHashMap(Point, u8);
const BasinMap = AutoHashMap(Point, void);

fn isMinima(map: *CaveMap, p: Point) bool {
    const x = p[0];
    const y = p[1];

    const v = map.get(.{ x, y }).?;

    const neighbors = [_]u8{
        map.get(.{ x - 1, y }) orelse 10,
        map.get(.{ x + 1, y }) orelse 10,
        map.get(.{ x, y - 1 }) orelse 10,
        map.get(.{ x, y + 1 }) orelse 10,
    };

    for (neighbors) |n| {
        if (v >= n) return false;
    }

    return true;
}

fn findBasin(map: *CaveMap, p: Point, basin: *BasinMap) void {
    const x = p[0];
    const y = p[1];

    const v = map.get(.{ x, y }).?;

    // TODO: how to handle errors in recursive fns?
    basin.put(p, {}) catch {};

    const neighbors = [_]Point{
        .{ x - 1, y },
        .{ x + 1, y },
        .{ x, y - 1 },
        .{ x, y + 1 },
    };

    for (neighbors) |n| {
        if (!basin.contains(n)) {
            if (map.get(n)) |nv| {
                if (nv >= v and nv != 9) {
                    findBasin(map, n, basin);
                }
            }
        }
    }
}

fn p1(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var x: i32 = 0;
    var y: i32 = 0;

    var cave_map = CaveMap.init(gpa);
    defer cave_map.deinit();

    while (line_iter.next()) |line| : (y += 1) {
        x = 0;
        for (line) |c| {
            const v = try std.fmt.charToDigit(c, 10);

            try cave_map.put(.{ x, y }, v);
            x += 1;
        }
    }

    var kiter = cave_map.keyIterator();
    var sum: usize = 0;

    while (kiter.next()) |k| {
        if (isMinima(&cave_map, k.*)) {
            sum += cave_map.get(k.*).? + 1;
        }
    }

    return sum;
}

fn p2(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var x: i32 = 0;
    var y: i32 = 0;

    var cave_map = CaveMap.init(gpa);
    defer cave_map.deinit();

    while (line_iter.next()) |line| : (y += 1) {
        x = 0;
        for (line) |c| {
            const v = try std.fmt.charToDigit(c, 10);

            try cave_map.put(.{ x, y }, v);
            x += 1;
        }
    }

    var kiter = cave_map.keyIterator();

    var basins = ArrayList(BasinMap).init(gpa);
    defer basins.deinit();
    defer {
        for (basins.items) |*b| b.deinit();
    }

    while (kiter.next()) |k| {
        if (isMinima(&cave_map, k.*)) {
            var basin = BasinMap.init(gpa);
            findBasin(&cave_map, k.*, &basin);
            try basins.append(basin);
        }
    }

    std.sort.sort(BasinMap, basins.items, {}, compCount);

    const a = basins.items[0].count();
    const b = basins.items[1].count();
    const c = basins.items[2].count();

    return a * b * c;
}

// TODO: learn void arg does lol
fn compCount(_: void, a: BasinMap, b: BasinMap) bool {
    return a.count() > b.count();
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
    try std.testing.expectEqual(p1(text), 15);
    try std.testing.expectEqual(p2(text), 1134);
}
