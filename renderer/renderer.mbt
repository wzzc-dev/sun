///|
/// Renderer core that composes vector drawing, text masks, and pixmap output.
pub struct Renderer {
  canvas : @graphics.Canvas
} derive(Debug)

///|
/// Caller-owned text rendering resources shared across renderer text draws.
pub struct RendererTextResources {
  text_cache : @text.TextMaskCache
  glyph_cache : @text.GlyphMaskCache
  atlas : @text.GlyphMaskAtlas
} derive(Debug)

///|
/// Caller-owned renderer resources shared across GUI text and image draws.
pub struct RendererResources {
  font_cache : @text.FontFaceCache
  text : RendererTextResources
  image_cache : @graphics.PixmapCache
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
/// Result of parsing font bytes through renderer resources and drawing text.
pub struct CachedFontTextDrawResult {
  did_parse_font : Bool
  text_result : TextMaskDrawResult
} derive(Debug)

///|
/// Result of parsing font bytes through renderer resources and drawing atlas
/// text.
pub struct CachedFontAtlasDrawResult {
  did_parse_font : Bool
  atlas_result : TextAtlasDrawResult
} derive(Debug)

///|
/// Result of drawing through a caller-owned pixmap cache.
pub struct CachedPixmapDrawResult {
  did_insert_pixmap : Bool
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
/// Create text resources with unbounded text/glyph caches and a glyph atlas.
pub fn RendererTextResources::new(
  atlas_width : Int,
  atlas_height : Int,
) -> RendererTextResources {
  {
    text_cache: @text.TextMaskCache::new(),
    glyph_cache: @text.GlyphMaskCache::new(),
    atlas: @text.GlyphMaskAtlas::new(atlas_width, atlas_height),
  }
}

///|
/// Create text resources with bounded text/glyph caches and a glyph atlas.
pub fn RendererTextResources::with_capacities(
  atlas_width : Int,
  atlas_height : Int,
  text_mask_capacity : Int,
  glyph_mask_capacity : Int,
) -> RendererTextResources {
  {
    text_cache: @text.TextMaskCache::with_capacity(text_mask_capacity),
    glyph_cache: @text.GlyphMaskCache::with_capacity(glyph_mask_capacity),
    atlas: @text.GlyphMaskAtlas::new(atlas_width, atlas_height),
  }
}

///|
/// Create renderer resources with unbounded font, text, and image caches.
pub fn RendererResources::new(
  atlas_width : Int,
  atlas_height : Int,
) -> RendererResources {
  {
    font_cache: @text.FontFaceCache::new(),
    text: RendererTextResources::new(atlas_width, atlas_height),
    image_cache: @graphics.PixmapCache::new(),
  }
}

///|
/// Create renderer resources with bounded text and image caches.
pub fn RendererResources::with_capacities(
  atlas_width : Int,
  atlas_height : Int,
  text_mask_capacity : Int,
  glyph_mask_capacity : Int,
  image_capacity : Int,
) -> RendererResources {
  {
    font_cache: @text.FontFaceCache::new(),
    text: RendererTextResources::with_capacities(
      atlas_width, atlas_height, text_mask_capacity, glyph_mask_capacity,
    ),
    image_cache: @graphics.PixmapCache::with_capacity(image_capacity),
  }
}

///|
/// Create renderer resources with bounded font, text, and image caches.
pub fn RendererResources::with_font_capacity(
  atlas_width : Int,
  atlas_height : Int,
  font_face_capacity : Int,
  text_mask_capacity : Int,
  glyph_mask_capacity : Int,
  image_capacity : Int,
) -> RendererResources {
  {
    font_cache: @text.FontFaceCache::with_capacity(font_face_capacity),
    text: RendererTextResources::with_capacities(
      atlas_width, atlas_height, text_mask_capacity, glyph_mask_capacity,
    ),
    image_cache: @graphics.PixmapCache::with_capacity(image_capacity),
  }
}

///|
/// Get the reusable rendered text-mask cache.
pub fn RendererTextResources::get_text_mask_cache(
  self : RendererTextResources,
) -> @text.TextMaskCache {
  self.text_cache
}

///|
/// Get the reusable glyph mask cache.
pub fn RendererTextResources::get_glyph_mask_cache(
  self : RendererTextResources,
) -> @text.GlyphMaskCache {
  self.glyph_cache
}

///|
/// Get the reusable glyph mask atlas.
pub fn RendererTextResources::get_glyph_mask_atlas(
  self : RendererTextResources,
) -> @text.GlyphMaskAtlas {
  self.atlas
}

///|
/// Get the reusable checked font-face cache.
pub fn RendererResources::get_font_face_cache(
  self : RendererResources,
) -> @text.FontFaceCache {
  self.font_cache
}

///|
/// Get the reusable text rendering resources.
pub fn RendererResources::get_text_resources(
  self : RendererResources,
) -> RendererTextResources {
  self.text
}

///|
/// Get the reusable rendered text-mask cache.
pub fn RendererResources::get_text_mask_cache(
  self : RendererResources,
) -> @text.TextMaskCache {
  self.text.get_text_mask_cache()
}

///|
/// Get the reusable glyph mask cache.
pub fn RendererResources::get_glyph_mask_cache(
  self : RendererResources,
) -> @text.GlyphMaskCache {
  self.text.get_glyph_mask_cache()
}

///|
/// Get the reusable glyph mask atlas.
pub fn RendererResources::get_glyph_mask_atlas(
  self : RendererResources,
) -> @text.GlyphMaskAtlas {
  self.text.get_glyph_mask_atlas()
}

///|
/// Get the reusable image pixmap cache.
pub fn RendererResources::get_image_cache(
  self : RendererResources,
) -> @graphics.PixmapCache {
  self.image_cache
}

///|
/// Drop all cached text masks, glyph masks, and atlas entries.
pub fn RendererTextResources::clear(self : RendererTextResources) -> Unit {
  self.text_cache.clear()
  self.glyph_cache.clear()
  self.atlas.clear()
}

///|
/// Drop all cached font faces, text masks, glyph masks, atlas entries, and image
/// pixmaps.
pub fn RendererResources::clear(self : RendererResources) -> Unit {
  self.font_cache.clear()
  self.text.clear()
  self.image_cache.clear()
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
/// Return whether this draw parsed font bytes instead of hitting cache.
pub fn CachedFontTextDrawResult::did_parse_font(
  self : CachedFontTextDrawResult,
) -> Bool {
  self.did_parse_font
}

///|
/// Return whether this draw reused a checked font face from cache.
pub fn CachedFontTextDrawResult::did_hit_font_cache(
  self : CachedFontTextDrawResult,
) -> Bool {
  !self.did_parse_font
}

///|
/// Return whether this draw rendered a new text mask instead of hitting cache.
pub fn CachedFontTextDrawResult::did_render_mask(
  self : CachedFontTextDrawResult,
) -> Bool {
  self.text_result.did_render_mask()
}

///|
/// Return whether this draw reused a rendered text mask from cache.
pub fn CachedFontTextDrawResult::did_hit_text_cache(
  self : CachedFontTextDrawResult,
) -> Bool {
  self.text_result.did_hit_cache()
}

///|
/// Return the underlying rendered text-mask draw result.
pub fn CachedFontTextDrawResult::get_text_result(
  self : CachedFontTextDrawResult,
) -> TextMaskDrawResult {
  self.text_result
}

///|
/// Return whether this draw parsed font bytes instead of hitting cache.
pub fn CachedFontAtlasDrawResult::did_parse_font(
  self : CachedFontAtlasDrawResult,
) -> Bool {
  self.did_parse_font
}

///|
/// Return whether this draw reused a checked font face from cache.
pub fn CachedFontAtlasDrawResult::did_hit_font_cache(
  self : CachedFontAtlasDrawResult,
) -> Bool {
  !self.did_parse_font
}

///|
/// Return the underlying glyph-atlas draw result.
pub fn CachedFontAtlasDrawResult::get_atlas_result(
  self : CachedFontAtlasDrawResult,
) -> TextAtlasDrawResult {
  self.atlas_result
}

///|
/// Return the number of layout glyphs visited by the atlas draw.
pub fn CachedFontAtlasDrawResult::get_glyph_count(
  self : CachedFontAtlasDrawResult,
) -> Int {
  self.atlas_result.get_glyph_count()
}

///|
/// Return the number of glyphs composited from the atlas.
pub fn CachedFontAtlasDrawResult::get_drawn_glyph_count(
  self : CachedFontAtlasDrawResult,
) -> Int {
  self.atlas_result.get_drawn_glyph_count()
}

///|
/// Return the number of layout glyphs that could not be drawn through the atlas.
pub fn CachedFontAtlasDrawResult::get_skipped_glyph_count(
  self : CachedFontAtlasDrawResult,
) -> Int {
  self.atlas_result.get_skipped_glyph_count()
}

///|
/// Return the number of drawable glyphs reused from the glyph mask cache.
pub fn CachedFontAtlasDrawResult::get_cache_hit_count(
  self : CachedFontAtlasDrawResult,
) -> Int {
  self.atlas_result.get_cache_hit_count()
}

///|
/// Return the number of glyph masks rasterized on cache miss.
pub fn CachedFontAtlasDrawResult::get_rasterized_glyph_count(
  self : CachedFontAtlasDrawResult,
) -> Int {
  self.atlas_result.get_rasterized_glyph_count()
}

///|
/// Return the number of glyph placements reused from the atlas.
pub fn CachedFontAtlasDrawResult::get_atlas_hit_count(
  self : CachedFontAtlasDrawResult,
) -> Int {
  self.atlas_result.get_atlas_hit_count()
}

///|
/// Return the number of glyph placements newly inserted into the atlas.
pub fn CachedFontAtlasDrawResult::get_atlas_inserted_count(
  self : CachedFontAtlasDrawResult,
) -> Int {
  self.atlas_result.get_atlas_inserted_count()
}

///|
/// Return whether the atlas was cleared while drawing this text.
pub fn CachedFontAtlasDrawResult::did_clear_atlas(
  self : CachedFontAtlasDrawResult,
) -> Bool {
  self.atlas_result.did_clear_atlas()
}

///|
/// Return whether this draw inserted a pixmap into the image cache.
pub fn CachedPixmapDrawResult::did_insert_pixmap(
  self : CachedPixmapDrawResult,
) -> Bool {
  self.did_insert_pixmap
}

///|
/// Return whether this draw reused a pixmap from the image cache.
pub fn CachedPixmapDrawResult::did_hit_cache(
  self : CachedPixmapDrawResult,
) -> Bool {
  !self.did_insert_pixmap
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
/// Draw text through renderer-owned text resources and the rendered mask cache.
pub fn Renderer::draw_text_face_cached_with_resources(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererTextResources,
  text_key : String,
  paint : @graphics.Paint,
) -> TextMaskDrawResult {
  self.draw_text_face_cached(
    face,
    text,
    x,
    y,
    config,
    resources.get_text_mask_cache(),
    text_key,
    paint,
  )
}

///|
/// Draw text through renderer-owned resources and the rendered mask cache.
pub fn Renderer::draw_text_face_cached_with_renderer_resources(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  text_key : String,
  paint : @graphics.Paint,
) -> TextMaskDrawResult {
  self.draw_text_face_cached_with_resources(
    face,
    text,
    x,
    y,
    config,
    resources.get_text_resources(),
    text_key,
    paint,
  )
}

///|
/// Parse font bytes through renderer resources, then draw through the rendered
/// text-mask cache.
pub fn Renderer::draw_font_bytes_cached_with_renderer_resources(
  self : Renderer,
  font_data : Bytes,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  font_key : String,
  text_key : String,
  paint : @graphics.Paint,
) -> Result[CachedFontTextDrawResult, @text.FontParseError] {
  match
    resources.get_font_face_cache().get_or_parse_result(font_key, font_data) {
    Ok(parse_result) => {
      let text_result = self.draw_text_face_cached_with_renderer_resources(
        parse_result.get_face(),
        text,
        x,
        y,
        config,
        resources,
        text_key,
        paint,
      )
      Ok({ did_parse_font: parse_result.did_parse(), text_result })
    }
    Err(error) => Err(error)
  }
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
/// Draw text through renderer-owned text resources and the glyph atlas path.
pub fn Renderer::draw_text_face_atlas_with_resources(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererTextResources,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextAtlasDrawResult {
  self.draw_text_face_atlas(
    face,
    text,
    x,
    y,
    config,
    resources.get_glyph_mask_cache(),
    resources.get_glyph_mask_atlas(),
    glyph_key_prefix,
    paint,
  )
}

///|
/// Draw text through renderer-owned resources and the glyph atlas path.
pub fn Renderer::draw_text_face_atlas_with_renderer_resources(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextAtlasDrawResult {
  self.draw_text_face_atlas_with_resources(
    face,
    text,
    x,
    y,
    config,
    resources.get_text_resources(),
    glyph_key_prefix,
    paint,
  )
}

///|
/// Parse font bytes through renderer resources, then draw through glyph cache
/// and atlas resources.
pub fn Renderer::draw_font_bytes_atlas_with_renderer_resources(
  self : Renderer,
  font_data : Bytes,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  font_key : String,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> Result[CachedFontAtlasDrawResult, @text.FontParseError] {
  match
    resources.get_font_face_cache().get_or_parse_result(font_key, font_data) {
    Ok(parse_result) => {
      let atlas_result = self.draw_text_face_atlas_with_renderer_resources(
        parse_result.get_face(),
        text,
        x,
        y,
        config,
        resources,
        glyph_key_prefix,
        paint,
      )
      Ok({ did_parse_font: parse_result.did_parse(), atlas_result })
    }
    Err(error) => Err(error)
  }
}

///|
/// Draw an image through a caller-owned pixmap cache.
pub fn Renderer::draw_pixmap_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_pixmap(result.get_pixmap(), x, y, paint)
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw an image through renderer-owned resources and the pixmap cache.
pub fn Renderer::draw_pixmap_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
) -> CachedPixmapDrawResult {
  self.draw_pixmap_cached(
    pixmap,
    x,
    y,
    resources.get_image_cache(),
    image_key,
    paint,
  )
}

///|
/// Draw a scaled image through a caller-owned pixmap cache and quality policy.
pub fn Renderer::draw_quality_pixmap_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_quality_pixmap(
    result.get_pixmap(),
    x,
    y,
    width,
    height,
    paint,
    quality,
  )
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw a scaled image through renderer-owned resources and quality policy.
pub fn Renderer::draw_quality_pixmap_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  self.draw_quality_pixmap_cached(
    pixmap,
    x,
    y,
    width,
    height,
    resources.get_image_cache(),
    image_key,
    paint,
    quality,
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
