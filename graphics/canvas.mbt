///|
/// 2D drawing canvas backed by a pixmap
pub struct Canvas {
  pixmap : Pixmap
  mut transform : Transform
  mut clip_rect : Rect?
  dirty_region : DirtyRegion
} derive(Debug)

///|
/// Create a new canvas with the given dimensions
pub fn Canvas::new(width : Int, height : Int) -> Canvas {
  {
    pixmap: Pixmap::new(width, height),
    transform: Transform::identity(),
    clip_rect: None,
    dirty_region: DirtyRegion::new(),
  }
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
  self.dirty_region.add_all(self.pixmap.get_width(), self.pixmap.get_height())
}

///|
/// Get the accumulated dirty region for incremental rendering.
pub fn Canvas::get_dirty_region(self : Canvas) -> DirtyRegion {
  self.dirty_region
}

///|
/// Clear accumulated dirty rectangles.
pub fn Canvas::clear_dirty_region(self : Canvas) -> Unit {
  self.dirty_region.clear()
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
/// Set the current clip rectangle in device coordinates.
pub fn Canvas::set_clip_rect(self : Canvas, rect : Rect) -> Unit {
  if rect.width > 0.0 && rect.height > 0.0 {
    self.clip_rect = Some(rect)
  } else {
    self.clip_rect = Some(Rect::new(x=0.0, y=0.0, width=0.0, height=0.0))
  }
}

///|
/// Clear the current clip rectangle.
pub fn Canvas::clear_clip(self : Canvas) -> Unit {
  self.clip_rect = None
}

///|
/// Get the current clip rectangle, if any.
pub fn Canvas::get_clip_rect(self : Canvas) -> Rect? {
  self.clip_rect
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
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    ix,
    iy,
    ix + iw,
    iy + ih,
  )
  guard x_start < x_end && y_start < y_end else { return }

  self.pixmap.blend_rect(
    x_start,
    y_start,
    x_end - x_start,
    y_end - y_start,
    paint.color.scale_alpha(paint.opacity),
  )
  self.mark_dirty_bounds(x_start, y_start, x_end, y_end)
}

///|
/// Fill a path with the given paint
pub fn Canvas::fill_path(self : Canvas, path : Path, paint : Paint) -> Unit {
  guard paint.style is PaintStyle::Fill && !path.is_empty() else { return }
  let edges = path_to_edges(path, self.transform)
  guard edges.length() > 0 else { return }

  let (min_x_value, min_y_value, max_x_value, max_y_value) = path_bounds(edges)
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    min_x_value.to_int(),
    min_y_value.to_int(),
    max_x_value.to_int() + 1,
    max_y_value.to_int() + 1,
  )
  guard x_start < x_end && y_start < y_end else { return }
  let color = paint.color.scale_alpha(paint.opacity)
  let sample_count = 4
  let sample_count_sq = sample_count * sample_count
  let sample_count_double = sample_count.to_double()

  for y in y_start..<y_end {
    for x in x_start..<x_end {
      let mut covered = 0
      for sy in 0..<sample_count {
        for sx in 0..<sample_count {
          let sample_x = x.to_double() +
            (sx.to_double() + 0.5) / sample_count_double
          let sample_y = y.to_double() +
            (sy.to_double() + 0.5) / sample_count_double
          if is_point_in_edges(sample_x, sample_y, edges, paint.fill_rule) {
            covered = covered + 1
          }
        }
      }
      if covered > 0 {
        blend_coverage_pixel(self.pixmap, x, y, color, covered, sample_count_sq)
        self.mark_dirty_bounds(x, y, x + 1, y + 1)
      }
    }
  }
}

