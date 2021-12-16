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

const D16Error = error{
    BufEmpty,
    InvalidType,
};

const bitReader = struct {
    txt: Str,
    ptr: usize,

    fn fromDat(t: Str) bitReader {
        return bitReader{ .txt = t, .ptr = 0 };
    }

    fn read(self: *bitReader, len: usize) anyerror!Str {
        var ptr_old = self.ptr;
        self.ptr += len;
        if (self.ptr > self.txt.len) {
            return D16Error.BufEmpty;
        }

        return self.txt[ptr_old .. ptr_old + len];
    }

    fn readLiteral(self: *bitReader) !u64 {
        var buf = ArrayList(u8).init(gpa);
        defer buf.deinit();

        while (true) {
            const last_str = try self.read(1);
            const last = last_str[0] == '0';
            const digit_str = try self.read(4);

            try buf.appendSlice(digit_str[0..]);

            if (last) {
                const digit = try std.fmt.parseInt(u64, buf.items, 2);
                return digit;
            }
        }

        unreachable;
    }
};

const PType = enum {
    Sum,
    Product,
    Min,
    Max,
    Literal,
    GT,
    LT,
    EQ,

    fn fromStr(s: Str) !PType {
        const val = try std.fmt.parseInt(u64, s, 2);
        switch (val) {
            0 => return PType.Sum,
            1 => return PType.Product,
            2 => return PType.Min,
            3 => return PType.Max,
            4 => return PType.Literal,
            5 => return PType.GT,
            6 => return PType.LT,
            7 => return PType.EQ,
            else => return D16Error.InvalidType,
        }
    }
};

fn parse(rdr: *bitReader, sum: *usize) anyerror!void {
    const v_str = try rdr.read(3);
    const version = try std.fmt.parseInt(u64, v_str, 2);
    sum.* += version;

    const t_str = try rdr.read(3);
    const ptype = try PType.fromStr(t_str);

    switch (ptype) {
        PType.Literal => {
            const literal = try rdr.readLiteral();
            _ = literal;
        },
        else => {
            const i_str = try rdr.read(1);
            const length_type = i_str[0] == '0';

            if (length_type) {
                const len_str = try rdr.read(15);
                const len = try std.fmt.parseInt(u64, len_str, 2);

                const ptr_old = rdr.ptr;
                while (rdr.ptr - ptr_old < len) {
                    try parse(rdr, sum);
                }
            } else {
                const cnt_str = try rdr.read(11);
                const cnt = try std.fmt.parseInt(u64, cnt_str, 2);
                var i: usize = 0;
                while (i < cnt) : (i += 1) {
                    try parse(rdr, sum);
                }
            }
        },
    }
}

fn parse2(rdr: *bitReader) anyerror!u64 {
    const v_str = try rdr.read(3);
    const version = try std.fmt.parseInt(u64, v_str, 2);
    _ = version;

    const t_str = try rdr.read(3);
    const ptype = try PType.fromStr(t_str);

    switch (ptype) {
        PType.Literal => {
            const literal = try rdr.readLiteral();
            return literal;
        },
        else => {
            const i_str = try rdr.read(1);
            const length_type = i_str[0] == '0';

            var vals = ArrayList(u64).init(gpa);
            defer vals.deinit();

            if (length_type) {
                const len_str = try rdr.read(15);
                const len = try std.fmt.parseInt(u64, len_str, 2);

                const ptr_old = rdr.ptr;

                while (rdr.ptr - ptr_old < len) {
                    const v = try parse2(rdr);
                    try vals.append(v);
                }
            } else {
                const cnt_str = try rdr.read(11);
                const cnt = try std.fmt.parseInt(u64, cnt_str, 2);
                var i: usize = 0;
                while (i < cnt) : (i += 1) {
                    const v = try parse2(rdr);
                    try vals.append(v);
                }
            }

            switch (ptype) {
                PType.Sum => {
                    var sum: u64 = 0;
                    for (vals.items) |v| {
                        sum += v;
                    }
                    return sum;
                },
                PType.Product => {
                    var prod: u64 = 1;
                    for (vals.items) |v| {
                        prod *= v;
                    }
                    return prod;
                },
                PType.Min => {
                    var min: u64 = math.maxInt(u64);
                    for (vals.items) |v| {
                        min = math.min(min, v);
                    }
                    return min;
                },
                PType.Max => {
                    var max: u64 = 0;
                    for (vals.items) |v| {
                        max = math.max(max, v);
                    }
                    return max;
                },
                PType.GT => if (vals.items[0] > vals.items[1]) return 1 else return 0,
                PType.LT => if (vals.items[0] < vals.items[1]) return 1 else return 0,
                PType.EQ => if (vals.items[0] == vals.items[1]) return 1 else return 0,
                PType.Literal => unreachable,
            }
        },
    }

    unreachable;
}

fn p1(text: Str) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var dat = ArrayList(u8).init(gpa);
    defer dat.deinit();

    while (line_iter.next()) |line| {
        for (line) |c| {
            const val = try std.fmt.charToDigit(c, 16);

            var strbuf: [4]u8 = undefined;
            _ = try std.fmt.bufPrint(&strbuf, "{b:0>4}", .{val});

            try dat.appendSlice(strbuf[0..]);
        }
    }

    var rdr = bitReader.fromDat(dat.items);

    var sum: usize = 0;
    try parse(&rdr, &sum);

    return sum;
}

fn p2(text: Str) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var dat = ArrayList(u8).init(gpa);
    defer dat.deinit();

    while (line_iter.next()) |line| {
        for (line) |c| {
            const val = try std.fmt.charToDigit(c, 16);

            var strbuf: [4]u8 = undefined;
            _ = try std.fmt.bufPrint(&strbuf, "{b:0>4}", .{val});

            try dat.appendSlice(strbuf[0..]);
        }
    }

    var rdr = bitReader.fromDat(dat.items);

    const v = try parse2(&rdr);
    return v;
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
    try std.testing.expectEqual(p1(text), 14);
    try std.testing.expectEqual(p2(text), 3);
}
