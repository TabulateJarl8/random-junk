use rand::Rng;

fn main() {
    let words_string = include_str!("words.txt");
    let words: Vec<&str> = words_string.split("\n").collect();

    let selected_word: &str = words[rand::thread_rng().gen_range(0..words.len())];
    println!("{}", selected_word);
}