///|
/// Stroke a path with the given paint
pub fn Canvas::stroke_path(self : Canvas, path : Path, paint : Paint) -> Unit {
  guard paint.style is PaintStyle::Stroke && !path.is_empty() else { return }
  guard paint.stroke_width > 0.0 else { return }
  let solid_stroke_path = path_to_stroke_path(path, self.transform)
  guard solid_stroke_path.edges.length() > 0 else { return }
  let stroke_path = apply_stroke_dash(
    solid_stroke_path,
    paint.stroke_dash_pattern,
    paint.stroke_dash_offset,
  )
  guard stroke_path.edges.length() > 0 else { return }

  let half_width = paint.stroke_width / 2.0
  let cap_extension = match paint.stroke_cap {
    StrokeCap::Butt => 0.0
    StrokeCap::Round | StrokeCap::Square => half_width
  }
  let join_extension = match paint.stroke_join {
    StrokeJoin::Miter => half_width * (paint.miter_limit - 1.0).max(0.0)
    StrokeJoin::Round | StrokeJoin::Bevel => 0.0
  }
  let shape_extension = cap_extension.max(join_extension)
  let (min_x_value, min_y_value, max_x_value, max_y_value) = path_bounds(
    stroke_path.edges,
  )
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    (min_x_value - half_width - shape_extension).to_int(),
    (min_y_value - half_width - shape_extension).to_int(),
    (max_x_value + half_width + shape_extension).to_int() + 1,
    (max_y_value + half_width + shape_extension).to_int() + 1,
  )
  guard x_start < x_end && y_start < y_end else { return }
  let color = paint.color.scale_alpha(paint.opacity)
  let sample_count = 4
  let sample_count_sq = sample_count * sample_count
  let sample_count_double = sample_count.to_double()

  for y in y_start..<y_end {
    for x in x_start..<x_end {
      let mut covered = 0
      for sy in 0..<sample_count {
        for sx in 0..<sample_count {
          let sample_x = x.to_double() +
            (sx.to_double() + 0.5) / sample_count_double
          let sample_y = y.to_double() +
            (sy.to_double() + 0.5) / sample_count_double
          if is_point_on_stroke(
              sample_x,
              sample_y,
              stroke_path,
              half_width,
              paint.stroke_cap,
              paint.stroke_join,
              paint.miter_limit,
            ) {
            covered = covered + 1
          }
        }
      }
      if covered > 0 {
        blend_coverage_pixel(self.pixmap, x, y, color, covered, sample_count_sq)
        self.mark_dirty_bounds(x, y, x + 1, y + 1)
      }
    }
  }
}

///|
/// Draw a grayscale coverage mask with the given paint
pub fn Canvas::draw_mask(
  self : Canvas,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  mask : FixedArray[Byte],
  paint : Paint,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }
  guard width > 0 && height > 0 && mask.length() >= width * height else {
    return
  }
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    x,
    y,
    x + width,
    y + height,
  )
  guard x_start < x_end && y_start < y_end else { return }
  let color = paint.color.scale_alpha(paint.opacity)
  for py in y_start..<y_end {
    for px in x_start..<x_end {
      let mask_x = px - x
      let mask_y = py - y
      let coverage = mask[mask_y * width + mask_x].to_int()
      if coverage > 0 {
        let alpha = (color.a.to_int() * coverage + 127) / 255
        self.pixmap.blend_pixel(px, py, color.with_alpha(clamp_byte(alpha)))
        self.mark_dirty_bounds(px, py, px + 1, py + 1)
      }
    }
  }
}

///|
/// Draw a source pixmap at the given destination position.
pub fn Canvas::draw_pixmap(
  self : Canvas,
  src : Pixmap,
  x : Int,
  y : Int,
  paint : Paint,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    x,
    y,
    x + src.get_width(),
    y + src.get_height(),
  )
  guard x_start < x_end && y_start < y_end else { return }
  let opacity = paint.opacity
  for py in y_start..<y_end {
    for px in x_start..<x_end {
      let color = src.get_pixel(px - x, py - y).scale_alpha(opacity)
      if color.a.to_int() > 0 {
        self.pixmap.blend_pixel(px, py, color)
        self.mark_dirty_bounds(px, py, px + 1, py + 1)
      }
    }
  }
}

///|
/// Draw a source pixmap rectangle at the given destination position.
pub fn Canvas::draw_pixmap_rect(
  self : Canvas,
  src : Pixmap,
  src_rect : PixelRect,
  x : Int,
  y : Int,
  paint : Paint,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let src_bounds = PixelRect::new(
    x=0,
    y=0,
    width=src.get_width(),
    height=src.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) => {
      let dst_x = x + clipped_src.x - src_rect.x
      let dst_y = y + clipped_src.y - src_rect.y
      let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
        self,
        dst_x,
        dst_y,
        dst_x + clipped_src.width,
        dst_y + clipped_src.height,
      )
      guard x_start < x_end && y_start < y_end else { return }
      let opacity = paint.opacity
      for py in y_start..<y_end {
        for px in x_start..<x_end {
          let src_x = clipped_src.x + px - dst_x
          let src_y = clipped_src.y + py - dst_y
          let color = src.get_pixel(src_x, src_y).scale_alpha(opacity)
          if color.a.to_int() > 0 {
            self.pixmap.blend_pixel(px, py, color)
            self.mark_dirty_bounds(px, py, px + 1, py + 1)
          }
        }
      }
    }
    None => ()
  }
}

///|
/// Draw a source pixmap scaled to the given destination rectangle.
pub fn Canvas::draw_scaled_pixmap(
  self : Canvas,
  src : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : Paint,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    x,
    y,
    x + width,
    y + height,
  )
  guard x_start < x_end && y_start < y_end else { return }
  blend_scaled_pixmap_region(
    self.pixmap,
    x,
    y,
    width,
    height,
    src,
    paint.opacity,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  self.mark_dirty_bounds(x_start, y_start, x_end, y_end)
}

