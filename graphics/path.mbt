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
/// Add an open polyline through the given points
pub fn Path::add_polyline(self : Path, points : Array[Point]) -> Path {
  guard points.length() > 0 else { return self }
  ignore(self.move_to(points[0].x, points[0].y))
  for i in 1..<points.length() {
    ignore(self.line_to(points[i].x, points[i].y))
  }
  self
}

///|
/// Add a closed polygon through the given points
pub fn Path::add_polygon(self : Path, points : Array[Point]) -> Path {
  guard points.length() >= 3 else { return self }
  ignore(self.add_polyline(points))
  self.close()
}

///|
/// Add a rounded rectangle with a uniform corner radius to the path
pub fn Path::add_rounded_rect(
  self : Path,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  radius : Double,
) -> Path {
  guard w > 0.0 && h > 0.0 && radius > 0.0 else {
    return self.add_rect(x, y, w, h)
  }
  let r = radius.min(w / 2.0).min(h / 2.0)
  let k = 0.5522847498
  let kr = k * r
  let right = x + w
  let bottom = y + h

  ignore(self.move_to(x + r, y))
  ignore(self.line_to(right - r, y))
  ignore(self.cubic_to(right - r + kr, y, right, y + r - kr, right, y + r))
  ignore(self.line_to(right, bottom - r))
  ignore(
    self.cubic_to(
      right,
      bottom - r + kr,
      right - r + kr,
      bottom,
      right - r,
      bottom,
    ),
  )
  ignore(self.line_to(x + r, bottom))
  ignore(self.cubic_to(x + r - kr, bottom, x, bottom - r + kr, x, bottom - r))
  ignore(self.line_to(x, y + r))
  ignore(self.cubic_to(x, y + r - kr, x + r - kr, y, x + r, y))
  self.close()
}

///|
/// Add a rounded rectangle with independent corner radii in clockwise order.
pub fn Path::add_rounded_rect_corners(
  self : Path,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  top_left : Double,
  top_right : Double,
  bottom_right : Double,
  bottom_left : Double,
) -> Path {
  guard w > 0.0 && h > 0.0 else { return self.add_rect(x, y, w, h) }
  let tl = clamp_corner_radius(top_left, w, h)
  let tr = clamp_corner_radius(top_right, w, h)
  let br = clamp_corner_radius(bottom_right, w, h)
  let bl = clamp_corner_radius(bottom_left, w, h)
  guard tl > 0.0 || tr > 0.0 || br > 0.0 || bl > 0.0 else {
    return self.add_rect(x, y, w, h)
  }
  let k = 0.5522847498
  let right = x + w
  let bottom = y + h

  ignore(self.move_to(x + tl, y))
  ignore(self.line_to(right - tr, y))
  if tr > 0.0 {
    let kr = k * tr
    ignore(self.cubic_to(right - tr + kr, y, right, y + tr - kr, right, y + tr))
  }
  ignore(self.line_to(right, bottom - br))
  if br > 0.0 {
    let kr = k * br
    ignore(
      self.cubic_to(
        right,
        bottom - br + kr,
        right - br + kr,
        bottom,
        right - br,
        bottom,
      ),
    )
  }
  ignore(self.line_to(x + bl, bottom))
  if bl > 0.0 {
    let kr = k * bl
    ignore(
      self.cubic_to(x + bl - kr, bottom, x, bottom - bl + kr, x, bottom - bl),
    )
  }
  ignore(self.line_to(x, y + tl))
  if tl > 0.0 {
    let kr = k * tl
    ignore(self.cubic_to(x, y + tl - kr, x + tl - kr, y, x + tl, y))
  }
  self.close()
}

