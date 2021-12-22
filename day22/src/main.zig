const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Vec3 = [3]i64;
const Range = [2]i64;
const CubeMap = AutoHashMap(Vec3, bool);

const Cuboid = struct {
    x_range: Range,
    y_range: Range,
    z_range: Range,

    fn new(x: Range, y: Range, z: Range) Cuboid {
        return Cuboid{ .x_range = x, .y_range = y, .z_range = z };
    }

    fn area(self: *const Cuboid) i64 {
        return (self.x_range[1] - self.x_range[0] + 1) *
            (self.y_range[1] - self.y_range[0] + 1) *
            (self.z_range[1] - self.z_range[0] + 1);
    }
};

fn rangeFromStr(txt: Str) !Range {
    var num_iter = mem.tokenize(u8, txt, ".=xyz");
    const a = try std.fmt.parseInt(i64, num_iter.next().?, 10);
    const b = try std.fmt.parseInt(i64, num_iter.next().?, 10);

    return Range{ a, b };
}

fn checkP1Range(r: Range) bool {
    if (r[0] < -50 or r[0] > 50) return false;
    if (r[1] < -50 or r[1] > 50) return false;
    return true;
}

fn checkPoint(r: Range, p: i64) bool {
    return (p >= r[0] and p <= r[1]);
}

fn intersect1(a: Range, b: Range) ?Range {
    const in_1 = checkPoint(a, b[0]);
    const in_2 = checkPoint(a, b[1]);
    const in_3 = checkPoint(b, a[0]);
    const in_4 = checkPoint(b, a[1]);

    if (in_1 or in_2 or in_3 or in_4) {
        var points = [_]i64{ a[0], a[1], b[0], b[1] };
        std.sort.sort(i64, points[0..], {}, comptime std.sort.asc(i64));
        return Range{ points[1], points[2] };
    } else {
        return null;
    }
}

fn intersect3(a: *const Cuboid, b: *const Cuboid) ?Cuboid {
    const x_range = intersect1(a.x_range, b.x_range);
    const y_range = intersect1(a.y_range, b.y_range);
    const z_range = intersect1(a.z_range, b.z_range);

    if (x_range) |x| {
        if (y_range) |y| {
            if (z_range) |z| {
                // return Cuboid{ .x_range = x, .y_range = y, .z_range = z };
                return Cuboid.new(x, y, z);
            }
        }
    }
    return null;
}

// b smol
fn remove1(a: Range, b: Range) [3]?Range {
    var ret: [3]?Range = undefined;

    if (a[0] != b[0]) {
        var tmp: Range = undefined;
        tmp[0] = a[0];
        tmp[1] = b[0] - 1;
        ret[0] = tmp;
        assert(tmp[1] >= tmp[0]);
    } else {
        ret[0] = null;
    }

    ret[1] = b;
    assert(b[1] >= b[0]);

    if (a[1] != b[1]) {
        var tmp: Range = undefined;
        tmp[0] = b[1] + 1;
        tmp[1] = a[1];
        assert(tmp[1] >= tmp[0]);
        ret[2] = tmp;
    } else {
        ret[2] = null;
    }

    return ret;
}

// b smol
fn remove3(a: *const Cuboid, b: *const Cuboid) [27]?Cuboid {
    var ret: [27]?Cuboid = undefined;

    const x_smol = remove1(a.x_range, b.x_range);
    const y_smol = remove1(a.y_range, b.y_range);
    const z_smol = remove1(a.z_range, b.z_range);

    var cnt: usize = 0;
    for (x_smol) |xo| {
        for (y_smol) |yo| {
            for (z_smol) |zo| {
                if (xo != null and yo != null and zo != null) {
                    ret[cnt] = Cuboid.new(xo.?, yo.?, zo.?);
                } else {
                    ret[cnt] = null;
                }
                cnt += 1;
            }
        }
    }

    return ret;
}

const Rule = struct {
    on: bool,
    c: Cuboid,

    fn fromStr(line: Str) !Rule {
        var ret: Rule = undefined;
        var sp_iter = mem.tokenize(u8, line, " ");
        const on = sp_iter.next().?;

        const ranges = sp_iter.next().?;
        var comm_iter = mem.tokenize(u8, ranges, ",");

        const x_str = comm_iter.next().?;
        const y_str = comm_iter.next().?;
        const z_str = comm_iter.next().?;

        ret.c.x_range = try rangeFromStr(x_str);
        ret.c.y_range = try rangeFromStr(y_str);
        ret.c.z_range = try rangeFromStr(z_str);

        ret.on = mem.eql(u8, on, "on");
        return ret;
    }

    fn paint(self: *const Rule, map: *CubeMap) !void {
        if (!checkP1Range(self.c.x_range) or
            !checkP1Range(self.c.y_range) or
            !checkP1Range(self.c.z_range))
        {
            return;
        }

        var x = self.c.x_range[0];
        while (x <= self.c.x_range[1]) : (x += 1) {
            var y = self.c.y_range[0];
            while (y <= self.c.y_range[1]) : (y += 1) {
                var z = self.c.z_range[0];
                while (z <= self.c.z_range[1]) : (z += 1) {
                    try map.put(Vec3{ x, y, z }, self.on);
                }
            }
        }
    }
};