///|
/// Draw a source pixmap scaled with bilinear sampling.
pub fn Canvas::draw_scaled_pixmap_bilinear(
  self : Canvas,
  src : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : Paint,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    x,
    y,
    x + width,
    y + height,
  )
  guard x_start < x_end && y_start < y_end else { return }
  blend_scaled_pixmap_bilinear_region(
    self.pixmap,
    x,
    y,
    width,
    height,
    src,
    paint.opacity,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  self.mark_dirty_bounds(x_start, y_start, x_end, y_end)
}

///|
/// Draw a source pixmap scaled with an explicit sampling mode.
pub fn Canvas::draw_sampled_pixmap(
  self : Canvas,
  src : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : Paint,
  sampling : ImageSampling,
) -> Unit {
  match sampling {
    ImageSampling::Nearest =>
      self.draw_scaled_pixmap(src, x, y, width, height, paint)
    ImageSampling::Bilinear =>
      self.draw_scaled_pixmap_bilinear(src, x, y, width, height, paint)
  }
}

///|
/// Draw a source pixmap rectangle scaled to the given destination rectangle.
pub fn Canvas::draw_scaled_pixmap_rect(
  self : Canvas,
  src : Pixmap,
  src_rect : PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : Paint,
) -> Unit {
  self.draw_sampled_pixmap_rect(
    src, src_rect, x, y, width, height, paint, ImageSampling::Nearest,
  )
}

///|
/// Draw a source pixmap rectangle scaled with bilinear sampling.
pub fn Canvas::draw_scaled_pixmap_rect_bilinear(
  self : Canvas,
  src : Pixmap,
  src_rect : PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : Paint,
) -> Unit {
  self.draw_sampled_pixmap_rect(
    src, src_rect, x, y, width, height, paint, ImageSampling::Bilinear,
  )
}

///|
/// Draw a source pixmap rectangle scaled with an explicit sampling mode.
pub fn Canvas::draw_sampled_pixmap_rect(
  self : Canvas,
  src : Pixmap,
  src_rect : PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : Paint,
  sampling : ImageSampling,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let src_bounds = PixelRect::new(
    x=0,
    y=0,
    width=src.get_width(),
    height=src.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) => {
      let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
        self,
        x,
        y,
        x + width,
        y + height,
      )
      guard x_start < x_end && y_start < y_end else { return }
      blend_sampled_pixmap_rect_region(
        self.pixmap,
        x,
        y,
        width,
        height,
        src,
        clipped_src,
        paint.opacity,
        sampling,
        x_start,
        y_start,
        x_end,
        y_end,
      )
      self.mark_dirty_bounds(x_start, y_start, x_end, y_end)
    }
    None => ()
  }
}

///|
/// Draw a source pixmap using nine-patch scaling.
pub fn Canvas::draw_nine_patch_pixmap(
  self : Canvas,
  src : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : NinePatchInsets,
  paint : Paint,
  sampling : ImageSampling,
) -> Unit {
  guard paint.style is PaintStyle::Fill else { return }
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    self,
    x,
    y,
    x + width,
    y + height,
  )
  guard x_start < x_end && y_start < y_end else { return }
  blend_nine_patch_pixmap_region(
    self.pixmap,
    x,
    y,
    width,
    height,
    src,
    insets,
    paint.opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  self.mark_dirty_bounds(x_start, y_start, x_end, y_end)
}

///|
/// Draw a single pixel (for testing)
pub fn Canvas::draw_pixel(
  self : Canvas,
  x : Int,
  y : Int,
  color : Color,
) -> Unit {
  guard is_pixel_in_clip(self, x, y) else { return }
  self.pixmap.set_pixel(x, y, color)
  self.mark_dirty_bounds(x, y, x + 1, y + 1)
}

///|
/// Draw placeholder text boxes at the given position.
pub fn Canvas::draw_placeholder_text(
  self : Canvas,
  text : String,
  x : Double,
  y : Double,
  font_size : Double,
  color : Color,
) -> Unit {
  let char_width = font_size * 0.6
  for i in 0..<text.length() {
    let px = (x + i.to_double() * char_width).to_int()
    let py = y.to_int()
    let size = font_size.to_int()
    blend_clipped_rect(self, px, py, size, size, color)
  }
}

///|
struct CanvasEdge {
  x0 : Double
  y0 : Double
  x1 : Double
  y1 : Double
} derive(Debug)

///|
struct StrokeEndpoint {
  x : Double
  y : Double
  dir_x : Double
  dir_y : Double
} derive(Debug)

///|
struct StrokeJoinPoint {
  x : Double
  y : Double
  in_x : Double
  in_y : Double
  out_x : Double
  out_y : Double
} derive(Debug)

///|
struct StrokePathData {
  edges : Array[CanvasEdge]
  endpoints : Array[StrokeEndpoint]
  joins : Array[StrokeJoinPoint]
} derive(Debug)

