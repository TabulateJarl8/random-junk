use rocket::launch;

mod day0;
mod day1;
mod day11;
mod day12;
mod day4;
mod day6;
mod day7;
mod day8;

#[launch]
fn rocket() -> _ {
    rocket::build()
        .attach(day0::stage())
        .attach(day1::stage())
        .attach(day4::stage())
        .attach(day6::stage())
        .attach(day7::stage())
        .attach(day8::stage())
        .attach(day11::stage())
        .attach(day12::stage())
}
