use std::f32::consts::PI;

#[derive(Debug)]
struct Circle {
    radius: f32,
}

impl Circle {
    fn circumference(&self) -> f32 {
        return 2.0 * self.radius * PI;
    }

    fn area(&self) -> f32 {
        return PI * (f32::powf(self.radius, 2.0));
    }
}

fn main() {
    let circ = Circle {
        radius: 5.0,
    };
    println!("Circumference: {}", circ.circumference());
    println!("Area: {}", circ.area());
}
