use std::collections::{HashMap, HashSet};

use base64::{engine::general_purpose, Engine as _};
use rocket::{
    get,
    http::CookieJar,
    routes,
    serde::{
        self,
        json::{json, Value},
    },
};

fn base64_to_string(encoded: &str) -> Result<Value, anyhow::Error> {
    let bytes = general_purpose::STANDARD.decode(encoded)?;

    Ok(serde::json::from_str(std::str::from_utf8(&bytes)?)?)
}

#[get("/7/decode")]
fn decode_cookie(cookies: &CookieJar<'_>) -> Value {
    let cookie_encoded = cookies.get("recipe").unwrap();
    base64_to_string(cookie_encoded.value()).unwrap()
}

#[get("/7/bake")]
fn bake_cookies(cookies: &CookieJar<'_>) -> Value {
    let cookie_stats = base64_to_string(cookies.get("recipe").unwrap().value()).unwrap();
    let recipe = &cookie_stats["recipe"];
    let pantry = &cookie_stats["pantry"];

    // create sets of recipe and pantry ingredients
    // this also removes any keys with values of 0
    let recipe_ingredients: HashSet<&str> = recipe
        .as_object()
        .unwrap()
        .iter()
        .filter(|&(_, v)| v.as_f64().unwrap() > 0.0)
        .map(|(key, _)| key.as_str())
        .collect();
    let pantry_ingredients: HashSet<&str> = pantry
        .as_object()
        .unwrap()
        .keys()
        .map(|s| s.as_str())
        .collect();

    // create intersection of the two to find the ingredients we need to iterate over
    let ingredients_intersection: HashSet<&str> = recipe_ingredients
        .intersection(&pantry_ingredients)
        .copied()
        .collect();

    // check that the intersection matches the entire recipe, if not, return nothing changed
    if !ingredients_intersection.is_superset(&recipe_ingredients) {
        return json!({"cookies": 0, "pantry": pantry});
    }

    let num_cookies = ingredients_intersection
        .iter()
        .map(|&item| {
            pantry.get(item).unwrap_or(&json!(-1)).as_i64().unwrap()
                / recipe.get(item).unwrap_or(&json!(-1)).as_i64().unwrap()
        })
        .min()
        .unwrap();

    let mut new_pantry: HashMap<&str, i64> = pantry
        .as_object()
        .unwrap()
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_i64().unwrap()))
        .collect();

    // check that all ingredients were able to be fullfilled
    if num_cookies <= 0 {
        return json!({"cookies": 0, "pantry": pantry});
    }

    // everything is valid, calculate what is lost from the pantry
    for item in ingredients_intersection {
        new_pantry.insert(item, new_pantry[item] - recipe[item].as_i64().unwrap() * num_cookies);
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
