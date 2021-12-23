const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const AHashMap = std.AutoArrayHashMap;
const PQ = std.PriorityQueue;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

const stdin = std.io.getStdIn();

// var alloc = std.heap.GeneralPurposeAllocator(.{}){};
var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = alloc.allocator();

const Vec2 = [2]i8;
const Tile = enum {
    Wall,
    Empty,
    A,
    B,
    C,
    D,
};

const TileMap = AutoHashMap(Vec2, Tile);
const PosMap = AutoHashMap(Vec2, Tile);

const Pod = struct {
    pos: Vec2,
    pod_type: Tile,

    fn new(p: Vec2, t: Tile) Pod {
        assert(t != Tile.Wall);
        assert(t != Tile.Empty);

        return Pod{ .pos = p, .pod_type = t };
    }

    fn inRoom(self: *const Pod, tile_map: *const TileMap) bool {
        const tile = tile_map.get(self.pos).?;
        switch (tile) {
            Tile.A, Tile.B, Tile.C, Tile.D => return true,
            else => return false,
        }
    }

    fn inSelfRoom(self: *const Pod, tile_map: *const TileMap) bool {
        const tile = tile_map.get(self.pos).?;
        return tile == self.pod_type;
    }

    fn canLeaveRoom(self: *const Pod, tile_map: *const TileMap, pod_list: []Pod) bool {
        // hw above is empty
        const hw = Vec2{ self.pos[0], 1 };
        if (!isEmpty(tile_map, pod_list, hw, 20)) {
            return false;
        }

        // up is empty
        const u = up(self.pos);
        if (!isEmpty(tile_map, pod_list, u, 20)) {
            return false;
        }

        // not in our room and above is empty, leave
        if (!self.inSelfRoom(tile_map)) return true;

        // check down if we're in our room
        var dpos = down(self.pos);
        while (tile_map.get(dpos).? != Tile.Wall) : (dpos = down(dpos)) {
            assert(tile_map.get(dpos).? == self.pod_type);

            const other = getPod(pod_list, dpos).?;
            if (other != self.pod_type) {
                // we're in our room, but non-matching below
                return true;
            }
        }

        return false;
    }

    fn getCost(self: *const Pod) i32 {
        switch (self.pod_type) {
            Tile.A => return 1,
            Tile.B => return 10,
            Tile.C => return 100,
            Tile.D => return 1000,
            else => unreachable,
        }
    }
};

