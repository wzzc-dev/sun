///|
/// A line segment for rasterization
pub struct LineSegment {
  x0 : Double
  y0 : Double
  x1 : Double
  y1 : Double
} derive(Debug)

///|
/// Rasterizer for rendering glyph outlines to pixels
/// Implements scanline fill with anti-aliasing
pub struct Rasterizer {
  width : Int
  height : Int
  pixels : FixedArray[Byte]
  coverage : FixedArray[Int] // Coverage buffer for anti-aliasing
}

///|
/// Create a new rasterizer
pub fn Rasterizer::new(width : Int, height : Int) -> Rasterizer {
  let size = width * height
  {
    width,
    height,
    pixels: FixedArray::make(size, b"\x00"[0]),
    coverage: FixedArray::make(size, 0),
  }
}

///|
/// Get the pixel buffer (grayscale)
pub fn Rasterizer::get_pixels(self : Rasterizer) -> FixedArray[Byte] {
  self.pixels
}

///|
/// Clear the buffer
pub fn Rasterizer::clear(self : Rasterizer) -> Unit {
  for i in 0..<self.pixels.length() {
    self.pixels[i] = b"\x00"[0]
    self.coverage[i] = 0
  }
}

///|
/// Rasterize a simple glyph at the given position and scale with anti-aliasing
pub fn Rasterizer::rasterize_glyph(
  self : Rasterizer,
  glyph : SimpleGlyph,
  x : Double,
  y : Double,
  scale : Double,
) -> Unit {
  // Clear coverage buffer
  for i in 0..<self.coverage.length() {
    self.coverage[i] = 0
  }

  // Flatten contours to line segments
  let segments = []
  for contour in glyph.contours {
    let points = contour.points
    let len = points.length()
    guard len >= 2 else { continue }

    // Track previous point for handling off-curve starting points
    let mut prev_point = points[len - 1] // Start with last point (contour wraps)
    let mut i = 0
    while i < len {
      let p0 = points[i]
      let p1_idx = (i + 1) % len
      let p1 = points[p1_idx]

      if p0.on_curve && p1.on_curve {
        // Line segment
        segments.push({
          x0: x + p0.x.to_double() * scale,
          y0: y - p0.y.to_double() * scale,
          x1: x + p1.x.to_double() * scale,
          y1: y - p1.y.to_double() * scale,
        })
        i = i + 1
      } else if p0.on_curve && !p1.on_curve {
        // Quadratic bezier - flatten to line segments
        let p2_idx = (i + 2) % len
        let p2 = points[p2_idx]
        if p2.on_curve {
          let bezier_segments = flatten_quadratic_bezier(
            x + p0.x.to_double() * scale,
            y - p0.y.to_double() * scale,
            x + p1.x.to_double() * scale,
            y - p1.y.to_double() * scale,
            x + p2.x.to_double() * scale,
            y - p2.y.to_double() * scale,
          )
          for seg in bezier_segments {
            segments.push(seg)
          }
          i = i + 2
        } else {
          // Implicit on-curve point between two off-curve points
          // Per TrueType spec: insert on-curve point at midpoint of p1 and p2
          let mid_x = (p1.x + p2.x) / 2
          let mid_y = (p1.y + p2.y) / 2
          let bezier_segments = flatten_quadratic_bezier(
            x + p0.x.to_double() * scale,
            y - p0.y.to_double() * scale,
            x + p1.x.to_double() * scale,
            y - p1.y.to_double() * scale,
            x + mid_x.to_double() * scale,
            y - mid_y.to_double() * scale,
          )
          for seg in bezier_segments {
            segments.push(seg)
          }
          // Move to p1 (off-curve), next iteration will handle p2
          i = i + 1
        }
      } else if !p0.on_curve && p1.on_curve {
        // p0 is off-curve, p1 is on-curve
        // Create bezier from implicit midpoint through p0 to p1
        let mid_x = (prev_point.x + p0.x) / 2
        let mid_y = (prev_point.y + p0.y) / 2
        let bezier_segments = flatten_quadratic_bezier(
          x + mid_x.to_double() * scale,
          y - mid_y.to_double() * scale,
          x + p0.x.to_double() * scale,
          y - p0.y.to_double() * scale,
          x + p1.x.to_double() * scale,
          y - p1.y.to_double() * scale,
        )
        for seg in bezier_segments {
          segments.push(seg)
        }
        i = i + 1
      } else {
        // Both off-curve - skip (should not happen in valid fonts)
        i = i + 1
      }
      prev_point = p0
    }
  }

  // Fill using scanline algorithm with anti-aliasing
  scanline_fill_with_aa(self, segments)
}

