const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const mem = std.mem;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_impl.allocator;

const Board = struct {
    mat: [5][5]i32 = undefined,
    marks: [5][5]bool = undefined,
    won: bool = false, // TODO: this was needed to avoid removing boards

    fn setRow(self: *Board, i: usize, line: []const u8) !void {
        var num_iter = std.mem.tokenize(u8, line, " ");

        var c: usize = 0;

        while (num_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            self.mat[i][c] = num;
            self.marks[i][c] = false;
            c += 1;
        }
    }

    fn printBoard(self: *const Board) void {
        for (self.mat) |r| {
            for (r) |c| {
                print("{} ", .{c});
            }
            print("\n", .{});
        }

        for (self.marks) |r| {
            for (r) |c| {
                print("{} ", .{c});
            }
            print("\n", .{});
        }
    }

    fn markNum(self: *Board, num: i32) void {
        for (self.mat) |row, r| {
            for (row) |col, c| {
                if (col == num) {
                    self.marks[r][c] = true;
                }
            }
        }
    }

    fn bingo(self: *Board) bool {
        if (self.won) return false;

        outer: for (self.marks) |r| {
            for (r) |c| {
                if (!c) continue :outer;
            }
            self.won = true;
            return true;
        }

        // not the most readable way to check columns but it works
        outer: for (self.marks) |r, ir| {
            for (r) |_, ic| {
                if (!self.marks[ic][ir]) continue :outer;
            }
            self.won = true;
            return true;
        }
        return false;
    }

    fn score(self: *const Board) i32 {
        var sum: i32 = 0;

        for (self.marks) |r, ir| {
            for (r) |_, ic| {
                if (!self.marks[ir][ic]) {
                    sum += self.mat[ir][ic];
                }
            }
        }

        return sum;
    }
};

fn p1(text: []const u8) !i32 {
    var line_iter = std.mem.split(u8, text, "\n");

    var nums = ArrayList(i32).init(gpa);
    defer nums.deinit();

    {
        const line = line_iter.next().?;
        var num_iter = std.mem.tokenize(u8, line, ",");

        while (num_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            try nums.append(num);
        }
    }

    var boards = ArrayList(Board).init(gpa);
    defer boards.deinit();

    var tmp = Board{};

    var row: usize = 0;
    while (line_iter.next()) |line| {
        if (mem.eql(u8, line, "")) {
            if (row == 5) {
                try boards.append(tmp);
            }
            row = 0;
            continue;
        }
        try tmp.setRow(row, line);
        row += 1;
    }

    for (nums.items) |num| {
        for (boards.items) |*board| {
            board.markNum(num);

            if (board.bingo()) {
                const score = board.score();
                return score * num;
            }
        }
    }

    return 0;
}

fn p2(text: []const u8) !i32 {
    var line_iter = std.mem.split(u8, text, "\n");

    var nums = ArrayList(i32).init(gpa);
    defer nums.deinit();

    {
        const line = line_iter.next().?;
        var num_iter = std.mem.tokenize(u8, line, ",");

        while (num_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            try nums.append(num);
        }
    }

    var boards = ArrayList(Board).init(gpa);
    defer boards.deinit();

    var tmp = Board{};

    var row: usize = 0;
    while (line_iter.next()) |line| {
        if (mem.eql(u8, line, "")) {
            if (row == 5) {
                try boards.append(tmp);
            }
            row = 0;
            continue;
        }
        try tmp.setRow(row, line);
        row += 1;
    }

    var wincnt: usize = 0;
    // TODO: Remove boards, need an idiomatic way to remove while iterating
    // over the list without fiddling with indices
    for (nums.items) |num| {
        for (boards.items) |*board| {
            board.markNum(num);
            const won = board.bingo();
            if (won) wincnt += 1;

            if (wincnt == boards.items.len) {
                const score = board.score();
                return score * num;
            }
        }
    }

    return 0;
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
    try std.testing.expectEqual(p1(text), 4512);
    try std.testing.expectEqual(p2(text), 1924);
}