///|
struct DashCursor {
  pattern : Array[Double]
  mut index : Int
  mut remaining : Double
  mut is_drawing : Bool
} derive(Debug)

///|
fn path_to_edges(path : Path, transform : Transform) -> Array[CanvasEdge] {
  let edges = []
  let mut current_x = 0.0
  let mut current_y = 0.0
  let mut start_x = 0.0
  let mut start_y = 0.0
  let mut has_current = false

  for segment in path.get_segments() {
    match segment {
      PathSegment::MoveTo(x, y) => {
        current_x = x
        current_y = y
        start_x = x
        start_y = y
        has_current = true
      }
      PathSegment::LineTo(x, y) => {
        if has_current {
          push_transformed_edge(edges, transform, current_x, current_y, x, y)
        }
        current_x = x
        current_y = y
      }
      PathSegment::QuadTo(cx, cy, x, y) => {
        if has_current {
          flatten_quad(edges, transform, current_x, current_y, cx, cy, x, y)
        }
        current_x = x
        current_y = y
      }
      PathSegment::CubicTo(cx1, cy1, cx2, cy2, x, y) => {
        if has_current {
          flatten_cubic(
            edges, transform, current_x, current_y, cx1, cy1, cx2, cy2, x, y,
          )
        }
        current_x = x
        current_y = y
      }
      PathSegment::Close => {
        if has_current {
          push_transformed_edge(
            edges, transform, current_x, current_y, start_x, start_y,
          )
        }
        current_x = start_x
        current_y = start_y
      }
    }
  }

  edges
}

///|
fn path_to_stroke_path(path : Path, transform : Transform) -> StrokePathData {
  let edges = []
  let endpoints = []
  let joins = []
  let mut current_x = 0.0
  let mut current_y = 0.0
  let mut start_x = 0.0
  let mut start_y = 0.0
  let mut has_current = false
  let mut subpath_start = 0
  let mut subpath_closed = false

  for segment in path.get_segments() {
    match segment {
      PathSegment::MoveTo(x, y) => {
        if has_current && !subpath_closed {
          push_open_subpath_endpoints(edges, endpoints, subpath_start)
          push_open_subpath_joins(edges, joins, subpath_start)
        }
        current_x = x
        current_y = y
        start_x = x
        start_y = y
        has_current = true
        subpath_start = edges.length()
        subpath_closed = false
      }
      PathSegment::LineTo(x, y) => {
        if has_current {
          push_transformed_edge(edges, transform, current_x, current_y, x, y)
        }
        current_x = x
        current_y = y
      }
      PathSegment::QuadTo(cx, cy, x, y) => {
        if has_current {
          flatten_quad(edges, transform, current_x, current_y, cx, cy, x, y)
        }
        current_x = x
        current_y = y
      }
      PathSegment::CubicTo(cx1, cy1, cx2, cy2, x, y) => {
        if has_current {
          flatten_cubic(
            edges, transform, current_x, current_y, cx1, cy1, cx2, cy2, x, y,
          )
        }
        current_x = x
        current_y = y
      }
      PathSegment::Close => {
        if has_current {
          push_transformed_edge(
            edges, transform, current_x, current_y, start_x, start_y,
          )
          push_closed_subpath_joins(edges, joins, subpath_start)
        }
        current_x = start_x
        current_y = start_y
        subpath_closed = true
      }
    }
  }

  if has_current && !subpath_closed {
    push_open_subpath_endpoints(edges, endpoints, subpath_start)
    push_open_subpath_joins(edges, joins, subpath_start)
  }

  { edges, endpoints, joins }
}

///|
fn apply_stroke_dash(
  stroke_path : StrokePathData,
  pattern : Array[Double],
  offset : Double,
) -> StrokePathData {
  guard pattern.length() > 0 else { return stroke_path }

  let edges = []
  let endpoints = []
  let joins = []
  let mut cursor = DashCursor::new(pattern, offset)
  let mut dash_run_start = -1
  let mut has_previous_source_edge = false
  let mut previous_source_edge = CanvasEdge::{
    x0: 0.0,
    y0: 0.0,
    x1: 0.0,
    y1: 0.0,
  }

  for edge in stroke_path.edges {
    if has_previous_source_edge &&
      !close_point(
        previous_source_edge.x1,
        previous_source_edge.y1,
        edge.x0,
        edge.y0,
      ) {
      finish_dash_run(edges, endpoints, joins, dash_run_start)
      dash_run_start = -1
      cursor = DashCursor::new(pattern, offset)
    }
    dash_run_start = append_dashed_edge(
      edges, endpoints, joins, edge, cursor, dash_run_start,
    )
    previous_source_edge = edge
    has_previous_source_edge = true
  }
  finish_dash_run(edges, endpoints, joins, dash_run_start)
  { edges, endpoints, joins }
}

