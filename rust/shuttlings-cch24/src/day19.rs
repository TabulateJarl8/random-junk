use axum::{
    extract::{self, Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{delete, get, post, put},
    Router,
};
use serde::{Deserialize, Serialize};
use sqlx::{
    prelude::FromRow,
    types::{
        chrono::{DateTime, Utc},
        Uuid,
    },
};

#[derive(Debug, Deserialize)]
struct CreateQuote {
    author: String,
    quote: String,
}

#[derive(Debug, Deserialize, Serialize, FromRow)]
struct Quote {
    id: Uuid,
    author: String,
    quote: String,
    created_at: DateTime<Utc>,
    version: i32,
}

#[derive(Debug, Clone)]
struct AppState {
    pool: sqlx::PgPool,
}

impl AppState {
    fn new(pool: sqlx::PgPool) -> Self {
        AppState { pool }
    }
}

async fn clear_quotes_table(State(state): extract::State<AppState>) -> impl IntoResponse {
    sqlx::query("DELETE FROM quotes")
        .execute(&state.pool)
        .await
        .unwrap();
}

async fn fetch_quote(id: Uuid, pool: &sqlx::PgPool) -> Result<Quote, sqlx::Error> {
    sqlx::query_as::<_, Quote>("SELECT * FROM quotes WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
}

async fn get_quote(
    Path(id): Path<Uuid>,
    State(state): extract::State<AppState>,
) -> impl IntoResponse {
    match fetch_quote(id, &state.pool).await {
        Ok(v) => (StatusCode::OK, serde_json::to_string(&v).unwrap()),
        Err(_) => (StatusCode::NOT_FOUND, "".to_string()),
    }
}

async fn remove_quote(
    Path(id): Path<Uuid>,
    State(state): extract::State<AppState>,
) -> impl IntoResponse {
    match sqlx::query_as::<_, Quote>("DELETE FROM quotes WHERE id = $1 RETURNING *")
        .bind(id)
        .fetch_one(&state.pool)
        .await
    {
        Ok(v) => (StatusCode::OK, serde_json::to_string(&v).unwrap()),
        Err(_) => (StatusCode::NOT_FOUND, "".to_string()),
    }
}

async fn undo_quote(
    Path(id): Path<Uuid>,
    State(state): extract::State<AppState>,
    extract::Json(payload): extract::Json<CreateQuote>,
) -> Response {
    if (sqlx::query(
        "UPDATE quotes SET author = $1, quote = $2, version = version + 1 WHERE id = $3",
    )
    .bind(payload.author)
    .bind(payload.quote)
    .bind(id)
    .execute(&state.pool)
    .await)
        .is_err()
    {
        return StatusCode::NOT_FOUND.into_response();
    };

    match fetch_quote(id, &state.pool).await {
        Ok(v) => (StatusCode::OK, serde_json::to_string(&v).unwrap()).into_response(),
        Err(_) => StatusCode::NOT_FOUND.into_response(),
    }
}

async fn create_quote(
    State(state): extract::State<AppState>,
    extract::Json(payload): extract::Json<CreateQuote>,
) -> Response {
    let dt = Utc::now();
    let id = Uuid::new_v4();
    if (sqlx::query("INSERT INTO quotes (id, author, quote, created_at) VALUES ($1, $2, $3, $4)")
        .bind(id)
        .bind(payload.author)
        .bind(payload.quote)
        .bind(DateTime::<Utc>::from_naive_utc_and_offset(
            dt.naive_utc(),
            *dt.offset(),
        ))
        .execute(&state.pool)
        .await)
        .is_err()
    {
        return StatusCode::NOT_FOUND.into_response();
    };

    match fetch_quote(id, &state.pool).await {
        Ok(v) => (StatusCode::CREATED, serde_json::to_string(&v).unwrap()).into_response(),
        Err(_) => StatusCode::NOT_FOUND.into_response(),
    }
}

pub fn get_routes(pool: sqlx::PgPool) -> Router {
    let state = AppState::new(pool);

    Router::new()
        .route("/19/reset", post(clear_quotes_table))
        .route("/19/cite/:id", get(get_quote))
        .route("/19/remove/:id", delete(remove_quote))
        .route("/19/undo/:id", put(undo_quote))
        .route("/19/draft", post(create_quote))
        .with_state(state)
}
