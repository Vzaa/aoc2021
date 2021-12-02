const std = @import("std");
const mem = std.mem;

const D2Errors = error{
    InvalidDir,
};

const Dir = enum {
    Up,
    Down,
    Forward,

    fn fromStr(s: []const u8) !Dir {
        if (mem.eql(u8, s, "up")) {
            return Dir.Up;
        } else if (mem.eql(u8, s, "down")) {
            return Dir.Down;
        } else if (mem.eql(u8, s, "forward")) {
            return Dir.Forward;
        } else {
            return D2Errors.InvalidDir;
        }
    }
};

const Vec2 = struct {
    x: i32 = 0,
    y: i32 = 0,

    fn fromDir(d: Dir, v: i32) Vec2 {
        switch (d) {
            Dir.Up => return Vec2{ .x = 0, .y = -v },
            Dir.Down => return Vec2{ .x = 0, .y = v },
            Dir.Forward => return Vec2{ .x = v, .y = 0 },
        }
    }

    fn add(self: *Vec2, d: *const Vec2) void {
        self.x += d.x;
        self.y += d.y;
    }

    fn mul(self: *Vec2, v: i32) void {
        self.x *= v;
        self.y *= v;
    }
};

fn p1(text: []const u8) !i32 {
    var pos: Vec2 = .{};
    var line_iter = std.mem.tokenize(u8, text, "\n");

    while (line_iter.next()) |line| {
        var tokens_iter = std.mem.tokenize(u8, line, " ");
        const dir = try Dir.fromStr(tokens_iter.next().?);
        const num = try std.fmt.parseInt(i32, tokens_iter.next().?, 10);
        var d = Vec2.fromDir(dir, num);
        pos.add(&d);
    }

    return pos.x * pos.y;
}

fn p2(text: []const u8) !i32 {
    var pos: Vec2 = .{};
    var aim: Vec2 = .{};
    var line_iter = std.mem.tokenize(u8, text, "\n");

    while (line_iter.next()) |line| {
        var tokens_iter = std.mem.tokenize(u8, line, " ");
        const dir = try Dir.fromStr(tokens_iter.next().?);
        const num = try std.fmt.parseInt(i32, tokens_iter.next().?, 10);
        var d = Vec2.fromDir(dir, num);

        switch (dir) {
            Dir.Up => aim.add(&d),
            Dir.Down => aim.add(&d),
            Dir.Forward => {
                pos.add(&d);
                var d2 = aim;
                d2.mul(num);
                pos.add(&d2);
            },
        }
    }

    return pos.x * pos.y;
}

pub fn main() anyerror!void {
    const text = @embedFile("../input");
    std.debug.print("Part 1: {}\n", .{p1(text)});
    std.debug.print("Part 2: {}\n", .{p2(text)});
}

test "examples" {
    const text = @embedFile("../test");
    try std.testing.expectEqual(p1(text), 150);
    try std.testing.expectEqual(p2(text), 900);
}

test "types" {
    var pos = Vec2.fromDir(Dir.Up, 42);
    try std.testing.expectEqual(pos.x, 0);
    try std.testing.expectEqual(pos.y, -42);

    var d = Dir.fromStr("up");
    try std.testing.expectEqual(d, Dir.Up);

    d = Dir.fromStr("foo");
    try std.testing.expectEqual(d, D2Errors.InvalidDir);
}
