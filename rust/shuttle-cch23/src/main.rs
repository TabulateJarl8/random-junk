use rocket_db_pools::{sqlx, Database};
use rocket_dyn_templates::Template;
use shuttle_rocket::ShuttleRocket;

mod day0;
mod day1;
mod day11;
mod day12;
mod day13;
mod day14;
mod day15;
mod day19;
mod day4;
mod day6;
mod day7;
mod day8;

#[derive(Database)]
#[database("sqlx")]
struct DB(sqlx::PgPool);

#[shuttle_runtime::main]
async fn rocket() -> ShuttleRocket {
    let rocket = rocket::build()
        .attach(day0::stage())
        .attach(day1::stage())
        .attach(day4::stage())
        .attach(day6::stage())
        .attach(day7::stage())
        .attach(day8::stage())
        .attach(day11::stage())
        .attach(day12::stage())
        // .attach(day13::stage()).attach(DB::init())
        .attach(day14::stage())
        .attach(Template::fairing())
        .attach(day15::stage())
        .attach(day19::stage());

    Ok(rocket.into())
}

// #[macro_use]
// extern crate rocket;

// ...[Omitted Text]...

// use sqlx::{Executor, PgPool};

// #[get("/<id>")]
// async fn retrieve(id: i32, state: &State<MyState>) -> Result<Json<Todo>, BadRequest<String>> {
//     let todo = sqlx::query_as("SELECT * FROM todos WHERE id = $1")
//         .bind(id)
//         .fetch_one(&state.pool)
//         .await
//         .map_err(|e| BadRequest(e.to_string()))?;
//     Ok(Json(todo))
// }

// ...[Omitted Text]...

// #[shuttle_runtime::main]
// async fn rocket(#[shuttle_shared_db::Postgres] pool: PgPool) -> shuttle_rocket::ShuttleRocket {
//     pool.execute(include_str!("../schema.sql"))
//         .await
//         .map_err(CustomError::new)?;
//     let state = MyState { pool };
//     let rocket = rocket::build()
//         .mount("/todos", routes![retrieve, add])
//         .manage(state);
//     Ok(rocket.into())
// }
