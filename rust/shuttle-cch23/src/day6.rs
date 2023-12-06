use fancy_regex::Regex;
use rocket::{routes, post, serde::json::{Value, json}};

#[post("/6", data = "<hidden_elves>")]
fn find_elves(hidden_elves: String) -> Value {
    let elf_count = hidden_elves.matches("elf").count();
    let elf_shelf_count = hidden_elves.matches("elf on a shelf").count();

    let shelf_no_elf_regex = Regex::new(r"(?<!elf on a )(shelf)").unwrap();
    let shelf_no_elf_count = match shelf_no_elf_regex.captures(&hidden_elves) {
        Ok(v) => match v {
            Some(c) => {println!("{:?}", c); c.len()},
            None => 0,
        },
        Err(_) => 0,
    };

    json!({"elf": elf_count, "elf on a shelf": elf_shelf_count, "shelf with no elf on it": shelf_no_elf_count})
}


pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY6", |rocket| async {
        rocket.mount("/", routes![find_elves])
    })
}
