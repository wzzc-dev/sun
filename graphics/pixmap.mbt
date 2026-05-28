///|
/// Pixel buffer for 2D rendering (RGBA format)
pub struct Pixmap {
  width : Int
  height : Int
  pixels : FixedArray[Byte]
} derive(Debug)

///|
/// Create a new pixmap filled with transparent pixels
pub fn Pixmap::new(width : Int, height : Int) -> Pixmap {
  let size = width * height * 4
  { width, height, pixels: FixedArray::make(size, 0) }
}

///|
/// Get the width of the pixmap
pub fn Pixmap::get_width(self : Pixmap) -> Int {
  self.width
}

///|
/// Get the height of the pixmap
pub fn Pixmap::get_height(self : Pixmap) -> Int {
  self.height
}

///|
/// Get the raw pixel data
pub fn Pixmap::get_pixels(self : Pixmap) -> FixedArray[Byte] {
  self.pixels
}

///|
/// Set a pixel at the given coordinates
pub fn Pixmap::set_pixel(
  self : Pixmap,
  x : Int,
  y : Int,
  color : Color,
) -> Unit {
  guard x >= 0 && x < self.width && y >= 0 && y < self.height else { return }
  let idx = (y * self.width + x) * 4
  self.pixels[idx] = color.r
  self.pixels[idx + 1] = color.g
  self.pixels[idx + 2] = color.b
  self.pixels[idx + 3] = color.a
}

///|
/// Get the color at the given coordinates
pub fn Pixmap::get_pixel(self : Pixmap, x : Int, y : Int) -> Color {
  guard x >= 0 && x < self.width && y >= 0 && y < self.height else {
    return Color::transparent()
  }
  let idx = (y * self.width + x) * 4
  Color::new(
    r=self.pixels[idx],
    g=self.pixels[idx + 1],
    b=self.pixels[idx + 2],
    a=self.pixels[idx + 3],
  )
}

///|
/// Clear the pixmap with a color
pub fn Pixmap::clear(self : Pixmap, color : Color) -> Unit {
  for y in 0..<self.height {
    for x in 0..<self.width {
      self.set_pixel(x, y, color)
    }
  }
}

///|
/// Fill a rectangle with a color
pub fn Pixmap::fill_rect(
  self : Pixmap,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  color : Color,
) -> Unit {
  for dy in 0..<h {
    for dx in 0..<w {
      self.set_pixel(x + dx, y + dy, color)
    }
  }
}
