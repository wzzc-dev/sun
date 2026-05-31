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
/// Snapshot of renderer text resource cache and atlas state.
pub struct RendererTextResourcesSnapshot {
  text_mask_count : Int
  text_mask_capacity : Int
  text_mask_is_bounded : Bool
  glyph_mask_count : Int
  glyph_mask_capacity : Int
  glyph_mask_is_bounded : Bool
  atlas_entry_count : Int
  atlas_width : Int
  atlas_height : Int
  atlas_capacity : Int
  atlas_used_pixel_count : Int
  atlas_free_pixel_count : Int
  atlas_occupancy_ratio : Double
} derive(Debug)

///|
/// Snapshot of renderer-wide resource cache state.
pub struct RendererResourcesSnapshot {
  font_face_count : Int
  font_face_capacity : Int
  font_face_is_bounded : Bool
  text_snapshot : RendererTextResourcesSnapshot
  image_count : Int
  image_capacity : Int
  image_is_bounded : Bool
} derive(Debug)

///|
/// One keyed font-byte source in an ordered fallback stack.
pub struct FontBytesFallbackSource {
  font_key : String
  font_data : Bytes
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
/// Result of drawing one fallback line through glyph-mask cache and atlas
/// resources.
pub struct TextFallbackAtlasDrawResult {
  plan : @text.FontFallbackPlan
  drawn_span_count : Int
  skipped_span_count : Int
  advance_width : Double
  atlas_result : TextAtlasDrawResult
} derive(Debug)

///|
/// Result of drawing text through a caller-owned rendered text-mask cache.
pub struct TextMaskDrawResult {
  did_render_mask : Bool
} derive(Debug)

///|
/// Result of drawing a single line through an ordered font fallback stack.
pub struct TextFallbackDrawResult {
  plan : @text.FontFallbackPlan
  drawn_span_count : Int
  skipped_span_count : Int
  rendered_mask_count : Int
  cache_hit_count : Int
  advance_width : Double
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
/// Result of parsing a font-byte fallback stack and drawing cached fallback
/// text.
pub struct CachedFontFallbackDrawResult {
  parsed_font_count : Int
  font_cache_hit_count : Int
  fallback_result : TextFallbackDrawResult
} derive(Debug)

///|
/// Result of parsing a font-byte fallback stack and drawing atlas fallback
/// text.
pub struct CachedFontFallbackAtlasDrawResult {
  parsed_font_count : Int
  font_cache_hit_count : Int
  fallback_result : TextFallbackAtlasDrawResult
} derive(Debug)

///|
/// Result of drawing through a caller-owned pixmap cache.
pub struct CachedPixmapDrawResult {
  did_insert_pixmap : Bool
} derive(Debug)

///|
/// Result of decoding BMP bytes through a pixmap cache and drawing them.
pub struct CachedBmpPixmapDrawResult {
  did_decode_pixmap : Bool
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
/// Return the number of cached text masks in this snapshot.
pub fn RendererTextResourcesSnapshot::get_text_mask_count(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.text_mask_count
}

///|
/// Return the text-mask cache capacity, or 0 for unbounded caches.
pub fn RendererTextResourcesSnapshot::get_text_mask_capacity(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.text_mask_capacity
}

///|
/// Return whether the text-mask cache has an entry limit.
pub fn RendererTextResourcesSnapshot::is_text_mask_capacity_bounded(
  self : RendererTextResourcesSnapshot,
) -> Bool {
  self.text_mask_is_bounded
}

///|
/// Return the number of cached glyph masks in this snapshot.
pub fn RendererTextResourcesSnapshot::get_glyph_mask_count(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.glyph_mask_count
}

///|
/// Return the glyph-mask cache capacity, or 0 for unbounded caches.
pub fn RendererTextResourcesSnapshot::get_glyph_mask_capacity(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.glyph_mask_capacity
}

///|
/// Return whether the glyph-mask cache has an entry limit.
pub fn RendererTextResourcesSnapshot::is_glyph_mask_capacity_bounded(
  self : RendererTextResourcesSnapshot,
) -> Bool {
  self.glyph_mask_is_bounded
}

///|
/// Return the number of placed glyph atlas entries.
pub fn RendererTextResourcesSnapshot::get_atlas_entry_count(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.atlas_entry_count
}

///|
/// Return the glyph atlas width.
pub fn RendererTextResourcesSnapshot::get_atlas_width(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.atlas_width
}

///|
/// Return the glyph atlas height.
pub fn RendererTextResourcesSnapshot::get_atlas_height(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.atlas_height
}

///|
/// Return the total glyph atlas pixel capacity.
pub fn RendererTextResourcesSnapshot::get_atlas_capacity(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.atlas_capacity
}

///|
/// Return the number of glyph atlas pixels currently occupied.
pub fn RendererTextResourcesSnapshot::get_atlas_used_pixel_count(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.atlas_used_pixel_count
}

///|
/// Return the number of glyph atlas pixels still free.
pub fn RendererTextResourcesSnapshot::get_atlas_free_pixel_count(
  self : RendererTextResourcesSnapshot,
) -> Int {
  self.atlas_free_pixel_count
}

///|
/// Return used atlas pixels divided by atlas capacity.
pub fn RendererTextResourcesSnapshot::get_atlas_occupancy_ratio(
  self : RendererTextResourcesSnapshot,
) -> Double {
  self.atlas_occupancy_ratio
}

///|
/// Return the number of cached font faces in this snapshot.
pub fn RendererResourcesSnapshot::get_font_face_count(
  self : RendererResourcesSnapshot,
) -> Int {
  self.font_face_count
}

///|
/// Return the font-face cache capacity, or 0 for unbounded caches.
pub fn RendererResourcesSnapshot::get_font_face_capacity(
  self : RendererResourcesSnapshot,
) -> Int {
  self.font_face_capacity
}

///|
/// Return whether the font-face cache has an entry limit.
pub fn RendererResourcesSnapshot::is_font_face_capacity_bounded(
  self : RendererResourcesSnapshot,
) -> Bool {
  self.font_face_is_bounded
}

///|
/// Return the nested text-resource snapshot.
pub fn RendererResourcesSnapshot::get_text_snapshot(
  self : RendererResourcesSnapshot,
) -> RendererTextResourcesSnapshot {
  self.text_snapshot
}

///|
/// Return the number of cached image pixmaps in this snapshot.
pub fn RendererResourcesSnapshot::get_image_count(
  self : RendererResourcesSnapshot,
) -> Int {
  self.image_count
}

///|
/// Return the image cache capacity, or 0 for unbounded caches.
pub fn RendererResourcesSnapshot::get_image_capacity(
  self : RendererResourcesSnapshot,
) -> Int {
  self.image_capacity
}

///|
/// Return whether the image cache has an entry limit.
pub fn RendererResourcesSnapshot::is_image_capacity_bounded(
  self : RendererResourcesSnapshot,
) -> Bool {
  self.image_is_bounded
}

///|
/// Return a compact snapshot of text cache and glyph atlas telemetry.
pub fn RendererTextResources::snapshot(
  self : RendererTextResources,
) -> RendererTextResourcesSnapshot {
  {
    text_mask_count: self.text_cache.len(),
    text_mask_capacity: self.text_cache.capacity(),
    text_mask_is_bounded: self.text_cache.is_capacity_bounded(),
    glyph_mask_count: self.glyph_cache.len(),
    glyph_mask_capacity: self.glyph_cache.capacity(),
    glyph_mask_is_bounded: self.glyph_cache.is_capacity_bounded(),
    atlas_entry_count: self.atlas.len(),
    atlas_width: self.atlas.get_width(),
    atlas_height: self.atlas.get_height(),
    atlas_capacity: self.atlas.get_capacity(),
    atlas_used_pixel_count: self.atlas.get_used_pixel_count(),
    atlas_free_pixel_count: self.atlas.get_free_pixel_count(),
    atlas_occupancy_ratio: self.atlas.get_occupancy_ratio(),
  }
}

///|
/// Return a compact snapshot of renderer-wide resource telemetry.
pub fn RendererResources::snapshot(
  self : RendererResources,
) -> RendererResourcesSnapshot {
  {
    font_face_count: self.font_cache.len(),
    font_face_capacity: self.font_cache.capacity(),
    font_face_is_bounded: self.font_cache.is_capacity_bounded(),
    text_snapshot: self.text.snapshot(),
    image_count: self.image_cache.len(),
    image_capacity: self.image_cache.capacity(),
    image_is_bounded: self.image_cache.is_capacity_bounded(),
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
/// Return whether these text resources have a rendered text mask for this key.
pub fn RendererTextResources::contains_text_mask(
  self : RendererTextResources,
  key : String,
) -> Bool {
  self.text_cache.contains(key)
}

///|
/// Return whether these text resources have a rendered glyph mask for this key.
pub fn RendererTextResources::contains_glyph_mask(
  self : RendererTextResources,
  key : String,
) -> Bool {
  self.glyph_cache.contains(key)
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
/// Return a cached image pixmap or decode BMP bytes into the image cache.
pub fn RendererResources::get_or_decode_bmp_image(
  self : RendererResources,
  image_key : String,
  image_data : Bytes,
) -> Result[@graphics.Pixmap, @graphics.PixmapDecodeError] {
  self.image_cache.get_or_decode_bmp(image_key, image_data)
}

///|
/// Return a cached image pixmap or decode BMP bytes, reporting cache hits.
pub fn RendererResources::get_or_decode_bmp_image_result(
  self : RendererResources,
  image_key : String,
  image_data : Bytes,
) -> Result[@graphics.PixmapCacheDecodeResult, @graphics.PixmapDecodeError] {
  self.image_cache.get_or_decode_bmp_result(image_key, image_data)
}

///|
/// Return whether these resources have a parsed font face for this key.
pub fn RendererResources::contains_font_face(
  self : RendererResources,
  key : String,
) -> Bool {
  self.font_cache.contains(key)
}

///|
/// Return whether these resources have a rendered text mask for this key.
pub fn RendererResources::contains_text_mask(
  self : RendererResources,
  key : String,
) -> Bool {
  self.text.contains_text_mask(key)
}

///|
/// Return whether these resources have a rendered glyph mask for this key.
pub fn RendererResources::contains_glyph_mask(
  self : RendererResources,
  key : String,
) -> Bool {
  self.text.contains_glyph_mask(key)
}

///|
/// Return whether these resources have an image pixmap for this key.
pub fn RendererResources::contains_image(
  self : RendererResources,
  key : String,
) -> Bool {
  self.image_cache.contains(key)
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
/// Create one keyed font-byte source for fallback rendering.
pub fn FontBytesFallbackSource::new(
  font_key : String,
  font_data : Bytes,
) -> FontBytesFallbackSource {
  { font_key, font_data }
}

///|
/// Return the stable font-resource key for this fallback source.
pub fn FontBytesFallbackSource::get_font_key(
  self : FontBytesFallbackSource,
) -> String {
  self.font_key
}

///|
/// Return the font bytes for this fallback source.
pub fn FontBytesFallbackSource::get_font_data(
  self : FontBytesFallbackSource,
) -> Bytes {
  self.font_data
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
/// Get the fallback plan used by this draw.
pub fn TextFallbackDrawResult::get_plan(
  self : TextFallbackDrawResult,
) -> @text.FontFallbackPlan {
  self.plan
}

///|
/// Return the number of fallback spans visited by this draw.
pub fn TextFallbackDrawResult::get_span_count(
  self : TextFallbackDrawResult,
) -> Int {
  self.plan.span_count()
}

///|
/// Return the number of fallback spans drawn with a covering face.
pub fn TextFallbackDrawResult::get_drawn_span_count(
  self : TextFallbackDrawResult,
) -> Int {
  self.drawn_span_count
}

///|
/// Return the number of missing-glyph spans skipped by this draw.
pub fn TextFallbackDrawResult::get_skipped_span_count(
  self : TextFallbackDrawResult,
) -> Int {
  self.skipped_span_count
}

///|
/// Return the number of missing-glyph spans skipped by this draw.
pub fn TextFallbackDrawResult::get_missing_span_count(
  self : TextFallbackDrawResult,
) -> Int {
  self.skipped_span_count
}

///|
/// Return the number of text scalars not covered by any fallback face.
pub fn TextFallbackDrawResult::get_missing_char_count(
  self : TextFallbackDrawResult,
) -> Int {
  self.plan.get_missing_char_count()
}

///|
/// Return the number of fallback spans that rendered a fresh mask.
pub fn TextFallbackDrawResult::get_rendered_mask_count(
  self : TextFallbackDrawResult,
) -> Int {
  self.rendered_mask_count
}

///|
/// Return the number of fallback spans reused from a text-mask cache.
pub fn TextFallbackDrawResult::get_cache_hit_count(
  self : TextFallbackDrawResult,
) -> Int {
  self.cache_hit_count
}

///|
/// Return whether this draw skipped at least one missing glyph span.
pub fn TextFallbackDrawResult::has_missing_glyphs(
  self : TextFallbackDrawResult,
) -> Bool {
  self.plan.has_missing_glyphs()
}

///|
/// Return the horizontal advance consumed by the fallback line draw.
pub fn TextFallbackDrawResult::get_advance_width(
  self : TextFallbackDrawResult,
) -> Double {
  self.advance_width
}

///|
/// Get the fallback plan used by this atlas draw.
pub fn TextFallbackAtlasDrawResult::get_plan(
  self : TextFallbackAtlasDrawResult,
) -> @text.FontFallbackPlan {
  self.plan
}

///|
/// Return the number of fallback spans visited by this atlas draw.
pub fn TextFallbackAtlasDrawResult::get_span_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.plan.span_count()
}

///|
/// Return the number of fallback spans drawn with a covering face.
pub fn TextFallbackAtlasDrawResult::get_drawn_span_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.drawn_span_count
}

///|
/// Return the number of missing-glyph spans skipped by this atlas draw.
pub fn TextFallbackAtlasDrawResult::get_skipped_span_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.skipped_span_count
}

///|
/// Return the number of missing-glyph spans skipped by this atlas draw.
pub fn TextFallbackAtlasDrawResult::get_missing_span_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.skipped_span_count
}

///|
/// Return the number of text scalars not covered by any fallback face.
pub fn TextFallbackAtlasDrawResult::get_missing_char_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.plan.get_missing_char_count()
}

///|
/// Return whether this atlas draw skipped at least one missing glyph span.
pub fn TextFallbackAtlasDrawResult::has_missing_glyphs(
  self : TextFallbackAtlasDrawResult,
) -> Bool {
  self.plan.has_missing_glyphs()
}

///|
/// Return the horizontal advance consumed by the fallback atlas draw.
pub fn TextFallbackAtlasDrawResult::get_advance_width(
  self : TextFallbackAtlasDrawResult,
) -> Double {
  self.advance_width
}

///|
/// Return the underlying glyph-atlas draw result.
pub fn TextFallbackAtlasDrawResult::get_atlas_result(
  self : TextFallbackAtlasDrawResult,
) -> TextAtlasDrawResult {
  self.atlas_result
}

///|
/// Return the number of layout glyphs visited by covered fallback spans.
pub fn TextFallbackAtlasDrawResult::get_glyph_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.atlas_result.get_glyph_count()
}

///|
/// Return the number of glyphs composited from the atlas.
pub fn TextFallbackAtlasDrawResult::get_drawn_glyph_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.atlas_result.get_drawn_glyph_count()
}

///|
/// Return the number of layout glyphs that could not be drawn through the atlas.
pub fn TextFallbackAtlasDrawResult::get_skipped_glyph_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.atlas_result.get_skipped_glyph_count()
}

