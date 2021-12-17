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

const Vec2 = [2]i32;

const Area = struct {
    a: Vec2,
    b: Vec2,

    fn fromStr(line: Str) !Area {
        var ret: Area = undefined;
        var sp_iter = mem.tokenize(u8, line, " ");
        _ = sp_iter.next().?;
        _ = sp_iter.next().?;
        const x_str = mem.trim(u8, sp_iter.next().?, "x=,");
        const y_str = mem.trim(u8, sp_iter.next().?, "y=,");

        var dot_iter = mem.tokenize(u8, x_str, "..");

        ret.a[0] = try std.fmt.parseInt(i32, dot_iter.next().?, 10);
        ret.b[0] = try std.fmt.parseInt(i32, dot_iter.next().?, 10);

        dot_iter = mem.tokenize(u8, y_str, "..");

        ret.a[1] = try std.fmt.parseInt(i32, dot_iter.next().?, 10);
        ret.b[1] = try std.fmt.parseInt(i32, dot_iter.next().?, 10);

        return ret;
    }

    fn in(self: *const Area, p: Vec2) bool {
        const xb = math.min(self.a[0], self.b[0]);
        const yb = math.min(self.a[1], self.b[1]);
        const xe = math.max(self.a[0], self.b[0]);
        const ye = math.max(self.a[1], self.b[1]);

        return (p[0] >= xb) and (p[0] <= xe) and (p[1] >= yb) and (p[1] <= ye);
    }

    fn rip(self: *const Area, p: Vec2) bool {
        const yb = math.min(self.a[1], self.b[1]);
        const xe = math.max(self.a[0], self.b[0]);

        return (p[0] >= xe) or (p[1] <= yb);
    }
};

fn p1(text: Str) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n");
    const box = try Area.fromStr(line_iter.next().?);

    var y_max: i32 = 0;

    var x_v: i32 = 1;
    while (x_v < 5000) : (x_v += 1) {
        var y_v: i32 = 1;
        while (y_v < 500) : (y_v += 1) {
            var p = Vec2{ 0, 0 };
            var v = Vec2{ x_v, y_v };
            var y_max_local: i32 = 0;

            while (!box.rip(p)) {
                p[0] += v[0];
                p[1] += v[1];

                y_max_local = math.max(y_max_local, p[1]);
                if (box.in(p)) {
                    y_max = math.max(y_max_local, y_max);
                    break;
                }

                if (v[0] > 0) v[0] -= 1;
                v[1] -= 1;
            }
        }
    }

    return y_max;
}

fn p2(text: Str) !usize {
    var line_iter = mem.tokenize(u8, text, "\n");
    const box = try Area.fromStr(line_iter.next().?);

    var cnt: usize = 0;

    var x_v: i32 = 1;
    while (x_v < 5000) : (x_v += 1) {
        var y_v: i32 = -500;
        while (y_v < 500) : (y_v += 1) {
            var p = Vec2{ 0, 0 };
            var v = Vec2{ x_v, y_v };

            while (!box.rip(p)) {
                p[0] += v[0];
                p[1] += v[1];

                if (box.in(p)) {
                    cnt += 1;
                    break;
                }

                if (v[0] > 0) v[0] -= 1;
                v[1] -= 1;
            }
        }
    }

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
    try std.testing.expectEqual(p1(text), 45);
    try std.testing.expectEqual(p2(text), 112);
}
