use chrono::prelude::*;
use std::process::Command;

#[derive(Debug)]
pub struct Event {
    title: String,
    start_time: NaiveTime,
}

impl Into<Event> for &str {
    fn into(self) -> Event {
        let mut raw_event = self.split(" : ");
        let title = raw_event.next().expect("title for event").to_string();
        let start = raw_event.next().expect("start time for event");

        let start_time = NaiveTime::parse_from_str(start, "%I:%M%p")
            .expect("could not parse start time from event");

        Event {
            title,
            start_time,
        }
    }
}

fn main() {
    // icalBuddy -ea -npn -nc -iep "title,datetime" -ps "| : |" -eed -b "" eventsToday
    let output = Command::new("icalBuddy")
        .arg("-ea")
        .arg("-npn")
        .arg("-eed")
        .arg("-nc")
        .arg("-iep")
        .arg("title,datetime")
        .arg("-ps")
        .arg("| : |")
        .arg("-b")
        .arg("")
        .arg("-n")
        .arg("-li")
        .arg("2")
        .arg("-tf")
        .arg("%I:%M%p")
        .arg("eventsToday")
        .output()
        .expect("failed to execute process");

    let out = String::from_utf8_lossy(&output.stdout);
    let now = Local::now().time();

    match out
        .lines()
        .map(|line| line.into())
        .find(|e: &Event| e.start_time > now)
    {
        Some(event) => {
            let duration_until_event = event.start_time - now;
            let hours = duration_until_event.num_hours();
            let minutes = duration_until_event.num_minutes() % 60;

            if hours > 0 {
                    println!("{} in {}h{}m", event.title, hours, minutes)
            } else {
                    println!("{} in {}m", event.title, minutes)
            };
        }
        None => println!("No meetings"),
    };
}
