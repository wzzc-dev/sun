///|
/// A line segment for rasterization
pub struct LineSegment {
  x0 : Double
  y0 : Double
  x1 : Double
  y1 : Double
} derive(Debug)

///|
priv struct CurvePoint {
  cx : Double
  cy : Double
  curve_on : Bool
}

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
/// Grayscale coverage mask produced by text rasterization
pub struct CoverageMask {
  width : Int
  height : Int
  pixels : FixedArray[Byte]
} derive(Debug)

///|
/// Create a coverage mask from grayscale pixels
pub fn CoverageMask::new(
  width : Int,
  height : Int,
  pixels : FixedArray[Byte],
) -> CoverageMask {
  { width, height, pixels }
}

///|
/// Get the width of the mask
pub fn CoverageMask::get_width(self : CoverageMask) -> Int {
  self.width
}

///|
/// Get the height of the mask
pub fn CoverageMask::get_height(self : CoverageMask) -> Int {
  self.height
}

///|
/// Get the grayscale coverage pixels
pub fn CoverageMask::get_pixels(self : CoverageMask) -> FixedArray[Byte] {
  self.pixels
}

///|
/// Copy this coverage mask and its pixel storage.
pub fn CoverageMask::copy(self : CoverageMask) -> CoverageMask {
  CoverageMask::new(self.width, self.height, copy_bytes(self.pixels))
}

///|
/// Placement of one glyph mask inside a glyph mask atlas.
pub struct GlyphAtlasEntry {
  key : String
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Debug)

///|
/// Result of inserting a glyph mask into an atlas with lifecycle policy.
pub struct GlyphMaskAtlasInsertResult {
  entry : GlyphAtlasEntry
  did_clear : Bool
} derive(Debug)

///|
priv struct GlyphAtlasPlacement {
  x : Int
  y : Int
  row_height : Int
}

///|
/// Create a glyph atlas entry.
pub fn GlyphAtlasEntry::new(
  key~ : String,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
) -> GlyphAtlasEntry {
  { key, x, y, width, height }
}

///|
/// Get the caller-provided glyph key for this atlas entry.
pub fn GlyphAtlasEntry::get_key(self : GlyphAtlasEntry) -> String {
  self.key
}

///|
/// Get the atlas x coordinate.
pub fn GlyphAtlasEntry::get_x(self : GlyphAtlasEntry) -> Int {
  self.x
}

///|
/// Get the atlas y coordinate.
pub fn GlyphAtlasEntry::get_y(self : GlyphAtlasEntry) -> Int {
  self.y
}

///|
/// Get the entry width.
pub fn GlyphAtlasEntry::get_width(self : GlyphAtlasEntry) -> Int {
  self.width
}

///|
/// Get the entry height.
pub fn GlyphAtlasEntry::get_height(self : GlyphAtlasEntry) -> Int {
  self.height
}

///|
/// Get the placed atlas entry.
pub fn GlyphMaskAtlasInsertResult::get_entry(
  self : GlyphMaskAtlasInsertResult,
) -> GlyphAtlasEntry {
  self.entry
}

///|
/// Return whether the atlas was cleared before this entry was inserted.
pub fn GlyphMaskAtlasInsertResult::did_clear(
  self : GlyphMaskAtlasInsertResult,
) -> Bool {
  self.did_clear
}

///|
/// Small row-packed atlas for rendered glyph coverage masks.
pub struct GlyphMaskAtlas {
  width : Int
  height : Int
  pixels : FixedArray[Byte]
  mut entries : Map[String, GlyphAtlasEntry]
  mut cursor_x : Int
  mut cursor_y : Int
  mut row_height : Int
  mut used_pixel_count : Int
} derive(Debug)

///|
/// Create an empty glyph mask atlas.
pub fn GlyphMaskAtlas::new(width : Int, height : Int) -> GlyphMaskAtlas {
  {
    width,
    height,
    pixels: FixedArray::make(width * height, b"\x00"[0]),
    entries: {},
    cursor_x: 0,
    cursor_y: 0,
    row_height: 0,
    used_pixel_count: 0,
  }
}

