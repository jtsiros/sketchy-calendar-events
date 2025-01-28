package main

import "core:bytes"
import "core:fmt"
import "core:time"
import "core:time/datetime"


EventParseError :: enum {
	InvalidFormat,
	InvalidDateFormat,
}

Event :: struct {
	title: string,
	dt:    datetime.DateTime,
}

events_from_bytes :: proc(
	event_bytes: []byte,
) -> (
	parsed_events: [dynamic]Event,
	err: EventParseError,
) {
	events_it := bytes.split(event_bytes, []u8{'\n'})

	for event, idx in events_it {
		event_fields := bytes.split(event, []u8{' ', '#', '#', ' '})
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
