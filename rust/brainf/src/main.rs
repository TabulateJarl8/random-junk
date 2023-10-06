use clap::{arg, command, value_parser};
use regex::Regex;
use std::{fs, path::PathBuf};

mod cells;
mod runner;

fn main() {
    let matches = command!()
        .arg(
            arg!(
                <FILE> "Input file"
            )
            .required(true)
            .value_parser(value_parser!(PathBuf)),
        )
        .arg(
            arg!(
                -s --cellsize <CELLSIZE> "Cell Size (bits)"
            )
            .required(false)
            .value_parser(value_parser!(u8).range(8..=32))
            .default_value("8"),
        )
        .get_matches();

    // extract the cell size from the arguments
    let cellsize = match matches.get_one::<u8>("cellsize") {
        Some(8) => 8,
        Some(16) => 16,
        Some(32) => 32,
        _ => panic!("Error: cellsize argument must be either 8, 16, or 32"),
    };

    // extract the input file path
    let input_file = matches.get_one::<PathBuf>("FILE").unwrap();
    // read the contents of the file into a string
    let brainf_file = fs::read_to_string(input_file).expect("Unable to read input file");

    // create a RE to remove any non-valid BrainF characters
    let re = Regex::new(r"[^<>+\-,.\[\]]").unwrap();
    let formatted_brainf = re.replace_all(&brainf_file, "").to_string();

    // Create a new `Cells` object with the specified cell size
    let mut cells_object = cells::Cells::new(cellsize);
    // Create a new `BrainF` object and parse the formatted `BrainF` source code
    let mut brainf = runner::BrainF::new(formatted_brainf);
    brainf.parse_code();

    // evaluate the BrainF code
    brainf.run(&mut cells_object);
}