///|
/// Return the number of drawable glyphs reused from the glyph mask cache.
pub fn TextFallbackAtlasDrawResult::get_cache_hit_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.atlas_result.get_cache_hit_count()
}

///|
/// Return the number of glyph masks rasterized on cache miss.
pub fn TextFallbackAtlasDrawResult::get_rasterized_glyph_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.atlas_result.get_rasterized_glyph_count()
}

///|
/// Return the number of glyph placements reused from the atlas.
pub fn TextFallbackAtlasDrawResult::get_atlas_hit_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.atlas_result.get_atlas_hit_count()
}

///|
/// Return the number of glyph placements newly inserted into the atlas.
pub fn TextFallbackAtlasDrawResult::get_atlas_inserted_count(
  self : TextFallbackAtlasDrawResult,
) -> Int {
  self.atlas_result.get_atlas_inserted_count()
}

///|
/// Return whether the atlas was cleared while drawing this fallback line.
pub fn TextFallbackAtlasDrawResult::did_clear_atlas(
  self : TextFallbackAtlasDrawResult,
) -> Bool {
  self.atlas_result.did_clear_atlas()
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
/// Return the number of fallback font sources parsed on this draw.
pub fn CachedFontFallbackDrawResult::get_parsed_font_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.parsed_font_count
}

