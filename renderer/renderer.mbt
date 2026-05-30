///|
/// Renderer core that composes vector drawing, text masks, and pixmap output.
pub struct Renderer {
  canvas : @graphics.Canvas
} derive(Debug)

///|
/// Result of drawing text through glyph-mask cache and atlas resources.
pub struct TextAtlasDrawResult {
  glyph_count : Int
  drawn_glyph_count : Int
  skipped_glyph_count : Int
  cache_hit_count : Int
  rasterized_glyph_count : Int
  atlas_hit_count : Int
  atlas_inserted_count : Int
  did_clear_atlas : Bool
} derive(Debug)

///|
/// Result of drawing text through a caller-owned rendered text-mask cache.
pub struct TextMaskDrawResult {
  did_render_mask : Bool
} derive(Debug)

///|
priv struct GlyphAtlasMaskPlacement {
  width : Int
  height : Int
  origin_x : Double
  origin_y : Double
  draw_offset_x : Int
  draw_offset_y : Int
}

///|
/// Create a renderer around an existing canvas.
pub fn Renderer::new(canvas : @graphics.Canvas) -> Renderer {
  { canvas, }
}

///|
/// Get the renderer canvas.
pub fn Renderer::get_canvas(self : Renderer) -> @graphics.Canvas {
  self.canvas
}

///|
/// Return the number of layout glyphs visited by an atlas text draw.
pub fn TextAtlasDrawResult::get_glyph_count(self : TextAtlasDrawResult) -> Int {
  self.glyph_count
}

///|
/// Return the number of glyphs composited from the atlas.
pub fn TextAtlasDrawResult::get_drawn_glyph_count(
  self : TextAtlasDrawResult,
) -> Int {
  self.drawn_glyph_count
}

///|
/// Return the number of layout glyphs that could not be drawn through the atlas.
pub fn TextAtlasDrawResult::get_skipped_glyph_count(
  self : TextAtlasDrawResult,
) -> Int {
  self.skipped_glyph_count
}

///|
/// Return the number of drawable glyphs reused from the glyph mask cache.
pub fn TextAtlasDrawResult::get_cache_hit_count(
  self : TextAtlasDrawResult,
) -> Int {
  self.cache_hit_count
}

///|
/// Return the number of glyph masks rasterized on cache miss.
pub fn TextAtlasDrawResult::get_rasterized_glyph_count(
  self : TextAtlasDrawResult,
) -> Int {
  self.rasterized_glyph_count
}

///|
/// Return the number of glyph placements reused from the atlas.
pub fn TextAtlasDrawResult::get_atlas_hit_count(
  self : TextAtlasDrawResult,
) -> Int {
  self.atlas_hit_count
}

///|
/// Return the number of glyph placements newly inserted into the atlas.
pub fn TextAtlasDrawResult::get_atlas_inserted_count(
  self : TextAtlasDrawResult,
) -> Int {
  self.atlas_inserted_count
}

///|
/// Return whether the atlas was cleared while drawing this text.
pub fn TextAtlasDrawResult::did_clear_atlas(self : TextAtlasDrawResult) -> Bool {
  self.did_clear_atlas
}

///|
/// Return whether this draw rendered a new text mask instead of hitting cache.
pub fn TextMaskDrawResult::did_render_mask(self : TextMaskDrawResult) -> Bool {
  self.did_render_mask
}

///|
/// Return whether this draw reused a rendered text mask from cache.
pub fn TextMaskDrawResult::did_hit_cache(self : TextMaskDrawResult) -> Bool {
  !self.did_render_mask
}

///|
/// Draw text through the real text rasterization pipeline.
pub fn Renderer::draw_text(
  self : Renderer,
  font : @text.Font,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let pixmap = self.canvas.get_pixmap()
  draw_text(
    self.canvas,
    font,
    text,
    x,
    y,
    pixmap.get_width(),
    pixmap.get_height(),
    config,
    paint,
  )
}

