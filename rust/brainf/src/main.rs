use std::{
    path::PathBuf,
    fs,
};
use clap::{arg, command, value_parser};
use regex::Regex;

mod cells;
mod runner;

fn main() {
    let matches = command!()
        .arg(
            arg!(
                <FILE> "Input file"
            )
            .required(true)
            .value_parser(value_parser!(PathBuf))
        )
        .arg(
            arg!(
                -s --cellsize <CELLSIZE> "Cell Size (bits)"
            )
            .required(false)
            .value_parser(value_parser!(u8).range(8..=32))
            .default_value("8")
        )
        .get_matches();

    let cellsize = match matches.get_one::<u8>("cellsize") {
        Some(8) => 8,
        Some(16) => 16,
        Some(32) => 32,
        _ => panic!("Error: cellsize argument must be either 8, 16, or 32"), 
    };

    let input_file = matches.get_one::<PathBuf>("FILE").unwrap();
    let brainf = fs::read_to_string(input_file).expect("Unable to read input file");
    
    let re = Regex::new(r"[^<>+\-,.\[\]]").unwrap();
    let formatted_brainf = re.replace_all(&brainf, "").to_string();

    let mut cells_object = cells::Cells::new(cellsize);
    let mut brainf = runner::BrainF::new(formatted_brainf);
    brainf.parse_code();
    brainf.run(&mut cells_object);

}