///|
/// Get the atlas width.
pub fn GlyphMaskAtlas::get_width(self : GlyphMaskAtlas) -> Int {
  self.width
}

///|
/// Get the atlas height.
pub fn GlyphMaskAtlas::get_height(self : GlyphMaskAtlas) -> Int {
  self.height
}

///|
/// Return the total pixel capacity of the atlas.
pub fn GlyphMaskAtlas::get_capacity(self : GlyphMaskAtlas) -> Int {
  self.width * self.height
}

///|
/// Return the number of atlas pixels occupied by placed glyph masks.
pub fn GlyphMaskAtlas::get_used_pixel_count(self : GlyphMaskAtlas) -> Int {
  self.used_pixel_count
}

///|
/// Return atlas capacity minus placed mask pixels.
pub fn GlyphMaskAtlas::get_free_pixel_count(self : GlyphMaskAtlas) -> Int {
  self.get_capacity() - self.used_pixel_count
}

///|
/// Return placed mask pixels divided by total atlas capacity.
pub fn GlyphMaskAtlas::get_occupancy_ratio(self : GlyphMaskAtlas) -> Double {
  let capacity = self.get_capacity()
  if capacity <= 0 {
    0.0
  } else {
    self.used_pixel_count.to_double() / capacity.to_double()
  }
}

///|
/// Return the number of placed glyph masks.
pub fn GlyphMaskAtlas::len(self : GlyphMaskAtlas) -> Int {
  self.entries.length()
}

///|
/// Return whether the atlas has no placed glyph masks.
pub fn GlyphMaskAtlas::is_empty(self : GlyphMaskAtlas) -> Bool {
  self.len() is 0
}

///|
/// Look up a placed glyph mask by key.
pub fn GlyphMaskAtlas::get(
  self : GlyphMaskAtlas,
  key : String,
) -> GlyphAtlasEntry? {
  self.entries.get(key)
}

///|
/// Snapshot the full atlas pixels as a coverage mask.
pub fn GlyphMaskAtlas::to_mask(self : GlyphMaskAtlas) -> CoverageMask {
  CoverageMask::new(self.width, self.height, copy_bytes(self.pixels))
}

///|
/// Return whether this mask can be placed as a new atlas entry.
pub fn GlyphMaskAtlas::can_fit(
  self : GlyphMaskAtlas,
  mask : CoverageMask,
) -> Bool {
  match self.next_placement(mask) {
    Some(_) => true
    None => false
  }
}

///|
/// Insert a rendered glyph mask if there is space, or return the existing entry.
pub fn GlyphMaskAtlas::insert(
  self : GlyphMaskAtlas,
  key : String,
  mask : CoverageMask,
) -> GlyphAtlasEntry? {
  match self.get(key) {
    Some(entry) => Some(entry)
    None => self.place(key, mask)
  }
}

///|
/// Insert a mask, clearing the atlas first if the current row-packing state is full.
/// When the result reports `did_clear`, previous atlas entries are no longer valid.
pub fn GlyphMaskAtlas::insert_or_clear(
  self : GlyphMaskAtlas,
  key : String,
  mask : CoverageMask,
) -> GlyphMaskAtlasInsertResult? {
  match self.get(key) {
    Some(entry) => Some({ entry, did_clear: false })
    None =>
      match self.place(key, mask) {
        Some(entry) => Some({ entry, did_clear: false })
        None => {
          guard self.can_fit_empty(mask) else { return None }
          self.clear()
          match self.place(key, mask) {
            Some(entry) => Some({ entry, did_clear: true })
            None => None
          }
        }
      }
  }
}

///|
/// Remove all atlas entries and clear atlas pixels.
pub fn GlyphMaskAtlas::clear(self : GlyphMaskAtlas) -> Unit {
  self.entries = {}
  self.cursor_x = 0
  self.cursor_y = 0
  self.row_height = 0
  self.used_pixel_count = 0
  for i in 0..<self.pixels.length() {
    self.pixels[i] = b"\x00"[0]
  }
}

