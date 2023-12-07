use std::collections::HashMap;

use base64::{engine::general_purpose, Engine as _};
use rocket::{
    get,
    http::CookieJar,
    routes,
    serde::{self, json::{Value, json}},
};

fn base64_to_string(encoded: &str) -> Result<Value, anyhow::Error> {
    let bytes = general_purpose::STANDARD
        .decode(encoded)?;

    Ok(serde::json::from_str(&std::str::from_utf8(&bytes)?.to_string())?)
}

#[get("/7/decode")]
fn decode_cookie(cookies: &CookieJar<'_>) -> Value {
    let cookie_encoded = cookies.get("recipe").unwrap();
    base64_to_string(cookie_encoded.value()).unwrap()
}


#[get("/7/bake")]
fn bake_cookies(cookies: &CookieJar<'_>) -> Value {
    let cookie_stats = base64_to_string(cookies.get("recipe").unwrap().value()).unwrap();
    println!("{:?}", cookie_stats);
    let recipe = &cookie_stats["recipe"];
    let pantry = &cookie_stats["pantry"];

    // TODO: fix bonus #3
    let ingredients: Vec<&String> = recipe.as_object().unwrap().keys().collect();

    let num_cookies = ingredients.iter().map(|&item| pantry[item].as_u64().unwrap() / recipe[item].as_u64().unwrap()).min().unwrap();
    
    let mut new_pantry: HashMap<&str, u64> = HashMap::new();

    for item in ingredients {
        new_pantry.insert(item, pantry[item].as_u64().unwrap() - recipe[item].as_u64().unwrap() * num_cookies);
    }

    json!({
        "cookies": num_cookies,
        "pantry": new_pantry,
    })

}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY7", |rocket| async {
        rocket.mount("/", routes![decode_cookie, bake_cookies])
    })
}
