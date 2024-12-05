use axum::Router;

mod day01;
mod day02;
mod day05;

#[shuttle_runtime::main]
async fn main() -> shuttle_axum::ShuttleAxum {
    let router = Router::new()
        .merge(day01::get_routes())
        .merge(day02::get_routes())
        .merge(day05::get_routes());

    Ok(router.into())
}
