use std::fs;

fn main() {
    let mut calories: Vec<u32> = Vec::new();
    let contents = fs::read_to_string("calories.txt").expect("error");
    let mut total_cal = 0;
    for line in contents.split("\n") {
        if line.trim().is_empty() {
            calories.push(total_cal);
            total_cal = 0;
        } else {
            total_cal += line.parse::<u32>().unwrap();
        }
    }

    println!("{}", calories.iter().max().unwrap());
}