///|
/// Return the number of fallback font sources reused from the font cache.
pub fn CachedFontFallbackDrawResult::get_font_cache_hit_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.font_cache_hit_count
}

///|
/// Return the underlying fallback line draw result.
pub fn CachedFontFallbackDrawResult::get_fallback_result(
  self : CachedFontFallbackDrawResult,
) -> TextFallbackDrawResult {
  self.fallback_result
}

///|
/// Return the number of fallback spans visited by this draw.
pub fn CachedFontFallbackDrawResult::get_span_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.fallback_result.get_span_count()
}

///|
/// Return the number of fallback spans drawn with a covering face.
pub fn CachedFontFallbackDrawResult::get_drawn_span_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.fallback_result.get_drawn_span_count()
}

///|
/// Return the number of missing-glyph spans skipped by this draw.
pub fn CachedFontFallbackDrawResult::get_skipped_span_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.fallback_result.get_skipped_span_count()
}

///|
/// Return the number of missing-glyph spans skipped by this draw.
pub fn CachedFontFallbackDrawResult::get_missing_span_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.fallback_result.get_missing_span_count()
}

///|
/// Return the number of text scalars not covered by any fallback face.
pub fn CachedFontFallbackDrawResult::get_missing_char_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.fallback_result.get_missing_char_count()
}