///|
/// Draw text through the stable font-face layout pipeline.
pub fn Renderer::draw_text_face(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let pixmap = self.canvas.get_pixmap()
  draw_text_face(
    self.canvas,
    face,
    text,
    x,
    y,
    pixmap.get_width(),
    pixmap.get_height(),
    config,
    paint,
  )
}

///|
/// Draw text through a caller-owned rendered text-mask cache.
pub fn Renderer::draw_text_face_cached(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  text_cache : @text.TextMaskCache,
  text_key : String,
  paint : @graphics.Paint,
) -> TextMaskDrawResult {
  let pixmap = self.canvas.get_pixmap()
  draw_text_face_cached(
    self.canvas,
    face,
    text,
    x,
    y,
    pixmap.get_width(),
    pixmap.get_height(),
    config,
    text_cache,
    text_key,
    paint,
  )
}

///|
/// Draw text through caller-owned glyph mask cache and glyph atlas resources.
pub fn Renderer::draw_text_face_atlas(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  glyph_cache : @text.GlyphMaskCache,
  atlas : @text.GlyphMaskAtlas,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextAtlasDrawResult {
  draw_text_face_atlas(
    self.canvas,
    face,
    text,
    x,
    y,
    config,
    glyph_cache,
    atlas,
    glyph_key_prefix,
    paint,
  )
}

///|
/// Composite an existing text coverage mask on the renderer canvas.
pub fn Renderer::draw_coverage_mask(
  self : Renderer,
  mask : @text.CoverageMask,
  paint : @graphics.Paint,
) -> Unit {
  draw_coverage_mask(self.canvas, mask, paint)
}

///|
/// Draw one glyph entry from a coverage-mask atlas snapshot.
pub fn Renderer::draw_glyph_atlas_entry(
  self : Renderer,
  atlas_mask : @text.CoverageMask,
  entry : @text.GlyphAtlasEntry,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> Unit {
  draw_glyph_atlas_entry(self.canvas, atlas_mask, entry, x, y, paint)
}

///|
/// Rasterize text through the text package and composite it on a canvas.
pub fn draw_text(
  canvas : @graphics.Canvas,
  font : @text.Font,
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let mask = @text.render_text_mask(font, text, width, height, x, y, config)
  draw_coverage_mask(canvas, mask, paint)
}

///|
/// Rasterize font-face text and composite it on a canvas.
pub fn draw_text_face(
  canvas : @graphics.Canvas,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let mask = @text.render_text_mask_face(
    face, text, width, height, x, y, config,
  )
  draw_coverage_mask(canvas, mask, paint)
}

///|
/// Draw text through a caller-owned rendered text-mask cache.
pub fn draw_text_face_cached(
  canvas : @graphics.Canvas,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  text_cache : @text.TextMaskCache,
  text_key : String,
  paint : @graphics.Paint,
) -> TextMaskDrawResult {
  let result = text_cache.get_or_render_face_result(
    text_key, face, text, width, height, x, y, config,
  )
  draw_coverage_mask(canvas, result.get_mask(), paint)
  { did_render_mask: result.did_render() }
}

///|
/// Draw text through caller-owned glyph mask cache and glyph atlas resources.
pub fn draw_text_face_atlas(
  canvas : @graphics.Canvas,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  glyph_cache : @text.GlyphMaskCache,
  atlas : @text.GlyphMaskAtlas,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextAtlasDrawResult {
  let layout = @text.TextLayout::layout(face, text, config)
  let scale = config.font_size / face.get_units_per_em().to_double()
  let mut glyph_count = 0
  let mut drawn_glyph_count = 0
  let mut skipped_glyph_count = 0
  let mut cache_hit_count = 0
  let mut rasterized_glyph_count = 0
  let mut atlas_hit_count = 0
  let mut atlas_inserted_count = 0
  let mut did_clear_atlas = false

  for run in layout.get_runs() {
    for glyph in run.get_glyphs() {
      glyph_count += 1
      match face.get_glyph(glyph.glyph_id) {
        @text.GlyphData::Simple(simple_glyph) =>
          match make_glyph_atlas_mask_placement(simple_glyph, scale) {
            Some(placement) => {
              let key = glyph_atlas_cache_key(
                glyph_key_prefix,
                glyph.glyph_id,
                config.font_size,
              )
              let cache_result = glyph_cache.get_or_rasterize_glyph_result(
                key,
                simple_glyph,
                placement.width,
                placement.height,
                placement.origin_x,
                placement.origin_y,
                scale,
              )
              if cache_result.did_rasterize() {
                rasterized_glyph_count += 1
              } else {
                cache_hit_count += 1
              }
              let mask = cache_result.get_mask()
              match atlas.insert_or_clear(key, mask) {
                Some(result) => {
                  if result.did_clear() {
                    did_clear_atlas = true
                  }
                  if result.did_reuse() {
                    atlas_hit_count += 1
                  } else {
                    atlas_inserted_count += 1
                  }
                  let entry = result.get_entry()
                  draw_glyph_atlas_entry(
                    canvas,
                    atlas.to_mask(),
                    entry,
                    floor_to_int(x + glyph.x) + placement.draw_offset_x,
                    floor_to_int(y + run.get_baseline_y()) +
                    placement.draw_offset_y,
                    paint,
                  )
                  drawn_glyph_count += 1
                }
                None => skipped_glyph_count += 1
              }
            }
            None => skipped_glyph_count += 1
          }
        _ => skipped_glyph_count += 1
      }
    }
  }

  {
    glyph_count,
    drawn_glyph_count,
    skipped_glyph_count,
    cache_hit_count,
    rasterized_glyph_count,
    atlas_hit_count,
    atlas_inserted_count,
    did_clear_atlas,
  }
}

///|
/// Composite a text coverage mask on a canvas.
pub fn draw_coverage_mask(
  canvas : @graphics.Canvas,
  mask : @text.CoverageMask,
  paint : @graphics.Paint,
) -> Unit {
  canvas.draw_mask(
    0,
    0,
    mask.get_width(),
    mask.get_height(),
    mask.get_pixels(),
    paint,
  )
}

///|
/// Composite one glyph entry from a coverage-mask atlas snapshot on a canvas.
pub fn draw_glyph_atlas_entry(
  canvas : @graphics.Canvas,
  atlas_mask : @text.CoverageMask,
  entry : @text.GlyphAtlasEntry,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> Unit {
  canvas.draw_mask_rect(
    x,
    y,
    atlas_mask.get_width(),
    atlas_mask.get_height(),
    atlas_mask.get_pixels(),
    @graphics.PixelRect::new(
      x=entry.get_x(),
      y=entry.get_y(),
      width=entry.get_width(),
      height=entry.get_height(),
    ),
    paint,
  )
}

///|
fn make_glyph_atlas_mask_placement(
  glyph : @text.SimpleGlyph,
  scale : Double,
) -> GlyphAtlasMaskPlacement? {
  guard scale > 0.0 && glyph.contours.length() > 0 else { return None }
  let left = floor_to_int(glyph.xmin.to_double() * scale)
  let right = ceil_to_int(glyph.xmax.to_double() * scale)
  let top = floor_to_int(0.0 - glyph.ymax.to_double() * scale)
  let bottom = ceil_to_int(0.0 - glyph.ymin.to_double() * scale)
  guard right > left && bottom > top else { return None }
  Some({
    width: right - left,
    height: bottom - top,
    origin_x: (0 - left).to_double(),
    origin_y: (0 - top).to_double(),
    draw_offset_x: left,
    draw_offset_y: top,
  })
}

///|
fn glyph_atlas_cache_key(
  prefix : String,
  glyph_id : Int,
  font_size : Double,
) -> String {
  prefix + ":glyph:" + glyph_id.to_string() + ":size:" + font_size.to_string()
}

///|
fn floor_to_int(value : Double) -> Int {
  let truncated = value.to_int()
  if truncated.to_double() > value {
    truncated - 1
  } else {
    truncated
  }
}

///|
fn ceil_to_int(value : Double) -> Int {
  let truncated = value.to_int()
  if truncated.to_double() < value {
    truncated + 1
  } else {
    truncated
  }
}
