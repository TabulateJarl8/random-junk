use axum::{
    http::{header::CONTENT_TYPE, HeaderMap, StatusCode},
    response::IntoResponse,
    routing::post,
    Router,
};
use serde::Deserialize;
use toml::Value;

#[derive(Deserialize, Debug)]
struct Config {
    package: Package,
}

#[derive(Deserialize, Debug)]
struct Package {
    metadata: Metadata,
}

#[derive(Deserialize, Debug)]
struct Metadata {
    orders: Vec<Value>,
}

#[derive(Deserialize, Debug)]
struct Order {
    item: String,
    quantity: u16,
}

async fn manifest(headers: HeaderMap, body: String) -> impl IntoResponse {
    match headers.get(CONTENT_TYPE) {
        Some(content_type) => {
            if content_type != "application/toml" {
                return (StatusCode::BAD_REQUEST, "expected TOML data".to_string());
            }
        }
        None => return (StatusCode::BAD_REQUEST, "expected TOML data".to_string()),
    };

    // filter order data to only include valid orders
    let order_data = match toml::from_str::<Config>(&body) {
        Ok(v) => v
            .package
            .metadata
            .orders
            .into_iter()
            .filter_map(|o| o.try_into::<Order>().ok())
            .collect(),
        Err(_) => Vec::new(),
    };

    if order_data.is_empty() {
        return (
            StatusCode::NO_CONTENT,
            "no valid orders provided".to_string(),
        );
    }

    let mut response = String::new();

    // construct response string from valid orders
    order_data.into_iter().for_each(|order| {
        response.push_str(&format!("{}: {}\n", order.item, order.quantity));
    });

    (StatusCode::OK, response)
}

pub fn get_routes() -> Router {
    Router::new().route("/5/manifest", post(manifest))
}
