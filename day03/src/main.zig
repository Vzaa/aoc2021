const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_impl.allocator;

fn p1(text: []const u8, comptime len: usize) !usize {
    var cnts = [_]usize{0} ** len;
    var iter = std.mem.tokenize(u8, text, "\n");
    var total: usize = 0;

    while (iter.next()) |num_str| {
        total += 1;

        for (num_str) |num, i| {
            if (num == '1') {
                cnts[len - i - 1] += 1;
            }
        }
    }

    var g: usize = 0;
    var e: usize = 0;

    for (cnts) |c, i| {
        if (c > (total / 2)) {
            g |= 1 <<| i;
        } else {
            e |= 1 <<| i;
        }
    }

    return g * e;
}

fn bitCriteria(list: *ArrayList([]const u8), i: usize, oxy: bool) !void {
    var ones: usize = 0;

    for (list.items) |num| {
        const bit = num[i];
        if (bit == '1') {
            ones += 1;
        }
    }
    const zeros: usize = list.items.len - ones;

    var new_list = ArrayList([]const u8).init(gpa);
    defer new_list.deinit();

    // TODO: Not the best solution to copy to a new list and replace...
    for (list.items) |num| {
        const bit = num[i];
        // TODO: More readable logic
        if (ones >= zeros) {
            if (!((bit == '0' and oxy) or (bit == '1' and !oxy))) {
                try new_list.append(num);
            }
        } else {
            if (!((bit == '1' and oxy) or (bit == '0' and !oxy))) {
                try new_list.append(num);
            }
        }
    }

    // TODO: This is not good:
    list.clearRetainingCapacity();
    try list.appendSlice(new_list.items);
}

fn p2(text: []const u8) !usize {
    var iter = std.mem.tokenize(u8, text, "\n");

    var list_o2 = ArrayList([]const u8).init(gpa);
    defer list_o2.deinit();

    var list_co2 = ArrayList([]const u8).init(gpa);
    defer list_co2.deinit();

    while (iter.next()) |num_str| {
        try list_o2.append(num_str);
        try list_co2.append(num_str);
    }

    const len = list_o2.items[0].len;

    var o2_rating: ?usize = null;
    var co2_rating: ?usize = null;

    var i: usize = 0;
    while (i < len) : (i += 1) {
        if (list_o2.items.len > 1) {
            try bitCriteria(&list_o2, i, true);
        }

        if (list_co2.items.len > 1) {
            try bitCriteria(&list_co2, i, false);
        }

        if (list_o2.items.len == 1 and list_co2.items.len == 1) {
            var num_str = list_o2.items[0];
            o2_rating = try std.fmt.parseInt(usize, num_str, 2);

            num_str = list_co2.items[0];
            co2_rating = try std.fmt.parseInt(usize, num_str, 2);

            break;
        }
    }

    return co2_rating.? * o2_rating.?;
}

pub fn main() anyerror!void {
    const text = @embedFile("../input");
    std.debug.print("Part 1: {}\n", .{p1(text, 12)});
    std.debug.print("Part 2: {}\n", .{p2(text)});
}

test "examples" {
    const text = @embedFile("../test");
    try std.testing.expectEqual(p1(text, 5), 198);
    try std.testing.expectEqual(p2(text), 230);
}
