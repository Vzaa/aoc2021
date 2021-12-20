const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;
const Image = AutoHashMap(Point, u8);
const VisitSet = AutoHashMap(Point, void);

fn getAsStr(map: *Image, p: Point, fb: u8) [9]u8 {
    const x = p[0];
    const y = p[1];

    const neighbors = [9]Point{
        .{ x - 1, y - 1 },
        .{ x, y - 1 },
        .{ x + 1, y - 1 },

        .{ x - 1, y },
        .{ x, y },
        .{ x + 1, y },

        .{ x - 1, y + 1 },
        .{ x, y + 1 },
        .{ x + 1, y + 1 },
    };

    var vals: [9]u8 = undefined;

    for (neighbors) |n, i| {
        const val = map.get(n) orelse fb;
        vals[i] = if (val == '#') '1' else '0';
    }

    return vals;
}

fn core(text: Str, lim: usize) !usize {
    var line_iter = mem.split(u8, text, "\n");
    const rules = line_iter.next().?;

    var cave_map = Image.init(gpa);
    defer cave_map.deinit();

    {
        var y: i32 = 0;
        while (line_iter.next()) |line| {
            if (line.len == 0) {
                continue;
            }
            var x: i32 = 0;
            for (line) |c| {
                try cave_map.put(.{ x, y }, c);
                x += 1;
            }
            y += 1;
        }
    }

    var cnt: usize = 0;
    while (cnt < lim) : (cnt += 1) {
        var visited = VisitSet.init(gpa);
        defer visited.deinit();

        var new_map = Image.init(gpa);

        var kiter = cave_map.keyIterator();
        while (kiter.next()) |p| {
            // dumb way to expand but whatevz
            var y = p[1] - 1;
            while (y <= p[1] + 1) : (y += 1) {
                var x = p[0] - 1;
                while (x <= p[0] + 1) : (x += 1) {
                    if (visited.contains(.{ x, y })) {
                        continue;
                    }
                    try visited.put(.{ x, y }, {});

                    const fb: u8 = if (rules[0] == '#' and cnt % 2 == 1) '#' else '.';
                    const bin_str = getAsStr(&cave_map, .{ x, y }, fb);
                    const idx = try std.fmt.parseInt(usize, bin_str[0..], 2);
                    try new_map.put(.{ x, y }, rules[idx]);
                }
            }
        }
        cave_map.clearAndFree();
        cave_map = new_map;
    }

    var tmp: usize = 0;
    var viter = cave_map.valueIterator();
    while (viter.next()) |v| {
        if (v.* == '#') {
            tmp += 1;
        }
    }

    return tmp;
}

fn p1(text: Str) !usize {
    return core(text, 2);
}

fn p2(text: Str) !usize {
    return core(text, 50);
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
    try std.testing.expectEqual(p1(text), 35);
    try std.testing.expectEqual(p2(text), 3351);
}
