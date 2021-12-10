const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const mem = std.mem;
const math = std.math;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

fn p1(text: []const u8) !i64 {
    var line_iter = mem.tokenize(u8, text, "\n");

    const open = "([{<";
    const close = ")]}>";

    var stack = ArrayList(u8).init(gpa);
    defer stack.deinit();

    var score: i64 = 0;

    while (line_iter.next()) |line| {
        stack.clearRetainingCapacity();
        for (line) |c| {
            if (mem.indexOfScalar(u8, open, c)) |_| {
                try stack.append(c);
            } else {
                var idx = mem.indexOfScalar(u8, close, c).?;
                const matching_open = open[idx];
                const last = stack.pop();
                if (last != matching_open) {
                    switch (c) {
                        ')' => {
                            score += 3;
                        },
                        ']' => {
                            score += 57;
                        },
                        '}' => {
                            score += 1197;
                        },
                        '>' => {
                            score += 25137;
                        },
                        else => {
                            unreachable;
                        },
                    }
                }
            }
        }
    }
    return score;
}

fn p2(text: []const u8) !i64 {
    var line_iter = mem.tokenize(u8, text, "\n");

    const open = "([{<";
    const close = ")]}>";

    var scores = ArrayList(i64).init(gpa);
    defer scores.deinit();

    var stack = ArrayList(u8).init(gpa);
    defer stack.deinit();

    outer: while (line_iter.next()) |line| {
        stack.clearRetainingCapacity();

        for (line) |c| {
            if (mem.indexOfScalar(u8, open, c)) |_| {
                try stack.append(c);
            } else {
                var idx = mem.indexOfScalar(u8, close, c).?;
                const matching_open = open[idx];
                const last = stack.pop();
                if (last != matching_open) {
                    continue :outer;
                }
            }
        }

        stack.clearRetainingCapacity();

        for (line) |c| {
            if (mem.indexOfScalar(u8, open, c)) |_| {
                try stack.append(c);
            } else {
                _ = stack.pop();
            }
        }

        var score: i64 = 0;

        while (stack.popOrNull()) |c| {
            score *= 5;

            switch (c) {
                '(' => {
                    score += 1;
                },
                '[' => {
                    score += 2;
                },
                '{' => {
                    score += 3;
                },
                '<' => {
                    score += 4;
                },
                else => {
                    unreachable;
                },
            }
        }
        try scores.append(score);
    }

    std.sort.sort(i64, scores.items, {}, comptime std.sort.asc(i64));
    return scores.items[scores.items.len / 2];
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
    try std.testing.expectEqual(p1(text), 26397);
    try std.testing.expectEqual(p2(text), 288957);
}
