use axum::Router;
use tower_http::services::ServeDir;

mod day01;
mod day02;
mod day05;
mod day09;
mod day12;
mod day16;
mod day19;
mod day23;

#[shuttle_runtime::main]
async fn main(#[shuttle_shared_db::Postgres] pool: sqlx::PgPool) -> shuttle_axum::ShuttleAxum {
    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("Failed to run migrations");

    let router = Router::new()
        .nest_service("/assets/", ServeDir::new("assets"))
        .merge(day01::get_routes())
        .merge(day02::get_routes())
        .merge(day05::get_routes())
        .merge(day09::get_routes())
        .merge(day12::get_routes())
        .merge(day16::get_routes())
        .merge(day19::get_routes(pool))
        .merge(day23::get_routes());

    Ok(router.into())
}
