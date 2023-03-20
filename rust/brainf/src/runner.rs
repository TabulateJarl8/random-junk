use crate::cells::Cells;

#[derive(Debug)]
pub struct BrainF {
    code: String,
    loop_count: u32,
    first_str: String,
    loop_str: String,
    second_str: String,
    loop_code: Option<Box<BrainF>>,
    second_code: Option<Box<BrainF>>,
}

impl BrainF {
    pub fn new(code: String) -> BrainF {
        BrainF {
            code: code,
            loop_count: 0,
            first_str: String::new(),
            loop_str: String::new(),
            second_str: String::new(),
            loop_code: None,
            second_code: None,
        }
    }

    pub fn parse_code(&mut self) -> &mut Self {
        for char in self.code.chars() {
            if self.loop_count == 0 && !self.loop_str.is_empty() {
                // we've already gone through the loop, append the rest to second
                self.second_str.push(char);
            } else if char == ']' {
                // attempt to close a loop if we haven't already been through
                self.loop_count -= 1;
            } else if char == '[' {
                self.loop_count += 1;
            } else if self.loop_count == 0 && self.loop_str.is_empty() {
                // not in a loop yet, append to first
                self.first_str.push(char);
            }

            if self.loop_count > 0 {
                // in loop currently; append to loop unless its the [ which opens the loop
                if !(char == '[' && self.loop_count == 1) {
                    self.loop_str.push(char);
                }
            }
        }

        if !self.loop_str.is_empty() {
            let mut loop_brainf = BrainF::new(self.loop_str.clone());
            loop_brainf.parse_code();
            self.loop_code = Some(Box::new(loop_brainf));
        }
        if !self.second_str.is_empty() {
            let mut second_brainf = BrainF::new(self.second_str.clone());
            second_brainf.parse_code();
            self.second_code = Some(Box::new(second_brainf));
        }

        self
    }

    pub fn run(&mut self, cells: &mut Cells) {
        cells.run_instruction_set(&self.first_str);
        if self.loop_code.is_some() {
            while !cells.current_cell_is_zero() {
                self.loop_code.as_mut().unwrap().run(cells);
            }
        }
        if self.second_code.is_some() {
            self.second_code.as_mut().unwrap().run(cells);
        }
    }
}
