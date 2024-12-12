use std::{
    sync::{Arc, Mutex},
    time::Duration,
};

use axum::{
    extract::State,
    http::{header::CONTENT_TYPE, HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
    Json, Router,
};
use leaky_bucket::RateLimiter;
use serde::{Deserialize, Serialize};

struct AppState {
    limiter: RateLimiter,
}

impl AppState {
    fn new() -> Self {
        AppState {
            limiter: AppState::construct_new_limiter(),
        }
    }

    /// Construct and return a new pre-configured rate limiter object
    fn construct_new_limiter() -> RateLimiter {
        RateLimiter::builder()
            .initial(5)
            .max(5)
            .interval(Duration::from_millis(1000))
            .refill(1)
            .build()
    }

    /// Reset the rate limiter object to it's original state
    fn reset_limiter(&mut self) {
        self.limiter = AppState::construct_new_limiter();
    }
}

#[derive(Deserialize, Serialize, Debug)]
#[serde(rename_all = "lowercase")]
enum Unit {
    Liters(f32),
    Gallons(f32),
    Litres(f32),
    Pints(f32),
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)] // for the mutually exclusive units
struct MilkData {
    #[serde(flatten)]
    unit: Unit,
}

async fn milk(
    headers: HeaderMap,
    State(state): State<Arc<Mutex<AppState>>>,
    body: String,
) -> Response {
    let has_json = match headers.get(CONTENT_TYPE) {
        Some(val) => val == "application/json",
        None => false,
    };

    let rate_limit_success = state.lock().unwrap().limiter.try_acquire(1);

    // rate limiter errors
    if !rate_limit_success {
        return (StatusCode::TOO_MANY_REQUESTS, "No milk available\n").into_response();
    }

    if !has_json {
        // rate limit succeeded but no json provided, respond as normal
        (StatusCode::OK, "Milk withdrawn\n").into_response()
    } else {
        // attempt to parse the json
        let json = match serde_json::from_str::<MilkData>(&body) {
            Ok(v) => v,
            Err(_) => return (StatusCode::BAD_REQUEST, "Invalid JSON Data\n").into_response(),
        };

        // convert between gallons and liters
        let converted_value = match json.unit {
            Unit::Liters(liters) => (
                StatusCode::OK,
                Json(MilkData {
                    unit: Unit::Gallons(liters / 3.785_411_8),
                }),
            ),
            Unit::Gallons(gallons) => (
                StatusCode::OK,
                Json(MilkData {
                    unit: Unit::Liters(gallons * 3.785_411_8),
                }),
            ),
            Unit::Litres(litres) => (
                StatusCode::OK,
                Json(MilkData {
                    unit: Unit::Pints(litres * 1.759_754),
                }),
            ),
            Unit::Pints(pints) => (
                StatusCode::OK,
                Json(MilkData {
                    unit: Unit::Litres(pints / 1.759_754),
                }),
            ),
        };

        converted_value.into_response()
    }
}

async fn refill_rate_limit(State(state): State<Arc<Mutex<AppState>>>) -> Response {
    // reset the rate limiter to refill the bucket
    state.lock().unwrap().reset_limiter();

    StatusCode::OK.into_response()
}

pub fn get_routes() -> Router {
    let state = Arc::new(Mutex::new(AppState::new()));
    Router::new()
        .route("/9/milk", post(milk))
        .route("/9/refill", post(refill_rate_limit))
        .with_state(state)
}
