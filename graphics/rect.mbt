///|
/// 2D rectangle defined by origin and size
pub struct Rect {
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
/// Create a rectangle
pub fn Rect::new(
  x~ : Double,
  y~ : Double,
  width~ : Double,
  height~ : Double,
) -> Rect {
  { x, y, width, height }
}

///|
/// Get the right edge (x + width)
pub fn Rect::right(self : Rect) -> Double {
  self.x + self.width
}

///|
/// Get the bottom edge (y + height)
pub fn Rect::bottom(self : Rect) -> Double {
  self.y + self.height
}

///|
/// Check if a point is inside the rectangle
pub fn Rect::contains(self : Rect, px : Double, py : Double) -> Bool {
  px >= self.x && px < self.right() && py >= self.y && py < self.bottom()
}

///|
/// 2D size (width and height)
pub struct Size {
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub fn Size::new(width~ : Double, height~ : Double) -> Size {
  { width, height }
}
