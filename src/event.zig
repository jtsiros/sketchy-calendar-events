const std = @import("std");
const zeit = @import("zeit");
const ArrayList = std.ArrayList;

const parseError = error{
    InvalidFormat,
    InvalidTimeFormat,
};

title: []const u8,
datetime: zeit.Instant,

const Event = @This();

pub fn from(local: *const zeit.TimeZone, raw: []const u8) !?Event {
    var it = std.mem.splitSequence(u8, raw, " ## ");

    const title = it.next() orelse return null;
    const raw_datetime = it.next() orelse return null;

    if (it.next() != null) {
        return error.InvalidFormat;
    }

    const datetime = zeit.instant(.{
        .source = .{ .iso8601 = raw_datetime },
    }) catch |err| {
        std.debug.print("error parsing time: {!}\n", .{err});
        return error.InalidTimeFormat;
    };

    const event = Event{
        .title = title,
        .datetime = datetime.in(local),
    };

    return event;
}

pub fn timeUntilEvent(self: *const Event, alloc: std.mem.Allocator, local: *const zeit.timezone.TimeZone) ![]const u8 {

    const now_gmt = try zeit.instant(.{});
    const now_local = now_gmt.in(local);
    const now = now_local.time();

    const event_time = self.datetime.time();

    const now_total = now.hour * @as(i16, 60) + now.minute;
    const other_total = event_time.hour * @as(i16, 60) + event_time.minute;
    var diff_minutes = other_total - now_total;

    if (diff_minutes < 0) {
        diff_minutes = 0;
    }

    const hours = @divFloor(diff_minutes, 60);
    const minutes = @mod(diff_minutes, 60);
    var printed_any = false;

    var buffer = ArrayList(u8).init(alloc);
    const writer = buffer.writer();

    if (hours != 0) {
        try writer.print("{}h", .{hours});
        printed_any = true;
    }

    if (minutes != 0) {
        if (printed_any) try writer.print(" ", .{});
        try writer.print("{}m", .{minutes});
        printed_any = true;
    }

    if (!printed_any) {
        try writer.print("now", .{});
    }

    // no need to deinit buffer here when
    // converting to owned slice.
    return try buffer.toOwnedSlice();
}
