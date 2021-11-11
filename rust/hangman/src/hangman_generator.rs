// this file only contains the code for generating the hangman, as
// the ASCII art gets quite cluttered

pub const HANGMANPICS: [&str; 7] = ["
  +---+
  |   |
      |
      |
      |
      |
=========", "
  +---+
  |   |
  O   |
      |
      |
      |
=========", "
  +---+
  |   |
  O   |
  |   |
      |
      |
=========", "
  +---+
  |   |
  O   |
 /|   |
      |
      |
=========", "
  +---+
  |   |
  O   |
 /|\\  |
      |
      |
=========", "
  +---+
  |   |
  O   |
 /|\\  |
 /    |
      |
=========", "
  +---+
  |   |
  O   |
 /|\\  |
 / \\  |
      |
========="];

pub fn generate_hangman(mistakes: usize) -> &'static str {

    HANGMANPICS[mistakes]
}