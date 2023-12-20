use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};

use rocket::{
    futures::{SinkExt, StreamExt},
    get, post, routes, State,
};
use rocket_ws::{Stream, WebSocket};

struct GameState {
    game_started: AtomicBool,
}

struct ChatState {
    views: AtomicU64,
}

#[get("/19/ws/ping")]
fn ping_game(ws: WebSocket, state: &State<GameState>) -> Stream!['_] {
    rocket_ws::Stream! { ws =>
        for await message in ws {
            let msg_text = match message.as_ref() {
                Ok(v) => v.to_text()?,
                Err(_) => "",
            };
            if msg_text == "serve" {
                let _ = state.game_started.fetch_update(Ordering::SeqCst, Ordering::SeqCst, |_| Some(true));
            }

            if state.game_started.load(Ordering::Relaxed) && msg_text == "ping" {
                yield "pong".into();
            }

        }
    }
}

#[post("/19/reset")]
fn reset_views(state: &State<ChatState>) {
    state.views.store(0, Ordering::Relaxed);
}

#[get("/19/views")]
fn get_views(state: &State<ChatState>) -> String {
    state.views.load(Ordering::Relaxed).to_string()
}

#[get("/19/ws/room/<number>/user/<string>")]
fn connect_chat_room<'r>(
    number: u32,
    string: String,
    ws: WebSocket,
    state: &State<ChatState>,
) -> rocket_ws::Channel<'r> {
    ws.channel(move |mut stream| {
        Box::pin(async move {
            while let Some(message) = stream.next().await {
                let _ = stream.send(message?).await;
            }

            Ok(())
        })
    })
}

pub fn stage() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("DAY19", |rocket| async {
        rocket
            .mount(
                "/",
                routes![ping_game, reset_views, get_views, connect_chat_room],
            )
            .manage(GameState {
                game_started: AtomicBool::new(false),
            })
            .manage(ChatState {
                views: AtomicU64::new(0),
            })
    })
}
