package main

import "core:bytes"
import "core:fmt"
import "core:time"
import "core:time/datetime"
import "core:time/timezone"


EventParseError :: enum {
	InvalidFormat,
	InvalidDateFormat,
}

Event :: struct {
	title: string,
	dt:    datetime.DateTime,
}


display_event :: proc(event: Event) {
	tz, _ := timezone.region_load("local")
	defer timezone.region_destroy(tz)

	now := time.now()
	dt, ok := time.time_to_datetime(now)
	if !ok {
		return
	}
	dt_local, ok_to_tz := timezone.datetime_to_tz(dt, tz)

	if !ok_to_tz {
		return
	}

	now_total := (u16(dt_local.hour) * 60) + u16(dt_local.minute)
	event_total := (u16(event.dt.hour) * 60) + u16(event.dt.minute)
	diff_minutes := event_total - now_total

	if diff_minutes < 0 {
		diff_minutes = 0
	}

	hours := diff_minutes / 60
	minutes := diff_minutes % 60
	printed_any := false

	fmt.printf("%s: ", event.title)

	if hours != 0 {
		fmt.printf("%ih", hours)
		printed_any = true
	}

	if minutes != 0 {
		if printed_any {
			fmt.print(" ")
		}

		fmt.printf("%im", minutes)
		printed_any = true
	}

	if !printed_any {
		fmt.print("now")
	}

	fmt.println()
}

events_from_bytes :: proc(
	event_bytes: []byte,
) -> (
	parsed_events: [dynamic]Event,
	err: EventParseError,
) {
	events_it := bytes.split(event_bytes, []u8{'\n'})
	defer delete(events_it)

	for event, idx in events_it {
		event_fields := bytes.split(event, []u8{' ', '#', '#', ' '})
		defer delete(event_fields)

		if len(event_fields) != 2 {
			continue
		}

		event_title := string(event_fields[0])
		event_time := string(event_fields[1])


		t, _ := time.iso8601_to_time_utc(event_time)
		dt, ok := time.time_to_datetime(t)
		if !ok {
			err = .InvalidFormat
			return
		}

		append(&parsed_events, Event{title = event_title, dt = dt})
	}
	return
}
