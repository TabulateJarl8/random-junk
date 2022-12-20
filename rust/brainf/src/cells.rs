use std::io::{Read, Write};

#[derive(Debug)]
pub struct Cells {
    cells: Vec<u32>,
    pointer: usize,
    integer_max: u32,
}

impl Cells {
    pub fn new(cell_size_bits: u8) -> Cells {
        Cells {
            cells: vec![0],
            pointer: 0,
            integer_max: match cell_size_bits {
                8 => u8::MAX.into(),
                16 => u16::MAX.into(),
                32 => u32::MAX,
                _ => panic!("invalid cell size"),
            }
        }
    }

    fn seek_left(&mut self) {
        if self.pointer == 0 {
            // beginning of cells, insert another
            self.cells.insert(0, 0);
        } else {
            self.pointer -= 1;
        }
    }

    fn seek_right(&mut self) {
        if (self.pointer + 1) as usize == self.cells.len() {
            self.cells.push(0)
        }

        self.pointer += 1;
    }

    fn increment(&mut self) {
        if self.cells[self.pointer] as u32 != self.integer_max {
            self.cells[self.pointer] += 1;
        } else {
            // current cell is integer_max, overflow to 0
            self.cells[self.pointer] = 0;
        }
    }

    fn decrement(&mut self) {
        if self.cells[self.pointer] != 0 {
            self.cells[self.pointer] -= 1;
        } else {
            // current cell is 0, underflow to integer_max
            self.cells[self.pointer] = self.integer_max;
        }
    }

    fn print_current_cell(&self) {
        print!("{}", char::from_u32(self.cells[self.pointer]).unwrap_or('�'));
        std::io::stdout().flush().unwrap();
    }

    fn take_user_input(&mut self) {
        let input_as_bytes: Option<u32> = std::io::stdin()
            .bytes()
            .next()
            .and_then(|result| result.ok())
            .map(|byte| byte as u32);

        self.cells[self.pointer] = input_as_bytes.unwrap();
    }

    pub fn current_cell_is_zero(&self) -> bool {
        self.cells[self.pointer] == 0
    }

    pub fn run_instruction_set(&mut self, instructions: &str) {
        for char in instructions.chars() {
            match char {
                '+' => self.increment(),
                '-' => self.decrement(),
                '<' => self.seek_left(),
                '>' => self.seek_right(),
                ',' => self.take_user_input(),
                '.' => self.print_current_cell(),
                _ => (),
            }
        }
    }
}