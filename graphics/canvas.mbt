///|
/// 2D drawing canvas backed by a pixmap
pub struct Canvas {
  pixmap : Pixmap
  mut transform : Transform
} derive(Debug)

///|
/// Create a new canvas with the given dimensions
pub fn Canvas::new(width : Int, height : Int) -> Canvas {
  { pixmap: Pixmap::new(width, height), transform: Transform::identity() }
}

///|
/// Get the underlying pixmap
pub fn Canvas::get_pixmap(self : Canvas) -> Pixmap {
  self.pixmap
}

///|
/// Clear the canvas with a color
pub fn Canvas::clear(self : Canvas, color : Color) -> Unit {
  self.pixmap.clear(color)
}

///|
/// Set the current transform
pub fn Canvas::set_transform(self : Canvas, transform : Transform) -> Unit {
  self.transform = transform
}

///|
/// Get the current transform
pub fn Canvas::get_transform(self : Canvas) -> Transform {
  self.transform
}

///|
/// Draw a filled rectangle
pub fn Canvas::fill_rect(
  self : Canvas,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  paint : Paint,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }

  let ix = x.to_int()
  let iy = y.to_int()
  let iw = w.to_int()
  let ih = h.to_int()

  self.pixmap.fill_rect(ix, iy, iw, ih, paint.color)
}

///|
/// Draw a single pixel (for testing)
pub fn Canvas::draw_pixel(
  self : Canvas,
  x : Int,
  y : Int,
  color : Color,
) -> Unit {
  self.pixmap.set_pixel(x, y, color)
}

///|
/// Draw text at the given position (simplified - just draws placeholder glyphs)
pub fn Canvas::draw_text(
  self : Canvas,
  text : String,
  x : Double,
  y : Double,
  font_size : Double,
  color : Color,
) -> Unit {
  // Simplified text rendering - draw each character as a small rectangle
  let char_width = font_size * 0.6
  for i in 0..<text.length() {
    let px = (x + i.to_double() * char_width).to_int()
    let py = y.to_int()
    let size = font_size.to_int()
    self.pixmap.fill_rect(px, py, size, size, color)
  }
}
