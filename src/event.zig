const std = @import("std");
const zeit = @import("zeit");
const ArrayList = std.ArrayList;

const parseError = error{InvalidFormat};

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
        return error.InvalidFormat;
    };

    const event = Event{
        .title = title,
        .datetime = datetime.in(local),
    };

    return event;
}

pub fn timeUntilEvent(
    self: *const Event,
    alloc: std.mem.Allocator,
    local: *const zeit.timezone.TimeZone,
) ![]const u8 {
    const now_gmt = try zeit.instant(.{});
    const now_local = now_gmt.in(local);
    const now = now_local.time();

    const eventTime = self.datetime.time();

    const nowTotal = now.hour * @as(i16, 60) + now.minute;
    const otherTotal = eventTime.hour * @as(i16, 60) + eventTime.minute;
    var diffMinutes = otherTotal - nowTotal;

    if (diffMinutes < 0) {
        diffMinutes = 0;
    }

    const hours = @divFloor(diffMinutes, 60);
    const minutes = @mod(diffMinutes, 60);
    var printedAny = false;

    var buffer = ArrayList(u8).init(alloc);
    const writer = buffer.writer();

    if (hours != 0) {
        try writer.print("{}h", .{hours});
        printedAny = true;
    }

    if (minutes != 0) {
        if (printedAny) try writer.print(" ", .{});
        try writer.print("{}m", .{minutes});
        printedAny = true;
    }

    if (!printedAny) {
        try writer.print("now", .{});
    }

    // no need to deinit buffer here when
    // converting to owned slice.
    return try buffer.toOwnedSlice();
}
