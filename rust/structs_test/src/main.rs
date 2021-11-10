use std::f32::consts::PI;

#[derive(Debug)]
struct Circle {
    radius: f32,
}

impl Circle {
    fn circumference(&self) -> f32 {
        2.0 * self.radius * PI
    }

    fn area(&self) -> f32 {
        PI * (f32::powf(self.radius, 2.0))
    }

    fn can_fit_in(&self, circ: &Circle) -> bool {
        circ.radius > self.radius
    }

    fn can_contain(&self, circ: &Circle) -> bool {
        circ.radius < self.radius
    }
}

fn main() {
    let circ = Circle {
        radius: 5.0,
    };
    let circ2 = Circle {
        radius: 6.0,
    };
    println!("Circumference small: {}", circ.circumference());
    println!("Area small: {}\n", circ.area());
    println!("Circumference large: {}", circ2.circumference());
    println!("Area large: {}\n", circ2.area());
    println!("Small fits in large? {}", circ.can_fit_in(&circ2));
    println!("Large fits in small? {}", circ2.can_fit_in(&circ));
    println!("Can contain small? {}", circ2.can_contain(&circ));
    println!("Can contain large? {}", circ.can_contain(&circ2));
}