///|
fn GlyphMaskAtlas::next_placement(
  self : GlyphMaskAtlas,
  mask : CoverageMask,
) -> GlyphAtlasPlacement? {
  let mask_width = mask.get_width()
  let mask_height = mask.get_height()
  guard self.can_fit_empty(mask) else { return None }

  let should_wrap = self.cursor_x + mask_width > self.width
  let (entry_x, entry_y, current_row_height) = if should_wrap {
    (0, self.cursor_y + self.row_height, 0)
  } else {
    (self.cursor_x, self.cursor_y, self.row_height)
  }
  guard entry_y + mask_height <= self.height else { return None }
  Some({ x: entry_x, y: entry_y, row_height: current_row_height })
}

///|
fn GlyphMaskAtlas::can_fit_empty(
  self : GlyphMaskAtlas,
  mask : CoverageMask,
) -> Bool {
  let mask_width = mask.get_width()
  let mask_height = mask.get_height()
  mask_width > 0 &&
  mask_height > 0 &&
  mask.get_pixels().length() >= mask_width * mask_height &&
  mask_width <= self.width &&
  mask_height <= self.height
}

///|
fn GlyphMaskAtlas::place(
  self : GlyphMaskAtlas,
  key : String,
  mask : CoverageMask,
) -> GlyphAtlasEntry? {
  let mask_width = mask.get_width()
  let mask_height = mask.get_height()
  let placement = match self.next_placement(mask) {
    Some(placement) => placement
    None => return None
  }

  let entry = GlyphAtlasEntry::new(
    key~,
    x=placement.x,
    y=placement.y,
    width=mask_width,
    height=mask_height,
  )
  copy_mask_into_atlas(self, entry, mask)
  self.entries[key] = entry
  self.cursor_x = placement.x + mask_width
  self.cursor_y = placement.y
  self.row_height = placement.row_height.max(mask_height)
  self.used_pixel_count += mask_width * mask_height
  Some(entry)
}

///|
fn copy_mask_into_atlas(
  atlas : GlyphMaskAtlas,
  entry : GlyphAtlasEntry,
  mask : CoverageMask,
) -> Unit {
  let src = mask.get_pixels()
  for y in 0..<entry.height {
    for x in 0..<entry.width {
      atlas.pixels[(entry.y + y) * atlas.width + entry.x + x] = src[y *
        entry.width +
        x]
    }
  }
}

///|
/// Small keyed cache for rendered glyph coverage masks.
pub struct GlyphMaskCache {
  mut masks : Map[String, CoverageMask]
} derive(Debug)

///|
/// Create an empty glyph mask cache.
pub fn GlyphMaskCache::new() -> GlyphMaskCache {
  { masks: {} }
}

///|
/// Return the number of cached glyph masks.
pub fn GlyphMaskCache::len(self : GlyphMaskCache) -> Int {
  self.masks.length()
}

///|
/// Return whether the cache currently has no glyph masks.
pub fn GlyphMaskCache::is_empty(self : GlyphMaskCache) -> Bool {
  self.len() is 0
}

///|
/// Look up a rendered glyph mask by caller-provided key.
pub fn GlyphMaskCache::get(
  self : GlyphMaskCache,
  key : String,
) -> CoverageMask? {
  match self.masks.get(key) {
    Some(mask) => Some(mask.copy())
    None => None
  }
}

///|
/// Insert or replace a rendered glyph mask under a caller-provided key.
pub fn GlyphMaskCache::insert(
  self : GlyphMaskCache,
  key : String,
  mask : CoverageMask,
) -> CoverageMask {
  let stored = mask.copy()
  self.masks[key] = stored
  stored.copy()
}

