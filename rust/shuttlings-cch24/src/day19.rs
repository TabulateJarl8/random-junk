use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use axum::{
    extract::{self, Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{delete, get, post, put},
    Json, Router,
};
use rand::{distributions::Alphanumeric, Rng};
use serde::{Deserialize, Serialize};
use serde_json::json;
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
    token_map: Arc<Mutex<HashMap<String, i32>>>,
}

#[derive(Debug, Deserialize)]
struct Pagination {
    token: Option<String>,
}

impl AppState {
    fn new(pool: sqlx::PgPool) -> Self {
        AppState {
            pool,
            token_map: Arc::new(Mutex::new(HashMap::new())),
        }
    }
}

async fn clear_quotes_table(State(state): extract::State<AppState>) -> impl IntoResponse {
    sqlx::query("DELETE FROM quotes")
        .execute(&state.pool)
        .await
        .unwrap();
}

/// return a quote from the table
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

async fn list_quotes(State(state): State<AppState>, pagination: Query<Pagination>) -> Response {
    // get page number, or 1 if not specified
    let page = if let Some(token) = pagination.0.token {
        let locked_map = state.token_map.lock().unwrap();
        match locked_map.get(&token) {
            Some(&v) => v,
            None => return StatusCode::BAD_REQUEST.into_response(),
        }
    } else {
        1
    };

    let offset = (page - 1) * 3;

    // get number of rows for page calculation
    let row_count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM quotes")
        .fetch_one(&state.pool)
        .await
        .unwrap();

    // fetch 3 rows from "page" to return
    match sqlx::query_as::<_, Quote>(
        "SELECT * FROM quotes ORDER BY created_at OFFSET $1 FETCH FIRST 3 ROWS ONLY",
    )
    .bind(offset)
    .fetch_all(&state.pool)
    .await
    {
        Ok(v) => {
            if i64::from(offset + 3) >= row_count {
                // no more pages after this
                Json(json!({"quotes": v, "page": page, "next_token": null})).into_response()
            } else {
                // generate random token for next page
                let next_token: String = rand::thread_rng()
                    .sample_iter(&Alphanumeric)
                    .take(16)
                    .map(char::from)
                    .collect();

                // insert token into hashmap
                let mut locked_map = state.token_map.lock().unwrap();
                locked_map.insert(next_token.clone(), page + 1);

                Json(json!({"quotes": v, "page": page, "next_token": next_token})).into_response()
            }
        }
        Err(_) => StatusCode::BAD_REQUEST.into_response(),
    }
}

pub fn get_routes(pool: sqlx::PgPool) -> Router {
    let state = AppState::new(pool);

    Router::new()
        .route("/19/reset", post(clear_quotes_table))
        .route("/19/cite/{id}", get(get_quote))
        .route("/19/remove/{id}", delete(remove_quote))
        .route("/19/undo/{id}", put(undo_quote))
        .route("/19/draft", post(create_quote))
        .route("/19/list", get(list_quotes))
        .with_state(state)
}
