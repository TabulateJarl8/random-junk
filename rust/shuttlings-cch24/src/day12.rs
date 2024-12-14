use std::{
    fmt::Display,
    sync::{Arc, Mutex},
};

use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Router,
};
use rand::{Rng, SeedableRng};
use serde::{de, Deserialize};

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
enum BoardTile {
    Empty,
    Cookie,
    Milk,
}

impl<'de> Deserialize<'de> for BoardTile {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let variant = String::deserialize(deserializer)?;
        match variant.as_str() {
            "cookie" => Ok(BoardTile::Cookie),
            "milk" => Ok(BoardTile::Milk),
            _ => Err(de::Error::custom(
                "invalid tile name provided, expected cookie or milk",
            )),
        }
    }
}

impl Display for BoardTile {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BoardTile::Empty => write!(f, "⬛"),
            BoardTile::Cookie => write!(f, "🍪"),
            BoardTile::Milk => write!(f, "🥛"),
        }
    }
}

const ROW_LENGTH: usize = 4;

#[derive(Debug)]
struct AppState {
    board: [BoardTile; ROW_LENGTH * ROW_LENGTH],
    rng_seed: rand::rngs::StdRng,
}

impl AppState {
    fn new() -> Self {
        AppState {
            board: AppState::new_board(),
            rng_seed: rand::rngs::StdRng::seed_from_u64(2024),
        }
    }

    fn new_board() -> [BoardTile; ROW_LENGTH * ROW_LENGTH] {
        [BoardTile::Empty; ROW_LENGTH * ROW_LENGTH]
    }

    fn reset_board(&mut self) {
        self.board = AppState::new_board();
        self.rng_seed = rand::rngs::StdRng::seed_from_u64(2024);
    }

    fn check_winner(&self) -> Option<BoardTile> {
        // check rows
        for row in 0..ROW_LENGTH {
            let start = row * ROW_LENGTH;
            if self.board[row * ROW_LENGTH] != BoardTile::Empty
                && self.board[start..start + ROW_LENGTH]
                    .iter()
                    .all(|&cell| cell == self.board[start])
            {
                return Some(self.board[start]);
            }
        }

        // check cols
        for col in 0..ROW_LENGTH {
            if self.board[col] != BoardTile::Empty
                && (0..ROW_LENGTH).all(|row| self.board[col + row * ROW_LENGTH] == self.board[col])
            {
                return Some(self.board[col]);
            }
        }

        // check top left to bottom right diagonal
        if self.board[0] != BoardTile::Empty
            && (0..ROW_LENGTH).all(|i| self.board[i * (ROW_LENGTH + 1)] == self.board[0])
        {
            return Some(self.board[0]);
        }

        // check top right to bottom left diagonal
        if self.board[ROW_LENGTH - 1] != BoardTile::Empty
            && (0..ROW_LENGTH)
                .all(|i| self.board[(i + 1) * (ROW_LENGTH - 1)] == self.board[ROW_LENGTH - 1])
        {
            return Some(self.board[ROW_LENGTH - 1]);
        }

        // entire board is filled, return empty to signify loss
        if self.board.iter().all(|&cell| cell != BoardTile::Empty) {
            return Some(BoardTile::Empty);
        }

        None
    }

    fn gen_random_board(&mut self) {
        self.board.iter_mut().for_each(|tile| {
            *tile = if self.rng_seed.gen::<bool>() {
                BoardTile::Cookie
            } else {
                BoardTile::Milk
            }
        });
    }
}

impl Display for AppState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for i in 0..self.board.len() {
            // print starting wall
            if i % ROW_LENGTH == 0 {
                write!(f, "⬜")?;
            }

            // write the current cell
            write!(f, "{}", self.board[i])?;

            // write the ending wall/newline
            if i % ROW_LENGTH == ROW_LENGTH - 1 {
                writeln!(f, "⬜")?;
            }
        }

        // write final row of walls
        writeln!(f, "⬜⬜⬜⬜⬜⬜")?;

        // check win status
        if let Some(winner) = self.check_winner() {
            match winner {
                BoardTile::Empty => writeln!(f, "No winner.")?,
                BoardTile::Cookie | BoardTile::Milk => writeln!(f, "{} wins!", winner)?,
            }
        }
        Ok(())
    }
}

async fn get_board(State(state): axum::extract::State<Arc<Mutex<AppState>>>) -> impl IntoResponse {
    state.lock().unwrap().to_string()
}

async fn gen_random_board(
    State(state): axum::extract::State<Arc<Mutex<AppState>>>,
) -> impl IntoResponse {
    state.lock().unwrap().gen_random_board();
    state.lock().unwrap().to_string()
}

async fn place_item(
    Path((team, column)): Path<(BoardTile, usize)>,
    State(state): axum::extract::State<Arc<Mutex<AppState>>>,
) -> impl IntoResponse {
    if !(1..=ROW_LENGTH).contains(&column) {
        return (
            StatusCode::BAD_REQUEST,
            "invalid column value\n".to_string(),
        );
    }

    let board_length = ROW_LENGTH * ROW_LENGTH;
    let bottom_col_index = board_length - ((ROW_LENGTH - column) + 1);

    let mut state_guard = state.lock().unwrap();

    if state_guard.check_winner().is_some() {
        return (StatusCode::SERVICE_UNAVAILABLE, state_guard.to_string());
    }

    let board = &mut state_guard.board;

    for index in (column - 1..=bottom_col_index).rev().step_by(ROW_LENGTH) {
        match board[index] {
            BoardTile::Empty => {
                board[index] = team;
                // return the board with 200 OK
                return (StatusCode::OK, state_guard.to_string());
            }
            BoardTile::Cookie | BoardTile::Milk => (),
        }
    }

    // no open spots were found, return 503
    (StatusCode::SERVICE_UNAVAILABLE, state_guard.to_string())
}

async fn reset_board(
    State(state): axum::extract::State<Arc<Mutex<AppState>>>,
) -> impl IntoResponse {
    state.lock().unwrap().reset_board();
    state.lock().unwrap().to_string()
}

pub fn get_routes() -> Router {
    let state = Arc::new(Mutex::new(AppState::new()));
    Router::new()
        .route("/12/board", get(get_board))
        .route("/12/reset", post(reset_board))
        .route("/12/place/:team/:column", post(place_item))
        .route("/12/random-board", get(gen_random_board))
        .with_state(state)
}
