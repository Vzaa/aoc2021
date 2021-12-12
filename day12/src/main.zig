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

const NodeSet = std.StringHashMap(void);
const EdgeMap = std.StringHashMap(NodeSet);

const NodeSetCnt = std.StringHashMap(i32);

fn findPaths(edges: *const EdgeMap, visited: *const NodeSet, cur: Str, cnt: *usize) void {
    if (mem.eql(u8, cur, "end")) {
        cnt.* += 1;
        return;
    }

    const dests = edges.get(cur).?;

    var new_visited = visited.clone() catch unreachable;
    defer new_visited.deinit();

    const big = std.ascii.isUpper(cur[0]);

    if (!big) {
        new_visited.put(cur, {}) catch {};
    }

    var diter = dests.keyIterator();

    while (diter.next()) |dest| {
        if (!new_visited.contains(dest.*)) {
            findPaths(edges, &new_visited, dest.*, cnt);
        }
    }
}

// This is terrible but it was the quickest hack I came up with
fn findPaths2(edges: *const EdgeMap, visited: *const NodeSetCnt, cur: Str, cnt: *usize) void {
    if (mem.eql(u8, cur, "end")) {
        cnt.* += 1;
        return;
    }

    const dests = edges.get(cur).?;

    var new_visited = visited.clone() catch unreachable;
    defer new_visited.deinit();

    const big = std.ascii.isUpper(cur[0]);

    if (!big) {
        // LOL
        var gop = new_visited.getOrPut(cur) catch unreachable;
        if (gop.found_existing) {
            gop.value_ptr.* += 1;
        } else {
            gop.value_ptr.* = 0;
        }
    }

    // LOL
    var sum: i32 = 0;
    var viter = new_visited.valueIterator();
    while (viter.next()) |v| {
        sum += v.*;
        if (sum > 1) return;
    }

    var diter = dests.keyIterator();

    while (diter.next()) |dest| {
        if (!mem.eql(u8, dest.*, "start")) {
            findPaths2(edges, &new_visited, dest.*, cnt);
        }
    }
}

fn p1(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var edges = EdgeMap.init(gpa);
    defer edges.deinit();
    defer {
        var viter = edges.valueIterator();
        while (viter.next()) |v| {
            v.deinit();
        }
    }

    while (line_iter.next()) |line| {
        var iter = mem.tokenize(u8, line, "-");
        var u = iter.next().?;
        var v = iter.next().?;

        var gop_u = try edges.getOrPut(u);
        if (!gop_u.found_existing) {
            gop_u.value_ptr.* = NodeSet.init(gpa);
        }
        try gop_u.value_ptr.put(v, {});

        var gop_v = try edges.getOrPut(v);
        if (!gop_v.found_existing) {
            gop_v.value_ptr.* = NodeSet.init(gpa);
        }
        try gop_v.value_ptr.put(u, {});
    }

    // Kinda silly
    var visited = NodeSet.init(gpa);
    defer visited.deinit();

    var cnt: usize = 0;
    findPaths(&edges, &visited, "start", &cnt);

    return cnt;
}

fn p2(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var edges = EdgeMap.init(gpa);
    defer edges.deinit();
    defer {
        var viter = edges.valueIterator();
        while (viter.next()) |v| {
            v.deinit();
        }
    }

    while (line_iter.next()) |line| {
        var iter = mem.tokenize(u8, line, "-");
        var u = iter.next().?;
        var v = iter.next().?;

        var gop_u = try edges.getOrPut(u);
        if (!gop_u.found_existing) {
            gop_u.value_ptr.* = NodeSet.init(gpa);
        }
        try gop_u.value_ptr.put(v, {});

        var gop_v = try edges.getOrPut(v);
        if (!gop_v.found_existing) {
            gop_v.value_ptr.* = NodeSet.init(gpa);
        }
        try gop_v.value_ptr.put(u, {});
    }

    // Kinda silly
    var visited = NodeSetCnt.init(gpa);
    defer visited.deinit();

    var cnt: usize = 0;

    findPaths2(&edges, &visited, "start", &cnt);

    return cnt;
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
    try std.testing.expectEqual(p1(text), 10);
    try std.testing.expectEqual(p2(text), 36);
}
