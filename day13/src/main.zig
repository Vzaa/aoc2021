const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const mem = std.mem;
const math = std.math;
const fmt = std.fmt;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;
const PMap = AutoHashMap(Point, void);

const XY = enum { x, y };

const Fold = struct {
    d: XY,
    v: i32,

    fn fromStr(s: Str) !Fold {
        var eq_iter = mem.split(u8, s, "=");
        const xy = eq_iter.next().?;
        const d = if (xy[0] == 'x') XY.x else XY.y;
        const v = try fmt.parseInt(i32, eq_iter.next().?, 10);
        return Fold{ .d = d, .v = v };
    }
};

fn p1(text: Str) !usize {
    var line_iter = mem.split(u8, text, "\n");

    var points = PMap.init(gpa);
    defer points.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var com_iter = mem.split(u8, line, ",");
        const x = try fmt.parseInt(i32, com_iter.next().?, 10);
        const y = try fmt.parseInt(i32, com_iter.next().?, 10);

        try points.put(.{ x, y }, {});
    }

    var folds = ArrayList(Fold).init(gpa);
    defer folds.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var sp_iter = mem.split(u8, line, " ");
        _ = sp_iter.next().?;
        _ = sp_iter.next().?;
        const s = sp_iter.next().?;
        const f = try Fold.fromStr(s);
        try folds.append(f);
    }

    for (folds.items) |f| {
        var np = PMap.init(gpa);
        defer np.deinit();
        var kiter = points.keyIterator();

        switch (f.d) {
            XY.x => {
                while (kiter.next()) |k| {
                    const y = k[1];
                    var x: i32 = undefined;
                    if (k[0] > f.v) {
                        x = f.v - (k[0] - f.v);
                    } else {
                        x = k[0];
                    }
                    try np.put(.{ x, y }, {});
                }
            },
            XY.y => {
                while (kiter.next()) |k| {
                    const x = k[0];
                    var y: i32 = undefined;
                    if (k[1] > f.v) {
                        y = f.v - (k[1] - f.v);
                    } else {
                        y = k[1];
                    }
                    try np.put(.{ x, y }, {});
                }
            },
        }
        return np.count();
    }

    unreachable;
}

fn p2(text: Str) !void {
    var line_iter = mem.split(u8, text, "\n");

    var points = PMap.init(gpa);
    defer points.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var com_iter = mem.split(u8, line, ",");
        const x = try fmt.parseInt(i32, com_iter.next().?, 10);
        const y = try fmt.parseInt(i32, com_iter.next().?, 10);

        try points.put(.{ x, y }, {});
    }

    var folds = ArrayList(Fold).init(gpa);
    defer folds.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var sp_iter = mem.split(u8, line, " ");
        _ = sp_iter.next().?;
        _ = sp_iter.next().?;
        const s = sp_iter.next().?;
        const f = try Fold.fromStr(s);
        try folds.append(f);
    }

    for (folds.items) |f| {
        var np = PMap.init(gpa);
        // don't deinit np, we will overwrite this over the old one
        var kiter = points.keyIterator();

        switch (f.d) {
            XY.x => {
                while (kiter.next()) |k| {
                    const y = k[1];
                    var x: i32 = undefined;
                    if (k[0] > f.v) {
                        x = f.v - (k[0] - f.v);
                    } else {
                        x = k[0];
                    }
                    try np.put(.{ x, y }, {});
                }
            },
            XY.y => {
                while (kiter.next()) |k| {
                    const x = k[0];
                    var y: i32 = undefined;
                    if (k[1] > f.v) {
                        y = f.v - (k[1] - f.v);
                    } else {
                        y = k[1];
                    }
                    try np.put(.{ x, y }, {});
                }
            },
        }

        points.clearAndFree();
        points = np;
    }

    var max_x: i32 = 0;
    var max_y: i32 = 0;

    var kiter = points.keyIterator();
    while (kiter.next()) |k| {
        max_x = math.max(k[0], max_x);
        max_y = math.max(k[1], max_y);
    }

    var y: i32 = 0;
    while (y <= max_y) : (y += 1) {
        var x: i32 = 0;
        while (x <= max_x) : (x += 1) {
            const c: u8 = if (points.contains(.{ x, y })) '#' else '.';
            print("{c}", .{c});
        }
        print("\n", .{});
    }
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../input");
    print("Part 1: {}\n", .{p1(text)});
    print("Part 2:\n", .{});
    try p2(text);
}

test "examples" {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../test");
    try std.testing.expectEqual(p1(text), 17);
    print("\n", .{});
    try p2(text);
}
