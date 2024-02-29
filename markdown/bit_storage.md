# Bit storage technique
This was created for a certain someone who needs to store 2 boolean flags and a number 1-4.

# How do bitwise operations work?

## Bit shifting to the left
Moves the bits x places to the left, and deletes any bits that "fall" off the left side.
```
0b0010 << 1   ->   0b0100
0b1100 << 1   ->   0b1000
```
## Bit shifting to the right
Moves the bits x places to the right, and deletes any bits that "fall" off the right side.
```
0b0100 >> 1   ->   0b0010
0b0011 >> 1   ->   0b0001
```
## Bitwise AND (`&`) operator
This does the AND operation on each bit and keeps only the ones where both bits are 1
```
0b1011 & 0b1101  ->  0b1001

0b1011
0b1101
  v  v
0b1001
```
## Bitwise OR (`|`) operator
This does the OR operation on each bit and keeps only the ones where either bits are 1
```
0b1001 | 0b1100  ->  0b1101

0b1001
0b1100
  vv v
0b1001
```

# How this works
Basically dont think of it as a number, just think of it as 4 bits (it's technically 8 in a `u8` but ignore the upper three since you dont need them for this). So you have `0b00000000` which is no flags set and 1 in the 1-4 specified. Then, we'll use the first 2 bits to be booleans, with `0b11` being all of them true. Then, since 3 (`0b11`) is only 2 bits (we use 0-3 instead of 1-4 to make it easier) and we'll never go above that, we use the next two bits to just store it as a number, so `0b1011` is 2 with both boolean flags set to true.

# Defining a spec
You'll need to create some constants and a function to use to construct your number. We'll define them like this:
```rust
const FILL: u8 = 0b01;
const EVENODD: u8 = 0b10;

enum StrokeType {
    NoStroke = 0,
    RoundCap = 1,
    ButtCap = 2,
    SquareCap = 3,
}

fn calc_stroke_type(stroke_type: StrokeType) -> u8 {
    // this takes the number representation of the StrokeType and pushes it to the left by 2 in order to make room for the flags
    // for example, passing in StrokeType::ButtCap (0b10) will shift it left by 2, giving us 0b1000
    // we could also do SquareCap (0b11) which would give us 0b1100
    (stroke_type as u8) << 2
}
```

You can see that each flag only has 1 of the bits set, so we can OR them together to create a new flag.

# Creating a Value
You can create a value with bit shifting and the bitwise OR operator.

```rust
const FILL: u8 = 0b01;
const EVENODD: u8 = 0b10;

enum StrokeType {
    NoStroke = 0,  // 0b00
    RoundCap = 1,  // 0b01
    ButtCap = 2,   // 0b10
    SquareCap = 3, // 0b11
}

fn calc_stroke_type(stroke_type: StrokeType) -> u8 {
    (stroke_type as u8) << 2
}

fn construct() {
    let mut value = FILL | EVENODD;
    // or you could do this to only set FILL and not EVENODD, which also works the other way around:
    // let value = FILL;

    // now, we need to calculate the stroke type and OR that onto the result
    let stroke = calc_stroke_type(StrokeType::ButtCap);
    value |= stroke; // this ORs 0b11 with 0b1000, giving us 0b1011
}
```

# Reading a value
You can read with the `&` bitwise operator and right bit shifting, which is the opposite of what we did to construct a value. First, check if the flags are set by ANDing the value with each flag:
```rust
const FILL: u8 = 0b01;
const EVENODD: u8 = 0b10;

fn read() {
    let mut value = 0b1011;

    if value & FILL {
        // FILL is set
    }
    if value & EVENODD {
        // EVENODD is set
    }
}
```

Then, you can shift to the right by 2 to get rid of the boolean flags, and then you can AND with the StrokeType enum to get which value is set:

```rust
enum StrokeType {
    NoStroke = 0,
    RoundCap = 1,
    ButtCap = 2,
    SquareCap = 3,
}

fn read() {
    let mut value = 0b1011;

    // read boolean flags as seen above

    // if value isnt mutable, you can just create a new variable instead of doing in-place assignment
    value >>= 2;
    
    if value & StrokeType::NoStroke {

    } else if value & StrokeType::RoundCap {

    } ... {

    }
}
```
