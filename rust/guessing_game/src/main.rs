use std::io;
use std::io::Write;
use std::process;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
	ctrlc::set_handler(move || {
		println!("SIGINT Recieved; Exiting");
		process::exit(0x0100);
	})
	.expect("Error settings Ctrl+C handler");
	
    let secret_number = rand::thread_rng().gen_range(1..101);

    println!("Guess the number");

    loop {
        print!("\nPlease input your guess: ");
        io::stdout().flush().expect("Failed to flush stdout buffer");

        let mut guess = String::new();

        io::stdin()
            .read_line(&mut guess)
            .expect("Failed to read line");

        let guess: u32 = match guess.trim().parse() {
                Ok(num) => num,
                Err(_) => {
                    if guess.trim().eq("exit") {
                        process::exit(0x0100);
                    }
                    println!("Please input a number");
                    continue;
                }
        };

        match guess.cmp(&secret_number) {
            Ordering::Less => println!("Too small"),
            Ordering::Greater => println!("Too big"),
            Ordering::Equal => {
                println!("You guessed it");
                break;
            }
        }
    }

}