///|
fn append_dashed_edge(
  edges : Array[CanvasEdge],
  endpoints : Array[StrokeEndpoint],
  joins : Array[StrokeJoinPoint],
  edge : CanvasEdge,
  cursor : DashCursor,
  dash_run_start : Int,
) -> Int {
  let dx = edge.x1 - edge.x0
  let dy = edge.y1 - edge.y0
  let length = (dx * dx + dy * dy).sqrt()
  guard length > 0.0 else { return dash_run_start }
  let mut current_run_start = dash_run_start
  let mut distance = 0.0
  while distance < length {
    if !cursor.is_drawing && current_run_start >= 0 {
      finish_dash_run(edges, endpoints, joins, current_run_start)
      current_run_start = -1
    }
    let remaining_edge = length - distance
    let step = remaining_edge.min(cursor.remaining)
    if cursor.is_drawing && step > 0.0 {
      let t0 = distance / length
      let t1 = (distance + step) / length
      if current_run_start < 0 {
        current_run_start = edges.length()
      }
      edges.push({
        x0: edge.x0 + dx * t0,
        y0: edge.y0 + dy * t0,
        x1: edge.x0 + dx * t1,
        y1: edge.y0 + dy * t1,
      })
    }
    distance = distance + step
    cursor.advance(step)
  }
  current_run_start
}

///|
fn finish_dash_run(
  edges : Array[CanvasEdge],
  endpoints : Array[StrokeEndpoint],
  joins : Array[StrokeJoinPoint],
  start_index : Int,
) -> Unit {
  guard start_index >= 0 && start_index < edges.length() else { return }
  push_open_subpath_endpoints(edges, endpoints, start_index)
  push_open_subpath_joins(edges, joins, start_index)
}

///|
fn DashCursor::new(pattern : Array[Double], offset : Double) -> DashCursor {
  let total = dash_pattern_total(pattern)
  let mut phase = normalize_dash_offset(offset, total)
  let mut index = 0
  let mut remaining = pattern[0]
  while phase >= remaining && pattern.length() > 0 {
    phase = phase - remaining
    index = (index + 1) % pattern.length()
    remaining = pattern[index]
  }
  { pattern, index, remaining: remaining - phase, is_drawing: index % 2 == 0 }
}

///|
fn DashCursor::advance(self : DashCursor, distance : Double) -> Unit {
  guard self.pattern.length() > 0 else { return }
  self.remaining = self.remaining - distance
  while self.remaining <= 0.000001 {
    self.index = (self.index + 1) % self.pattern.length()
    self.remaining = self.remaining + self.pattern[self.index]
    self.is_drawing = self.index % 2 == 0
  }
}

///|
fn dash_pattern_total(pattern : Array[Double]) -> Double {
  let mut total = 0.0
  for value in pattern {
    total = total + value
  }
  total
}

///|
fn normalize_dash_offset(offset : Double, total : Double) -> Double {
  guard total > 0.0 else { return 0.0 }
  let cycles = (offset / total).to_int()
  let mut phase = offset - cycles.to_double() * total
  while phase < 0.0 {
    phase = phase + total
  }
  while phase >= total {
    phase = phase - total
  }
  phase
}

