const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const print = std.debug.print;
const mem = std.mem;
const math = std.math;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Entry = struct {
    digits: [10][]u8 = undefined,
    outputs: [4][]u8 = undefined,
    allocator: Allocator,

    // TODO: Is this the idiomatic way to pass allocators to a struct?
    // TODO: This can leak memory on error
    fn fromStr(allocator: Allocator, txt: []const u8) !Entry {
        var ret = Entry{ .allocator = allocator };
        var div_iter = std.mem.tokenize(u8, txt, "|");
        var digits_str = mem.trim(u8, div_iter.next().?, std.ascii.spaces[0..]);
        var outputs_str = mem.trim(u8, div_iter.next().?, std.ascii.spaces[0..]);

        var digits_iter = std.mem.tokenize(u8, digits_str, " ");

        var i: usize = 0;
        while (digits_iter.next()) |digit| : (i += 1) {
            var tmp = try allocator.dupe(u8, digit);
            std.sort.sort(u8, tmp, {}, comptime std.sort.asc(u8));
            ret.digits[i] = tmp;
        }

        var outputs_iter = std.mem.tokenize(u8, outputs_str, " ");
        i = 0;
        while (outputs_iter.next()) |output| : (i += 1) {
            var tmp = try allocator.dupe(u8, output);
            std.sort.sort(u8, tmp, {}, comptime std.sort.asc(u8));
            ret.outputs[i] = tmp;
        }

        return ret;
    }

    fn deinit(self: *Entry) void {
        for (self.digits) |digit| {
            self.allocator.free(digit);
        }
        for (self.outputs) |digit| {
            self.allocator.free(digit);
        }
    }

    // Not great but works
    fn deduce(self: *const Entry) !usize {
        var digit_lut = StringHashMap(usize).init(gpa);
        defer digit_lut.deinit();

        // digits used for deduction of others
        var d1: ?[]const u8 = null;
        var d4: ?[]const u8 = null;
        var d3: ?[]const u8 = null;
        var d6: ?[]const u8 = null;
        var d7: ?[]const u8 = null;
        var d9: ?[]const u8 = null;

        for (self.digits) |digit| {
            if (digit.len == 2) {
                d1 = digit;
                try digit_lut.put(digit, 1);
            } else if (digit.len == 3) {
                d7 = digit;
                try digit_lut.put(digit, 7);
            } else if (digit.len == 4) {
                d4 = digit;
                try digit_lut.put(digit, 4);
            } else if (digit.len == 7) {
                try digit_lut.put(digit, 8);
            }
        }

        for (self.digits) |digit| {
            if (digit.len == 5) {
                var cnt: usize = anyCount(u8, digit, d7.?);
                if (cnt == 3) {
                    d3 = digit;
                    try digit_lut.put(digit, 3);
                    break;
                }
            }
        }

        for (self.digits) |digit| {
            if (digit.len == 5) {
                var cnt: usize = anyCount(u8, digit, d4.?);
                if (cnt == 2) {
                    try digit_lut.put(digit, 2);
                } else if (cnt == 3 and !mem.eql(u8, d3.?, digit)) {
                    try digit_lut.put(digit, 5);
                }
            }
        }

        for (self.digits) |digit| {
            if (digit.len == 6) {
                var cnt: usize = anyCount(u8, digit, d1.?);
                if (cnt == 1) {
                    d6 = digit;
                    try digit_lut.put(digit, 6);
                    break;
                }
            }
        }

        for (self.digits) |digit| {
            if (digit.len == 6) {
                var cnt: usize = anyCount(u8, digit, d4.?);
                if (cnt == 4) {
                    d9 = digit;
                    try digit_lut.put(digit, 9);
                    break;
                }
            }
        }

        for (self.digits) |digit| {
            if (digit.len == 6) {
                if (!mem.eql(u8, d6.?, digit) and !mem.eql(u8, d9.?, digit)) {
                    try digit_lut.put(digit, 0);
                    break;
                }
            }
        }

        var val: usize = 0;
        var cnt: usize = 3;

        for (self.outputs) |output| {
            var d = digit_lut.get(output).?;

            val += (d * try math.powi(usize, 10, cnt));
            if (cnt > 0) cnt -= 1;
        }
        return val;
    }
};

// TODO: could be optimized
pub fn anyCount(comptime T: type, haystack: []const T, needle: []const T) usize {
    var found: usize = 0;

    for (needle) |c| {
        // TODO: how to do without temporary variable?
        const tmp_sl = [_]T{c};
        found += mem.count(T, haystack, tmp_sl[0..]);
    }

    return found;
}

fn p1(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var list = ArrayList(Entry).init(gpa);
    defer list.deinit();
    // TODO: Is there a better way to do this in Zig?
    defer {
        for (list.items) |*l| {
            l.deinit();
        }
    }

    while (line_iter.next()) |line| {
        const entry = try Entry.fromStr(gpa, line);
        try list.append(entry);
    }

    var uniq_cnt: usize = 0;
    for (list.items) |e| {
        for (e.outputs) |o| {
            if (o.len == 2 or o.len == 3 or o.len == 4 or o.len == 7) {
                uniq_cnt += 1;
            }
        }
    }

    return uniq_cnt;
}

fn p2(text: []const u8) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");

    var list = ArrayList(Entry).init(gpa);
    defer list.deinit();
    // TODO: Is there a better way to do this in Zig?
    defer {
        for (list.items) |*l| {
            l.deinit();
        }
    }

    while (line_iter.next()) |line| {
        const entry = try Entry.fromStr(gpa, line);
        try list.append(entry);
    }

    var sum: usize = 0;

    for (list.items) |x| {
        sum += try x.deduce();
    }

    return sum;
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
    try std.testing.expectEqual(p1(text), 26);
    var tmp = try Entry.fromStr(gpa, "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf");
    defer tmp.deinit();
    var val = try tmp.deduce();
    try std.testing.expectEqual(val, 5353);
    try std.testing.expectEqual(p2(text), 61229);
}
