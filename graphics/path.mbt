///|
/// Path segment types
pub enum PathSegment {
  MoveTo(Double, Double)
  LineTo(Double, Double)
  QuadTo(Double, Double, Double, Double)
  CubicTo(Double, Double, Double, Double, Double, Double)
  Close
} derive(Eq, Debug)

///|
/// 2D path builder for constructing vector shapes
pub struct Path {
  segments : Array[PathSegment]
  mut current_x : Double
  mut current_y : Double
  mut start_x : Double
  mut start_y : Double
} derive(Debug)

///|
/// Create a new empty path
pub fn Path::new() -> Path {
  { segments: [], current_x: 0.0, current_y: 0.0, start_x: 0.0, start_y: 0.0 }
}

///|
/// Move to a point without drawing
pub fn Path::move_to(self : Path, x : Double, y : Double) -> Path {
  self.segments.push(PathSegment::MoveTo(x, y))
  self.current_x = x
  self.current_y = y
  self.start_x = x
  self.start_y = y
  self
}

///|
/// Draw a line to a point
pub fn Path::line_to(self : Path, x : Double, y : Double) -> Path {
  self.segments.push(PathSegment::LineTo(x, y))
  self.current_x = x
  self.current_y = y
  self
}

///|
/// Draw a quadratic bezier curve
pub fn Path::quad_to(
  self : Path,
  cx : Double,
  cy : Double,
  x : Double,
  y : Double,
) -> Path {
  self.segments.push(PathSegment::QuadTo(cx, cy, x, y))
  self.current_x = x
  self.current_y = y
  self
}

///|
/// Draw a cubic bezier curve
pub fn Path::cubic_to(
  self : Path,
  cx1 : Double,
  cy1 : Double,
  cx2 : Double,
  cy2 : Double,
  x : Double,
  y : Double,
) -> Path {
  self.segments.push(PathSegment::CubicTo(cx1, cy1, cx2, cy2, x, y))
  self.current_x = x
  self.current_y = y
  self
}

///|
/// Close the current subpath
pub fn Path::close(self : Path) -> Path {
  self.segments.push(PathSegment::Close)
  self.current_x = self.start_x
  self.current_y = self.start_y
  self
}

///|
/// Add a rectangle to the path
pub fn Path::add_rect(
  self : Path,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Path {
  ignore(self.move_to(x, y))
  ignore(self.line_to(x + w, y))
  ignore(self.line_to(x + w, y + h))
  ignore(self.line_to(x, y + h))
  self.close()
}

///|
/// Add a circle approximation using cubic bezier curves
pub fn Path::add_circle(
  self : Path,
  cx : Double,
  cy : Double,
  radius : Double,
) -> Path {
  let k = 0.5522847498 // kappa for circle approximation
  let kr = k * radius

  ignore(self.move_to(cx + radius, cy))
  ignore(
    self.cubic_to(cx + radius, cy - kr, cx + kr, cy - radius, cx, cy - radius),
  )
  ignore(
    self.cubic_to(cx - kr, cy - radius, cx - radius, cy - kr, cx - radius, cy),
  )
  ignore(
    self.cubic_to(cx - radius, cy + kr, cx - kr, cy + radius, cx, cy + radius),
  )
  ignore(
    self.cubic_to(cx + kr, cy + radius, cx + radius, cy + kr, cx + radius, cy),
  )
  self.close()
}

///|
/// Get the segments of the path
pub fn Path::get_segments(self : Path) -> Array[PathSegment] {
  self.segments
}

///|
/// Check if the path is empty
pub fn Path::is_empty(self : Path) -> Bool {
  self.segments.length() == 0
}
