// -1

use axum::{
    http::{header, StatusCode},
    response::IntoResponse,
    routing::get,
    Router,
};

async fn hello_world() -> &'static str {
    "Hello, bird!"
}

async fn redirect_response() -> impl IntoResponse {
    (
        StatusCode::FOUND,
        [(
            header::LOCATION,
            "https://www.youtube.com/watch?v=9Gc4QTqslN4",
        )],
    )
}

pub fn get_routes() -> Router {
    Router::new()
        .route("/", get(hello_world))
        .route("/-1/seek", get(redirect_response))
}
