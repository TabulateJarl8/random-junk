use rocket::launch;

mod day0;
mod day1;
mod day4;
mod day6;
mod day7;

// #[shuttle_runtime::main]
// async fn main() -> shuttle_rocket::ShuttleRocket {
#[launch]
fn rocket() -> _ {
    let rocket = rocket::build()
        .attach(day0::stage())
        .attach(day1::stage())
        .attach(day4::stage())
        .attach(day6::stage())
        .attach(day7::stage());

    rocket

    // Ok(rocket.into())
}
