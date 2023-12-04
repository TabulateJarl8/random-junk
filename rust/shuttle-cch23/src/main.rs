use std::path::PathBuf;

use rocket::{get, routes};

#[get("/")]
fn index() -> &'static str {
    "Hello, world!"
}

#[get("/-1/error")]
fn error_500() {
    panic!();
}

#[get("/1/<nums..>")]
fn cube_bits(nums: PathBuf) -> String {
    let mut xors = 0;
    for num in nums.components() {
        xors = xors
            ^ num
                .as_os_str()
                .to_string_lossy()
                .to_string()
                .parse::<i32>()
                .unwrap();
    }
    xors.pow(3).to_string()
}

#[shuttle_runtime::main]
async fn main() -> shuttle_rocket::ShuttleRocket {
    let rocket = rocket::build().mount("/", routes![index, error_500, cube_bits]);

    Ok(rocket.into())
}
