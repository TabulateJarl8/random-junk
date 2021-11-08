use rand::Rng;

pub fn get_fact() -> String {
    let bytes = include_bytes!("safe.txt");
    let facts_string = String::from_utf8_lossy(bytes);
    let facts: Vec<&str> = facts_string.split("\n").collect();

    facts[rand::thread_rng().gen_range(0..facts.len())].to_string()
}
