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
    // accept toml, yaml, or json manifests
    let body_string = match headers.get(CONTENT_TYPE).map(|x| x.as_bytes()) {
        Some(b"application/toml") => body,
        Some(b"application/json") => {
            let mut toml = String::new();

            let mut deserializer = serde_json::Deserializer::from_str(&body);
            let serializer = toml::ser::Serializer::pretty(&mut toml);
            serde_transcode::transcode(&mut deserializer, serializer).unwrap();
            toml
        }
        Some(b"application/yaml") => {
            let mut toml = String::new();

            let deserializer = serde_yaml::Deserializer::from_str(&body);
            let serializer = toml::ser::Serializer::pretty(&mut toml);
            serde_transcode::transcode(deserializer, serializer).unwrap();
            toml
        }
        _ => return (StatusCode::UNSUPPORTED_MEDIA_TYPE, "".to_string()),
    };

    // check for valid toml manifest
    let manifest = match Manifest::from_str(&body_string) {
        Ok(v) => v,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid manifest".to_string()),
    };

    // check that keywords are present in package
    let keywords = match manifest.package.clone().and_then(|p| p.keywords) {
        Some(k) => k.as_local().unwrap(),
        None => {
            return (
                StatusCode::BAD_REQUEST,
                "Magic keyword not provided".to_string(),
            )
        }
    };

    // check that keywords contain the magic keyword
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
