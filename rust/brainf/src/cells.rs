use std::io::{Read, Write};

#[derive(Debug)]
pub struct Cells {
    /// A Vector to represent the stack
    cells: Vec<u32>,
    /// The pointer to the current memory cell
    pointer: usize,
    /// The maximum integer value for a memory cell
    integer_max: u32,
}

impl Cells {
    pub fn new(cell_size_bits: u8) -> Self {
        Self {
            cells: vec![0],
            pointer: 0,
            integer_max: match cell_size_bits {
                8 => u8::MAX.into(),
                16 => u16::MAX.into(),
                32 => u32::MAX,
                _ => panic!("invalid cell size"),
            },
        }
    }

    /// Move the pointer one cell to the left
    /// Inserts a new cell at the beginning if pointer is 0
    fn seek_left(&mut self) {
        if self.pointer == 0 {
            // beginning of cells, insert another
            self.cells.insert(0, 0);
        } else {
            self.pointer -= 1;
        }
    }

    /// Move the pointer one cell to the right
    /// Inserts a new cell at the end if the pointer is at the end of the stack
    fn seek_right(&mut self) {
        if self.pointer + 1 == self.cells.len() {
            // end of cells, insert one at the end
            self.cells.push(0);
        }

        self.pointer += 1;
    }

    /// Increment the value in the current memory cell
    /// If the value is INTEGER_MAX, overflow to 0
    fn increment(&mut self) {
        if self.cells[self.pointer] != self.integer_max {
            self.cells[self.pointer] += 1;
        } else {
            // current cell is integer_max, overflow to 0
            self.cells[self.pointer] = 0;
        }
    }

    /// Decrement the value in the current memory cell
    /// If the value is 0, overflow to INTEGER_MAX
    fn decrement(&mut self) {
        if self.cells[self.pointer] != 0 {
            self.cells[self.pointer] -= 1;
        } else {
            // current cell is 0, underflow to integer_max
            self.cells[self.pointer] = self.integer_max;
        }
    }

    /// Convert the numerical value in the current memory cell to its Unicode representation and print it
    /// Does not print a newline
    /// If the character is not a valid unicode number, if will print uFFFD
    fn print_current_cell(&self) {
        print!(
            "{}",
            char::from_u32(self.cells[self.pointer]).unwrap_or('\u{fffd}')
        );
        std::io::stdout().flush().unwrap();
    }

    /// Read a character from stdin and store it's unicode value in the current cell
    fn take_user_input(&mut self) {
        let input_as_bytes: Option<u32> = std::io::stdin()
            .bytes()
            .next()
            .and_then(|result| result.ok())
            .map(|byte| byte as u32);

        self.cells[self.pointer] = input_as_bytes.unwrap();
    }

    /// Test if the value in the current memory cell is 0
    pub fn current_cell_is_zero(&self) -> bool {
        self.cells[self.pointer] == 0
    }

    /// Run each parsed BrainF instruction
    pub fn run_instruction_set(&mut self, instructions: &str) {
        // Iterate through each character in the input instructions
        for char in instructions.chars() {
            match char {
                '+' => self.increment(),
                '-' => self.decrement(),
                '<' => self.seek_left(),
                '>' => self.seek_right(),
                ',' => self.take_user_input(),
                '.' => self.print_current_cell(),
                // Ignore any other characters in the instruction set
                _ => (),
            }
        }
    }
}
