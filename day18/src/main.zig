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

const D18Error = error{
    BufEmpty,
};

const Node = union(enum) {
    pair: *Pair,
    num: u64,
};

const Pair = struct {
    left: Node,
    right: Node,

    fn deinit(self: *Pair) void {
        switch (self.left) {
            Node.num => {},
            Node.pair => |c| c.deinit(),
        }

        switch (self.right) {
            Node.num => {},
            Node.pair => |c| c.deinit(),
        }

        gpa.destroy(self);
    }

    fn fromRdr(rdr: *Reader) anyerror!*Pair {
        var p: *Pair = try gpa.create(Pair);
        var c = try rdr.next();

        assert(c == '[');

        c = try rdr.peek();
        if (c != '[') {
            c = try rdr.next();
            const v = try std.fmt.charToDigit(c, 10);
            p.left = Node{ .num = v };
        } else {
            const pair = try Pair.fromRdr(rdr);
            p.left = Node{ .pair = pair };
        }

        c = try rdr.next();
        assert(c == ',');

        c = try rdr.peek();
        if (c != '[') {
            c = try rdr.next();
            const v = try std.fmt.charToDigit(c, 10);
            p.right = Node{ .num = v };
        } else {
            const pair = try Pair.fromRdr(rdr);
            p.right = Node{ .pair = pair };
        }

        c = try rdr.next();
        assert(c == ']');

        return p;
    }

    fn numPair(a: u64, b: u64) !*Pair {
        var p: *Pair = try gpa.create(Pair);
        p.left = Node{ .num = a };
        p.right = Node{ .num = b };
        return p;
    }

    fn magnitude(self: *Pair) u64 {
        var l: u64 = undefined;
        var r: u64 = undefined;

        switch (self.left) {
            Node.pair => |c| l = c.magnitude(),
            Node.num => |n| l = n,
        }

        switch (self.right) {
            Node.pair => |c| r = c.magnitude(),
            Node.num => |n| r = n,
        }

        return (3 * l) + (2 * r);
    }
};

const Reader = struct {
    txt: Str,
    ptr: usize,

    fn fromDat(t: Str) Reader {
        return Reader{ .txt = t, .ptr = 0 };
    }

    fn peek(self: *Reader) !u8 {
        return self.txt[self.ptr];
    }

    fn next(self: *Reader) !u8 {
        var ptr_old = self.ptr;
        self.ptr += 1;
        if (self.ptr > self.txt.len) {
            return D18Error.BufEmpty;
        }

        return self.txt[ptr_old];
    }
};

fn add(a: *Pair, b: *Pair) !*Pair {
    var p: *Pair = try gpa.create(Pair);
    p.left = Node{ .pair = a };
    p.right = Node{ .pair = b };
    return p;
}

fn indexNums(p: *Pair, index: *ArrayList(*u64)) anyerror!void {
    switch (p.left) {
        Node.num => |*n| try index.append(n),
        Node.pair => |c| try indexNums(c, index),
    }

    switch (p.right) {
        Node.num => |*n| try index.append(n),
        Node.pair => |c| try indexNums(c, index),
    }
}

fn explode(p: *Pair, depth: usize, index: *ArrayList(*u64), i: *i32) bool {
    switch (p.left) {
        Node.pair => |c| {
            if (depth == 3) {
                const l: u64 = c.left.num;
                const r: u64 = c.right.num;
                if (i.* >= 0) {
                    index.items[@intCast(usize, i.*)].* += l;
                }

                if (i.* + 3 < index.items.len) {
                    index.items[@intCast(usize, i.* + 3)].* += r;
                }

                c.deinit();
                p.left = Node{ .num = 0 };
                return true;
            } else {
                if (explode(c, depth + 1, index, i)) return true;
            }
        },
        Node.num => |_| {
            i.* += 1;
        },
    }

    switch (p.right) {
        Node.pair => |c| {
            if (depth == 3) {
                const l: u64 = c.left.num;
                const r: u64 = c.right.num;
                if (i.* >= 0) {
                    index.items[@intCast(usize, i.*)].* += l;
                }

                if (i.* + 3 < index.items.len) {
                    index.items[@intCast(usize, i.* + 3)].* += r;
                }

                c.deinit();
                p.right = Node{ .num = 0 };
                return true;
            } else {
                if (explode(c, depth + 1, index, i)) return true;
            }
        },
        Node.num => |_| {
            i.* += 1;
        },
    }

    return false;
}

fn split(p: *Pair) anyerror!bool {
    switch (p.left) {
        Node.pair => |c| {
            if (try split(c)) return true;
        },
        Node.num => |n| {
            if (n > 9) {
                const a = @divFloor(n, 2);
                const b = if (n % 2 == 0) n / 2 else (n / 2) + 1;
                p.left = Node{ .pair = try Pair.numPair(a, b) };
                return true;
            }
        },
    }

    switch (p.right) {
        Node.pair => |c| {
            if (try split(c)) return true;
        },
        Node.num => |n| {
            if (n > 9) {
                const a = @divFloor(n, 2);
                const b = if (n % 2 == 0) n / 2 else (n / 2) + 1;
                p.right = Node{ .pair = try Pair.numPair(a, b) };
                return true;
            }
        },
    }

    return false;
}

fn p1(text: Str) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var first = line_iter.next().?;
    var rdr = Reader.fromDat(first);

    var sum = try Pair.fromRdr(&rdr);
    defer sum.deinit();

    while (line_iter.next()) |line| {
        rdr = Reader.fromDat(line);
        var pair = try Pair.fromRdr(&rdr);

        sum = try add(sum, pair);

        var index = ArrayList(*u64).init(gpa);
        defer index.deinit();

        while (true) {
            index.clearRetainingCapacity();
            try indexNums(sum, &index);

            var j: i32 = -1;
            const exp = explode(sum, 0, &index, &j);
            if (exp) {
                continue;
            }

            const spl = try split(sum);
            if (spl) {
                continue;
            }

            break;
        }
    }

    return sum.magnitude();
}

fn p2(text: Str) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var lines = ArrayList(Str).init(gpa);
    defer lines.deinit();

    while (line_iter.next()) |line| {
        try lines.append(line);
    }

    var maxm: u64 = 0;

    for (lines.items) |line_a, la| {
        for (lines.items) |line_b, lb| {
            if (la == lb) {
                continue;
            }
            var rdr = Reader.fromDat(line_a);
            var a = try Pair.fromRdr(&rdr);

            rdr = Reader.fromDat(line_b);
            var b = try Pair.fromRdr(&rdr);

            var sum = try add(a, b);
            defer sum.deinit();

            var index = ArrayList(*u64).init(gpa);
            defer index.deinit();

            while (true) {
                index.clearRetainingCapacity();
                try indexNums(sum, &index);

                var j: i32 = -1;
                const exp = explode(sum, 0, &index, &j);
                if (exp) {
                    continue;
                }

                const spl = try split(sum);
                if (spl) {
                    continue;
                }
                break;
            }

            maxm = math.max(maxm, sum.magnitude());
        }
    }
    return maxm;
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
    try std.testing.expectEqual(p1(text), 4140);
    try std.testing.expectEqual(p2(text), 3993);
}
