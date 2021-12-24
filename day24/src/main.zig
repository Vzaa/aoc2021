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

const Regs = struct {
    w: i64 = 0,
    x: i64 = 0,
    y: i64 = 0,
    z: i64 = 0,

    fn runLine(self: *Regs, line: Str, input: Str, idx: *usize) !void {
        var iter = mem.tokenize(u8, line, " ");
        const op = Op.fromStr(iter.next().?);
        const a = iter.next().?;

        const oper_a = switch (a[0]) {
            'w' => &self.w,
            'x' => &self.x,
            'y' => &self.y,
            'z' => &self.z,
            else => unreachable,
        };

        if (op == Op.Inp) {
            const val = try std.fmt.charToDigit(input[idx.*], 10);
            idx.* += 1;
            oper_a.* = val;
            return;
        }

        const b = iter.next().?;
        const oper_b = switch (b[0]) {
            'w' => self.w,
            'x' => self.x,
            'y' => self.y,
            'z' => self.z,
            else => try std.fmt.parseInt(i32, b, 10),
        };

        switch (op) {
            Op.Inp => unreachable,
            Op.Add => oper_a.* += oper_b,
            Op.Mul => oper_a.* *= oper_b,
            Op.Div => oper_a.* = @divFloor(oper_a.*, oper_b),
            Op.Mod => oper_a.* = @rem(oper_a.*, oper_b),
            Op.Eql => oper_a.* = if (oper_a.* == oper_b) 1 else 0,
        }
    }
};

const Op = enum {
    Inp,
    Add,
    Mul,
    Div,
    Mod,
    Eql,

    fn fromStr(s: Str) Op {
        if (mem.eql(u8, "inp", s)) return Op.Inp;
        if (mem.eql(u8, "add", s)) return Op.Add;
        if (mem.eql(u8, "mul", s)) return Op.Mul;
        if (mem.eql(u8, "div", s)) return Op.Div;
        if (mem.eql(u8, "mod", s)) return Op.Mod;
        if (mem.eql(u8, "eql", s)) return Op.Eql;
        unreachable;
    }
};

fn p1(text: Str) !i64 {
    var num: i64 = 65984919999999;

    var min: i64 = math.maxInt(i64);

    while (true) : (num -= 1) {
        var line_iter = mem.tokenize(u8, text, "\n");
        var regs = Regs{};

        var strbuf: [14]u8 = undefined;
        _ = try std.fmt.bufPrint(&strbuf, "{}", .{num});

        if (mem.indexOfScalar(u8, strbuf[0..], '0')) |_| {
            continue;
        }

        var idx: usize = 0;
        while (line_iter.next()) |line| {
            try regs.runLine(line, strbuf[0..], &idx);
        }

        if (regs.z == 0) {
            return num;
        } else {
            if (min > regs.z) {
                min = regs.z;
            }
        }
    }

    return 0;
}

fn p2(text: Str) !i64 {
    var num: i64 = 11211619511713;

    var min: i64 = math.maxInt(i64);

    while (true) : (num += 1) {
        var line_iter = mem.tokenize(u8, text, "\n");
        var regs = Regs{};

        var strbuf: [14]u8 = undefined;
        _ = try std.fmt.bufPrint(&strbuf, "{}", .{num});

        if (mem.indexOfScalar(u8, strbuf[0..], '0')) |_| {
            continue;
        }

        var idx: usize = 0;
        while (line_iter.next()) |line| {
            try regs.runLine(line, strbuf[0..], &idx);
        }

        if (regs.z == 0) {
            return num;
        } else {
            if (min > regs.z) {
                min = regs.z;
            }
        }
    }

    return 0;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("../input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}