///|
/// Return whether this draw skipped at least one missing glyph span.
pub fn CachedFontFallbackDrawResult::has_missing_glyphs(
  self : CachedFontFallbackDrawResult,
) -> Bool {
  self.fallback_result.has_missing_glyphs()
}

///|
/// Return the horizontal advance consumed by the fallback line draw.
pub fn CachedFontFallbackDrawResult::get_advance_width(
  self : CachedFontFallbackDrawResult,
) -> Double {
  self.fallback_result.get_advance_width()
}

///|
/// Return the number of fallback spans that rendered a fresh mask.
pub fn CachedFontFallbackDrawResult::get_rendered_mask_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.fallback_result.get_rendered_mask_count()
}

///|
/// Return the number of fallback spans reused from the text-mask cache.
pub fn CachedFontFallbackDrawResult::get_text_cache_hit_count(
  self : CachedFontFallbackDrawResult,
) -> Int {
  self.fallback_result.get_cache_hit_count()
}

///|
/// Return the number of fallback font sources parsed on this atlas draw.
pub fn CachedFontFallbackAtlasDrawResult::get_parsed_font_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.parsed_font_count
}

///|
/// Return the number of fallback font sources reused from the font cache.
pub fn CachedFontFallbackAtlasDrawResult::get_font_cache_hit_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.font_cache_hit_count
}

///|
/// Return the underlying fallback atlas draw result.
pub fn CachedFontFallbackAtlasDrawResult::get_fallback_result(
  self : CachedFontFallbackAtlasDrawResult,
) -> TextFallbackAtlasDrawResult {
  self.fallback_result
}

///|
/// Return the number of fallback spans visited by this atlas draw.
pub fn CachedFontFallbackAtlasDrawResult::get_span_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_span_count()
}

///|
/// Return the number of fallback spans drawn with a covering face.
pub fn CachedFontFallbackAtlasDrawResult::get_drawn_span_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_drawn_span_count()
}

///|
/// Return the number of missing-glyph spans skipped by this atlas draw.
pub fn CachedFontFallbackAtlasDrawResult::get_skipped_span_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_skipped_span_count()
}

///|
/// Return the number of missing-glyph spans skipped by this atlas draw.
pub fn CachedFontFallbackAtlasDrawResult::get_missing_span_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_missing_span_count()
}

///|
/// Return the number of text scalars not covered by any fallback face.
pub fn CachedFontFallbackAtlasDrawResult::get_missing_char_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_missing_char_count()
}

///|
/// Return whether this atlas draw skipped at least one missing glyph span.
pub fn CachedFontFallbackAtlasDrawResult::has_missing_glyphs(
  self : CachedFontFallbackAtlasDrawResult,
) -> Bool {
  self.fallback_result.has_missing_glyphs()
}

///|
/// Return the horizontal advance consumed by the fallback atlas draw.
pub fn CachedFontFallbackAtlasDrawResult::get_advance_width(
  self : CachedFontFallbackAtlasDrawResult,
) -> Double {
  self.fallback_result.get_advance_width()
}

///|
/// Return the underlying glyph-atlas draw result.
pub fn CachedFontFallbackAtlasDrawResult::get_atlas_result(
  self : CachedFontFallbackAtlasDrawResult,
) -> TextAtlasDrawResult {
  self.fallback_result.get_atlas_result()
}

///|
/// Return the number of layout glyphs visited by covered fallback spans.
pub fn CachedFontFallbackAtlasDrawResult::get_glyph_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_glyph_count()
}

///|
/// Return the number of glyphs composited from the atlas.
pub fn CachedFontFallbackAtlasDrawResult::get_drawn_glyph_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_drawn_glyph_count()
}

///|
/// Return the number of layout glyphs that could not be drawn through the atlas.
pub fn CachedFontFallbackAtlasDrawResult::get_skipped_glyph_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_skipped_glyph_count()
}

///|
/// Return the number of drawable glyphs reused from the glyph mask cache.
pub fn CachedFontFallbackAtlasDrawResult::get_cache_hit_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_cache_hit_count()
}

///|
/// Return the number of glyph masks rasterized on cache miss.
pub fn CachedFontFallbackAtlasDrawResult::get_rasterized_glyph_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_rasterized_glyph_count()
}

///|
/// Return the number of glyph placements reused from the atlas.
pub fn CachedFontFallbackAtlasDrawResult::get_atlas_hit_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_atlas_hit_count()
}

///|
/// Return the number of glyph placements newly inserted into the atlas.
pub fn CachedFontFallbackAtlasDrawResult::get_atlas_inserted_count(
  self : CachedFontFallbackAtlasDrawResult,
) -> Int {
  self.fallback_result.get_atlas_inserted_count()
}