///|
/// Rasterize a glyph on first use and return the cached mask afterwards.
pub fn GlyphMaskCache::get_or_rasterize_glyph(
  self : GlyphMaskCache,
  key : String,
  glyph : SimpleGlyph,
  width : Int,
  height : Int,
  x : Double,
  y : Double,
  scale : Double,
) -> CoverageMask {
  match self.get(key) {
    Some(mask) => mask
    None =>
      self.insert(key, render_glyph_mask(glyph, width, height, x, y, scale))
  }
}

///|
/// Remove a cached glyph mask by key.
pub fn GlyphMaskCache::remove(self : GlyphMaskCache, key : String) -> Unit {
  self.masks.remove(key)
}

///|
/// Drop all cached glyph masks.
pub fn GlyphMaskCache::clear(self : GlyphMaskCache) -> Unit {
  self.masks = {}
}

///|
/// Small keyed cache for rendered text coverage masks.
pub struct TextMaskCache {
  mut masks : Map[String, CoverageMask]
} derive(Debug)

///|
/// Create an empty text mask cache.
pub fn TextMaskCache::new() -> TextMaskCache {
  { masks: {} }
}

///|
/// Return the number of cached masks.
pub fn TextMaskCache::len(self : TextMaskCache) -> Int {
  self.masks.length()
}

///|
/// Return whether the cache currently has no masks.
pub fn TextMaskCache::is_empty(self : TextMaskCache) -> Bool {
  self.len() is 0
}

///|
/// Look up a rendered mask by caller-provided key.
pub fn TextMaskCache::get(self : TextMaskCache, key : String) -> CoverageMask? {
  match self.masks.get(key) {
    Some(mask) => Some(mask.copy())
    None => None
  }
}

///|
/// Insert or replace a rendered mask under a caller-provided key.
pub fn TextMaskCache::insert(
  self : TextMaskCache,
  key : String,
  mask : CoverageMask,
) -> CoverageMask {
  let stored = mask.copy()
  self.masks[key] = stored
  stored.copy()
}

///|
/// Render text from a checked face on first use and return the cached mask afterwards.
pub fn TextMaskCache::get_or_render_face(
  self : TextMaskCache,
  key : String,
  face : FontFace,
  text : String,
  width : Int,
  height : Int,
  x : Double,
  y : Double,
  config : LayoutConfig,
) -> CoverageMask {
  match self.get(key) {
    Some(mask) => mask
    None =>
      self.insert(
        key,
        render_text_mask_face(face, text, width, height, x, y, config),
      )
  }
}

///|
/// Remove a cached mask by key.
pub fn TextMaskCache::remove(self : TextMaskCache, key : String) -> Unit {
  self.masks.remove(key)
}

