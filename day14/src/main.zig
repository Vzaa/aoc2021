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

const Rules = std.StringHashMap(u8);

const Pair = [2]u8;
const PolymerMap = std.AutoHashMap(Pair, usize);

fn p1(text: Str) !usize {
    var line_iter = mem.split(u8, text, "\n");

    var polymer = ArrayList(u8).init(gpa);
    defer polymer.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        for (line) |c| {
            try polymer.append(c);
        }
    }

    var rules = Rules.init(gpa);
    defer rules.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var eq_iter = mem.split(u8, line, " -> ");
        const in = eq_iter.next().?;
        const out = eq_iter.next().?;

        try rules.put(in, out[0]);
    }

    var cnt: usize = 0;
    while (cnt < 10) : (cnt += 1) {
        var new_polymer = ArrayList(u8).init(gpa);

        var i: usize = 0;
        while (i < polymer.items.len - 1) : (i += 1) {
            var pair = polymer.items[i..(i + 2)];
            const n = rules.get(pair).?;
            try new_polymer.append(polymer.items[i]);
            try new_polymer.append(n);
        }
        try new_polymer.append(polymer.items[polymer.items.len - 1]);

        polymer.clearAndFree();
        polymer = new_polymer;
    }

    var counter = AutoHashMap(u8, usize).init(gpa);
    defer counter.deinit();

    for (polymer.items) |c| {
        var gop = try counter.getOrPut(c);
        if (gop.found_existing) {
            gop.value_ptr.* += 1;
        } else {
            gop.value_ptr.* = 1;
        }
    }

    var kiter = counter.keyIterator();
    var min: usize = math.maxInt(usize);
    var max: usize = 0;

    while (kiter.next()) |k| {
        const v = counter.get(k.*).?;
        min = math.min(min, v);
        max = math.max(max, v);
    }

    return max - min;
}

fn p2(text: Str) !usize {
    var line_iter = mem.split(u8, text, "\n");
    var last_char: u8 = undefined;

    var polymer = PolymerMap.init(gpa);
    defer polymer.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var i: usize = 0;

        while (i < line.len - 1) : (i += 1) {
            var pair = line[i..(i + 2)];

            var gop = try polymer.getOrPut(.{ pair[0], pair[1] });
            if (gop.found_existing) {
                gop.value_ptr.* += 1;
            } else {
                gop.value_ptr.* = 1;
            }
        }

        last_char = line[line.len - 1];
    }

    var rules = Rules.init(gpa);
    defer rules.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var eq_iter = mem.split(u8, line, " -> ");
        const in = eq_iter.next().?;
        const out = eq_iter.next().?;

        try rules.put(in, out[0]);
    }

    var cnt: usize = 0;
    while (cnt < 40) : (cnt += 1) {
        var new_polymer = PolymerMap.init(gpa);
        var kiter = polymer.keyIterator();

        while (kiter.next()) |k| {
            const pair = k.*;
            const out = rules.get(pair[0..]).?;

            const p_cnt = polymer.get(pair).?;

            const new_pair_a = [2]u8{ pair[0], out };
            const new_pair_b = [2]u8{ out, pair[1] };

            var gop = try new_polymer.getOrPut(new_pair_a);
            if (gop.found_existing) {
                gop.value_ptr.* += p_cnt;
            } else {
                gop.value_ptr.* = p_cnt;
            }

            gop = try new_polymer.getOrPut(new_pair_b);
            if (gop.found_existing) {
                gop.value_ptr.* += p_cnt;
            } else {
                gop.value_ptr.* = p_cnt;
            }
        }

        polymer.clearAndFree();
        polymer = new_polymer;
    }

    var counter = AutoHashMap(u8, usize).init(gpa);
    defer counter.deinit();

    var kiter = polymer.keyIterator();
    while (kiter.next()) |k| {
        const p_cnt = polymer.get(k.*).?;

        var gop = try counter.getOrPut(k.*[0]);
        if (gop.found_existing) {
            gop.value_ptr.* += p_cnt;
        } else {
            gop.value_ptr.* = p_cnt;
        }
    }
    counter.getPtr(last_char).?.* += 1;

    var citer = counter.keyIterator();
    var min: usize = math.maxInt(usize);
    var max: usize = 0;

    while (citer.next()) |k| {
        const v = counter.get(k.*).?;
        min = math.min(min, v);
        max = math.max(max, v);
    }

    return max - min;
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
    try std.testing.expectEqual(p1(text), 1588);
    try std.testing.expectEqual(p2(text), 2188189693529);
}
