///|
/// RGBA color representation
pub(all) struct Color {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
} derive(Eq, Debug, Show)

///|
/// Create a color from RGBA values
pub fn Color::new(r~ : Byte, g~ : Byte, b~ : Byte, a? : Byte = 255) -> Color {
  { r, g, b, a }
}

///|
/// Predefined colors
pub fn Color::white() -> Color {
  Color::new(r=255, g=255, b=255)
}

///|
pub fn Color::black() -> Color {
  Color::new(r=0, g=0, b=0)
}

///|
pub fn Color::red() -> Color {
  Color::new(r=255, g=0, b=0)
}

///|
pub fn Color::green() -> Color {
  Color::new(r=0, g=255, b=0)
}

///|
pub fn Color::blue() -> Color {
  Color::new(r=0, g=0, b=255)
}

///|
pub fn Color::transparent() -> Color {
  Color::new(r=0, g=0, b=0, a=0)
}
