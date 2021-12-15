const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;
const CaveMap = AutoHashMap(Point, i32);

fn getNeighbors(p: Point) [4]Point {
    const x = p[0];
    const y = p[1];

    const neighbors = [_]Point{
        .{ x - 1, y },
        .{ x + 1, y },
        .{ x, y - 1 },
        .{ x, y + 1 },
    };

    return neighbors;
}

const PC = struct {
    p: Point,
    c: i32,
};

fn ucs(cave_map: *CaveMap, tgt: Point) !i32 {
    var frontier = PriorityQueue(PC, compPc).init(gpa);
    defer frontier.deinit();

    var visited = AutoHashMap(Point, i32).init(gpa);
    defer visited.deinit();

    var p = Point{ 0, 0 };
    try frontier.add(PC{ .p = p, .c = 0 });

    while (frontier.removeOrNull()) |cur| {
        var cur_cost = cur.c;

        try visited.put(cur.p, cur.c);

        if (mem.eql(i32, cur.p[0..], tgt[0..])) {
            return cur.c;
        }

        const neighbors = getNeighbors(cur.p);

        for (neighbors) |np| {
            if (cave_map.get(np)) |c| {
                var cost = cur_cost + c;
                if (visited.get(np)) |old_c| {
                    if (old_c > cost) {
                        try frontier.add(PC{ .p = np, .c = cost });
                        try visited.put(np, cost);
                    }
                } else {
                    try frontier.add(PC{ .p = np, .c = cost });
                    try visited.put(np, cost);
                }
            }
        }
    }

    unreachable;
}

fn compPc(a: PC, b: PC) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn p1(text: Str) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var cave_map = CaveMap.init(gpa);
    defer cave_map.deinit();

    var y: i32 = 0;
    var x: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        x = 0;
        for (line) |c| {
            const v = try std.fmt.charToDigit(c, 10);

            try cave_map.put(.{ x, y }, v);
            x += 1;
        }
    }

    var tgt = Point{ x - 1, y - 1 };
    return ucs(&cave_map, tgt);
}

fn p2(text: Str) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var cave_map_s = CaveMap.init(gpa);
    defer cave_map_s.deinit();

    var y: i32 = 0;
    var x: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        x = 0;
        for (line) |c| {
            const v = try std.fmt.charToDigit(c, 10);

            try cave_map_s.put(.{ x, y }, v);
            x += 1;
        }
    }

    var cave_map = CaveMap.init(gpa);
    defer cave_map.deinit();

    var kiter = cave_map_s.keyIterator();
    // lol
    while (kiter.next()) |k| {
        var yy: i32 = 0;
        while (yy < 5) : (yy += 1) {
            var xx: i32 = 0;
            while (xx < 5) : (xx += 1) {
                const v = cave_map_s.get(k.*).?;
                var new_v = v + xx + yy;
                if (new_v > 9) {
                    new_v -= 9;
                }

                try cave_map.put(.{ k.*[0] + (xx * x), k.*[1] + (yy * y) }, new_v);
            }
        }
    }

    var tgt = Point{ (x * 5) - 1, (y * 5) - 1 };

    return ucs(&cave_map, tgt);
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
    try std.testing.expectEqual(p1(text), 40);
    try std.testing.expectEqual(p2(text), 315);
}
