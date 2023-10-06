use crate::cells::Cells;

#[derive(Debug)]
pub struct BrainF {
    /// The BrainF source code as a string
    code: String,
    /// Keeps track of the nested loop count
    loop_count: u32,
    /// The part of code before the first encountered loop
    first_str: String,
    /// The content of the first encountered loop (recurses into first_str, loop_str, and end_str)
    loop_str: String,
    /// The part of code after the first encountered loop
    second_str: String,
    /// The recursively parsed loop content as a BrainF object
    loop_code: Option<Box<BrainF>>,
    /// BrainF object representing the code after the loop
    second_code: Option<Box<BrainF>>,
}

impl BrainF {
    pub fn new(code: String) -> Self {
        Self {
            code,
            loop_count: 0,
            first_str: String::new(),
            loop_str: String::new(),
            second_str: String::new(),
            loop_code: None,
            second_code: None,
        }
    }

    /// Parse the BrainF code and structure into `first_str`, `loop_str`, and `second_str`
    pub fn parse_code(&mut self) -> &mut Self {
        for char in self.code.chars() {
            if self.loop_count == 0 && !self.loop_str.is_empty() {
                // we've already gone through the loop, append the rest to `second_str`
                self.second_str.push(char);
            } else if char == ']' {
                // attempt to close a loop if we haven't already been through
                self.loop_count -= 1;
            } else if char == '[' {
                // increment loop counter
                self.loop_count += 1;
            } else if self.loop_count == 0 && self.loop_str.is_empty() {
                // not in a loop yet, append to `first_str`
                self.first_str.push(char);
            }

            if self.loop_count > 0 {
                // in loop currently; append to `loop_str` unless its the [ which opens the loop
                if !(char == '[' && self.loop_count == 1) {
                    self.loop_str.push(char);
                }
            }
        }

        if !self.loop_str.is_empty() {
            // If `loop_str` is not empty, create a new 'BrainF' object for the loop and parse its content
            let mut loop_brainf = Self::new(self.loop_str.clone());
            loop_brainf.parse_code();
            self.loop_code = Some(Box::new(loop_brainf));
        }
        if !self.second_str.is_empty() {
            // If `second_str` is not empty, create a new 'BrainF' object for the code after the loop and parse it
            let mut second_brainf = Self::new(self.second_str.clone());
            second_brainf.parse_code();
            self.second_code = Some(Box::new(second_brainf));
        }

        self
    }

    /// Execute the BrainF code on the provided `Cells` object
    pub fn run(&mut self, cells: &mut Cells) {
        cells.run_instruction_set(&self.first_str);

        if self.loop_code.is_some() {
            // If a loop is defined and the current cell is not zero, execute the loop
            while !cells.current_cell_is_zero() {
                self.loop_code.as_mut().unwrap().run(cells);
            }
        }
        if self.second_code.is_some() {
            // If there's code after the loop, execute it
            self.second_code.as_mut().unwrap().run(cells);
        }
    }
}
