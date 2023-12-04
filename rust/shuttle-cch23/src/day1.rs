use std::path::PathBuf;

use rocket::{get, routes};

#[get("/1/<nums..>")]
fn cube_bits(nums: PathBuf) -> String {
    let mut xors = 0;
    for num in nums.components() {
        xors ^= num
            .as_os_str()
            .to_string_lossy()
            .to_string()
            .parse::<i32>()
            .unwrap();
    }
    xors.pow(3).to_string()
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY4", |rocket| async {
        rocket.mount("/", routes![cube_bits])
    })
}
