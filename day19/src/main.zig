const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

const Point = [3]i32;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

// Not all are valid but all combinations:
fn orient(p: Point, o: u8) Point {
    const x = p[0];
    const y = p[1];
    const z = p[2];

    switch (o) {
        0 => return Point{ x, y, z },
        1 => return Point{ x, z, y },
        2 => return Point{ x, y, -z },
        3 => return Point{ x, z, -y },
        4 => return Point{ x, -y, z },
        5 => return Point{ x, -z, y },
        6 => return Point{ x, -y, -z },
        7 => return Point{ x, -z, -y },

        8 => return Point{ y, x, z },
        9 => return Point{ y, z, x },
        10 => return Point{ y, x, -z },
        11 => return Point{ y, z, -x },
        12 => return Point{ y, -x, z },
        13 => return Point{ y, -z, x },
        14 => return Point{ y, -x, -z },
        15 => return Point{ y, -z, -x },

        16 => return Point{ z, y, x },
        17 => return Point{ z, x, y },
        18 => return Point{ z, y, -x },
        19 => return Point{ z, x, -y },
        20 => return Point{ z, -y, x },
        21 => return Point{ z, -x, y },
        22 => return Point{ z, -y, -x },
        23 => return Point{ z, -x, -y },

        24 => return Point{ -x, y, z },
        25 => return Point{ -x, z, y },
        26 => return Point{ -x, y, -z },
        27 => return Point{ -x, z, -y },
        28 => return Point{ -x, -y, z },
        29 => return Point{ -x, -z, y },
        30 => return Point{ -x, -y, -z },
        31 => return Point{ -x, -z, -y },

        32 => return Point{ -y, x, z },
        33 => return Point{ -y, z, x },
        34 => return Point{ -y, x, -z },
        35 => return Point{ -y, z, -x },
        36 => return Point{ -y, -x, z },
        37 => return Point{ -y, -z, x },
        38 => return Point{ -y, -x, -z },
        39 => return Point{ -y, -z, -x },

        40 => return Point{ -z, y, x },
        41 => return Point{ -z, x, y },
        42 => return Point{ -z, y, -x },
        43 => return Point{ -z, x, -y },
        44 => return Point{ -z, -y, x },
        45 => return Point{ -z, -x, y },
        46 => return Point{ -z, -y, -x },
        47 => return Point{ -z, -x, -y },

        else => unreachable,
    }
}

const Scanner = struct {
    points: ArrayList(Point),
    oriented: ArrayList(Point),
    diff: Point,
    orient: u8,

    fn init() Scanner {
        const p = ArrayList(Point).init(gpa);
        const oriented = ArrayList(Point).init(gpa);
        return Scanner{ .points = p, .oriented = oriented, .orient = 0, .diff = Point{ 0, 0, 0 } };
    }

    fn put(self: *Scanner, p: Point) !void {
        try self.points.append(p);
    }

    fn getOriented(self: *Scanner) ![]Point {
        self.oriented.clearRetainingCapacity();

        for (self.points.items) |x| {
            try self.oriented.append(orient(x, self.orient));
        }

        return self.oriented.items;
    }

    fn deinit(self: *Scanner) void {
        self.points.deinit();
        self.oriented.deinit();
    }
};

fn diff(a: Point, b: Point) Point {
    return Point{ a[0] - b[0], a[1] - b[1], a[2] - b[2] };
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1], a[2] + b[2] };
}

fn diffs(pts: []Point, p: Point, d: *ArrayList(Point)) !void {
    d.clearRetainingCapacity();
    for (pts) |x| {
        try d.append(diff(x, p));
    }
}

fn sliceComp(a: []Point, b: []Point) usize {
    var cnt: usize = 0;

    for (a) |pa| {
        for (b) |pb| {
            if (mem.eql(i32, pa[0..], pb[0..])) cnt += 1;
        }
    }

    return cnt;
}

fn compare(a: *const Scanner, b: *Scanner) !bool {
    assert(a.orient == 0);

    var lista = ArrayList(Point).init(gpa);
    defer lista.deinit();

    var listb = ArrayList(Point).init(gpa);
    defer listb.deinit();

    var o: u8 = 0;
    while (o < 48) : (o += 1) {
        b.orient = o;
        const b_points = try b.getOriented();

        for (a.points.items) |pa| {
            try diffs(a.points.items, pa, &lista);

            for (b_points) |pb| {
                try diffs(b_points, pb, &listb);

                const same = sliceComp(lista.items, listb.items);
                if (same >= 12) {
                    //fix pos
                    b.points.clearRetainingCapacity();
                    for (b_points) |old| {
                        const d = diff(pa, pb);
                        const n = add(d, old);
                        try b.points.append(n);
                        b.orient = 0;
                        b.diff = d;
                    }

                    return true;
                }
            }
        }
    }

    return false;
}

fn p1(text: Str) !usize {
    var line_iter = mem.split(u8, text, "\n");

    var scanners = ArrayList(Scanner).init(gpa);
    defer scanners.deinit();
    defer for (scanners.items) |*s| s.deinit();

    var scanner: ?Scanner = null;

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            if (scanner) |s| {
                try scanners.append(s);
                scanner = null;
            }
            continue;
        } else if (mem.indexOf(u8, line, "scanner")) |_| {
            scanner = Scanner.init();
            continue;
        }

        var num_iter = mem.split(u8, line, ",");

        const x = try std.fmt.parseInt(i32, num_iter.next().?, 10);
        const y = try std.fmt.parseInt(i32, num_iter.next().?, 10);
        const z = try std.fmt.parseInt(i32, num_iter.next().?, 10);

        try scanner.?.put(Point{ x, y, z });
    }

    var done = AutoHashMap(usize, void).init(gpa);
    defer done.deinit();

    var visited = AutoHashMap(usize, void).init(gpa);
    defer visited.deinit();

    try done.put(0, {});

    while (done.count() < scanners.items.len) {
        for (scanners.items) |*sa, i| {
            if (!done.contains(i)) continue;
            if (visited.contains(i)) continue;

            for (scanners.items) |*sb, j| {
                if (done.contains(j)) continue;

                const cmp = try compare(sa, sb);
                // print("cmp {} {} {}\n", .{ cmp, i, j });
                if (cmp) {
                    try done.put(j, {});
                }
            }
            try visited.put(i, {});
        }
    }

    var uniq = AutoHashMap(Point, void).init(gpa);
    defer uniq.deinit();

    for (scanners.items) |s| {
        assert(s.orient == 0);
        for (s.points.items) |p| {
            try uniq.put(p, {});
        }
    }

    print("Part 1: {}\n", .{uniq.count()});

    var max_d: i32 = 0;
    for (scanners.items) |sa| {
        for (scanners.items) |sb| {
            const dist = try mDist(sa.diff, sb.diff);
            max_d = math.max(max_d, dist);
        }
    }

    print("Part 2: {}\n", .{max_d});

    return uniq.count();
}

fn mDist(a: Point, b: Point) !i32 {
    const x = try math.absInt(a[0] - b[0]);
    const y = try math.absInt(a[1] - b[1]);
    const z = try math.absInt(a[2] - b[2]);
    return x + y + z;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../input");
    _ = try p1(text);
    // print("Part 1: {}\n", .{p1(text)});
    // print("Part 2: {}\n", .{p2(text)});
}

test "examples" {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../test");
    try std.testing.expectEqual(p1(text), 79);
    // try std.testing.expectEqual(p2(text), 0);
}
