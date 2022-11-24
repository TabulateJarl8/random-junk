use std::time::Instant; 
use num_bigint::BigInt;

fn intensive() -> f64 {
    let mut result: f64 = 0.0;
    let base_num = 8;
    let mut i: f64 = i32::pow(base_num, 7).into();

    while i >= 0.0 {
        result += (1.0/i.tan()) * i.tan();
        i -= 1.0;
    }

    result
}

fn sort() -> () {
    let mut vec = [432, -897, 65, 457, 321, 8, -658 ,89647, 21, 87, -54, 456, 415, 687, -867, 231, 56, 657, -987, 9528];
    vec.sort();
}

fn factorial(num: u128) -> BigInt {
    let mut current_count = num;
    let mut result = BigInt::from(num);
    while current_count > 1 {
        current_count -= 1;
        result = result * current_count;
    }
    result
}

fn main() {
    let start_sort = Instant::now();
    for _ in 0..7500000 {
        sort();
    }
    println!("Sorting time: {:?}", start_sort.elapsed());

    let start_intensive = Instant::now();
    for _ in 0..5 {
        intensive();
    }
    println!("Intensive Calculation Time: {:?}", start_intensive.elapsed());

    let start_factorial = Instant::now();
    for i in 1..=4000 {
        factorial(i);
    }
    println!("Factorials 1-4000 time: {:?}", start_factorial.elapsed());
}
