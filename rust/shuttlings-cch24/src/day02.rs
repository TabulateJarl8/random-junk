// Make a GET endpoint /2/dest that takes the query parameters from and key and responds with the dest address as text.

use std::net::{Ipv4Addr, Ipv6Addr};

use axum::{extract::Query, routing::get, Router};
use serde::Deserialize;

#[derive(Deserialize)]
struct DestParams {
    from: String,
    key: String,
}

#[derive(Deserialize)]
struct KeyParams {
    from: String,
    to: String,
}

async fn get_dest(params: Query<DestParams>) -> String {
    let destination = params.0;

    let from_addr = destination.from.parse::<Ipv4Addr>().unwrap();
    let key_addr = destination.key.parse::<Ipv4Addr>().unwrap();
    Ipv4Addr::new(
        from_addr.octets()[0]
            .overflowing_add(key_addr.octets()[0])
            .0,
        from_addr.octets()[1]
            .overflowing_add(key_addr.octets()[1])
            .0,
        from_addr.octets()[2]
            .overflowing_add(key_addr.octets()[2])
            .0,
        from_addr.octets()[3]
            .overflowing_add(key_addr.octets()[3])
            .0,
    )
    .to_string()
}

async fn get_key(params: Query<KeyParams>) -> String {
    let destination = params.0;

    let from_addr = destination.from.parse::<Ipv4Addr>().unwrap();
    let to_addr = destination.to.parse::<Ipv4Addr>().unwrap();
    Ipv4Addr::new(
        to_addr.octets()[0].overflowing_sub(from_addr.octets()[0]).0,
        to_addr.octets()[1].overflowing_sub(from_addr.octets()[1]).0,
        to_addr.octets()[2].overflowing_sub(from_addr.octets()[2]).0,
        to_addr.octets()[3].overflowing_sub(from_addr.octets()[3]).0,
    )
    .to_string()
}

async fn get_dest_ipv6(params: Query<DestParams>) -> String {
    let destination = params.0;

    let from_addr = destination.from.parse::<Ipv6Addr>().unwrap();
    let key_addr = destination.key.parse::<Ipv6Addr>().unwrap();
    Ipv6Addr::from_bits(from_addr.to_bits() ^ key_addr.to_bits()).to_string()
}

async fn get_key_ipv6(params: Query<KeyParams>) -> String {
    let destination = params.0;

    let from_addr = destination.from.parse::<Ipv6Addr>().unwrap();
    let to_addr = destination.to.parse::<Ipv6Addr>().unwrap();
    Ipv6Addr::from_bits(from_addr.to_bits() ^ to_addr.to_bits()).to_string()
}

pub fn get_routes() -> Router {
    Router::new()
        .route("/2/dest", get(get_dest))
        .route("/2/key", get(get_key))
        .route("/2/v6/dest", get(get_dest_ipv6))
        .route("/2/v6/key", get(get_key_ipv6))
}