fn p1(text: Str) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var list = ArrayList(Rule).init(gpa);
    defer list.deinit();

    var map = CubeMap.init(gpa);
    defer map.deinit();

    while (line_iter.next()) |line| {
        const r = try Rule.fromStr(line);
        try list.append(r);
    }

    for (list.items) |r| {
        try r.paint(&map);
        {
            var viter = map.valueIterator();
            var cnt: usize = 0;
            while (viter.next()) |v| {
                if (v.*) cnt += 1;
            }
        }
    }

    var viter = map.valueIterator();
    var cnt: usize = 0;
    while (viter.next()) |v| {
        if (v.*) cnt += 1;
    }

    return cnt;
}

fn p2(text: Str) !i64 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var list = ArrayList(Rule).init(gpa);
    defer list.deinit();

    while (line_iter.next()) |line| {
        const r = try Rule.fromStr(line);
        try list.append(r);
    }

    var state = ArrayList(Cuboid).init(gpa);
    defer state.deinit();

    var cache = ArrayList(Cuboid).init(gpa);
    defer cache.deinit();

    for (list.items) |r| {
        if (r.on) {
            try cache.append(r.c);

            var i: usize = 0;
            outer: while (i < state.items.len) {
                for (cache.items) |_, j| {
                    const a = &state.items[i];
                    const b = &cache.items[j];
                    if (intersect3(a, b)) |sect| {
                        const cb = cache.swapRemove(j);
                        const ca = state.swapRemove(i);

                        try state.append(sect);
                        var list_a = remove3(&ca, &sect);
                        for (list_a) |smol, ii| {
                            if (ii == 13) {
                                continue;
                            }
                            if (smol) |sm| {
                                try state.append(sm);
                            }
                        }

                        var list_b = remove3(&cb, &sect);
                        for (list_b) |smol, ii| {
                            if (ii == 13) {
                                continue;
                            }
                            if (smol) |sm| {
                                try cache.append(sm);
                            }
                        }
                        continue :outer;
                    }
                }
                i += 1;
            }
            try state.appendSlice(cache.items);
            cache.clearRetainingCapacity();
        } else {
            var i: usize = 0;
            outer: while (i < state.items.len) {
                const c = &state.items[i];
                if (intersect3(&r.c, c)) |sect| {
                    const ca = state.swapRemove(i);
                    var list_a = remove3(&ca, &sect);
                    for (list_a) |smol, ii| {
                        if (ii == 13) {
                            continue;
                        }
                        if (smol) |sm| {
                            try state.append(sm);
                        }
                    }
                    continue :outer;
                }
                i += 1;
            }
        }
    }

    var sum: i64 = 0;
    for (state.items) |c| {
        sum += c.area();
    }

    return sum;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}

test "examples" {
    defer _ = gpa_impl.deinit();
    var a = intersect1(Range{ 1, 5 }, Range{ 6, 10 });
    try std.testing.expect(a == null);

    a = intersect1(Range{ 6, 10 }, Range{ 1, 5 });
    try std.testing.expect(a == null);

    a = intersect1(Range{ 1, 5 }, Range{ 4, 10 });
    try std.testing.expect(a.?[0] == 4);
    try std.testing.expect(a.?[1] == 5);

    a = intersect1(Range{ 4, 10 }, Range{ 1, 5 });
    try std.testing.expect(a.?[0] == 4);
    try std.testing.expect(a.?[1] == 5);

    a = intersect1(Range{ 1, 5 }, Range{ 5, 10 });
    try std.testing.expect(a.?[0] == 5);
    try std.testing.expect(a.?[1] == 5);

    a = intersect1(Range{ 5, 10 }, Range{ 1, 5 });
    try std.testing.expect(a.?[0] == 5);
    try std.testing.expect(a.?[1] == 5);

    a = intersect1(Range{ 1, 10 }, Range{ 5, 6 });
    try std.testing.expect(a.?[0] == 5);
    try std.testing.expect(a.?[1] == 6);

    a = intersect1(Range{ 5, 6 }, Range{ 1, 10 });
    try std.testing.expect(a.?[0] == 5);
    try std.testing.expect(a.?[1] == 6);

    const text = @embedFile("../test");
    try std.testing.expectEqual(try p1(text), 474140);
    try std.testing.expectEqual(try p2(text), 2758514936282235);
}
