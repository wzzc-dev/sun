///|
/// A surface for rendering pixels to a window
pub struct Surface {
  window : Window
  mut width : Int
  mut height : Int
}

///|
/// Create a new surface for the given window
pub fn Surface::new(window : Window) -> Surface {
  { window, width: window.width(), height: window.height() }
}

///|
/// Get surface width
pub fn Surface::width(self : Surface) -> Int {
  self.width
}

///|
/// Get surface height
pub fn Surface::height(self : Surface) -> Int {
  self.height
}

///|
/// Resize the surface to match window size
pub fn Surface::resize(self : Surface) -> Unit {
  self.width = self.window.width()
  self.height = self.window.height()
}

///|
/// Present RGBA pixels to the surface
pub fn Surface::present(self : Surface, pixels : FixedArray[Byte]) -> Unit {
  self.window.present(pixels, self.width, self.height)
}
