use fancy_regex::Regex;
use rocket::{
    http::Status,
    post,
    response::status,
    routes,
    serde::{
        json::{json, Json, Value},
        Deserialize,
    },
};

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
struct Input<'r> {
    input: &'r str,
}

#[post("/15/nice", data = "<input>")]
fn nice(input: Json<Input<'_>>) -> status::Custom<Value> {
    let pat = Regex::new(r"(?=.*([A-Za-z])\1{1})(?=.*?[aeiouy].*?[aeiouy].*?[aeiouy])(?!.*(ab|cd|pq|xy))");
    match pat.unwrap().is_match(input.input) {
        Ok(v) => match v {
            true => status::Custom(Status::Ok, json!({"result":"nice"})),
            false => status::Custom(Status::BadRequest, json!({"result":"naughty"})),
        },
        Err(_) => status::Custom(Status::BadRequest, json!({"result":"naughty"})),
    }
}

#[post("/15/game", data = "<input>")]
fn game(input: Json<Input<'_>>) -> status::Custom<Value> {
    dbg!(&input.input);
    let string = input.input;
    if string.len() < 8 {
        return status::Custom(
            Status::BadRequest,
            json!({"result":"naughty", "reason": "8 chars"}),
        );
    }

    if !Regex::new(r"(?=.*[A-Z]+)(?=.*[a-z]+)(?=.*[0-9]+)")
        .unwrap()
        .is_match(string)
        .unwrap_or(false)
    {
        return status::Custom(
            Status::BadRequest,
            json!({"result":"naughty", "reason": "more types of chars"}),
        );
    }

    let num_digits = string.chars().filter(|c| c.is_numeric()).count();

    if num_digits < 5 {
        return status::Custom(
            Status::BadRequest,
            json!({"result":"naughty", "reason": "55555"}),
        );
    }

    let sum: u32 = Regex::new(r"[0-9]+").unwrap().find_iter(string).map(|n| n.unwrap().as_str().parse::<u32>().unwrap()).sum();

    dbg!(sum);

    if sum != 2023 {
        return status::Custom(
            Status::BadRequest,
            json!({"result":"naughty", "reason": "math is hard"}),
        );
    }

    if !Regex::new(r".*j.*o.*y.*").unwrap().is_match(string).unwrap() {
        return status::Custom(
            Status::NotAcceptable,
            json!({"result":"naughty", "reason": "not joyful enough"}),
        );
    }

    status::Custom(
        Status::Ok,
        json!({"result": "nice", "reason": "that's a nice password"}),
    )
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY15", |rocket| async { rocket.mount("/", routes![nice, game]) })
}
