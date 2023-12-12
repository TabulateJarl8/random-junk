use std::{collections::HashMap, sync::Mutex, time::SystemTime};

use chrono::{DateTime, Datelike, Utc, Weekday};
use rocket::{
    get, post, routes,
    serde::json::{json, Json, Value},
    State,
};
use ulid::Ulid;
use uuid::Builder;

struct PresentsState {
    presents: Mutex<HashMap<String, SystemTime>>,
}

#[post("/12/save/<string>")]
fn save_present(string: &str, presents_state: &State<PresentsState>) {
    presents_state
        .presents
        .lock()
        .unwrap()
        .insert(string.to_string(), SystemTime::now());
}

#[get("/12/load/<string>")]
fn get_present(string: &str, presents_state: &State<PresentsState>) -> String {
    match presents_state.presents.lock().unwrap().get(string) {
        Some(time) => SystemTime::now()
            .duration_since(*time)
            .unwrap()
            .as_secs()
            .to_string(),
        None => String::from("-1"),
    }
}

#[post("/12/ulids", data = "<ulids>")]
fn convert_ulid_to_uuid(ulids: Json<Vec<&str>>) -> Json<Vec<String>> {
    let vec = ulids
        .0
        .iter()
        .rev()
        .map(|u| Ulid::from_string(u))
        .filter_map(Result::ok)
        .map(|u| {
            // im doing some weird combination of different uuids to make their weird format
            let second_half = &Builder::from_u128(u.random())
                .as_uuid()
                .hyphenated()
                .to_string()[14..];
            let first_half = Builder::from_unix_timestamp_millis(u.timestamp_ms(), &[0; 10])
                .as_uuid()
                .hyphenated()
                .to_string()[..14]
                .to_string();
            first_half + second_half
        })
        .collect::<Vec<String>>();
    Json::from(vec)
}

#[post("/12/ulids/<weekday>", data = "<ulids>")]
fn check_ulids(weekday: usize, ulids: Json<Vec<&str>>) -> Value {
    let parsed_ulids: Vec<Ulid> = ulids
        .iter()
        .map(|s| Ulid::from_string(s))
        .filter_map(Result::ok)
        .collect();
    let date_ulids: Vec<DateTime<Utc>> = parsed_ulids.iter().map(|u| u.datetime().into()).collect();

    let weekdays = [
        Weekday::Mon,
        Weekday::Tue,
        Weekday::Wed,
        Weekday::Thu,
        Weekday::Fri,
        Weekday::Sat,
        Weekday::Sun,
    ];
    let xmas_eve = date_ulids
        .iter()
        .filter(|d| d.day() == 24 && d.month() == 12)
        .count();
    let weekday = date_ulids
        .iter()
        .filter(|d| weekdays[weekday] == d.weekday())
        .count();
    let future = date_ulids.iter().filter(|&d| d > &Utc::now()).count();
    let lsb = parsed_ulids.iter().filter(|u| u.0 & 1 == 1).count();

    json!({
        "christmas eve": xmas_eve,
        "weekday": weekday,
        "in the future": future,
        "LSB is 1": lsb
    })
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY12", |rocket| async {
        rocket
            .mount(
                "/",
                routes![save_present, get_present, convert_ulid_to_uuid, check_ulids],
            )
            .manage(PresentsState {
                presents: Mutex::new(HashMap::new()),
            })
    })
}
