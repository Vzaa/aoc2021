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

const Vec2 = [2]u32;
const CMap = AutoHashMap(Vec2, u8);

fn p1(text: Str) !u32 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var cmap = CMap.init(gpa);
    defer cmap.deinit();

    var y: u32 = 0;
    var x: u32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        x = 0;
        for (line) |c| {
            if ((c) == '.') {
                x += 1;
                continue;
            }
            try cmap.put(.{ x, y }, c);
            x += 1;
        }
    }

    var step: u32 = 1;
    while (true) : (step += 1) {
        var next = CMap.init(gpa);
        var done = true;

        var kiter = cmap.keyIterator();
        while (kiter.next()) |k| {
            const v = cmap.get(k.*).?;
            if (v == '>') {
                const np = Vec2{ (k.*[0] + 1) % x, k.*[1] };
                if (!cmap.contains(np)) {
                    try next.put(np, v);
                    done = false;
                } else {
                    try next.put(k.*, v);
                }
            } else {
                try next.put(k.*, v);
            }
        }
        cmap.clearAndFree();
        cmap = next;
        next = CMap.init(gpa);

        kiter = cmap.keyIterator();
        while (kiter.next()) |k| {
            const v = cmap.get(k.*).?;
            if (v == 'v') {
                const np = Vec2{ k.*[0], (k.*[1] + 1) % y };
                if (!cmap.contains(np)) {
                    try next.put(np, v);
                    done = false;
                } else {
                    try next.put(k.*, v);
                }
            } else {
                try next.put(k.*, v);
            }
        }
        cmap.clearAndFree();
        cmap = next;

        if (done) {
            break;
        }
    }

    return step;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../input");
    print("Part 1: {}\n", .{try p1(text)});
}

test "examples" {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../test");
    try std.testing.expectEqual(try p1(text), 58);
}
