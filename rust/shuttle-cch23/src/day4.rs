use std::borrow::Cow;

use rocket::serde::{json::Json, Deserialize, Serialize};
use rocket::{post, routes};

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
struct Reindeer<'r> {
    name: &'r str,
    strength: u32,
    speed: Option<f32>,
    height: Option<u32>,
    antler_width: Option<u32>,
    snow_magic_power: Option<u32>,
    favorite_food: Option<&'r str>,
    #[serde(rename = "cAnD13s_3ATeN-yesT3rdAy")]
    candies: Option<u32>,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
struct ReindeerSkills<'r> {
    fastest: Cow<'r, str>,
    tallest: Cow<'r, str>,
    magician: Cow<'r, str>,
    consumer: Cow<'r, str>,
}

#[post("/4/strength", data = "<reindeer>")]
fn strength(reindeer: Json<Vec<Reindeer<'_>>>) -> String {
    reindeer
        .0
        .into_iter()
        .map(|r| r.strength)
        .sum::<u32>()
        .to_string()
}

#[post("/4/contest", data = "<reindeer>")]
fn contest(reindeer: Json<Vec<Reindeer<'_>>>) -> Json<ReindeerSkills<'_>> {
    let fastest = reindeer
        .0
        .iter()
        .map(|r| match r.speed {
            Some(v) => (v, r.name, r.strength),
            None => (0.0, r.name, r.strength),
        })
        .max_by(|a, b| a.0.partial_cmp(&b.0).unwrap())
        .unwrap_or((0.0, "", 0));

    let tallest = reindeer
        .0
        .iter()
        .map(|r| match r.height {
            Some(v) => (v, r.name, r.antler_width),
            None => (0, r.name, r.antler_width),
        })
        .max_by(|a, b| a.0.partial_cmp(&b.0).unwrap())
        .unwrap_or((0, "", Some(0)));

    let magician = reindeer
        .0
        .iter()
        .map(|r| match r.snow_magic_power {
            Some(v) => (v, r.name),
            None => (0, r.name),
        })
        .max_by(|a, b| a.0.partial_cmp(&b.0).unwrap())
        .unwrap_or((0, ""));

    let consumer = reindeer
        .0
        .iter()
        .map(|r| match r.candies {
            Some(v) => (v, r.name, r.favorite_food),
            None => (0, r.name, r.favorite_food),
        })
        .max_by(|a, b| a.0.partial_cmp(&b.0).unwrap())
        .unwrap_or((0, "", Some("")));

    Json(ReindeerSkills {
        fastest: format!(
            "Speeding past the finish line with a strength of {} is {}",
            fastest.2, fastest.1
        )
        .into(),
        tallest: format!(
            "{} is standing tall with his {} cm wide antlers",
            tallest.1,
            tallest.2.unwrap()
        )
        .into(),
        magician: format!(
            "{} could blast you away with a snow magic power of {}",
            magician.1, magician.0
        )
        .into(),
        consumer: format!(
            "{} ate lots of candies, but also some {}",
            consumer.1,
            consumer.2.unwrap()
        )
        .into(),
    })
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY4", |rocket| async {
        rocket.mount("/", routes![strength, contest])
    })
}
