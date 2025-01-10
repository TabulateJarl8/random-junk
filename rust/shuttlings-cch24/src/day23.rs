use std::borrow::Borrow;

use axum::{
    extract::{Multipart, Path},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{get, post},
    Router,
};
use toml::Table;

const SUPPORTED_COLORS: [&str; 3] = ["red", "blue", "purple"];

async fn get_star() -> impl IntoResponse {
    "<div id=\"star\" class=\"lit\"></div>"
}

async fn get_present_color(Path(color): Path<String>) -> Response {
    let sanitized_color = html_escape::encode_safe(&color);
    let color_index = match SUPPORTED_COLORS.iter().position(|&r| r == sanitized_color) {
        Some(idx) => idx,
        None => return StatusCode::IM_A_TEAPOT.into_response(),
    };

    let next_color_index = (color_index + 1) % SUPPORTED_COLORS.len();

    format!(
        r###"
    <div class="present {}" hx-get="/23/present/{}" hx-swap="outerHTML">
                    <div class="ribbon"></div>
                    <div class="ribbon"></div>
                    <div class="ribbon"></div>
                    <div class="ribbon"></div>
                </div>
    "###,
        SUPPORTED_COLORS[color_index], SUPPORTED_COLORS[next_color_index]
    )
    .into_response()
}

async fn get_ornament(Path((state, id)): Path<(String, String)>) -> Response {
    let sanitized_state = html_escape::encode_safe(&state);
    let sanitized_id = html_escape::encode_safe(&id);

    // validate state
    let (next_state, state_class) = match sanitized_state.borrow() {
        "on" => ("off", " on"),
        "off" => ("on", ""),
        _ => return StatusCode::IM_A_TEAPOT.into_response(),
    };

    format!(
        r#"<div class="ornament{state_class}" id="ornament{id}" hx-trigger="load delay:2s once" hx-get="/23/ornament/{next_state}/{id}" hx-swap="outerHTML"></div>"#,
        id = sanitized_id,
        state_class = state_class,
        next_state = next_state
    ).into_response()
}

async fn upload_lockfile(mut multipart: Multipart) -> Response {
    let mut sprinkles = String::new();

    let field = match multipart.next_field().await {
        Ok(v) => match v {
            Some(f) => f,
            None => return StatusCode::BAD_REQUEST.into_response(),
        },
        Err(_) => return StatusCode::BAD_REQUEST.into_response(),
    };

    let data = field.text().await.unwrap();
    let lockfile = match data.parse::<Table>() {
        Ok(v) => v,
        Err(_) => return StatusCode::BAD_REQUEST.into_response(),
    };

    let package_arr = match lockfile.get("package") {
        Some(v) => match v.as_array() {
            Some(a) => a,
            None => return StatusCode::BAD_REQUEST.into_response(),
        },
        None => return StatusCode::BAD_REQUEST.into_response(),
    };

    for dependency in package_arr {
        let checksum = match dependency.get("checksum") {
            Some(v) => match v.as_str() {
                Some(s) => s,
                None => return StatusCode::BAD_REQUEST.into_response(),
            },
            None => {
                // skip this iteration when theres no checksum field
                continue;
            }
        };

        let hex_code = checksum.chars().take(6).collect::<String>();
        let top_str = checksum.chars().skip(6).take(2).collect::<String>();
        let left_str = checksum.chars().skip(8).take(2).collect::<String>();

        if hex_code.len() != 6 || top_str.len() != 2 || left_str.len() != 2 {
            return StatusCode::UNPROCESSABLE_ENTITY.into_response();
        }

        // validate that hex code is valid hex
        match u64::from_str_radix(&hex_code, 16) {
            Ok(_) => (),
            Err(_) => return StatusCode::UNPROCESSABLE_ENTITY.into_response(),
        }

        let top_num = match u64::from_str_radix(&top_str, 16) {
            Ok(v) => v,
            Err(_) => return StatusCode::UNPROCESSABLE_ENTITY.into_response(),
        };

        let left_num = match u64::from_str_radix(&left_str, 16) {
            Ok(v) => v,
            Err(_) => return StatusCode::UNPROCESSABLE_ENTITY.into_response(),
        };

        sprinkles.push_str(
             &format!(
                r#"<div style="background-color:#{hex_code};top:{top_num}px;left:{left_num}px;"></div>"#,
                hex_code = hex_code,
                top_num = top_num,
                left_num = left_num
            ));
    }

    sprinkles.into_response()
}

pub fn get_routes() -> Router {
    Router::new()
        .route("/23/star", get(get_star))
        .route("/23/present/{color}", get(get_present_color))
        .route("/23/ornament/{state}/{n}", get(get_ornament))
        .route("/23/lockfile", post(upload_lockfile))
}