///|
fn clipped_int_bounds(
  canvas : Canvas,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> (Int, Int, Int, Int) {
  let mut left = x_start.max(0)
  let mut top = y_start.max(0)
  let mut right = x_end.min(canvas.pixmap.get_width())
  let mut bottom = y_end.min(canvas.pixmap.get_height())
  match canvas.clip_rect {
    Some(rect) => {
      left = left.max(rect.x.to_int())
      top = top.max(rect.y.to_int())
      right = right.min(rect.right().to_int())
      bottom = bottom.min(rect.bottom().to_int())
    }
    None => ()
  }
  (left, top, right, bottom)
}

///|
fn is_pixel_in_clip(canvas : Canvas, x : Int, y : Int) -> Bool {
  guard x >= 0 &&
    x < canvas.pixmap.get_width() &&
    y >= 0 &&
    y < canvas.pixmap.get_height() else {
    return false
  }
  match canvas.clip_rect {
    Some(rect) => rect.contains(x.to_double() + 0.5, y.to_double() + 0.5)
    None => true
  }
}

///|
fn Canvas::mark_dirty_bounds(
  self : Canvas,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  self.dirty_region.add_rect(
    PixelRect::new(
      x=x_start,
      y=y_start,
      width=x_end - x_start,
      height=y_end - y_start,
    ),
  )
}

///|
fn blend_clipped_rect(
  canvas : Canvas,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  color : Color,
) -> Unit {
  let (x_start, y_start, x_end, y_end) = clipped_int_bounds(
    canvas,
    x,
    y,
    x + w,
    y + h,
  )
  guard x_start < x_end && y_start < y_end else { return }
  canvas.pixmap.blend_rect(
    x_start,
    y_start,
    x_end - x_start,
    y_end - y_start,
    color,
  )
  canvas.mark_dirty_bounds(x_start, y_start, x_end, y_end)
}

///|
fn push_open_subpath_endpoints(
  edges : Array[CanvasEdge],
  endpoints : Array[StrokeEndpoint],
  start_index : Int,
) -> Unit {
  guard start_index < edges.length() else { return }
  let first = edges[start_index]
  let last = edges[edges.length() - 1]
  push_endpoint(
    endpoints,
    first.x0,
    first.y0,
    first.x0 - first.x1,
    first.y0 - first.y1,
  )
  push_endpoint(
    endpoints,
    last.x1,
    last.y1,
    last.x1 - last.x0,
    last.y1 - last.y0,
  )
}

///|
fn push_open_subpath_joins(
  edges : Array[CanvasEdge],
  joins : Array[StrokeJoinPoint],
  start_index : Int,
) -> Unit {
  guard start_index + 1 < edges.length() else { return }
  for i in (start_index + 1)..<edges.length() {
    push_join_if_connected(joins, edges[i - 1], edges[i])
  }
}

///|
fn push_closed_subpath_joins(
  edges : Array[CanvasEdge],
  joins : Array[StrokeJoinPoint],
  start_index : Int,
) -> Unit {
  guard start_index < edges.length() else { return }
  push_open_subpath_joins(edges, joins, start_index)
  push_join_if_connected(joins, edges[edges.length() - 1], edges[start_index])
}

///|
fn push_join_if_connected(
  joins : Array[StrokeJoinPoint],
  prev : CanvasEdge,
  next : CanvasEdge,
) -> Unit {
  guard close_point(prev.x1, prev.y1, next.x0, next.y0) else { return }
  let in_x = prev.x1 - prev.x0
  let in_y = prev.y1 - prev.y0
  let out_x = next.x1 - next.x0
  let out_y = next.y1 - next.y0
  let in_len = (in_x * in_x + in_y * in_y).sqrt()
  let out_len = (out_x * out_x + out_y * out_y).sqrt()
  guard in_len > 0.0 && out_len > 0.0 else { return }
  joins.push({
    x: prev.x1,
    y: prev.y1,
    in_x: in_x / in_len,
    in_y: in_y / in_len,
    out_x: out_x / out_len,
    out_y: out_y / out_len,
  })
}

///|
fn close_point(x0 : Double, y0 : Double, x1 : Double, y1 : Double) -> Bool {
  (x0 - x1).abs() < 0.000001 && (y0 - y1).abs() < 0.000001
}

///|
fn push_endpoint(
  endpoints : Array[StrokeEndpoint],
  x : Double,
  y : Double,
  dir_x : Double,
  dir_y : Double,
) -> Unit {
  let len = (dir_x * dir_x + dir_y * dir_y).sqrt()
  guard len > 0.0 else { return }
  endpoints.push({ x, y, dir_x: dir_x / len, dir_y: dir_y / len })
}

///|
fn push_transformed_edge(
  edges : Array[CanvasEdge],
  transform : Transform,
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
) -> Unit {
  let (tx0, ty0) = transform.apply(x0, y0)
  let (tx1, ty1) = transform.apply(x1, y1)
  if tx0 != tx1 || ty0 != ty1 {
    edges.push({ x0: tx0, y0: ty0, x1: tx1, y1: ty1 })
  }
}

///|
fn flatten_quad(
  edges : Array[CanvasEdge],
  transform : Transform,
  x0 : Double,
  y0 : Double,
  cx : Double,
  cy : Double,
  x1 : Double,
  y1 : Double,
) -> Unit {
  let steps = 16
  let mut prev_x = x0
  let mut prev_y = y0
  for i in 1..<=steps {
    let t = i.to_double() / steps.to_double()
    let mt = 1.0 - t
    let x = mt * mt * x0 + 2.0 * mt * t * cx + t * t * x1
    let y = mt * mt * y0 + 2.0 * mt * t * cy + t * t * y1
    push_transformed_edge(edges, transform, prev_x, prev_y, x, y)
    prev_x = x
    prev_y = y
  }
}

///|
fn flatten_cubic(
  edges : Array[CanvasEdge],
  transform : Transform,
  x0 : Double,
  y0 : Double,
  cx1 : Double,
  cy1 : Double,
  cx2 : Double,
  cy2 : Double,
  x1 : Double,
  y1 : Double,
) -> Unit {
  let steps = 24
  let mut prev_x = x0
  let mut prev_y = y0
  for i in 1..<=steps {
    let t = i.to_double() / steps.to_double()
    let mt = 1.0 - t
    let x = mt * mt * mt * x0 +
      3.0 * mt * mt * t * cx1 +
      3.0 * mt * t * t * cx2 +
      t * t * t * x1
    let y = mt * mt * mt * y0 +
      3.0 * mt * mt * t * cy1 +
      3.0 * mt * t * t * cy2 +
      t * t * t * y1
    push_transformed_edge(edges, transform, prev_x, prev_y, x, y)
    prev_x = x
    prev_y = y
  }
}

///|
fn path_bounds(edges : Array[CanvasEdge]) -> (Double, Double, Double, Double) {
  let first = edges[0]
  let mut min_x_value = first.x0.min(first.x1)
  let mut min_y_value = first.y0.min(first.y1)
  let mut max_x_value = first.x0.max(first.x1)
  let mut max_y_value = first.y0.max(first.y1)
  for edge in edges {
    min_x_value = min_x_value.min(edge.x0).min(edge.x1)
    min_y_value = min_y_value.min(edge.y0).min(edge.y1)
    max_x_value = max_x_value.max(edge.x0).max(edge.x1)
    max_y_value = max_y_value.max(edge.y0).max(edge.y1)
  }
  (min_x_value, min_y_value, max_x_value, max_y_value)
}

///|
fn is_point_in_edges(
  px : Double,
  py : Double,
  edges : Array[CanvasEdge],
  fill_rule : FillRule,
) -> Bool {
  match fill_rule {
    FillRule::EvenOdd => is_point_in_edges_even_odd(px, py, edges)
    FillRule::NonZero => is_point_in_edges_non_zero(px, py, edges)
  }
}

///|
fn is_point_in_edges_even_odd(
  px : Double,
  py : Double,
  edges : Array[CanvasEdge],
) -> Bool {
  let mut inside = false
  for edge in edges {
    if edge_crosses_ray(edge, py) {
      let x = edge_intersection_x(edge, py)
      if x > px {
        inside = !inside
      }
    }
  }
  inside
}

///|
fn is_point_in_edges_non_zero(
  px : Double,
  py : Double,
  edges : Array[CanvasEdge],
) -> Bool {
  let mut winding = 0
  for edge in edges {
    if edge_crosses_ray(edge, py) {
      let x = edge_intersection_x(edge, py)
      if x > px {
        if edge.y1 > edge.y0 {
          winding = winding + 1
        } else {
          winding = winding - 1
        }
      }
    }
  }
  winding != 0
}

///|
fn edge_crosses_ray(edge : CanvasEdge, py : Double) -> Bool {
  (edge.y0 <= py && edge.y1 > py) || (edge.y1 <= py && edge.y0 > py)
}

///|
fn edge_intersection_x(edge : CanvasEdge, py : Double) -> Double {
  edge.x0 + (py - edge.y0) * (edge.x1 - edge.x0) / (edge.y1 - edge.y0)
}

///|
fn is_point_on_stroke(
  px : Double,
  py : Double,
  stroke_path : StrokePathData,
  half_width : Double,
  stroke_cap : StrokeCap,
  stroke_join : StrokeJoin,
  miter_limit : Double,
) -> Bool {
  let max_distance_sq = half_width * half_width
  for edge in stroke_path.edges {
    if distance_to_edge_sq(px, py, edge) <= max_distance_sq {
      return true
    }
  }
  if is_point_on_stroke_join(
      px,
      py,
      stroke_path.joins,
      half_width,
      stroke_join,
      miter_limit,
    ) {
    return true
  }
  is_point_on_stroke_cap(px, py, stroke_path.endpoints, half_width, stroke_cap)
}

///|
fn is_point_on_stroke_join(
  px : Double,
  py : Double,
  joins : Array[StrokeJoinPoint],
  half_width : Double,
  stroke_join : StrokeJoin,
  miter_limit : Double,
) -> Bool {
  match stroke_join {
    StrokeJoin::Round => {
      let max_distance_sq = half_width * half_width
      for join in joins {
        let dx = px - join.x
        let dy = py - join.y
        if is_point_in_join_sector(dx, dy, join) &&
          dx * dx + dy * dy <= max_distance_sq {
          return true
        }
      }
      false
    }
    StrokeJoin::Bevel => {
      for join in joins {
        if is_point_in_join_wedge(px, py, join, half_width) {
          return true
        }
      }
      false
    }
    StrokeJoin::Miter => {
      for join in joins {
        if is_point_in_miter_join(px, py, join, half_width, miter_limit) {
          return true
        }
      }
      false
    }
  }
}

///|
fn is_point_in_miter_join(
  px : Double,
  py : Double,
  join : StrokeJoinPoint,
  half_width : Double,
  miter_limit : Double,
) -> Bool {
  guard is_miter_join_within_limit(join, miter_limit) else {
    return is_point_in_join_wedge(px, py, join, half_width)
  }
  let dx = px - join.x
  let dy = py - join.y
  is_point_in_join_sector(dx, dy, join) &&
  cross2(join.in_x, join.in_y, dx, dy).abs() <= half_width &&
  cross2(join.out_x, join.out_y, dx, dy).abs() <= half_width
}

///|
fn is_miter_join_within_limit(
  join : StrokeJoinPoint,
  miter_limit : Double,
) -> Bool {
  let bx = -join.out_x
  let by = -join.out_y
  guard cross2(join.in_x, join.in_y, bx, by).abs() > 0.000001 else {
    return false
  }
  let dot = (join.in_x * bx + join.in_y * by).max(-1.0).min(1.0)
  let sin_half_sq = (1.0 - dot) / 2.0
  guard sin_half_sq > 0.0 else { return false }
  let ratio = 1.0 / sin_half_sq.sqrt()
  ratio <= miter_limit.max(1.0)
}

///|
fn is_point_in_join_wedge(
  px : Double,
  py : Double,
  join : StrokeJoinPoint,
  half_width : Double,
) -> Bool {
  let dx = px - join.x
  let dy = py - join.y
  let bx = -join.out_x
  let by = -join.out_y
  let denom = cross2(join.in_x, join.in_y, bx, by)
  guard denom.abs() > 0.000001 else { return false }
  let s = cross2(dx, dy, bx, by) / denom
  let t = cross2(join.in_x, join.in_y, dx, dy) / denom
  s >= 0.0 && t >= 0.0 && s + t <= half_width
}

///|
fn is_point_in_join_sector(
  dx : Double,
  dy : Double,
  join : StrokeJoinPoint,
) -> Bool {
  let bx = -join.out_x
  let by = -join.out_y
  let cross = cross2(join.in_x, join.in_y, bx, by)
  guard cross.abs() > 0.000001 else { return false }
  let side = if cross > 0.0 { 1.0 } else { -1.0 }
  side * cross2(join.in_x, join.in_y, dx, dy) >= 0.0 &&
  side * cross2(dx, dy, bx, by) >= 0.0
}

///|
fn cross2(ax : Double, ay : Double, bx : Double, by : Double) -> Double {
  ax * by - ay * bx
}

///|
fn is_point_on_stroke_cap(
  px : Double,
  py : Double,
  endpoints : Array[StrokeEndpoint],
  half_width : Double,
  stroke_cap : StrokeCap,
) -> Bool {
  match stroke_cap {
    StrokeCap::Butt => false
    StrokeCap::Round => {
      let max_distance_sq = half_width * half_width
      for endpoint in endpoints {
        let dx = px - endpoint.x
        let dy = py - endpoint.y
        let outward = dx * endpoint.dir_x + dy * endpoint.dir_y
        if outward >= 0.0 && dx * dx + dy * dy <= max_distance_sq {
          return true
        }
      }
      false
    }
    StrokeCap::Square => {
      for endpoint in endpoints {
        let dx = px - endpoint.x
        let dy = py - endpoint.y
        let outward = dx * endpoint.dir_x + dy * endpoint.dir_y
        let sideways = dx * -endpoint.dir_y + dy * endpoint.dir_x
        if outward >= 0.0 &&
          outward <= half_width &&
          sideways.abs() <= half_width {
          return true
        }
      }
      false
    }
  }
}

///|
fn distance_to_edge_sq(px : Double, py : Double, edge : CanvasEdge) -> Double {
  let dx = edge.x1 - edge.x0
  let dy = edge.y1 - edge.y0
  let length_sq = dx * dx + dy * dy
  guard length_sq > 0.0 else {
    let point_dx = px - edge.x0
    let point_dy = py - edge.y0
    return point_dx * point_dx + point_dy * point_dy
  }
  let projected = ((px - edge.x0) * dx + (py - edge.y0) * dy) / length_sq
  guard projected >= 0.0 && projected <= 1.0 else { return half_infinite }
  let t = projected
  let closest_x = edge.x0 + t * dx
  let closest_y = edge.y0 + t * dy
  point_distance_sq(px, py, closest_x, closest_y)
}

///|
fn point_distance_sq(
  px : Double,
  py : Double,
  x : Double,
  y : Double,
) -> Double {
  let point_dx = px - x
  let point_dy = py - y
  point_dx * point_dx + point_dy * point_dy
}

///|
let half_infinite = 1.0e100

///|
fn blend_coverage_pixel(
  pixmap : Pixmap,
  x : Int,
  y : Int,
  color : Color,
  covered : Int,
  sample_count : Int,
) -> Unit {
  let coverage = coverage_to_byte(covered, sample_count).to_int()
  let alpha = (color.a.to_int() * coverage + 127) / 255
  pixmap.blend_pixel(x, y, color.with_alpha(clamp_byte(alpha)))
}

///|
fn coverage_to_byte(covered : Int, sample_count : Int) -> Byte {
  guard sample_count > 0 else { return 0 }
  clamp_byte((covered * 255 + sample_count / 2) / sample_count)
}
