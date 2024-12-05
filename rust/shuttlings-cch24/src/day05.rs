use std::str::FromStr;

use axum::{
    http::{header::CONTENT_TYPE, HeaderMap, StatusCode},
    response::IntoResponse,
    routing::post,
    Router,
};
use cargo_manifest::Manifest;
use serde::Deserialize;

#[derive(Deserialize, Debug)]
struct Order {
    item: String,
    quantity: u32,
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

    let manifest = match Manifest::from_str(&body) {
        Ok(v) => v,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid manifest".to_string()),
    };

    let keywords = match manifest.package.clone().and_then(|p| p.keywords) {
        Some(k) => k.as_local().unwrap(),
        None => {
            return (
                StatusCode::BAD_REQUEST,
                "Magic keyword not provided".to_string(),
            )
        }
    };

    if !keywords.contains(&"Christmas 2024".to_string()) {
        return (
            StatusCode::BAD_REQUEST,
            "Magic keyword not provided".to_string(),
        );
    }

    let metadata = manifest.package.and_then(|p| p.metadata);

    // filter order data to only include valid orders
    let order_data: Vec<Order> = match metadata {
        Some(m) => match m.get("orders") {
            Some(v) => v
                .as_array()
                .unwrap()
                .iter()
                .cloned()
                .filter_map(|o| o.try_into().ok())
                .collect(),
            None => Vec::new(),
        },
        None => Vec::new(),
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

    (StatusCode::OK, response.trim_end().to_string())
}

pub fn get_routes() -> Router {
    Router::new().route("/5/manifest", post(manifest))
}