///|
fn clamp_corner_radius(radius : Double, w : Double, h : Double) -> Double {
  radius.max(0.0).min(w / 2.0).min(h / 2.0)
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
/// Add an ellipse approximation using cubic bezier curves
pub fn Path::add_ellipse(
  self : Path,
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
) -> Path {
  let k = 0.5522847498 // kappa for circle/ellipse approximation
  let kx = k * rx
  let ky = k * ry

  ignore(self.move_to(cx + rx, cy))
  ignore(self.cubic_to(cx + rx, cy - ky, cx + kx, cy - ry, cx, cy - ry))
  ignore(self.cubic_to(cx - kx, cy - ry, cx - rx, cy - ky, cx - rx, cy))
  ignore(self.cubic_to(cx - rx, cy + ky, cx - kx, cy + ry, cx, cy + ry))
  ignore(self.cubic_to(cx + kx, cy + ry, cx + rx, cy + ky, cx + rx, cy))
  self.close()
}

///|
/// Add an open circular arc approximated with cubic bezier curves.
pub fn Path::add_arc(
  self : Path,
  cx : Double,
  cy : Double,
  radius : Double,
  start_angle : Double,
  sweep_angle : Double,
) -> Path {
  let sweep = clamp_sweep_angle(sweep_angle)
  guard radius > 0.0 && sweep != 0.0 else { return self }
  ignore(
    self.move_to(arc_x(cx, radius, start_angle), arc_y(cy, radius, start_angle)),
  )
  append_arc_segments(self, cx, cy, radius, start_angle, sweep)
}

///|
/// Add a closed pie slice from the center through a circular arc.
pub fn Path::add_pie(
  self : Path,
  cx : Double,
  cy : Double,
  radius : Double,
  start_angle : Double,
  sweep_angle : Double,
) -> Path {
  let sweep = clamp_sweep_angle(sweep_angle)
  guard radius > 0.0 && sweep != 0.0 else { return self }
  ignore(self.move_to(cx, cy))
  ignore(
    self.line_to(arc_x(cx, radius, start_angle), arc_y(cy, radius, start_angle)),
  )
  ignore(append_arc_segments(self, cx, cy, radius, start_angle, sweep))
  self.close()
}

///|
fn append_arc_segments(
  path : Path,
  cx : Double,
  cy : Double,
  radius : Double,
  start_angle : Double,
  sweep_angle : Double,
) -> Path {
  let half_pi = 1.5707963267948966
  let mut remaining = sweep_angle
  let mut angle = start_angle
  while remaining != 0.0 {
    let step = if remaining > half_pi {
      half_pi
    } else if remaining < -half_pi {
      -half_pi
    } else {
      remaining
    }
    ignore(append_arc_segment(path, cx, cy, radius, angle, step))
    angle = angle + step
    remaining = remaining - step
  }
  path
}

///|
fn append_arc_segment(
  path : Path,
  cx : Double,
  cy : Double,
  radius : Double,
  start_angle : Double,
  sweep_angle : Double,
) -> Path {
  let end_angle = start_angle + sweep_angle
  let k = 4.0 / 3.0 * @math.tan(sweep_angle / 4.0)
  let cos0 = @math.cos(start_angle)
  let sin0 = @math.sin(start_angle)
  let cos1 = @math.cos(end_angle)
  let sin1 = @math.sin(end_angle)
  let x0 = cx + radius * cos0
  let y0 = cy + radius * sin0
  let x1 = cx + radius * cos1
  let y1 = cy + radius * sin1

  path.cubic_to(
    x0 - radius * k * sin0,
    y0 + radius * k * cos0,
    x1 + radius * k * sin1,
    y1 - radius * k * cos1,
    x1,
    y1,
  )
}

///|
fn arc_x(cx : Double, radius : Double, angle : Double) -> Double {
  cx + radius * @math.cos(angle)
}

///|
fn arc_y(cy : Double, radius : Double, angle : Double) -> Double {
  cy + radius * @math.sin(angle)
}

///|
fn clamp_sweep_angle(sweep : Double) -> Double {
  let two_pi = 6.283185307179586
  if sweep != sweep {
    0.0
  } else if sweep > two_pi {
    two_pi
  } else if sweep < -two_pi {
    -two_pi
  } else {
    sweep
  }
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
