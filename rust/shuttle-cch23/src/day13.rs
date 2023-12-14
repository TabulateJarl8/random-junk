use rocket::routes;

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY13", |rocket| async { rocket.mount("/", routes![]) })
}
