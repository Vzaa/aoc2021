const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const mem = std.mem;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_impl.allocator;
const MapVal = AutoHashMap(Vec2, usize);

const Vec2 = struct {
    x: i32 = 0,
    y: i32 = 0,

    fn fromStr(txt: []const u8) !Vec2 {
        var num_iter = std.mem.tokenize(u8, txt, ",");
        const x = try std.fmt.parseInt(i32, num_iter.next().?, 10);
        const y = try std.fmt.parseInt(i32, num_iter.next().?, 10);

        return Vec2{ .x = x, .y = y };
    }
};

const Line = struct {
    a: Vec2,
    b: Vec2,

    fn fromStr(txt: []const u8) !Line {
        var vec_iter = std.mem.tokenize(u8, txt, " -> ");

        const a = try Vec2.fromStr(vec_iter.next().?);
        const b = try Vec2.fromStr(vec_iter.next().?);

        return Line{ .a = a, .b = b };
    }

    fn isVer(self: *const Line) bool {
        return self.a.x == self.b.x;
    }

    fn isHor(self: *const Line) bool {
        return self.a.y == self.b.y;
    }
};

fn p1(text: []const u8) !usize {
    var line_iter = std.mem.tokenize(u8, text, "\n");

    var lines = ArrayList(Line).init(gpa);
    defer lines.deinit();

    while (line_iter.next()) |line| {
        const l = try Line.fromStr(line);
        try lines.append(l);
    }

    var map = MapVal.init(gpa);
    defer map.deinit();

    for (lines.items) |line| {
        if (line.isHor()) {
            const y = line.a.y;
            const s = if (line.a.x > line.b.x) line.b.x else line.a.x;
            const e = if (line.a.x > line.b.x) line.a.x else line.b.x;

            var x = s;
            while (x <= e) : (x += 1) {
                var gop = try map.getOrPut(Vec2{ .x = x, .y = y });
                if (gop.found_existing) {
                    gop.value_ptr.* += 1;
                } else {
                    gop.value_ptr.* = 1;
                }
            }
        } else if (line.isVer()) {
            const x = line.a.x;
            const s = if (line.a.y > line.b.y) line.b.y else line.a.y;
            const e = if (line.a.y > line.b.y) line.a.y else line.b.y;

            var y = s;
            while (y <= e) : (y += 1) {
                var gop = try map.getOrPut(Vec2{ .x = x, .y = y });
                if (gop.found_existing) {
                    gop.value_ptr.* += 1;
                } else {
                    gop.value_ptr.* = 1;
                }
            }
        }
    }

    var var_iter = map.valueIterator();
    var sum: usize = 0;

    while (var_iter.next()) |v| {
        if (v.* > 1) sum += 1;
    }
    return sum;
}

fn p2(text: []const u8) !usize {
    var line_iter = std.mem.tokenize(u8, text, "\n");

    var lines = ArrayList(Line).init(gpa);
    defer lines.deinit();

    while (line_iter.next()) |line| {
        const l = try Line.fromStr(line);
        try lines.append(l);
    }

    var map = MapVal.init(gpa);
    defer map.deinit();

    for (lines.items) |line| {
        if (line.isHor()) {
            const y = line.a.y;
            const s = if (line.a.x > line.b.x) line.b.x else line.a.x;
            const e = if (line.a.x > line.b.x) line.a.x else line.b.x;

            var x = s;
            while (x <= e) : (x += 1) {
                var gop = try map.getOrPut(Vec2{ .x = x, .y = y });
                if (gop.found_existing) {
                    gop.value_ptr.* += 1;
                } else {
                    gop.value_ptr.* = 1;
                }
            }
        } else if (line.isVer()) {
            const x = line.a.x;
            const s = if (line.a.y > line.b.y) line.b.y else line.a.y;
            const e = if (line.a.y > line.b.y) line.a.y else line.b.y;

            var y = s;
            while (y <= e) : (y += 1) {
                var gop = try map.getOrPut(Vec2{ .x = x, .y = y });
                if (gop.found_existing) {
                    gop.value_ptr.* += 1;
                } else {
                    gop.value_ptr.* = 1;
                }
            }
        } else {
            const s = if (line.a.x > line.b.x) line.b else line.a;
            const e = if (line.a.x > line.b.x) line.a else line.b;

            var y = s.y;
            var x = s.x;

            const y_step: i32 = if (s.y < e.y) 1 else -1;

            while (x <= e.x) : (x += 1) {
                var gop = try map.getOrPut(Vec2{ .x = x, .y = y });
                if (gop.found_existing) {
                    gop.value_ptr.* += 1;
                } else {
                    gop.value_ptr.* = 1;
                }

                y += y_step;
            }
        }
    }

    var var_iter = map.valueIterator();
    var sum: usize = 0;

    while (var_iter.next()) |v| {
        if (v.* > 1) sum += 1;
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
    try std.testing.expectEqual(p1(text), 5);
    try std.testing.expectEqual(p2(text), 12);
}