fn setRooms(tile_map: *TileMap, numpod: usize) !void {
    var gop = try tile_map.getOrPut(.{ 3, 2 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.A;

    gop = try tile_map.getOrPut(.{ 3, 3 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.A;

    if (numpod == 16) {
        gop = try tile_map.getOrPut(.{ 3, 4 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.A;

        gop = try tile_map.getOrPut(.{ 3, 5 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.A;
    }

    gop = try tile_map.getOrPut(.{ 5, 2 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.B;

    gop = try tile_map.getOrPut(.{ 5, 3 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.B;

    if (numpod == 16) {
        gop = try tile_map.getOrPut(.{ 5, 4 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.B;

        gop = try tile_map.getOrPut(.{ 5, 5 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.B;
    }

    gop = try tile_map.getOrPut(.{ 7, 2 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.C;

    gop = try tile_map.getOrPut(.{ 7, 3 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.C;

    if (numpod == 16) {
        gop = try tile_map.getOrPut(.{ 7, 4 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.C;

        gop = try tile_map.getOrPut(.{ 7, 5 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.C;
    }

    gop = try tile_map.getOrPut(.{ 9, 2 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.D;

    gop = try tile_map.getOrPut(.{ 9, 3 });
    assert(gop.found_existing);
    assert(gop.value_ptr.* == Tile.Empty);
    gop.value_ptr.* = Tile.D;

    if (numpod == 16) {
        gop = try tile_map.getOrPut(.{ 9, 4 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.D;

        gop = try tile_map.getOrPut(.{ 9, 5 });
        assert(gop.found_existing);
        assert(gop.value_ptr.* == Tile.Empty);
        gop.value_ptr.* = Tile.D;
    }
}

fn getPod(pod_list: []const Pod, p: Vec2) ?Tile {
    for (pod_list) |other| {
        if (mem.eql(i8, p[0..], other.pos[0..])) return other.pod_type;
    }

    return null;
}

fn prTile(tile_map: *const TileMap, pod_list: []Pod) void {
    var y: i8 = 0;
    while (y < 7) : (y += 1) {
        var x: i8 = 0;
        while (x < 13) : (x += 1) {
            const po = getPod(pod_list, .{ x, y });
            const t = tile_map.get(.{ x, y }) orelse Tile.Wall;
            const ct: u8 = switch (t) {
                Tile.A => '.',
                Tile.B => '.',
                Tile.C => '.',
                Tile.D => '.',
                Tile.Wall => '#',
                Tile.Empty => '.',
            };
            if (po) |p| {
                const tmp: u8 = switch (p) {
                    Tile.A => 'A',
                    Tile.B => 'B',
                    Tile.C => 'C',
                    Tile.D => 'D',
                    else => unreachable,
                };
                print("{c}", .{tmp});
            } else {
                print("{c}", .{ct});
            }
        }
        print("\n", .{});
    }
}

const SC = struct {
    state: []Pod,
    energy: i32,
};

fn compSc(_: void, a: SC, b: SC) std.math.Order {
    return std.math.order(a.energy, b.energy);
}

fn isEmpty(tile_map: *const TileMap, pod_list: []const Pod, p: Vec2, idx: usize) bool {
    // Check wall
    const tile = tile_map.get(p) orelse Tile.Wall;
    if (tile == Tile.Wall) return false;

    // Check other pods
    for (pod_list) |other, i| {
        if (idx == i) continue;
        if (mem.eql(i8, p[0..], other.pos[0..])) return false;
    }

    return true;
}

fn right(p: Vec2) Vec2 {
    return Vec2{ p[0] + 1, p[1] };
}

fn left(p: Vec2) Vec2 {
    return Vec2{ p[0] - 1, p[1] };
}

fn down(p: Vec2) Vec2 {
    return Vec2{ p[0], p[1] + 1 };
}

fn up(p: Vec2) Vec2 {
    return Vec2{ p[0], p[1] - 1 };
}

fn getPossibleHallway(tile_map: *const TileMap, pod_list: []const Pod, idx: usize) [11]?Vec2 {
    var ret: [11]?Vec2 = [_]?Vec2{null} ** 11;
    const pod = &pod_list[idx];

    assert(pod.inRoom(tile_map));

    // if (pod.pos[1] == 3) {
    {
        const u = up(pod.pos);
        assert(isEmpty(tile_map, pod_list, u, idx));
    }

    var cnt: usize = 0;
    var pos = Vec2{ pod.pos[0], 1 };
    while (isEmpty(tile_map, pod_list, pos, idx)) : (pos = right(pos)) {
        const d = down(pos);
        if (tile_map.get(d).? != Tile.Wall) continue;
        ret[cnt] = pos;
        cnt += 1;
    }

    pos = Vec2{ pod.pos[0] - 1, 1 };
    while (isEmpty(tile_map, pod_list, pos, idx)) : (pos = left(pos)) {
        const d = down(pos);
        if (tile_map.get(d).? != Tile.Wall) continue;
        ret[cnt] = pos;
        cnt += 1;
    }

    return ret;
}

fn getRoomPath(tile_map: *const TileMap, pod_list: []const Pod, idx: usize) ?Vec2 {
    const pod = &pod_list[idx];

    assert(!pod.inRoom(tile_map));

    var pos = pod.pos;
    while (isEmpty(tile_map, pod_list, pos, idx)) : (pos = right(pos)) {
        var dpos = down(pos);
        if (tile_map.get(dpos).? == pod.pod_type) {
            var last_empty: ?Vec2 = null;
            while (isEmpty(tile_map, pod_list, dpos, idx)) : (dpos = down(dpos)) {
                last_empty = dpos;
            }
            if (last_empty) |empty| {
                var all_same = true;
                dpos = down(empty);
                while (tile_map.get(dpos).? != Tile.Wall) : (dpos = down(dpos)) {
                    if (getPod(pod_list, dpos)) |other| {
                        if (other != pod.pod_type) {
                            all_same = false;
                            break;
                        }
                    }
                }
                if (all_same) {
                    return empty;
                }
            }
        }
    }

    pos = left(pod.pos);
    while (isEmpty(tile_map, pod_list, pos, idx)) : (pos = left(pos)) {
        var dpos = down(pos);
        if (tile_map.get(dpos).? == pod.pod_type) {
            var last_empty: ?Vec2 = null;
            while (isEmpty(tile_map, pod_list, dpos, idx)) : (dpos = down(dpos)) {
                last_empty = dpos;
            }
            if (last_empty) |empty| {
                var all_same = true;
                dpos = down(empty);
                while (tile_map.get(dpos).? != Tile.Wall) : (dpos = down(dpos)) {
                    if (getPod(pod_list, dpos)) |other| {
                        if (other != pod.pod_type) {
                            all_same = false;
                            break;
                        }
                    }
                }
                if (all_same) {
                    return empty;
                }
            }
        }
    }

    return null;
}

fn mDist(a: Vec2, b: Vec2) !i8 {
    const x = try math.absInt(a[0] - b[0]);
    const y = try math.absInt(a[1] - b[1]);
    return x + y;
}

fn ucs(tile_map: *TileMap, init_list: []const Pod, comptime numpod: usize) !i32 {
    var frontier = PQ(SC, void, compSc).init(allocator, {});
    defer frontier.deinit();

    var visited = AutoHashMap([numpod]Pod, i32).init(allocator);
    defer visited.deinit();
    defer while (frontier.removeOrNull()) |cur| allocator.free(cur.state);

    try frontier.add(SC{ .state = try allocator.dupe(Pod, init_list), .energy = 0 });

    while (frontier.removeOrNull()) |cur| {
        var cur_energy = cur.energy;
        defer allocator.free(cur.state);

        const hash = cur.state[0..numpod].*;
        try visited.put(hash, cur_energy);

        if (isCorrect(cur.state, tile_map)) {
            return cur.energy;
        }

        for (cur.state) |pod, i| {
            if (pod.canLeaveRoom(tile_map, cur.state)) {
                const dests = getPossibleHallway(tile_map, cur.state, i);

                for (dests) |desto| {
                    if (desto) |dest| {
                        const m_dist = try mDist(dest, pod.pos);
                        const new_energy = cur_energy + (m_dist * pod.getCost());
                        const new_state = try allocator.dupe(Pod, cur.state);

                        new_state[i].pos = dest;
                        assert(!new_state[i].inRoom(tile_map));
                        const hashn = new_state[0..numpod].*;

                        if (visited.get(hashn)) |old_c| {
                            if (old_c > new_energy) {
                                try frontier.add(SC{ .state = new_state, .energy = new_energy });
                                try visited.put(hashn, new_energy);
                            } else {
                                // ayy lmao C
                                allocator.free(new_state);
                            }
                        } else {
                            try frontier.add(SC{ .state = new_state, .energy = new_energy });
                            try visited.put(hashn, new_energy);
                        }
                    }
                }
            } else if (!pod.inRoom(tile_map)) {
                const desto = getRoomPath(tile_map, cur.state, i);
                if (desto) |dest| {
                    const new_state = try allocator.dupe(Pod, cur.state);
                    const m_dist = try mDist(dest, pod.pos);
                    const new_energy = cur_energy + (m_dist * pod.getCost());

                    assert(isEmpty(tile_map, cur.state, .{ dest[0], 1 }, i));

                    new_state[i].pos = dest;

                    assert(new_state[i].inSelfRoom(tile_map));
                    const hashn = new_state[0..numpod].*;

                    if (visited.get(hashn)) |old_c| {
                        if (old_c > new_energy) {
                            try frontier.add(SC{ .state = new_state, .energy = new_energy });
                            try visited.put(hashn, new_energy);
                        } else {
                            // ayy lmao C
                            allocator.free(new_state);
                        }
                    } else {
                        try frontier.add(SC{ .state = new_state, .energy = new_energy });
                        try visited.put(hashn, new_energy);
                    }
                }
            }
        }
    }

    unreachable;
}

fn core(text: Str, comptime numpods: usize) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var tile_map = TileMap.init(allocator);
    defer tile_map.deinit();

    var pod_list = ArrayList(Pod).init(allocator);
    defer pod_list.deinit();

    var y: i8 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i8 = 0;
        for (line) |c| {
            const tile = switch (c) {
                '#', ' ' => Tile.Wall,
                '.', 'A', 'B', 'C', 'D' => Tile.Empty,
                else => unreachable,
            };

            const pod_t = switch (c) {
                'A' => Tile.A,
                'B' => Tile.B,
                'C' => Tile.C,
                'D' => Tile.D,
                else => null,
            };

            if (pod_t) |p| {
                const pod = Pod.new(.{ x, y }, p);
                try pod_list.append(pod);
            }

            try tile_map.put(.{ x, y }, tile);
            x += 1;
        }
    }

    try setRooms(&tile_map, numpods);

    var ret = try ucs(&tile_map, pod_list.items, numpods);

    return ret;
}

fn isCorrect(pod_list: []Pod, tile_map: *TileMap) bool {
    for (pod_list) |pod| {
        if (!pod.inSelfRoom(tile_map)) {
            return false;
        }
    }
    return true;
}

pub fn main() anyerror!void {
    defer _ = alloc.deinit();
    const text = @embedFile("../input");
    print("Part 1: {}\n", .{try core(text, 8)});
    const text2 = @embedFile("../input2");
    print("Part 2: {}\n", .{try core(text2, 16)});
}

test "examples" {
    defer _ = alloc.deinit();
    const text = @embedFile("../test");
    try std.testing.expectEqual(try core(text, 8), 12521);
    const text2 = @embedFile("../test2");
    try std.testing.expectEqual(try core(text2, 16), 44169);
}