///|
/// Return whether the atlas was cleared while drawing this fallback line.
pub fn CachedFontFallbackAtlasDrawResult::did_clear_atlas(
  self : CachedFontFallbackAtlasDrawResult,
) -> Bool {
  self.fallback_result.did_clear_atlas()
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
/// Return whether this draw decoded BMP bytes into the image cache.
pub fn CachedBmpPixmapDrawResult::did_decode_pixmap(
  self : CachedBmpPixmapDrawResult,
) -> Bool {
  self.did_decode_pixmap
}

///|
/// Return whether this draw reused a cached decoded pixmap.
pub fn CachedBmpPixmapDrawResult::did_hit_cache(
  self : CachedBmpPixmapDrawResult,
) -> Bool {
  !self.did_decode_pixmap
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
/// Draw a single left-to-right text line through an ordered font fallback stack.
pub fn Renderer::draw_text_fallback_line(
  self : Renderer,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> TextFallbackDrawResult {
  let pixmap = self.canvas.get_pixmap()
  draw_text_fallback_line(
    self.canvas,
    faces,
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
/// Draw a single fallback line through a caller-owned rendered text-mask cache.
pub fn Renderer::draw_text_fallback_line_cached(
  self : Renderer,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  text_cache : @text.TextMaskCache,
  text_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackDrawResult {
  let pixmap = self.canvas.get_pixmap()
  draw_text_fallback_line_cached(
    self.canvas,
    faces,
    text,
    x,
    y,
    pixmap.get_width(),
    pixmap.get_height(),
    config,
    text_cache,
    text_key_prefix,
    paint,
  )
}

///|
/// Draw a cached fallback line through renderer-owned text resources.
pub fn Renderer::draw_text_fallback_line_cached_with_resources(
  self : Renderer,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererTextResources,
  text_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackDrawResult {
  self.draw_text_fallback_line_cached(
    faces,
    text,
    x,
    y,
    config,
    resources.get_text_mask_cache(),
    text_key_prefix,
    paint,
  )
}

///|
/// Draw a cached fallback line through renderer-owned resources.
pub fn Renderer::draw_text_fallback_line_cached_with_renderer_resources(
  self : Renderer,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  text_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackDrawResult {
  self.draw_text_fallback_line_cached_with_resources(
    faces,
    text,
    x,
    y,
    config,
    resources.get_text_resources(),
    text_key_prefix,
    paint,
  )
}

///|
/// Draw a single fallback line through caller-owned glyph mask cache and atlas
/// resources.
pub fn Renderer::draw_text_fallback_line_atlas(
  self : Renderer,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  glyph_cache : @text.GlyphMaskCache,
  atlas : @text.GlyphMaskAtlas,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackAtlasDrawResult {
  draw_text_fallback_line_atlas(
    self.canvas,
    faces,
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
/// Draw a fallback line through renderer-owned text resources and the glyph
/// atlas path.
pub fn Renderer::draw_text_fallback_line_atlas_with_resources(
  self : Renderer,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererTextResources,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackAtlasDrawResult {
  self.draw_text_fallback_line_atlas(
    faces,
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
/// Draw a fallback line through renderer-owned resources and the glyph atlas
/// path.
pub fn Renderer::draw_text_fallback_line_atlas_with_renderer_resources(
  self : Renderer,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackAtlasDrawResult {
  self.draw_text_fallback_line_atlas_with_resources(
    faces,
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
/// Parse an ordered font-byte stack through renderer resources, then draw a
/// cached fallback line through the shared text-mask cache.
pub fn Renderer::draw_font_bytes_fallback_line_cached_with_renderer_resources(
  self : Renderer,
  sources : Array[FontBytesFallbackSource],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  text_key_prefix : String,
  paint : @graphics.Paint,
) -> Result[CachedFontFallbackDrawResult, @text.FontParseError] {
  let faces : Array[@text.FontFace] = []
  let mut parsed_font_count = 0
  let mut font_cache_hit_count = 0
  for source in sources {
    match
      resources
      .get_font_face_cache()
      .get_or_parse_result(source.get_font_key(), source.get_font_data()) {
      Ok(parse_result) => {
        faces.push(parse_result.get_face())
        if parse_result.did_parse() {
          parsed_font_count += 1
        } else {
          font_cache_hit_count += 1
        }
      }
      Err(error) => return Err(error)
    }
  }
  let fallback_result = self.draw_text_fallback_line_cached_with_renderer_resources(
    faces, text, x, y, config, resources, text_key_prefix, paint,
  )
  Ok({ parsed_font_count, font_cache_hit_count, fallback_result })
}

///|
/// Parse an ordered font-byte stack through renderer resources, then draw a
/// fallback line through the shared glyph mask cache and atlas.
pub fn Renderer::draw_font_bytes_fallback_line_atlas_with_renderer_resources(
  self : Renderer,
  sources : Array[FontBytesFallbackSource],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  resources : RendererResources,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> Result[CachedFontFallbackAtlasDrawResult, @text.FontParseError] {
  let faces : Array[@text.FontFace] = []
  let mut parsed_font_count = 0
  let mut font_cache_hit_count = 0
  for source in sources {
    match
      resources
      .get_font_face_cache()
      .get_or_parse_result(source.get_font_key(), source.get_font_data()) {
      Ok(parse_result) => {
        faces.push(parse_result.get_face())
        if parse_result.did_parse() {
          parsed_font_count += 1
        } else {
          font_cache_hit_count += 1
        }
      }
      Err(error) => return Err(error)
    }
  }
  let fallback_result = self.draw_text_fallback_line_atlas_with_renderer_resources(
    faces, text, x, y, config, resources, glyph_key_prefix, paint,
  )
  Ok({ parsed_font_count, font_cache_hit_count, fallback_result })
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
/// Draw a source rectangle from an image through a caller-owned pixmap cache.
pub fn Renderer::draw_pixmap_rect_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_pixmap_rect(result.get_pixmap(), src_rect, x, y, paint)
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw a source rectangle from an image through renderer-owned resources.
pub fn Renderer::draw_pixmap_rect_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
) -> CachedPixmapDrawResult {
  self.draw_pixmap_rect_cached(
    pixmap,
    src_rect,
    x,
    y,
    resources.get_image_cache(),
    image_key,
    paint,
  )
}

///|
/// Draw a tiled source rectangle from an image through a caller-owned pixmap
/// cache.
pub fn Renderer::draw_tiled_pixmap_rect_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_tiled_pixmap_rect(
    result.get_pixmap(),
    src_rect,
    x,
    y,
    width,
    height,
    paint,
  )
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw a tiled source rectangle from an image through renderer-owned
/// resources.
pub fn Renderer::draw_tiled_pixmap_rect_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
) -> CachedPixmapDrawResult {
  self.draw_tiled_pixmap_rect_cached(
    pixmap,
    src_rect,
    x,
    y,
    width,
    height,
    resources.get_image_cache(),
    image_key,
    paint,
  )
}

///|
/// Draw an image through a pixmap cache using nine-patch scaling.
pub fn Renderer::draw_nine_patch_pixmap_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_nine_patch_pixmap(
    result.get_pixmap(),
    x,
    y,
    width,
    height,
    insets,
    paint,
    sampling,
  )
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw an image through renderer-owned resources using nine-patch scaling.
pub fn Renderer::draw_nine_patch_pixmap_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> CachedPixmapDrawResult {
  self.draw_nine_patch_pixmap_cached(
    pixmap,
    x,
    y,
    width,
    height,
    insets,
    resources.get_image_cache(),
    image_key,
    paint,
    sampling,
  )
}

///|
/// Decode BMP bytes through a caller-owned pixmap cache and draw the image.
pub fn Renderer::draw_bmp_bytes_cached(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_pixmap(result.get_pixmap(), x, y, paint)
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw the image.
pub fn Renderer::draw_bmp_bytes_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_bmp_bytes_cached(
    image_data,
    x,
    y,
    resources.get_image_cache(),
    image_key,
    paint,
  )
}

///|
/// Decode BMP bytes through a pixmap cache and draw a source rectangle.
pub fn Renderer::draw_bmp_bytes_rect_cached(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_pixmap_rect(result.get_pixmap(), src_rect, x, y, paint)
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a source rectangle.
pub fn Renderer::draw_bmp_bytes_rect_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_bmp_bytes_rect_cached(
    image_data,
    src_rect,
    x,
    y,
    resources.get_image_cache(),
    image_key,
    paint,
  )
}

///|
/// Decode BMP bytes through a pixmap cache and draw a tiled source rectangle.
pub fn Renderer::draw_tiled_bmp_bytes_rect_cached(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_tiled_pixmap_rect(
        result.get_pixmap(),
        src_rect,
        x,
        y,
        width,
        height,
        paint,
      )
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a tiled source
/// rectangle.
pub fn Renderer::draw_tiled_bmp_bytes_rect_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_tiled_bmp_bytes_rect_cached(
    image_data,
    src_rect,
    x,
    y,
    width,
    height,
    resources.get_image_cache(),
    image_key,
    paint,
  )
}

///|
/// Decode BMP bytes through a pixmap cache and draw with nine-patch scaling.
pub fn Renderer::draw_nine_patch_bmp_bytes_cached(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_nine_patch_pixmap(
        result.get_pixmap(),
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling,
      )
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw with nine-patch
/// scaling.
pub fn Renderer::draw_nine_patch_bmp_bytes_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_nine_patch_bmp_bytes_cached(
    image_data,
    x,
    y,
    width,
    height,
    insets,
    resources.get_image_cache(),
    image_key,
    paint,
    sampling,
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
/// Draw an image through a pixmap cache using nine-patch quality scaling.
pub fn Renderer::draw_quality_nine_patch_pixmap_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_quality_nine_patch_pixmap(
    result.get_pixmap(),
    x,
    y,
    width,
    height,
    insets,
    paint,
    quality,
  )
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw an image through renderer-owned resources using nine-patch quality
/// scaling.
pub fn Renderer::draw_quality_nine_patch_pixmap_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  self.draw_quality_nine_patch_pixmap_cached(
    pixmap,
    x,
    y,
    width,
    height,
    insets,
    resources.get_image_cache(),
    image_key,
    paint,
    quality,
  )
}

///|
/// Draw a scaled image source rectangle through a caller-owned pixmap cache.
pub fn Renderer::draw_quality_pixmap_rect_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
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
  self.canvas.draw_quality_pixmap_rect(
    result.get_pixmap(),
    src_rect,
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
/// Draw a scaled image source rectangle through renderer-owned resources.
pub fn Renderer::draw_quality_pixmap_rect_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  self.draw_quality_pixmap_rect_cached(
    pixmap,
    src_rect,
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
/// Decode BMP bytes through a pixmap cache and draw with nine-patch quality
/// scaling.
pub fn Renderer::draw_quality_nine_patch_bmp_bytes_cached(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_quality_nine_patch_pixmap(
        result.get_pixmap(),
        x,
        y,
        width,
        height,
        insets,
        paint,
        quality,
      )
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw with nine-patch
/// quality scaling.
pub fn Renderer::draw_quality_nine_patch_bmp_bytes_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_quality_nine_patch_bmp_bytes_cached(
    image_data,
    x,
    y,
    width,
    height,
    insets,
    resources.get_image_cache(),
    image_key,
    paint,
    quality,
  )
}

///|
/// Decode BMP bytes through a caller-owned pixmap cache and draw a scaled image.
pub fn Renderer::draw_quality_bmp_bytes_cached(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_quality_pixmap(
        result.get_pixmap(),
        x,
        y,
        width,
        height,
        paint,
        quality,
      )
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a scaled image.
pub fn Renderer::draw_quality_bmp_bytes_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_quality_bmp_bytes_cached(
    image_data,
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
/// Decode BMP bytes through a pixmap cache and draw a scaled source rectangle.
pub fn Renderer::draw_quality_bmp_bytes_rect_cached(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_quality_pixmap_rect(
        result.get_pixmap(),
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality,
      )
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a scaled source
/// rectangle.
pub fn Renderer::draw_quality_bmp_bytes_rect_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_quality_bmp_bytes_rect_cached(
    image_data,
    src_rect,
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
/// Draw a transformed sampled image through a caller-owned pixmap cache.
pub fn Renderer::draw_transformed_sampled_pixmap_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_transformed_sampled_pixmap(
    result.get_pixmap(),
    x,
    y,
    width,
    height,
    paint,
    sampling,
  )
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw a transformed sampled image through renderer-owned resources.
pub fn Renderer::draw_transformed_sampled_pixmap_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> CachedPixmapDrawResult {
  self.draw_transformed_sampled_pixmap_cached(
    pixmap,
    x,
    y,
    width,
    height,
    resources.get_image_cache(),
    image_key,
    paint,
    sampling,
  )
}

///|
/// Draw a transformed sampled source rectangle through a caller-owned pixmap
/// cache.
pub fn Renderer::draw_transformed_sampled_pixmap_rect_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> CachedPixmapDrawResult {
  let result = image_cache.get_or_insert_result(image_key, pixmap)
  self.canvas.draw_transformed_sampled_pixmap_rect(
    result.get_pixmap(),
    src_rect,
    x,
    y,
    width,
    height,
    paint,
    sampling,
  )
  { did_insert_pixmap: result.did_insert() }
}

///|
/// Draw a transformed sampled source rectangle through renderer-owned
/// resources.
pub fn Renderer::draw_transformed_sampled_pixmap_rect_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> CachedPixmapDrawResult {
  self.draw_transformed_sampled_pixmap_rect_cached(
    pixmap,
    src_rect,
    x,
    y,
    width,
    height,
    resources.get_image_cache(),
    image_key,
    paint,
    sampling,
  )
}

///|
/// Draw a transformed image through a caller-owned pixmap cache and quality
/// policy.
pub fn Renderer::draw_transformed_quality_pixmap_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  self.draw_transformed_sampled_pixmap_cached(
    pixmap,
    x,
    y,
    width,
    height,
    image_cache,
    image_key,
    paint,
    quality.to_sampling(),
  )
}

///|
/// Draw a transformed image through renderer-owned resources and quality
/// policy.
pub fn Renderer::draw_transformed_quality_pixmap_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  self.draw_transformed_quality_pixmap_cached(
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
/// Draw a transformed image source rectangle through a caller-owned pixmap cache
/// and quality policy.
pub fn Renderer::draw_transformed_quality_pixmap_rect_cached(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  self.draw_transformed_sampled_pixmap_rect_cached(
    pixmap,
    src_rect,
    x,
    y,
    width,
    height,
    image_cache,
    image_key,
    paint,
    quality.to_sampling(),
  )
}

///|
/// Draw a transformed image source rectangle through renderer-owned resources
/// and quality policy.
pub fn Renderer::draw_transformed_quality_pixmap_rect_cached_with_renderer_resources(
  self : Renderer,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> CachedPixmapDrawResult {
  self.draw_transformed_quality_pixmap_rect_cached(
    pixmap,
    src_rect,
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
/// Decode BMP bytes through a pixmap cache and draw a transformed sampled image.
pub fn Renderer::draw_transformed_sampled_bmp_bytes_cached(
  self : Renderer,
  image_data : Bytes,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_transformed_sampled_pixmap(
        result.get_pixmap(),
        x,
        y,
        width,
        height,
        paint,
        sampling,
      )
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a transformed
/// sampled image.
pub fn Renderer::draw_transformed_sampled_bmp_bytes_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_transformed_sampled_bmp_bytes_cached(
    image_data,
    x,
    y,
    width,
    height,
    resources.get_image_cache(),
    image_key,
    paint,
    sampling,
  )
}

///|
/// Decode BMP bytes through a pixmap cache and draw a transformed sampled
/// source rectangle.
pub fn Renderer::draw_transformed_sampled_bmp_bytes_rect_cached(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  match image_cache.get_or_decode_bmp_result(image_key, image_data) {
    Ok(result) => {
      self.canvas.draw_transformed_sampled_pixmap_rect(
        result.get_pixmap(),
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling,
      )
      Ok({ did_decode_pixmap: result.did_decode() })
    }
    Err(error) => Err(error)
  }
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a transformed
/// sampled source rectangle.
pub fn Renderer::draw_transformed_sampled_bmp_bytes_rect_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_transformed_sampled_bmp_bytes_rect_cached(
    image_data,
    src_rect,
    x,
    y,
    width,
    height,
    resources.get_image_cache(),
    image_key,
    paint,
    sampling,
  )
}

///|
/// Decode BMP bytes through a pixmap cache and draw a transformed image with a
/// quality policy.
pub fn Renderer::draw_transformed_quality_bmp_bytes_cached(
  self : Renderer,
  image_data : Bytes,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_transformed_sampled_bmp_bytes_cached(
    image_data,
    x,
    y,
    width,
    height,
    image_cache,
    image_key,
    paint,
    quality.to_sampling(),
  )
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a transformed
/// image with a quality policy.
pub fn Renderer::draw_transformed_quality_bmp_bytes_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_transformed_quality_bmp_bytes_cached(
    image_data,
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
/// Decode BMP bytes through a pixmap cache and draw a transformed source
/// rectangle with a quality policy.
pub fn Renderer::draw_transformed_quality_bmp_bytes_rect_cached(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  image_cache : @graphics.PixmapCache,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_transformed_sampled_bmp_bytes_rect_cached(
    image_data,
    src_rect,
    x,
    y,
    width,
    height,
    image_cache,
    image_key,
    paint,
    quality.to_sampling(),
  )
}

///|
/// Decode BMP bytes through renderer-owned resources and draw a transformed
/// source rectangle with a quality policy.
pub fn Renderer::draw_transformed_quality_bmp_bytes_rect_cached_with_renderer_resources(
  self : Renderer,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  resources : RendererResources,
  image_key : String,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError] {
  self.draw_transformed_quality_bmp_bytes_rect_cached(
    image_data,
    src_rect,
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
/// Draw a single left-to-right text line through an ordered font fallback stack.
pub fn draw_text_fallback_line(
  canvas : @graphics.Canvas,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> TextFallbackDrawResult {
  draw_text_fallback_line_with_cache(
    canvas,
    faces,
    text,
    x,
    y,
    width,
    height,
    config,
    None,
    "",
    paint,
  )
}

///|
/// Draw a single fallback line through a caller-owned rendered text-mask cache.
pub fn draw_text_fallback_line_cached(
  canvas : @graphics.Canvas,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  text_cache : @text.TextMaskCache,
  text_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackDrawResult {
  draw_text_fallback_line_with_cache(
    canvas,
    faces,
    text,
    x,
    y,
    width,
    height,
    config,
    Some(text_cache),
    text_key_prefix,
    paint,
  )
}

///|
/// Draw a single fallback line through caller-owned glyph mask cache and atlas
/// resources.
pub fn draw_text_fallback_line_atlas(
  canvas : @graphics.Canvas,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  glyph_cache : @text.GlyphMaskCache,
  atlas : @text.GlyphMaskAtlas,
  glyph_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackAtlasDrawResult {
  let plan = @text.plan_font_fallback(faces, text)
  let line_config = fallback_line_config(config)
  let mut cursor_x = x
  let mut drawn_span_count = 0
  let mut skipped_span_count = 0
  let mut emitted_char_count = 0
  let mut glyph_count = 0
  let mut drawn_glyph_count = 0
  let mut skipped_glyph_count = 0
  let mut cache_hit_count = 0
  let mut rasterized_glyph_count = 0
  let mut atlas_hit_count = 0
  let mut atlas_inserted_count = 0
  let mut did_clear_atlas = false

  for span in plan.get_spans() {
    if emitted_char_count > 0 {
      cursor_x += line_config.letter_spacing
    }
    if span.is_missing() {
      skipped_span_count += 1
      cursor_x += estimate_missing_span_advance(span.get_text(), line_config)
    } else {
      let face = faces[span.get_face_index()]
      let span_text = span.get_text()
      let result = draw_text_face_atlas(
        canvas,
        face,
        span_text,
        cursor_x,
        y,
        line_config,
        glyph_cache,
        atlas,
        fallback_glyph_atlas_cache_prefix(
          glyph_key_prefix,
          span.get_face_index(),
        ),
        paint,
      )
      glyph_count += result.get_glyph_count()
      drawn_glyph_count += result.get_drawn_glyph_count()
      skipped_glyph_count += result.get_skipped_glyph_count()
      cache_hit_count += result.get_cache_hit_count()
      rasterized_glyph_count += result.get_rasterized_glyph_count()
      atlas_hit_count += result.get_atlas_hit_count()
      atlas_inserted_count += result.get_atlas_inserted_count()
      if result.did_clear_atlas() {
        did_clear_atlas = true
      }
      cursor_x += @text.TextLayout::layout(face, span_text, line_config).get_width()
      drawn_span_count += 1
    }
    emitted_char_count += span.get_char_count()
  }

  {
    plan,
    drawn_span_count,
    skipped_span_count,
    advance_width: cursor_x - x,
    atlas_result: {
      glyph_count,
      drawn_glyph_count,
      skipped_glyph_count,
      cache_hit_count,
      rasterized_glyph_count,
      atlas_hit_count,
      atlas_inserted_count,
      did_clear_atlas,
    },
  }
}

///|
fn draw_text_fallback_line_with_cache(
  canvas : @graphics.Canvas,
  faces : Array[@text.FontFace],
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  text_cache : @text.TextMaskCache?,
  text_key_prefix : String,
  paint : @graphics.Paint,
) -> TextFallbackDrawResult {
  let plan = @text.plan_font_fallback(faces, text)
  let line_config = fallback_line_config(config)
  let mut cursor_x = x
  let mut drawn_span_count = 0
  let mut skipped_span_count = 0
  let mut rendered_mask_count = 0
  let mut cache_hit_count = 0
  let mut emitted_char_count = 0
  let mut span_index = 0

  for span in plan.get_spans() {
    if emitted_char_count > 0 {
      cursor_x += line_config.letter_spacing
    }
    if span.is_missing() {
      skipped_span_count += 1
      cursor_x += estimate_missing_span_advance(span.get_text(), line_config)
    } else {
      let face = faces[span.get_face_index()]
      let span_text = span.get_text()
      match text_cache {
        Some(cache) => {
          let key = fallback_text_cache_key(
            text_key_prefix,
            span_index,
            span.get_face_index(),
            span_text,
            width,
            height,
            cursor_x,
            y,
            line_config,
          )
          let result = cache.get_or_render_face_result(
            key, face, span_text, width, height, cursor_x, y, line_config,
          )
          draw_coverage_mask(canvas, result.get_mask(), paint)
          if result.did_render() {
            rendered_mask_count += 1
          } else {
            cache_hit_count += 1
          }
        }
        None =>
          draw_text_face(
            canvas, face, span_text, cursor_x, y, width, height, line_config, paint,
          )
      }
      cursor_x += @text.TextLayout::layout(face, span_text, line_config).get_width()
      drawn_span_count += 1
    }
    emitted_char_count += span.get_char_count()
    span_index += 1
  }

  {
    plan,
    drawn_span_count,
    skipped_span_count,
    rendered_mask_count,
    cache_hit_count,
    advance_width: cursor_x - x,
  }
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
fn fallback_line_config(config : @text.LayoutConfig) -> @text.LayoutConfig {
  @text.LayoutConfig::new(
    max_width=1000000000.0,
    font_size=config.font_size,
    line_height=config.line_height,
    alignment=@text.TextAlign::Left,
    letter_spacing=config.letter_spacing,
    word_spacing=config.word_spacing,
  )
}

///|
fn estimate_missing_span_advance(
  text : String,
  config : @text.LayoutConfig,
) -> Double {
  let mut width = 0.0
  let mut char_count = 0
  for ch in text {
    width += config.font_size * 0.6
    if ch is ' ' {
      width += config.word_spacing
    }
    char_count += 1
  }
  if char_count > 1 {
    width += config.letter_spacing * (char_count - 1).to_double()
  }
  width
}

///|
fn fallback_text_cache_key(
  prefix : String,
  span_index : Int,
  face_index : Int,
  text : String,
  width : Int,
  height : Int,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
) -> String {
  prefix +
  ":fallback-span:" +
  span_index.to_string() +
  ":face:" +
  face_index.to_string() +
  ":width:" +
  width.to_string() +
  ":height:" +
  height.to_string() +
  ":x:" +
  x.to_string() +
  ":y:" +
  y.to_string() +
  ":size:" +
  config.font_size.to_string() +
  ":letter:" +
  config.letter_spacing.to_string() +
  ":word:" +
  config.word_spacing.to_string() +
  ":text:" +
  text
}

///|
fn fallback_glyph_atlas_cache_prefix(
  prefix : String,
  face_index : Int,
) -> String {
  prefix + ":fallback-face:" + face_index.to_string()
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
