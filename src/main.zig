const std = @import("std");
const zeit = @import("zeit");
const Event = @import("event.zig");
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");
    const alloc = gpa.allocator();

    var env = try std.process.getEnvMap(alloc);
    defer env.deinit();

    const args = [_][]const u8{
        "/opt/homebrew/bin/iCalBuddy",
        "-ea",
        "-npn",
        "-eed",
        "-nc",
        "-iep",
        "title,datetime",
        "-ps",
        "| ## |",
        "-b",
        "",
        "-n",
        "-li",
        "2",
        "-tf",
        "%Y-%m-%dT%H:%M:%S%z",
        "eventsToday",
    };

    var child = std.process.Child.init(&args, alloc);
    child.stderr_behavior = .Pipe;
    child.stdout_behavior = .Pipe;

    var stdout = ArrayList(u8).init(alloc);
    var stderr = ArrayList(u8).init(alloc);
    defer {
        stdout.deinit();
        stderr.deinit();
    }

    try child.spawn();
    try child.collectOutput(&stdout, &stderr, 1024);
    const term = try child.wait();

    if (term.Exited != 0) {
        std.debug.print("error: {s}\n", .{stderr.items});
        return error.InvalidFormat;
    }

    var events = ArrayList(Event).init(alloc);
    defer events.deinit();

    const local_tz = try zeit.local(alloc, &env);
    defer local_tz.deinit();

    var it = std.mem.splitSequence(u8, stdout.items, "\n");
    while (it.next()) |raw_event| {
        if (try Event.from(&local_tz, raw_event) orelse null) |event| {
            try events.append(event);
        }
    }

    const outw = std.io.getStdOut().writer();

    if (events.items.len > 0) {
        const event = events.items[0];
        const tu = try event.timeUntilEvent(alloc, &local_tz);
        defer alloc.free(tu);

        try outw.print("{s}: {s}\n", .{ event.title, tu });
        return;
    }

    try outw.print("No meetings\n", .{});
}
