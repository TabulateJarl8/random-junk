use axum::{
    extract,
    http::{header::SET_COOKIE, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Router,
};
use axum_extra::extract::CookieJar;
use jsonwebtoken::{decode, decode_header, encode, DecodingKey, EncodingKey, Header, Validation};
use serde_json::Value;

const SECRET: &str = "supersecretcode";

async fn create_jwt(extract::Json(payload): extract::Json<Value>) -> impl IntoResponse {
    let token = encode(
        &Header::default(),
        &payload,
        &EncodingKey::from_secret(SECRET.as_ref()),
    )
    .unwrap();
    let mut headers = HeaderMap::new();
    headers.insert(
        SET_COOKIE,
        HeaderValue::from_str(&format!("gift={}", token)).expect("cookie not formed correctly"),
    );

    (headers, "")
}

async fn decode_jwt_header(jar: CookieJar) -> impl IntoResponse {
    let jwt = match jar.get("gift") {
        Some(val) => val.value_trimmed(),
        None => return (StatusCode::BAD_REQUEST, "".to_string()),
    };

    let mut valid = Validation::default();
    valid.set_required_spec_claims::<String>(&[]);

    let decoded = decode::<Value>(jwt, &DecodingKey::from_secret(SECRET.as_ref()), &valid).unwrap();
    (StatusCode::OK, decoded.claims.to_string())
}

async fn decode_old_jwt(body: String) -> Response {
    let header = match decode_header(&body) {
        Ok(val) => val,
        Err(_) => return StatusCode::BAD_REQUEST.into_response(),
    };

    let mut valid = Validation::default();
    valid.set_required_spec_claims::<String>(&[]);
    valid.algorithms = vec![header.alg];

    let key = DecodingKey::from_rsa_pem(include_bytes!("day16_santa_public_key.pem")).unwrap();

    match decode::<Value>(&body, &key, &valid) {
        Ok(val) => val.claims.to_string().into_response(),
        Err(err) => match err.into_kind() {
            jsonwebtoken::errors::ErrorKind::InvalidSignature => StatusCode::UNAUTHORIZED,
            _ => StatusCode::BAD_REQUEST,
        }
        .into_response(),
    }
}

pub fn get_routes() -> Router {
    Router::new()
        .route("/16/wrap", post(create_jwt))
        .route("/16/unwrap", get(decode_jwt_header))
        .route("/16/decode", post(decode_old_jwt))
}
