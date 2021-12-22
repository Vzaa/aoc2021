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

const DDice = struct {
    cur: u32 = 1,
    roll_cnt: u32 = 0,

    fn next3(self: *DDice) [3]u32 {
        var ret: [3]u32 = undefined;

        ret[0] = self.cur;

        self.cur += 1;
        self.cur = ((self.cur - 1) % 100) + 1;
        ret[1] = self.cur;

        self.cur += 1;
        self.cur = ((self.cur - 1) % 100) + 1;
        ret[2] = self.cur;

        self.cur += 1;
        self.cur = ((self.cur - 1) % 100) + 1;

        self.roll_cnt += 3;

        return ret;
    }
};

const Player = struct {
    score: u32 = 0,
    pos: u32,

    fn new(pos: u32) Player {
        return Player{ .pos = pos };
    }

    fn move(self: *Player, total: u32) u32 {
        self.pos += total;
        self.pos = ((self.pos - 1) % 10) + 1;
        self.score += self.pos;
        return self.score;
    }
};

const Game = struct {
    players: [2]Player,

    fn new(pos1: u32, pos2: u32) Game {
        var ret: Game = undefined;
        ret.players[0] = Player.new(pos1);
        ret.players[1] = Player.new(pos2);
        return ret;
    }

    fn from(self: *Game, move: u32, player: usize) Game {
        var ret: Game = self.*;
        _ = ret.players[player].move(move);
        return ret;
    }

    fn over(self: *Game) bool {
        return self.players[0].score >= 21 or self.players[1].score >= 21;
    }
};

fn p1(text: Str) !u32 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var line = line_iter.next().?;
    var tok_iter = mem.split(u8, line, ": ");
    var tmp = tok_iter.next().?;
    tmp = tok_iter.next().?;
    var p1_pos = try std.fmt.parseInt(u32, tmp, 10);

    line = line_iter.next().?;
    tok_iter = mem.split(u8, line, ": ");
    tmp = tok_iter.next().?;
    tmp = tok_iter.next().?;
    var p2_pos = try std.fmt.parseInt(u32, tmp, 10);

    var die = DDice{};

    var pl1 = Player.new(p1_pos);
    var pl2 = Player.new(p2_pos);

    while (true) {
        var roll = die.next3();
        var sum = roll[0] + roll[1] + roll[2];

        var score = pl1.move(sum);
        if (score >= 1000) {
            return die.roll_cnt * pl2.score;
        }

        roll = die.next3();
        sum = roll[0] + roll[1] + roll[2];
        score = pl2.move(sum);
        if (score >= 1000) {
            return die.roll_cnt * pl1.score;
        }
    }
    unreachable;
}

// sum -> cnt lut
const rules = [7][2]u32{
    .{ 3, 1 },
    .{ 4, 3 },
    .{ 5, 6 },
    .{ 6, 7 },
    .{ 7, 6 },
    .{ 8, 3 },
    .{ 9, 1 },
};

fn p2(text: Str) !u64 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var line = line_iter.next().?;
    var tok_iter = mem.split(u8, line, ": ");
    var tmp = tok_iter.next().?;
    tmp = tok_iter.next().?;
    var p1_pos = try std.fmt.parseInt(u32, tmp, 10);

    line = line_iter.next().?;
    tok_iter = mem.split(u8, line, ": ");
    tmp = tok_iter.next().?;
    tmp = tok_iter.next().?;
    var p2_pos = try std.fmt.parseInt(u32, tmp, 10);

    var states = AutoHashMap(Game, usize).init(gpa);
    defer states.deinit();

    var init = Game.new(p1_pos, p2_pos);

    try states.put(init, 1);

    var turn: usize = 0;

    outer: while (true) : (turn += 1) {
        print("{}\n", .{turn});
        
        var next = AutoHashMap(Game, usize).init(gpa);

        var iter = states.iterator();
        while (iter.next()) |kv| {
            const g = kv.key_ptr;
            const c = kv.value_ptr.*;

            if (g.over()) {
                var gop = try next.getOrPut(g.*);
                if (gop.found_existing) {
                    gop.value_ptr.* += c;
                } else {
                    gop.value_ptr.* = c;
                }
                continue;
            }

            for (rules) |r| {
                const roll = r[0];
                const times = r[1];

                const ng = g.from(roll, turn % 2);

                var gop = try next.getOrPut(ng);
                if (gop.found_existing) {
                    gop.value_ptr.* += c * times;
                } else {
                    gop.value_ptr.* = c * times;
                }
            }
        }

        states.clearAndFree();
        states = next;

        var kiter = states.keyIterator();
        while (kiter.next()) |g| {
            if (!g.over()) {
                continue :outer;
            }
        }
        break;
    }

    var p1_w: usize = 0;
    var p2_w: usize = 0;

    var iter = states.iterator();
    while (iter.next()) |kv| {
        const g = kv.key_ptr;
        const c = kv.value_ptr.*;
        if (g.players[0].score > g.players[1].score) {
            p1_w += c;
        } else {
            p2_w += c;
        }
    }

    return if (p1_w > p2_w) p1_w else p2_w;
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
    try std.testing.expectEqual(try p1(text), 739785);
    try std.testing.expectEqual(try p2(text), 444356092776315);
}
