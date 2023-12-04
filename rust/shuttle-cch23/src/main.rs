mod day0;
mod day1;
mod day4;

#[shuttle_runtime::main]
async fn main() -> shuttle_rocket::ShuttleRocket {
    let rocket = rocket::build()
        .attach(day0::stage())
        .attach(day1::stage())
        .attach(day4::stage());

    Ok(rocket.into())
}
