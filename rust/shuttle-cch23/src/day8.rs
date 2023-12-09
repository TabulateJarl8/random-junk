use rocket::{get, routes, serde::Deserialize};

#[derive(Deserialize, Debug)]
#[serde(crate = "rocket::serde")]
struct PokeResp {
    weight: f32,
}

async fn get_pokemon_weight(pokedex_number: u32) -> f32 {
    let resp = reqwest::get(format!(
        "https://pokeapi.co/api/v2/pokemon/{}",
        pokedex_number
    ))
    .await
    .unwrap()
    .json::<PokeResp>()
    .await
    .unwrap();

    // pokemon weight is in hg, convert to kg
    resp.weight / 10.0
}

#[get("/8/weight/<pokedex_number>")]
async fn pokemon_weight(pokedex_number: u32) -> String {
    get_pokemon_weight(pokedex_number).await.to_string()
}

#[get("/8/drop/<pokedex_number>")]
async fn pokemon_momentum(pokedex_number: u32) -> String {
    let weight = get_pokemon_weight(pokedex_number).await;

    // p = m*g*t
    // t = sqrt(2h/g)
    let height: f32 = 10.0;
    let g: f32 = 9.825;
    // let m: f32 = weight * g;

    let time = (2.0 * height / g).sqrt();
    (weight * g * time).to_string()
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY8", |rocket| async {
        rocket.mount("/", routes![pokemon_weight, pokemon_momentum])
    })
}
