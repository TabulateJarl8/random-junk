enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter(USState),
}

#[derive(Debug)]
enum USState {
    Virginia,
    NewJersey,
    NewYork,
    NCarolina,
    SCarolina,
}

fn value_in_cents(coin: Coin) -> u8 {
    match coin {
        Coin::Penny => 1,
        Coin::Nickel => 5,
        Coin::Dime => 10,
        Coin::Quarter(state) => {
            println!("From: {:?}", state);
            25
        }
    }
}

fn main() {
    println!("{}", value_in_cents(Coin::Quarter(USState::Virginia)));
}
