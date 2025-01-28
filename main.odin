package main

import "core:fmt"
import "core:os"
import "core:os/os2"

main :: proc() {

	debug_tracker_setup()

	args := []string {
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
		"%Y-%m-%dT%H:%M:%SZ%z",
		"eventsToday",
	}

	_, stdout, stderr, exec_err := os2.process_exec(
		os2.Process_Desc{command = args},
		context.allocator,
	)
	defer {
		delete(stdout)
		delete(stderr)
	}

	if exec_err != nil {
		fmt.eprintf("err fetching events from iCalBuddy: %v\n", exec_err)
		os.exit(1)
	}


	if len(stderr) > 0 {
		fmt.eprintln(stderr)
		os.exit(1)
	}

	events, events_err := events_from_bytes(stdout)
	if events_err != nil {
		fmt.eprintf("could not parse events: %v\n", events_err)
		os.exit(1)
	}

	if len(events) == 0 {
		fmt.println("No meetings")
		os.exit(0)
	}


	defer delete(events)
	display_event(events[0])
}
