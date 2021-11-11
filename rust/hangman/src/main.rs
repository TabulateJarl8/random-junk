use rand::Rng;
use ansi_term::Style;
use ansi_term::Colour::{Cyan, Yellow};
use std::io;
use std::io::Write;

mod hangman_generator;

fn main() {
    #[cfg(windows)]
    {
        let enable = ansi_term::enable_ansi_support();
        drop(enable);
    }


    println!("{}\n", Style::new().underline().paint("-- RUST HANGMAN --"));
    let words_string = include_str!("words.txt");
    let words: Vec<&str> = words_string.split("\n").collect();
    let mut alphabet: [&str; 26] = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
        "s", "t", "u", "v", "w", "x", "y", "z",
    ];

    let selected_word: String = String::from(words[rand::thread_rng().gen_range(0..words.len())]);

    // inconsequential memory management
    drop(words_string);
    drop(words);

    // define mistakes and blacklisted word
    let mut blacklisted_word: Vec<String> = (0..selected_word.len()).map(|_| String::from("_ ")).collect();
    let mut mistakes: usize = 0;

    // game loop

    loop {
        // clear screen and reset cursor to 1, 1
        print!("\x1B[2J\x1B[1;1H");

        // current word progress
        // println!("{}", selected_word);
        println!("{}: {}", Yellow.paint("Word"), blacklisted_word.join(""));

        // show current hangman
        println!("{}", hangman_generator::generate_hangman(mistakes));

        if mistakes == hangman_generator::HANGMANPICS.len() - 1 {
            println!("\nYou lose. The word was: {}", selected_word);
            break;
        }
        if selected_word == str::replace(&blacklisted_word.join("").as_str(), " ", "") {
            println!("You win!");
            break;
        }

        // print available alphabet
        println!("{}", alphabet.join(" "));

        print!("\n{}: ", Cyan.underline().paint("Input a letter"));
        io::stdout().flush().expect("Failed to flush stdout buffer");

        // input user guess
        let mut guess = String::new();
        io::stdin().read_line(&mut guess).expect("Failed to read stdin buffer");

        let guess = guess.trim().to_lowercase();
        let guess_character = guess.chars().next().unwrap();

        // validate user input
        if !(guess.len() == 1) {
            // warn user and restart loop
            println!("Please input 1 character\n\n");
            continue;
        }

        if !(guess_character.is_alphabetic()) {
            println!("Please input an alphabetic character");
            continue;
        }

        if !(alphabet.contains(&guess.as_str())) {
            println!("Please input a character that you haven\'t already tried");
            continue;
        }

        // valid guess; remove letter from alphabet
        alphabet[(guess_character as u32 - 97) as usize] = " ";

        if selected_word.contains(&guess_character.to_string()) {
            // correct guess; set all instances of character in blacklisted list to correct character
            let indexes_of_matches: Vec<usize> = selected_word.match_indices(guess_character).map(|(i, _)|i).collect();
            for index in indexes_of_matches.iter() {
                blacklisted_word[*index] = format!("{} ", guess_character);
            }

        } else {
            mistakes += 1;
        }
    }
}
