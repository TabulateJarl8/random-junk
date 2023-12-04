use rocket::{get, routes};

#[get("/")]
fn index() -> &'static str {
    "Hello, world!"
}

#[get("/-1/error")]
fn error_500() {
    panic!();
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY4", |rocket| async {
        rocket.mount("/", routes![index, error_500])
    })
}