///|
/// Drop all cached masks.
pub fn TextMaskCache::clear(self : TextMaskCache) -> Unit {
  self.masks = {}
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
/// Get the rasterizer width
pub fn Rasterizer::get_width(self : Rasterizer) -> Int {
  self.width
}

///|
/// Get the rasterizer height
pub fn Rasterizer::get_height(self : Rasterizer) -> Int {
  self.height
}

///|
/// Snapshot the current grayscale pixels as a coverage mask
pub fn Rasterizer::to_mask(self : Rasterizer) -> CoverageMask {
  CoverageMask::new(self.width, self.height, copy_bytes(self.pixels))
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

  let segments = []
  for contour in glyph.contours {
    let contour_segments = flatten_contour(contour, x, y, scale)
    for segment in contour_segments {
      segments.push(segment)
    }
  }

  // Fill using scanline algorithm with anti-aliasing
  scanline_fill_with_aa(self, segments)
}

///|
/// Rasterize laid-out text from a parsed font into this rasterizer
pub fn Rasterizer::rasterize_text(
  self : Rasterizer,
  font : Font,
  text : String,
  x : Double,
  y : Double,
  config : LayoutConfig,
) -> Unit {
  let result = layout_text(font, text, config)
  let scale = config.font_size / font.get_units_per_em().to_double()
  for line in result.lines {
    for glyph in line.glyphs {
      match font.get_glyph(glyph.glyph_id) {
        GlyphData::Simple(simple_glyph) =>
          self.rasterize_glyph(simple_glyph, x + glyph.x, y + line.y, scale)
        _ => ()
      }
    }
  }
}

///|
/// Rasterize laid-out text from a parsed font face into this rasterizer.
pub fn Rasterizer::rasterize_text_face(
  self : Rasterizer,
  face : FontFace,
  text : String,
  x : Double,
  y : Double,
  config : LayoutConfig,
) -> Unit {
  let font = face.get_font()
  let layout = layout_text_face(face, text, config)
  let scale = config.font_size / face.get_units_per_em().to_double()
  for run in layout.get_runs() {
    for glyph in run.get_glyphs() {
      match font.get_glyph(glyph.glyph_id) {
        GlyphData::Simple(simple_glyph) =>
          self.rasterize_glyph(
            simple_glyph,
            x + glyph.x,
            y + run.get_baseline_y(),
            scale,
          )
        _ => ()
      }
    }
  }
}

///|
/// Render one glyph into a grayscale coverage mask.
pub fn render_glyph_mask(
  glyph : SimpleGlyph,
  width : Int,
  height : Int,
  x : Double,
  y : Double,
  scale : Double,
) -> CoverageMask {
  let rasterizer = Rasterizer::new(width, height)
  rasterizer.rasterize_glyph(glyph, x, y, scale)
  rasterizer.to_mask()
}

///|
/// Render text into a grayscale coverage mask
pub fn render_text_mask(
  font : Font,
  text : String,
  width : Int,
  height : Int,
  x : Double,
  y : Double,
  config : LayoutConfig,
) -> CoverageMask {
  let rasterizer = Rasterizer::new(width, height)
  rasterizer.rasterize_text(font, text, x, y, config)
  rasterizer.to_mask()
}

///|
/// Render text from a parsed font face into a grayscale coverage mask.
pub fn render_text_mask_face(
  face : FontFace,
  text : String,
  width : Int,
  height : Int,
  x : Double,
  y : Double,
  config : LayoutConfig,
) -> CoverageMask {
  let rasterizer = Rasterizer::new(width, height)
  rasterizer.rasterize_text_face(face, text, x, y, config)
  rasterizer.to_mask()
}

///|
fn flatten_contour(
  contour : GlyphContour,
  x : Double,
  y : Double,
  scale : Double,
) -> Array[LineSegment] {
  let points = contour.points
  let segments = []
  let len = points.length()
  guard len >= 2 else { return segments }

  let first = transform_point(points[0], x, y, scale)
  let last = transform_point(points[len - 1], x, y, scale)
  let mut current = if first.curve_on {
    first
  } else if last.curve_on {
    last
  } else {
    midpoint(last, first)
  }
  let mut index = if first.curve_on { 1 } else { 0 }
  let mut processed = 0

  while processed < len {
    let point = transform_point(points[index % len], x, y, scale)
    if point.curve_on {
      segments.push({
        x0: current.cx,
        y0: current.cy,
        x1: point.cx,
        y1: point.cy,
      })
      current = point
      index = index + 1
      processed = processed + 1
    } else {
      let next = transform_point(points[(index + 1) % len], x, y, scale)
      if next.curve_on {
        push_quadratic_segments(segments, current, point, next)
        current = next
        index = index + 2
        processed = processed + 2
      } else {
        let implicit = midpoint(point, next)
        push_quadratic_segments(segments, current, point, implicit)
        current = implicit
        index = index + 1
        processed = processed + 1
      }
    }
  }

  segments
}

///|
fn transform_point(
  point : GlyphPoint,
  x : Double,
  y : Double,
  scale : Double,
) -> CurvePoint {
  {
    cx: x + point.x.to_double() * scale,
    cy: y - point.y.to_double() * scale,
    curve_on: point.on_curve,
  }
}

///|
fn midpoint(a : CurvePoint, b : CurvePoint) -> CurvePoint {
  { cx: (a.cx + b.cx) / 2.0, cy: (a.cy + b.cy) / 2.0, curve_on: true }
}

///|
fn push_quadratic_segments(
  segments : Array[LineSegment],
  start : CurvePoint,
  control : CurvePoint,
  end : CurvePoint,
) -> Unit {
  let bezier_segments = flatten_quadratic_bezier(
    start.cx,
    start.cy,
    control.cx,
    control.cy,
    end.cx,
    end.cy,
  )
  for segment in bezier_segments {
    segments.push(segment)
  }
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
/// Scanline fill with non-zero winding rule and 4x4 supersampling anti-aliasing
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
  let x_start = min_x(segments).to_int().max(0)
  let x_end = max_x(segments).to_int().min(rasterizer.width)

  // 4x4 supersampling for anti-aliasing
  let sample_count = 4
  let sample_count_sq = sample_count * sample_count // 16

  // For each pixel in the bounding box
  for y in y_start..<y_end {
    for x in x_start..<x_end {
      let mut covered = 0

      // Check each sub-pixel
      for sy in 0..<sample_count {
        for sx in 0..<sample_count {
          // Sub-pixel position (center of sub-pixel)
          let sample_x = x.to_double() +
            (sx.to_double() + 0.5) / sample_count.to_double()
          let sample_y = y.to_double() +
            (sy.to_double() + 0.5) / sample_count.to_double()

          // Check if this sub-pixel is inside the glyph using non-zero winding rule
          if is_point_inside_glyph(sample_x, sample_y, segments) {
            covered = covered + 1
          }
        }
      }

      // Map coverage count to 0-255
      if covered > 0 {
        let idx = y * rasterizer.width + x
        rasterizer.coverage[idx] = covered * 255 / sample_count_sq
      }
    }
  }

  // Apply coverage to pixels
  for i in 0..<rasterizer.pixels.length() {
    if rasterizer.coverage[i] > 0 {
      let coverage = rasterizer.coverage[i].min(255).to_byte()
      if coverage.to_int() > rasterizer.pixels[i].to_int() {
        rasterizer.pixels[i] = coverage
      }
    }
  }
}

///|
fn copy_bytes(src : FixedArray[Byte]) -> FixedArray[Byte] {
  let dst = FixedArray::make(src.length(), b"\x00"[0])
  for i in 0..<src.length() {
    dst[i] = src[i]
  }
  dst
}

///|
/// Get minimum x coordinate from segments
fn min_x(segments : Array[LineSegment]) -> Double {
  let mut min_val = segments[0].x0
  for seg in segments {
    if seg.x0 < min_val {
      min_val = seg.x0
    }
    if seg.x1 < min_val {
      min_val = seg.x1
    }
  }
  min_val
}

///|
/// Get maximum x coordinate from segments
fn max_x(segments : Array[LineSegment]) -> Double {
  let mut max_val = segments[0].x0
  for seg in segments {
    if seg.x0 > max_val {
      max_val = seg.x0
    }
    if seg.x1 > max_val {
      max_val = seg.x1
    }
  }
  max_val
}

///|
/// Check if a point is inside the glyph using non-zero winding rule
fn is_point_inside_glyph(
  px : Double,
  py : Double,
  segments : Array[LineSegment],
) -> Bool {
  // Count crossings with direction
  let mut winding = 0

  for seg in segments {
    let y0 = seg.y0
    let y1 = seg.y1

    // Check if segment crosses the horizontal line at py
    if (y0 < py && y1 >= py) || (y1 < py && y0 >= py) {
      // Calculate x intersection
      let t = (py - y0) / (y1 - y0)
      let x = seg.x0 + t * (seg.x1 - seg.x0)

      // Only count if intersection is to the left of the point
      if x < px {
        // Direction: +1 if crossing upward, -1 if downward
        if y0 < y1 {
          winding = winding + 1
        } else {
          winding = winding - 1
        }
      }
    }
  }

  // Non-zero rule: point is inside if winding number is non-zero
  winding != 0
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