///|
/// Flatten a quadratic bezier curve into line segments
fn flatten_quadratic_bezier(
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Array[LineSegment] {
  let segments = []
  let steps = calculate_bezier_steps(x0, y0, x1, y1, x2, y2)
  let mut prev_x = x0
  let mut prev_y = y0

  for i in 1..<=steps {
    let t = i.to_double() / steps.to_double()
    let mt = 1.0 - t
    let px = mt * mt * x0 + 2.0 * mt * t * x1 + t * t * x2
    let py = mt * mt * y0 + 2.0 * mt * t * y1 + t * t * y2
    segments.push({ x0: prev_x, y0: prev_y, x1: px, y1: py })
    prev_x = px
    prev_y = py
  }

  segments
}

///|
/// Calculate number of steps needed for bezier flattening based on curve complexity
fn calculate_bezier_steps(
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Int {
  // Calculate deviation from straight line
  let dx = x2 - x0
  let dy = y2 - y0
  let d = dx * dx + dy * dy

  // If very short, use few steps
  if d < 4.0 {
    return 2
  }

  // Calculate control point deviation
  let mid_x = (x0 + x2) / 2.0
  let mid_y = (y0 + y2) / 2.0
  let dev_x = x1 - mid_x
  let dev_y = y1 - mid_y
  let deviation = dev_x * dev_x + dev_y * dev_y

  // More steps for higher deviation
  if deviation > 100.0 {
    32
  } else if deviation > 25.0 {
    16
  } else if deviation > 4.0 {
    8
  } else {
    4
  }
}

///|
/// Scanline fill with anti-aliasing using coverage calculation
fn scanline_fill_with_aa(
  rasterizer : Rasterizer,
  segments : Array[LineSegment],
) -> Unit {
  guard segments.length() > 0 else { return }

  // Find bounding box
  let mut min_y = segments[0].y0
  let mut max_y = segments[0].y0
  for seg in segments {
    if seg.y0 < min_y {
      min_y = seg.y0
    }
    if seg.y1 < min_y {
      min_y = seg.y1
    }
    if seg.y0 > max_y {
      max_y = seg.y0
    }
    if seg.y1 > max_y {
      max_y = seg.y1
    }
  }

  let y_start = min_y.to_int().max(0)
  let y_end = (max_y.to_int() + 1).min(rasterizer.height)

  // For each scanline
  for y in y_start..<y_end {
    // Find intersections with this scanline (at pixel center)
    let y_double = y.to_double() + 0.5
    let intersections = []
    for seg in segments {
      let y0 = seg.y0
      let y1 = seg.y1

      // Check if segment crosses this scanline (using >= and < for proper winding)
      if (y0 < y_double && y1 >= y_double) || (y1 < y_double && y0 >= y_double) {
        // Calculate x intersection
        let t = (y_double - y0) / (y1 - y0)
        let x = seg.x0 + t * (seg.x1 - seg.x0)
        intersections.push(x)
      }
    }

    // Sort intersections
    let sorted = sort_doubles(intersections)

    // Fill between pairs of intersections (even-odd rule)
    let mut i = 0
    while i + 1 < sorted.length() {
      let x_start_f = sorted[i]
      let x_end_f = sorted[i + 1]

      // Calculate pixel range
      let x_start = x_start_f.to_int().max(0)
      let x_end = (x_end_f.to_int() + 1).min(rasterizer.width)

      // Set coverage for fully covered pixels
      for x in x_start..<x_end {
        let idx = y * rasterizer.width + x
        rasterizer.coverage[idx] = 255
      }

      i = i + 2
    }
  }

  // Apply coverage to pixels with anti-aliasing
  // Apply a simple 2x2 box filter to smooth edges
  for y in y_start..<y_end {
    for x in 0..<rasterizer.width {
      let idx = y * rasterizer.width + x
      if rasterizer.coverage[idx] > 0 {
        // Check neighbors for anti-aliasing
        let has_left = x > 0 && rasterizer.coverage[idx - 1] == 0
        let has_right = x < rasterizer.width - 1 &&
          rasterizer.coverage[idx + 1] == 0
        let has_top = y > 0 &&
          rasterizer.coverage[(y - 1) * rasterizer.width + x] == 0
        let has_bottom = y < rasterizer.height - 1 &&
          rasterizer.coverage[(y + 1) * rasterizer.width + x] == 0

        // If this pixel is at the edge, apply partial coverage
        if has_left || has_right || has_top || has_bottom {
          // Edge pixel - use partial coverage for anti-aliasing
          rasterizer.coverage[idx] = 192 // ~75% coverage for edge pixels
        }
      }
    }
  }

  // Apply coverage to pixels
  for i in 0..<rasterizer.pixels.length() {
    if rasterizer.coverage[i] > 0 {
      rasterizer.pixels[i] = rasterizer.coverage[i].to_byte()
    }
  }
}

///|
/// Sort an array of doubles (simple insertion sort for small arrays)
fn sort_doubles(arr : Array[Double]) -> Array[Double] {
  let result = []
  for val in arr {
    result.push(val)
  }

  // Insertion sort
  let len = result.length()
  for i in 1..<len {
    let key = result[i]
    let mut j = i - 1
    while j >= 0 && result[j] > key {
      result[j + 1] = result[j]
      j = j - 1
    }
    result[j + 1] = key
  }

  result
}

///|
/// Draw a line using Bresenham's algorithm (for outline rendering)
pub fn Rasterizer::draw_line(
  self : Rasterizer,
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
) -> Unit {
  let x_start = x0.to_int()
  let y_start = y0.to_int()
  let x_end = x1.to_int()
  let y_end = y1.to_int()

  let dx = (x_end - x_start).abs()
  let dy = (y_end - y_start).abs()
  let sx = if x_start < x_end { 1 } else { -1 }
  let sy = if y_start < y_end { 1 } else { -1 }
  let mut err = dx - dy

  let mut x = x_start
  let mut y = y_start

  while true {
    self.set_pixel(x, y, b"\xff"[0])

    if x == x_end && y == y_end {
      break
    }

    let e2 = 2 * err
    if e2 > -dy {
      err = err - dy
      x = x + sx
    }
    if e2 < dx {
      err = err + dx
      y = y + sy
    }
  }
}

///|
/// Set a pixel with bounds checking
fn Rasterizer::set_pixel(
  self : Rasterizer,
  x : Int,
  y : Int,
  value : Byte,
) -> Unit {
  guard x >= 0 && x < self.width && y >= 0 && y < self.height else { return }
  let idx = y * self.width + x
  self.pixels[idx] = value
}
