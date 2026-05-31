///|
test "Renderer::draw_coverage_mask composites text mask" {
  let canvas = @graphics.Canvas::new(2, 2)
  canvas.clear(@graphics.Color::white())
  let pixels : FixedArray[Byte] = FixedArray::make(4, 0)
  pixels[1] = 255
  let mask = @text.CoverageMask::new(2, 2, pixels)
  let renderer = Renderer::new(canvas)
  renderer.draw_coverage_mask(
    mask,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
  assert_eq(pixmap.get_pixel(1, 0), @graphics.Color::black())
}

///|
test "Renderer::draw_glyph_atlas_entry composites atlas subrect" {
  let atlas = @text.GlyphMaskAtlas::new(4, 2)
  let first = @text.CoverageMask::new(2, 2, FixedArray::make(4, 0))
  ignore(atlas.insert("empty", first))
  let glyph_pixels : FixedArray[Byte] = FixedArray::make(4, 0)
  glyph_pixels[0] = 255
  glyph_pixels[1] = 128
  glyph_pixels[2] = 0
  glyph_pixels[3] = 64
  let glyph = @text.CoverageMask::new(2, 2, glyph_pixels)
  let entry = match atlas.insert("glyph", glyph) {
    Some(entry) => entry
    None => abort("expected atlas entry")
  }

  let canvas = @graphics.Canvas::new(4, 3)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  renderer.draw_glyph_atlas_entry(
    atlas.to_mask(),
    entry,
    1,
    0,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
  assert_eq(pixmap.get_pixel(1, 0), @graphics.Color::black())
  assert_eq(
    pixmap.get_pixel(2, 0),
    @graphics.Color::new(r=127, g=127, b=127, a=255),
  )
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::white())
  assert_eq(
    pixmap.get_pixel(2, 1),
    @graphics.Color::new(r=191, g=191, b=191, a=255),
  )
}

///|
test "draw_coverage_mask uses paint opacity" {
  let canvas = @graphics.Canvas::new(1, 1)
  canvas.clear(@graphics.Color::white())
  let pixels : FixedArray[Byte] = FixedArray::make(1, 255)
  let mask = @text.CoverageMask::new(1, 1, pixels)
  let paint = @graphics.Paint::new()
    .set_color(@graphics.Color::black())
    .set_opacity(0.5)
  draw_coverage_mask(canvas, mask, paint)
  assert_eq(
    canvas.get_pixmap().get_pixel(0, 0),
    @graphics.Color::new(r=127, g=127, b=127, a=255),
  )
}

///|
test "Renderer::draw_text renders parsed TTF bytes to pixmap" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  renderer.draw_text_face(
    face,
    "A",
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
}

///|
test "Renderer::draw_text_face_atlas renders parsed TTF bytes" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  let glyph_cache = @text.GlyphMaskCache::new()
  let atlas = @text.GlyphMaskAtlas::new(16, 16)
  let result = renderer.draw_text_face_atlas(
    face,
    "A",
    1.0,
    1.0,
    config,
    glyph_cache,
    atlas,
    "fixture",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(result.get_glyph_count(), 1)
  assert_eq(result.get_drawn_glyph_count(), 1)
  assert_eq(result.get_skipped_glyph_count(), 0)
  assert_eq(result.get_cache_hit_count(), 0)
  assert_eq(result.get_rasterized_glyph_count(), 1)
  assert_eq(result.get_atlas_hit_count(), 0)
  assert_eq(result.get_atlas_inserted_count(), 1)
  assert_true(!result.did_clear_atlas())
  assert_eq(glyph_cache.len(), 1)
  assert_eq(atlas.len(), 1)
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
}

///|
test "Renderer::draw_text_face_atlas reports atlas rotation" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(16, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let glyph_cache = @text.GlyphMaskCache::new()
  let atlas = @text.GlyphMaskAtlas::new(10, 10)
  let result = renderer.draw_text_face_atlas(
    face,
    "AB",
    1.0,
    1.0,
    config,
    glyph_cache,
    atlas,
    "fixture",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(result.get_glyph_count(), 2)
  assert_eq(result.get_drawn_glyph_count(), 2)
  assert_eq(result.get_skipped_glyph_count(), 0)
  assert_eq(result.get_cache_hit_count(), 0)
  assert_eq(result.get_rasterized_glyph_count(), 2)
  assert_eq(result.get_atlas_hit_count(), 0)
  assert_eq(result.get_atlas_inserted_count(), 2)
  assert_true(result.did_clear_atlas())
  assert_eq(glyph_cache.len(), 2)
  assert_eq(atlas.len(), 1)
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(14, 4), @graphics.Color::black())
}

///|
test "Renderer::draw_text_face_atlas reports glyph cache hits" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(24, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let glyph_cache = @text.GlyphMaskCache::new()
  let atlas = @text.GlyphMaskAtlas::new(16, 16)
  let result = renderer.draw_text_face_atlas(
    face,
    "AA",
    1.0,
    1.0,
    config,
    glyph_cache,
    atlas,
    "fixture",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(result.get_glyph_count(), 2)
  assert_eq(result.get_drawn_glyph_count(), 2)
  assert_eq(result.get_skipped_glyph_count(), 0)
  assert_eq(result.get_cache_hit_count(), 1)
  assert_eq(result.get_rasterized_glyph_count(), 1)
  assert_eq(result.get_atlas_hit_count(), 1)
  assert_eq(result.get_atlas_inserted_count(), 1)
  assert_true(!result.did_clear_atlas())
  assert_eq(glyph_cache.len(), 1)
  assert_eq(atlas.len(), 1)
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(11, 1), @graphics.Color::black())
}

///|
test "Renderer::draw_text_fallback_line draws spans with covering faces" {
  let primary = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([65])),
  )
  let fallback = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([66])),
  )
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let result = renderer.draw_text_fallback_line(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(result.get_span_count(), 3)
  assert_eq(result.get_drawn_span_count(), 2)
  assert_eq(result.get_skipped_span_count(), 1)
  assert_eq(result.get_missing_span_count(), 1)
  assert_eq(result.get_missing_char_count(), 1)
  assert_eq(result.get_rendered_mask_count(), 0)
  assert_eq(result.get_cache_hit_count(), 0)
  assert_true(result.has_missing_glyphs())
  assert_eq(result.get_advance_width(), 26.0)
  let plan = result.get_plan()
  assert_eq(plan.get_missing_char_count(), 1)
  let spans = plan.get_spans()
  assert_eq(spans[0].get_face_index(), 0)
  assert_eq(spans[1].get_face_index(), 1)
  assert_true(spans[2].is_missing())

  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(14, 5), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(21, 1), @graphics.Color::white())
}

///|
test "draw_text_fallback_line handles empty fallback stack" {
  let canvas = @graphics.Canvas::new(24, 12)
  canvas.clear(@graphics.Color::white())
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let result = draw_text_fallback_line(
    canvas,
    [],
    "AB",
    1.0,
    1.0,
    24,
    12,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(result.get_span_count(), 1)
  assert_eq(result.get_drawn_span_count(), 0)
  assert_eq(result.get_skipped_span_count(), 1)
  assert_eq(result.get_missing_char_count(), 2)
  assert_eq(result.get_rendered_mask_count(), 0)
  assert_eq(result.get_cache_hit_count(), 0)
  assert_eq(result.get_advance_width(), 12.0)
  assert_true(!pixmap_has_ink(canvas.get_pixmap()))
}

///|
test "draw_text_fallback_line keeps spacing across fallback spans" {
  let primary = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([65])),
  )
  let fallback = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([66])),
  )
  let canvas = @graphics.Canvas::new(40, 12)
  canvas.clear(@graphics.Color::white())
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
    letter_spacing=2.0,
  )
  let result = draw_text_fallback_line(
    canvas,
    [primary, fallback],
    "AB",
    1.0,
    1.0,
    40,
    12,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(result.get_advance_width(), 22.0)
  assert_eq(result.get_rendered_mask_count(), 0)
  assert_eq(result.get_cache_hit_count(), 0)
  assert_eq(canvas.get_pixmap().get_pixel(16, 5), @graphics.Color::black())
}

///|
test "Renderer::draw_text_fallback_line_cached reuses fallback span masks" {
  let primary = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([65])),
  )
  let fallback = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([66])),
  )
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let text_cache = @text.TextMaskCache::new()
  let first = renderer.draw_text_fallback_line_cached(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    text_cache,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(first.get_span_count(), 3)
  assert_eq(first.get_drawn_span_count(), 2)
  assert_eq(first.get_skipped_span_count(), 1)
  assert_eq(first.get_missing_char_count(), 1)
  assert_eq(first.get_rendered_mask_count(), 2)
  assert_eq(first.get_cache_hit_count(), 0)
  assert_eq(text_cache.len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_fallback_line_cached(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    text_cache,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(second.get_drawn_span_count(), 2)
  assert_eq(second.get_skipped_span_count(), 1)
  assert_eq(second.get_rendered_mask_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(text_cache.len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
test "Renderer::draw_text_fallback_line_atlas reuses fallback glyph resources" {
  let primary = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([65])),
  )
  let fallback = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([66])),
  )
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let glyph_cache = @text.GlyphMaskCache::new()
  let atlas = @text.GlyphMaskAtlas::new(24, 12)
  let first = renderer.draw_text_fallback_line_atlas(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    glyph_cache,
    atlas,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(first.get_span_count(), 3)
  assert_eq(first.get_drawn_span_count(), 2)
  assert_eq(first.get_skipped_span_count(), 1)
  assert_eq(first.get_missing_char_count(), 1)
  assert_eq(first.get_glyph_count(), 2)
  assert_eq(first.get_drawn_glyph_count(), 2)
  assert_eq(first.get_rasterized_glyph_count(), 2)
  assert_eq(first.get_cache_hit_count(), 0)
  assert_eq(first.get_atlas_inserted_count(), 2)
  assert_eq(first.get_atlas_hit_count(), 0)
  assert_eq(glyph_cache.len(), 2)
  assert_eq(atlas.len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_fallback_line_atlas(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    glyph_cache,
    atlas,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(second.get_drawn_span_count(), 2)
  assert_eq(second.get_skipped_span_count(), 1)
  assert_eq(second.get_rasterized_glyph_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(second.get_atlas_inserted_count(), 0)
  assert_eq(second.get_atlas_hit_count(), 2)
  assert_eq(glyph_cache.len(), 2)
  assert_eq(atlas.len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
test "Renderer fallback atlas text path uses RendererResources" {
  let primary = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([65])),
  )
  let fallback = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([66])),
  )
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(24, 12, 4, 4, 1)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = renderer.draw_text_fallback_line_atlas_with_renderer_resources(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(first.get_rasterized_glyph_count(), 2)
  assert_eq(first.get_cache_hit_count(), 0)
  assert_eq(first.get_atlas_inserted_count(), 2)
  assert_eq(resources.get_glyph_mask_cache().len(), 2)
  assert_eq(resources.get_glyph_mask_atlas().len(), 2)

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_fallback_line_atlas_with_renderer_resources(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(second.get_rasterized_glyph_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(second.get_atlas_hit_count(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
test "Renderer fallback cached text path uses RendererResources" {
  let primary = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([65])),
  )
  let fallback = unwrap_font_face(
    @text.FontFace::from_bytes(make_ttf_for_codes([66])),
  )
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 4, 4, 1)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = renderer.draw_text_fallback_line_cached_with_renderer_resources(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(first.get_rendered_mask_count(), 2)
  assert_eq(first.get_cache_hit_count(), 0)
  assert_eq(resources.get_text_mask_cache().len(), 2)

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_fallback_line_cached_with_renderer_resources(
    [primary, fallback],
    "ABZ",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(second.get_rendered_mask_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(resources.get_text_mask_cache().len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
test "RendererTextResources configures bounded text caches" {
  let resources = RendererTextResources::with_capacities(16, 16, 1, 2)
  let text_cache = resources.get_text_mask_cache()
  let glyph_cache = resources.get_glyph_mask_cache()
  let atlas = resources.get_glyph_mask_atlas()
  assert_true(text_cache.is_capacity_bounded())
  assert_eq(text_cache.capacity(), 1)
  assert_true(glyph_cache.is_capacity_bounded())
  assert_eq(glyph_cache.capacity(), 2)
  assert_eq(atlas.get_width(), 16)
  assert_eq(atlas.get_height(), 16)
}

///|
test "RendererTextResources reports cached text and glyph residency" {
  let resources = RendererTextResources::new(16, 16)
  let text_pixels : FixedArray[Byte] = FixedArray::make(1, 24)
  let glyph_pixels : FixedArray[Byte] = FixedArray::make(1, 48)
  ignore(
    resources
    .get_text_mask_cache()
    .insert("label", @text.CoverageMask::new(1, 1, text_pixels)),
  )
  ignore(
    resources
    .get_glyph_mask_cache()
    .insert("glyph:A", @text.CoverageMask::new(1, 1, glyph_pixels)),
  )
  assert_true(resources.contains_text_mask("label"))
  assert_true(!resources.contains_text_mask("missing"))
  assert_true(resources.contains_glyph_mask("glyph:A"))
  assert_true(!resources.contains_glyph_mask("glyph:B"))

  resources.clear()
  assert_true(!resources.contains_text_mask("label"))
  assert_true(!resources.contains_glyph_mask("glyph:A"))
}

///|
test "RendererTextResources snapshots cache and atlas telemetry" {
  let resources = RendererTextResources::with_capacities(16, 8, 2, 3)
  let empty = resources.snapshot()
  assert_eq(empty.get_text_mask_count(), 0)
  assert_eq(empty.get_text_mask_capacity(), 2)
  assert_true(empty.is_text_mask_capacity_bounded())
  assert_eq(empty.get_glyph_mask_count(), 0)
  assert_eq(empty.get_glyph_mask_capacity(), 3)
  assert_true(empty.is_glyph_mask_capacity_bounded())
  assert_eq(empty.get_atlas_entry_count(), 0)
  assert_eq(empty.get_atlas_width(), 16)
  assert_eq(empty.get_atlas_height(), 8)
  assert_eq(empty.get_atlas_capacity(), 128)
  assert_eq(empty.get_atlas_used_pixel_count(), 0)
  assert_eq(empty.get_atlas_free_pixel_count(), 128)
  assert_eq(empty.get_atlas_occupancy_ratio(), 0.0)

  ignore(
    resources
    .get_text_mask_cache()
    .insert("label", @text.CoverageMask::new(1, 1, FixedArray::make(1, 8))),
  )
  let glyph_mask = @text.CoverageMask::new(2, 2, FixedArray::make(4, 16))
  ignore(resources.get_glyph_mask_cache().insert("glyph:A", glyph_mask))
  ignore(resources.get_glyph_mask_atlas().insert("glyph:A", glyph_mask))

  let filled = resources.snapshot()
  assert_eq(filled.get_text_mask_count(), 1)
  assert_eq(filled.get_glyph_mask_count(), 1)
  assert_eq(filled.get_atlas_entry_count(), 1)
  assert_eq(filled.get_atlas_used_pixel_count(), 4)
  assert_eq(filled.get_atlas_free_pixel_count(), 124)
  assert_eq(filled.get_atlas_occupancy_ratio(), 0.03125)

  resources.clear()
  let cleared = resources.snapshot()
  assert_eq(cleared.get_text_mask_count(), 0)
  assert_eq(cleared.get_glyph_mask_count(), 0)
  assert_eq(cleared.get_atlas_entry_count(), 0)
  assert_eq(cleared.get_atlas_used_pixel_count(), 0)
  assert_eq(cleared.get_atlas_free_pixel_count(), 128)
}

///|
test "RendererResources configures bounded font text and image caches" {
  let resources = RendererResources::with_font_capacity(16, 16, 1, 2, 3, 1)
  let font_cache = resources.get_font_face_cache()
  let text_resources = resources.get_text_resources()
  let text_cache = resources.get_text_mask_cache()
  let glyph_cache = resources.get_glyph_mask_cache()
  let atlas = resources.get_glyph_mask_atlas()
  let image_cache = resources.get_image_cache()
  assert_true(font_cache.is_capacity_bounded())
  assert_eq(font_cache.capacity(), 1)
  assert_true(text_cache.is_capacity_bounded())
  assert_eq(text_cache.capacity(), 2)
  assert_eq(text_resources.get_text_mask_cache().capacity(), 2)
  assert_true(glyph_cache.is_capacity_bounded())
  assert_eq(glyph_cache.capacity(), 3)
  assert_eq(atlas.get_width(), 16)
  assert_eq(atlas.get_height(), 16)
  assert_true(image_cache.is_capacity_bounded())
  assert_eq(image_cache.capacity(), 1)

  ignore(
    font_cache.insert(
      "first",
      unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf())),
    ),
  )
  ignore(
    font_cache.insert(
      "second",
      unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf())),
    ),
  )
  assert_eq(font_cache.len(), 1)
  assert_true(font_cache.get("first") is None)
  assert_true(font_cache.get("second") is Some(_))

  let red = @graphics.Pixmap::new(1, 1)
  red.set_pixel(0, 0, @graphics.Color::red())
  let blue = @graphics.Pixmap::new(1, 1)
  blue.set_pixel(0, 0, @graphics.Color::blue())
  ignore(image_cache.insert("red", red))
  ignore(image_cache.insert("blue", blue))
  assert_eq(image_cache.len(), 1)
  assert_true(image_cache.get("red") is None)
  match image_cache.get("blue") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), @graphics.Color::blue())
    None => abort("expected cached blue pixmap")
  }
}

///|
test "RendererResources reports unified cache residency" {
  let resources = RendererResources::new(16, 16)
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  ignore(resources.get_font_face_cache().insert("ui-font", face))
  let text_pixels : FixedArray[Byte] = FixedArray::make(1, 32)
  let glyph_pixels : FixedArray[Byte] = FixedArray::make(1, 64)
  ignore(
    resources
    .get_text_mask_cache()
    .insert("label", @text.CoverageMask::new(1, 1, text_pixels)),
  )
  ignore(
    resources
    .get_glyph_mask_cache()
    .insert("glyph:A", @text.CoverageMask::new(1, 1, glyph_pixels)),
  )
  let icon = @graphics.Pixmap::new(1, 1)
  icon.set_pixel(0, 0, @graphics.Color::green())
  ignore(resources.get_image_cache().insert("icon", icon))

  assert_true(resources.contains_font_face("ui-font"))
  assert_true(!resources.contains_font_face("missing-font"))
  assert_true(resources.contains_text_mask("label"))
  assert_true(!resources.contains_text_mask("missing-label"))
  assert_true(resources.contains_glyph_mask("glyph:A"))
  assert_true(!resources.contains_glyph_mask("glyph:B"))
  assert_true(resources.contains_image("icon"))
  assert_true(!resources.contains_image("missing-icon"))

  resources.clear()
  assert_true(!resources.contains_font_face("ui-font"))
  assert_true(!resources.contains_text_mask("label"))
  assert_true(!resources.contains_glyph_mask("glyph:A"))
  assert_true(!resources.contains_image("icon"))
}

///|
test "RendererResources snapshots unified resource telemetry" {
  let resources = RendererResources::with_font_capacity(16, 8, 1, 2, 3, 4)
  let empty = resources.snapshot()
  assert_eq(empty.get_font_face_count(), 0)
  assert_eq(empty.get_font_face_capacity(), 1)
  assert_true(empty.is_font_face_capacity_bounded())
  assert_eq(empty.get_image_count(), 0)
  assert_eq(empty.get_image_capacity(), 4)
  assert_true(empty.is_image_capacity_bounded())
  let empty_text = empty.get_text_snapshot()
  assert_eq(empty_text.get_text_mask_capacity(), 2)
  assert_eq(empty_text.get_glyph_mask_capacity(), 3)
  assert_eq(empty_text.get_atlas_capacity(), 128)

  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  ignore(resources.get_font_face_cache().insert("ui-font", face))
  ignore(
    resources
    .get_text_mask_cache()
    .insert("label", @text.CoverageMask::new(1, 1, FixedArray::make(1, 8))),
  )
  let glyph_mask = @text.CoverageMask::new(2, 2, FixedArray::make(4, 16))
  ignore(resources.get_glyph_mask_cache().insert("glyph:A", glyph_mask))
  ignore(resources.get_glyph_mask_atlas().insert("glyph:A", glyph_mask))
  let icon = @graphics.Pixmap::new(1, 1)
  icon.set_pixel(0, 0, @graphics.Color::green())
  ignore(resources.get_image_cache().insert("icon", icon))

  let filled = resources.snapshot()
  assert_eq(filled.get_font_face_count(), 1)
  assert_eq(filled.get_image_count(), 1)
  let filled_text = filled.get_text_snapshot()
  assert_eq(filled_text.get_text_mask_count(), 1)
  assert_eq(filled_text.get_glyph_mask_count(), 1)
  assert_eq(filled_text.get_atlas_entry_count(), 1)
  assert_eq(filled_text.get_atlas_used_pixel_count(), 4)

  resources.clear()
  let cleared = resources.snapshot()
  assert_eq(cleared.get_font_face_count(), 0)
  assert_eq(cleared.get_image_count(), 0)
  assert_eq(cleared.get_text_snapshot().get_text_mask_count(), 0)
  assert_eq(cleared.get_text_snapshot().get_glyph_mask_count(), 0)
  assert_eq(cleared.get_text_snapshot().get_atlas_entry_count(), 0)
}

///|
test "RendererResources decodes BMP images into image cache" {
  let resources = RendererResources::new(16, 16)
  let icon = @graphics.Pixmap::new(1, 1)
  icon.set_pixel(0, 0, @graphics.Color::green())

  match resources.get_or_decode_bmp_image_result("icon", icon.to_bmp_bytes()) {
    Ok(first) => {
      assert_true(first.did_decode())
      assert_true(!first.did_hit_cache())
      assert_eq(first.get_pixmap().get_pixel(0, 0), @graphics.Color::green())
    }
    Err(_) => abort("expected renderer resources BMP decode")
  }
  assert_true(resources.contains_image("icon"))
  assert_eq(resources.snapshot().get_image_count(), 1)

  match resources.get_or_decode_bmp_image("icon", Bytes::from_array([0, 0])) {
    Ok(second) => assert_eq(second.get_pixel(0, 0), @graphics.Color::green())
    Err(_) => abort("expected renderer resources BMP cache hit")
  }
  assert_eq(resources.snapshot().get_image_count(), 1)
}

///|
test "Renderer::draw_pixmap_cached reuses cached pixmap copies" {
  let canvas = @graphics.Canvas::new(3, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let image_cache = @graphics.PixmapCache::new()
  let icon = @graphics.Pixmap::new(1, 1)
  icon.set_pixel(0, 0, @graphics.Color::red())

  let first = renderer.draw_pixmap_cached(
    icon,
    0,
    0,
    image_cache,
    "icon",
    @graphics.Paint::new(),
  )
  assert_true(first.did_insert_pixmap())
  assert_true(!first.did_hit_cache())
  assert_eq(image_cache.len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::red())

  icon.set_pixel(0, 0, @graphics.Color::blue())
  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_pixmap_cached(
    icon,
    1,
    0,
    image_cache,
    "icon",
    @graphics.Paint::new(),
  )
  assert_true(!second.did_insert_pixmap())
  assert_true(second.did_hit_cache())
  assert_eq(image_cache.len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::white())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::red())
}

///|
test "Renderer cached image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(2, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let icon = @graphics.Pixmap::new(1, 1)
  icon.set_pixel(0, 0, @graphics.Color::green())

  let first = renderer.draw_pixmap_cached_with_renderer_resources(
    icon,
    0,
    0,
    resources,
    "icon",
    @graphics.Paint::new(),
  )
  assert_true(first.did_insert_pixmap())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::green())

  icon.set_pixel(0, 0, @graphics.Color::blue())
  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_pixmap_cached_with_renderer_resources(
    icon,
    1,
    0,
    resources,
    "icon",
    @graphics.Paint::new(),
  )
  assert_true(second.did_hit_cache())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())
}

///|
test "Renderer cached image source rect path uses RendererResources" {
  let canvas = @graphics.Canvas::new(4, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let atlas = @graphics.Pixmap::new(3, 1)
  atlas.set_pixel(0, 0, @graphics.Color::red())
  atlas.set_pixel(1, 0, @graphics.Color::green())
  atlas.set_pixel(2, 0, @graphics.Color::blue())
  let green_rect = @graphics.PixelRect::new(x=1, y=0, width=1, height=1)
  let blue_rect = @graphics.PixelRect::new(x=2, y=0, width=1, height=1)

  let first = renderer.draw_pixmap_rect_cached_with_renderer_resources(
    atlas,
    green_rect,
    0,
    0,
    resources,
    "atlas",
    @graphics.Paint::new(),
  )
  assert_true(first.did_insert_pixmap())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::green())

  atlas.set_pixel(1, 0, @graphics.Color::red())
  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_pixmap_rect_cached_with_renderer_resources(
    atlas,
    green_rect,
    1,
    0,
    resources,
    "atlas",
    @graphics.Paint::new(),
  )
  assert_true(second.did_hit_cache())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())

  let scaled = renderer.draw_quality_pixmap_rect_cached_with_renderer_resources(
    atlas,
    blue_rect,
    2,
    0,
    2,
    1,
    resources,
    "atlas",
    @graphics.Paint::new(),
    @graphics.ImageQuality::Fast,
  )
  assert_true(scaled.did_hit_cache())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::blue())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::blue())
}

///|
test "Renderer cached tiled image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(4, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let tile = make_renderer_test_tile_source()
  let src_rect = @graphics.PixelRect::new(x=0, y=0, width=2, height=1)

  let first = renderer.draw_tiled_pixmap_rect_cached_with_renderer_resources(
    tile,
    src_rect,
    0,
    0,
    4,
    1,
    resources,
    "tile",
    @graphics.Paint::new(),
  )
  assert_true(first.did_insert_pixmap())
  assert_true(!first.did_hit_cache())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::green())

  tile.set_pixel(0, 0, @graphics.Color::blue())
  tile.set_pixel(1, 0, @graphics.Color::blue())
  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_tiled_pixmap_rect_cached_with_renderer_resources(
    tile,
    src_rect,
    0,
    0,
    4,
    1,
    resources,
    "tile",
    @graphics.Paint::new(),
  )
  assert_true(!second.did_insert_pixmap())
  assert_true(second.did_hit_cache())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::green())
}

///|
test "Renderer cached transformed image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(5, 3)
  canvas.clear(@graphics.Color::white())
  canvas.set_transform(
    @graphics.Transform::translate(tx=1.0, ty=1.0).multiply(
      @graphics.Transform::scale(sx=2.0, sy=1.0),
    ),
  )
  canvas.set_clip_rect(@graphics.Rect::new(x=2.0, y=1.0, width=2.0, height=1.0))
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let tile = make_renderer_test_tile_source()

  let first = renderer.draw_transformed_sampled_pixmap_cached_with_renderer_resources(
    tile,
    0.0,
    0.0,
    2.0,
    1.0,
    resources,
    "tile-transform",
    @graphics.Paint::new(),
    @graphics.ImageSampling::Nearest,
  )
  assert_true(first.did_insert_pixmap())
  assert_true(!first.did_hit_cache())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), @graphics.Color::white())
  assert_eq(canvas.get_pixmap().get_pixel(2, 1), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(3, 1), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(4, 1), @graphics.Color::white())

  tile.set_pixel(0, 0, @graphics.Color::blue())
  tile.set_pixel(1, 0, @graphics.Color::blue())
  canvas.clear(@graphics.Color::white())
  let src_rect = @graphics.PixelRect::new(x=0, y=0, width=2, height=1)
  let second = renderer.draw_transformed_quality_pixmap_rect_cached_with_renderer_resources(
    tile,
    src_rect,
    0.0,
    0.0,
    2.0,
    1.0,
    resources,
    "tile-transform",
    @graphics.Paint::new(),
    @graphics.ImageQuality::Fast,
  )
  assert_true(!second.did_insert_pixmap())
  assert_true(second.did_hit_cache())
  assert_eq(canvas.get_pixmap().get_pixel(2, 1), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(3, 1), @graphics.Color::green())
}

///|
test "Renderer cached nine-patch image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(5, 5)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let panel = make_renderer_test_nine_patch_source()
  let insets = @graphics.NinePatchInsets::new(left=1, top=1, right=1, bottom=1)

  let first = renderer.draw_nine_patch_pixmap_cached_with_renderer_resources(
    panel,
    0,
    0,
    5,
    5,
    insets,
    resources,
    "panel",
    @graphics.Paint::new(),
    @graphics.ImageSampling::Nearest,
  )
  assert_true(first.did_insert_pixmap())
  assert_true(!first.did_hit_cache())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(
    canvas.get_pixmap().get_pixel(0, 0),
    @graphics.Color::new(r=10, g=0, b=0),
  )
  assert_eq(
    canvas.get_pixmap().get_pixel(2, 2),
    @graphics.Color::new(r=50, g=0, b=0),
  )
  assert_eq(
    canvas.get_pixmap().get_pixel(4, 4),
    @graphics.Color::new(r=90, g=0, b=0),
  )

  panel.set_pixel(1, 1, @graphics.Color::blue())
  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_quality_nine_patch_pixmap_cached_with_renderer_resources(
    panel,
    0,
    0,
    5,
    5,
    insets,
    resources,
    "panel",
    @graphics.Paint::new(),
    @graphics.ImageQuality::Fast,
  )
  assert_true(!second.did_insert_pixmap())
  assert_true(second.did_hit_cache())
  assert_eq(
    canvas.get_pixmap().get_pixel(2, 2),
    @graphics.Color::new(r=50, g=0, b=0),
  )
}

///|
test "Renderer cached BMP image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(3, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 2)
  let icon = @graphics.Pixmap::new(1, 1)
  icon.set_pixel(0, 0, @graphics.Color::green())

  match
    renderer.draw_bmp_bytes_cached_with_renderer_resources(
      icon.to_bmp_bytes(),
      0,
      0,
      resources,
      "icon",
      @graphics.Paint::new(),
    ) {
    Ok(first) => {
      assert_true(first.did_decode_pixmap())
      assert_true(!first.did_hit_cache())
    }
    Err(_) => abort("expected cached BMP draw")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::green())

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_bmp_bytes_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      1,
      0,
      resources,
      "icon",
      @graphics.Paint::new(),
    ) {
    Ok(second) => {
      assert_true(!second.did_decode_pixmap())
      assert_true(second.did_hit_cache())
    }
    Err(_) => abort("expected cached BMP hit")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::white())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())

  match
    renderer.draw_bmp_bytes_cached_with_renderer_resources(
      Bytes::from_array([66, 77]),
      2,
      0,
      resources,
      "broken",
      @graphics.Paint::new(),
    ) {
    Err(@graphics.PixmapDecodeError::UnexpectedEndOfData(0, 54, 2)) => ()
    _ => abort("expected cached BMP draw decode error")
  }
  assert_true(!resources.contains_image("broken"))
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::white())
}

///|
test "Renderer cached BMP source rect path uses RendererResources" {
  let canvas = @graphics.Canvas::new(4, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let atlas = @graphics.Pixmap::new(3, 1)
  atlas.set_pixel(0, 0, @graphics.Color::red())
  atlas.set_pixel(1, 0, @graphics.Color::green())
  atlas.set_pixel(2, 0, @graphics.Color::blue())
  let green_rect = @graphics.PixelRect::new(x=1, y=0, width=1, height=1)
  let blue_rect = @graphics.PixelRect::new(x=2, y=0, width=1, height=1)

  match
    renderer.draw_bmp_bytes_rect_cached_with_renderer_resources(
      atlas.to_bmp_bytes(),
      green_rect,
      0,
      0,
      resources,
      "atlas",
      @graphics.Paint::new(),
    ) {
    Ok(first) => {
      assert_true(first.did_decode_pixmap())
      assert_true(!first.did_hit_cache())
    }
    Err(_) => abort("expected cached BMP source rect draw")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::green())

  match
    renderer.draw_bmp_bytes_rect_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      blue_rect,
      1,
      0,
      resources,
      "atlas",
      @graphics.Paint::new(),
    ) {
    Ok(second) => assert_true(second.did_hit_cache())
    Err(_) => abort("expected cached BMP source rect hit")
  }
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::blue())

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_quality_bmp_bytes_rect_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      green_rect,
      2,
      0,
      2,
      1,
      resources,
      "atlas",
      @graphics.Paint::new(),
      @graphics.ImageQuality::Fast,
    ) {
    Ok(scaled) => assert_true(scaled.did_hit_cache())
    Err(_) => abort("expected cached quality BMP source rect hit")
  }
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::green())
}

///|
test "Renderer cached BMP tiled image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(4, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let tile = make_renderer_test_tile_source()
  let src_rect = @graphics.PixelRect::new(x=0, y=0, width=2, height=1)

  match
    renderer.draw_tiled_bmp_bytes_rect_cached_with_renderer_resources(
      tile.to_bmp_bytes(),
      src_rect,
      0,
      0,
      4,
      1,
      resources,
      "tile",
      @graphics.Paint::new(),
    ) {
    Ok(first) => {
      assert_true(first.did_decode_pixmap())
      assert_true(!first.did_hit_cache())
    }
    Err(_) => abort("expected cached BMP tiled draw")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::green())

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_tiled_bmp_bytes_rect_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      src_rect,
      0,
      0,
      4,
      1,
      resources,
      "tile",
      @graphics.Paint::new(),
    ) {
    Ok(second) => {
      assert_true(!second.did_decode_pixmap())
      assert_true(second.did_hit_cache())
    }
    Err(_) => abort("expected cached BMP tiled hit")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::green())

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_tiled_bmp_bytes_rect_cached_with_renderer_resources(
      Bytes::from_array([66, 77]),
      src_rect,
      0,
      0,
      4,
      1,
      resources,
      "broken",
      @graphics.Paint::new(),
    ) {
    Err(@graphics.PixmapDecodeError::UnexpectedEndOfData(0, 54, 2)) => ()
    _ => abort("expected cached BMP tiled decode error")
  }
  assert_true(!resources.contains_image("broken"))
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::white())
}

///|
test "Renderer cached BMP transformed image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(4, 1)
  canvas.clear(@graphics.Color::white())
  canvas.set_transform(@graphics.Transform::translate(tx=1.0, ty=0.0))
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let tile = make_renderer_test_tile_source()
  let src_rect = @graphics.PixelRect::new(x=0, y=0, width=2, height=1)

  match
    renderer.draw_transformed_sampled_bmp_bytes_cached_with_renderer_resources(
      tile.to_bmp_bytes(),
      0.0,
      0.0,
      2.0,
      1.0,
      resources,
      "tile-transform-bmp",
      @graphics.Paint::new(),
      @graphics.ImageSampling::Nearest,
    ) {
    Ok(first) => {
      assert_true(first.did_decode_pixmap())
      assert_true(!first.did_hit_cache())
    }
    Err(_) => abort("expected cached transformed BMP draw")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::white())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::green())

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_transformed_quality_bmp_bytes_rect_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      src_rect,
      0.0,
      0.0,
      2.0,
      1.0,
      resources,
      "tile-transform-bmp",
      @graphics.Paint::new(),
      @graphics.ImageQuality::Fast,
    ) {
    Ok(second) => {
      assert_true(!second.did_decode_pixmap())
      assert_true(second.did_hit_cache())
    }
    Err(_) => abort("expected cached transformed BMP hit")
  }
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::red())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::green())

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_transformed_sampled_bmp_bytes_cached_with_renderer_resources(
      Bytes::from_array([66, 77]),
      0.0,
      0.0,
      2.0,
      1.0,
      resources,
      "broken-transform-bmp",
      @graphics.Paint::new(),
      @graphics.ImageSampling::Nearest,
    ) {
    Err(@graphics.PixmapDecodeError::UnexpectedEndOfData(0, 54, 2)) => ()
    _ => abort("expected cached transformed BMP decode error")
  }
  assert_true(!resources.contains_image("broken-transform-bmp"))
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::white())
}

///|
test "Renderer sampled cached image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(3, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let image = make_renderer_test_bicubic_source()

  let first = renderer.draw_sampled_pixmap_cached_with_renderer_resources(
    image,
    0,
    0,
    3,
    1,
    resources,
    "sampled",
    @graphics.Paint::new(),
    @graphics.ImageSampling::Bicubic,
  )
  assert_true(first.did_insert_pixmap())
  assert_true(!first.did_hit_cache())
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(
    canvas.get_pixmap().get_pixel(0, 0),
    @graphics.Color::new(r=34, g=0, b=0, a=255),
  )

  image.set_pixel(1, 0, @graphics.Color::blue())
  image.set_pixel(3, 0, @graphics.Color::blue())
  canvas.clear(@graphics.Color::white())
  let src_rect = @graphics.PixelRect::new(x=0, y=0, width=4, height=1)
  let second = renderer.draw_sampled_pixmap_rect_cached_with_renderer_resources(
    image,
    src_rect,
    0,
    0,
    3,
    1,
    resources,
    "sampled",
    @graphics.Paint::new(),
    @graphics.ImageSampling::Bilinear,
  )
  assert_true(!second.did_insert_pixmap())
  assert_true(second.did_hit_cache())
  assert_eq(
    canvas.get_pixmap().get_pixel(1, 0),
    @graphics.Color::new(r=128, g=0, b=0, a=255),
  )
}

///|
test "Renderer sampled cached BMP image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(3, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let image = make_renderer_test_bicubic_source()

  match
    renderer.draw_sampled_bmp_bytes_cached_with_renderer_resources(
      image.to_bmp_bytes(),
      0,
      0,
      3,
      1,
      resources,
      "sampled-bmp",
      @graphics.Paint::new(),
      @graphics.ImageSampling::Bicubic,
    ) {
    Ok(first) => {
      assert_true(first.did_decode_pixmap())
      assert_true(!first.did_hit_cache())
    }
    Err(_) => abort("expected cached sampled BMP draw")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(
    canvas.get_pixmap().get_pixel(0, 0),
    @graphics.Color::new(r=34, g=0, b=0, a=255),
  )

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_sampled_bmp_bytes_rect_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      @graphics.PixelRect::new(x=0, y=0, width=4, height=1),
      0,
      0,
      3,
      1,
      resources,
      "sampled-bmp",
      @graphics.Paint::new(),
      @graphics.ImageSampling::Bilinear,
    ) {
    Ok(second) => {
      assert_true(!second.did_decode_pixmap())
      assert_true(second.did_hit_cache())
    }
    Err(_) => abort("expected cached sampled BMP hit")
  }
  assert_eq(
    canvas.get_pixmap().get_pixel(1, 0),
    @graphics.Color::new(r=128, g=0, b=0, a=255),
  )

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_sampled_bmp_bytes_cached_with_renderer_resources(
      Bytes::from_array([66, 77]),
      0,
      0,
      3,
      1,
      resources,
      "broken-sampled-bmp",
      @graphics.Paint::new(),
      @graphics.ImageSampling::Bicubic,
    ) {
    Err(@graphics.PixmapDecodeError::UnexpectedEndOfData(0, 54, 2)) => ()
    _ => abort("expected sampled BMP decode error")
  }
  assert_true(!resources.contains_image("broken-sampled-bmp"))
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::white())
}

///|
test "Renderer quality cached image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(4, 2)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let panel = @graphics.Pixmap::new(1, 1)
  panel.set_pixel(0, 0, @graphics.Color::green())

  let first = renderer.draw_quality_pixmap_cached_with_renderer_resources(
    panel,
    0,
    0,
    2,
    1,
    resources,
    "panel",
    @graphics.Paint::new(),
    @graphics.ImageQuality::Fast,
  )
  assert_true(first.did_insert_pixmap())
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())

  panel.set_pixel(0, 0, @graphics.Color::blue())
  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_quality_pixmap_cached_with_renderer_resources(
    panel,
    2,
    0,
    2,
    1,
    resources,
    "panel",
    @graphics.Paint::new(),
    @graphics.ImageQuality::Fast,
  )
  assert_true(second.did_hit_cache())
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::green())

  let accent = @graphics.Pixmap::new(1, 1)
  accent.set_pixel(0, 0, @graphics.Color::red())
  ignore(
    renderer.draw_quality_pixmap_cached_with_renderer_resources(
      accent,
      0,
      1,
      1,
      1,
      resources,
      "accent",
      @graphics.Paint::new(),
      @graphics.ImageQuality::Fast,
    ),
  )
  assert_eq(resources.get_image_cache().len(), 1)
  assert_true(resources.get_image_cache().get("panel") is None)
  match resources.get_image_cache().get("accent") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), @graphics.Color::red())
    None => abort("expected cached accent pixmap")
  }
}

///|
test "Renderer quality cached BMP image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(4, 1)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let panel = @graphics.Pixmap::new(1, 1)
  panel.set_pixel(0, 0, @graphics.Color::green())

  match
    renderer.draw_quality_bmp_bytes_cached_with_renderer_resources(
      panel.to_bmp_bytes(),
      0,
      0,
      2,
      1,
      resources,
      "panel",
      @graphics.Paint::new(),
      @graphics.ImageQuality::Fast,
    ) {
    Ok(first) => assert_true(first.did_decode_pixmap())
    Err(_) => abort("expected cached quality BMP draw")
  }
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), @graphics.Color::green())

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_quality_bmp_bytes_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      2,
      0,
      2,
      1,
      resources,
      "panel",
      @graphics.Paint::new(),
      @graphics.ImageQuality::Fast,
    ) {
    Ok(second) => assert_true(second.did_hit_cache())
    Err(_) => abort("expected cached quality BMP hit")
  }
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), @graphics.Color::green())
  assert_eq(canvas.get_pixmap().get_pixel(3, 0), @graphics.Color::green())
}

///|
test "Renderer cached BMP nine-patch image path uses RendererResources" {
  let canvas = @graphics.Canvas::new(5, 5)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 1, 1)
  let panel = make_renderer_test_nine_patch_source()
  let insets = @graphics.NinePatchInsets::new(left=1, top=1, right=1, bottom=1)

  match
    renderer.draw_nine_patch_bmp_bytes_cached_with_renderer_resources(
      panel.to_bmp_bytes(),
      0,
      0,
      5,
      5,
      insets,
      resources,
      "panel",
      @graphics.Paint::new(),
      @graphics.ImageSampling::Nearest,
    ) {
    Ok(first) => {
      assert_true(first.did_decode_pixmap())
      assert_true(!first.did_hit_cache())
    }
    Err(_) => abort("expected cached BMP nine-patch draw")
  }
  assert_eq(resources.get_image_cache().len(), 1)
  assert_eq(
    canvas.get_pixmap().get_pixel(2, 2),
    @graphics.Color::new(r=50, g=0, b=0),
  )

  canvas.clear(@graphics.Color::white())
  match
    renderer.draw_quality_nine_patch_bmp_bytes_cached_with_renderer_resources(
      Bytes::from_array([0, 0]),
      0,
      0,
      5,
      5,
      insets,
      resources,
      "panel",
      @graphics.Paint::new(),
      @graphics.ImageQuality::Fast,
    ) {
    Ok(second) => {
      assert_true(!second.did_decode_pixmap())
      assert_true(second.did_hit_cache())
    }
    Err(_) => abort("expected cached BMP nine-patch hit")
  }
  assert_eq(
    canvas.get_pixmap().get_pixel(4, 4),
    @graphics.Color::new(r=90, g=0, b=0),
  )

  match
    renderer.draw_nine_patch_bmp_bytes_cached_with_renderer_resources(
      Bytes::from_array([66, 77]),
      0,
      0,
      5,
      5,
      insets,
      resources,
      "broken",
      @graphics.Paint::new(),
      @graphics.ImageSampling::Nearest,
    ) {
    Err(@graphics.PixmapDecodeError::UnexpectedEndOfData(0, 54, 2)) => ()
    _ => abort("expected cached BMP nine-patch decode error")
  }
  assert_true(!resources.contains_image("broken"))
}

///|
test "Renderer cached font bytes path uses RendererResources" {
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_font_capacity(16, 16, 1, 1, 2, 1)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )

  let first = match
    renderer.draw_font_bytes_cached_with_renderer_resources(
      make_minimal_ttf(),
      "A",
      1.0,
      1.0,
      config,
      resources,
      "ui-font",
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached font text draw")
  }
  assert_true(first.did_parse_font())
  assert_true(!first.did_hit_font_cache())
  assert_true(first.did_render_mask())
  assert_true(!first.did_hit_text_cache())
  assert_true(first.get_text_result().did_render_mask())
  assert_eq(resources.get_font_face_cache().len(), 1)
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), @graphics.Color::black())

  canvas.clear(@graphics.Color::white())
  let second = match
    renderer.draw_font_bytes_cached_with_renderer_resources(
      b"not a font",
      "O",
      1.0,
      1.0,
      config,
      resources,
      "ui-font",
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached font hit to skip invalid bytes")
  }
  assert_true(!second.did_parse_font())
  assert_true(second.did_hit_font_cache())
  assert_true(second.did_hit_text_cache())
  assert_eq(resources.get_font_face_cache().len(), 1)
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), @graphics.Color::black())
}

///|
test "Renderer cached font atlas path uses RendererResources" {
  let canvas = @graphics.Canvas::new(24, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_font_capacity(16, 16, 1, 4, 4, 1)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )

  let first = match
    renderer.draw_font_bytes_atlas_with_renderer_resources(
      make_minimal_ttf(),
      "AA",
      1.0,
      1.0,
      config,
      resources,
      "ui-font",
      "fixture",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached font atlas draw")
  }
  assert_true(first.did_parse_font())
  assert_eq(first.get_glyph_count(), 2)
  assert_eq(first.get_drawn_glyph_count(), 2)
  assert_eq(first.get_skipped_glyph_count(), 0)
  assert_eq(first.get_rasterized_glyph_count(), 1)
  assert_eq(first.get_cache_hit_count(), 1)
  assert_eq(first.get_atlas_inserted_count(), 1)
  assert_eq(first.get_atlas_hit_count(), 1)
  assert_true(!first.did_clear_atlas())
  assert_eq(first.get_atlas_result().get_glyph_count(), 2)

  canvas.clear(@graphics.Color::white())
  let second = match
    renderer.draw_font_bytes_atlas_with_renderer_resources(
      b"not a font",
      "AA",
      1.0,
      1.0,
      config,
      resources,
      "ui-font",
      "fixture",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached font hit to skip invalid bytes")
  }
  assert_true(!second.did_parse_font())
  assert_true(second.did_hit_font_cache())
  assert_eq(second.get_rasterized_glyph_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(second.get_atlas_inserted_count(), 0)
  assert_eq(second.get_atlas_hit_count(), 2)
  assert_eq(resources.get_font_face_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_atlas().len(), 1)
}

///|
test "Renderer cached font bytes path preserves parse errors" {
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::new(16, 16)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  match
    renderer.draw_font_bytes_cached_with_renderer_resources(
      b"not a font",
      "A",
      1.0,
      1.0,
      config,
      resources,
      "bad-font",
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Err(@text.FontParseError::UnexpectedEndOfData(0, 12, 10)) => ()
    _ => abort("expected checked parser error")
  }
  assert_true(resources.get_font_face_cache().is_empty())
  assert_true(resources.get_text_mask_cache().is_empty())
}

///|
test "Renderer cached font bytes fallback path uses RendererResources" {
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_font_capacity(16, 16, 2, 4, 4, 1)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = match
    renderer.draw_font_bytes_fallback_line_cached_with_renderer_resources(
      [
        FontBytesFallbackSource::new("primary", make_ttf_for_codes([65])),
        FontBytesFallbackSource::new("fallback", make_ttf_for_codes([66])),
      ],
      "ABZ",
      1.0,
      1.0,
      config,
      resources,
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached fallback font-byte draw")
  }
  assert_eq(first.get_parsed_font_count(), 2)
  assert_eq(first.get_font_cache_hit_count(), 0)
  assert_eq(first.get_span_count(), 3)
  assert_eq(first.get_drawn_span_count(), 2)
  assert_eq(first.get_skipped_span_count(), 1)
  assert_eq(first.get_missing_span_count(), 1)
  assert_eq(first.get_missing_char_count(), 1)
  assert_true(first.has_missing_glyphs())
  assert_eq(first.get_advance_width(), 26.0)
  assert_eq(first.get_rendered_mask_count(), 2)
  assert_eq(first.get_text_cache_hit_count(), 0)
  assert_eq(resources.get_font_face_cache().len(), 2)
  assert_eq(resources.get_text_mask_cache().len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))

  canvas.clear(@graphics.Color::white())
  let second = match
    renderer.draw_font_bytes_fallback_line_cached_with_renderer_resources(
      [
        FontBytesFallbackSource::new("primary", b"not a font"),
        FontBytesFallbackSource::new("fallback", b"also not a font"),
      ],
      "ABZ",
      1.0,
      1.0,
      config,
      resources,
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached font hits to skip invalid bytes")
  }
  assert_eq(second.get_parsed_font_count(), 0)
  assert_eq(second.get_font_cache_hit_count(), 2)
  assert_eq(second.get_rendered_mask_count(), 0)
  assert_eq(second.get_text_cache_hit_count(), 2)
  assert_eq(resources.get_font_face_cache().len(), 2)
  assert_eq(resources.get_text_mask_cache().len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
test "Renderer cached font bytes fallback atlas path uses RendererResources" {
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_font_capacity(24, 12, 2, 4, 4, 1)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = match
    renderer.draw_font_bytes_fallback_line_atlas_with_renderer_resources(
      [
        FontBytesFallbackSource::new("primary", make_ttf_for_codes([65])),
        FontBytesFallbackSource::new("fallback", make_ttf_for_codes([66])),
      ],
      "ABZ",
      1.0,
      1.0,
      config,
      resources,
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached fallback font-byte atlas draw")
  }
  assert_eq(first.get_parsed_font_count(), 2)
  assert_eq(first.get_font_cache_hit_count(), 0)
  assert_eq(first.get_span_count(), 3)
  assert_eq(first.get_drawn_span_count(), 2)
  assert_eq(first.get_skipped_span_count(), 1)
  assert_eq(first.get_missing_span_count(), 1)
  assert_eq(first.get_missing_char_count(), 1)
  assert_true(first.has_missing_glyphs())
  assert_eq(first.get_advance_width(), 26.0)
  assert_eq(first.get_atlas_result().get_glyph_count(), 2)
  assert_eq(first.get_glyph_count(), 2)
  assert_eq(first.get_drawn_glyph_count(), 2)
  assert_eq(first.get_rasterized_glyph_count(), 2)
  assert_eq(first.get_cache_hit_count(), 0)
  assert_eq(first.get_atlas_inserted_count(), 2)
  assert_eq(first.get_atlas_hit_count(), 0)
  assert_eq(resources.get_font_face_cache().len(), 2)
  assert_eq(resources.get_glyph_mask_cache().len(), 2)
  assert_eq(resources.get_glyph_mask_atlas().len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))

  canvas.clear(@graphics.Color::white())
  let second = match
    renderer.draw_font_bytes_fallback_line_atlas_with_renderer_resources(
      [
        FontBytesFallbackSource::new("primary", b"not a font"),
        FontBytesFallbackSource::new("fallback", b"also not a font"),
      ],
      "ABZ",
      1.0,
      1.0,
      config,
      resources,
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Ok(result) => result
    Err(_) => abort("expected cached fallback atlas font hits")
  }
  assert_eq(second.get_parsed_font_count(), 0)
  assert_eq(second.get_font_cache_hit_count(), 2)
  assert_eq(second.get_span_count(), 3)
  assert_eq(second.get_missing_span_count(), 1)
  assert_true(second.has_missing_glyphs())
  assert_eq(second.get_rasterized_glyph_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(second.get_atlas_inserted_count(), 0)
  assert_eq(second.get_atlas_hit_count(), 2)
  assert_eq(resources.get_font_face_cache().len(), 2)
  assert_eq(resources.get_glyph_mask_cache().len(), 2)
  assert_eq(resources.get_glyph_mask_atlas().len(), 2)
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
test "Renderer cached font bytes fallback path preserves parse errors" {
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::new(16, 16)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  match
    renderer.draw_font_bytes_fallback_line_cached_with_renderer_resources(
      [
        FontBytesFallbackSource::new("primary", make_ttf_for_codes([65])),
        FontBytesFallbackSource::new("bad-fallback", b"not a font"),
      ],
      "AB",
      1.0,
      1.0,
      config,
      resources,
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ) {
    Err(@text.FontParseError::UnexpectedEndOfData(0, 12, 10)) => ()
    _ => abort("expected checked parser error")
  }
  assert_true(resources.get_text_mask_cache().is_empty())
  assert_true(!pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
test "Renderer::draw_text_face_cached_with_resources reuses text masks" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererTextResources::with_capacities(16, 16, 1, 2)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = renderer.draw_text_face_cached_with_resources(
    face,
    "A",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_true(first.did_render_mask())
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), @graphics.Color::black())

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_face_cached_with_resources(
    face,
    "O",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_true(second.did_hit_cache())
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), @graphics.Color::black())

  ignore(
    renderer.draw_text_face_cached_with_resources(
      face,
      "O",
      1.0,
      1.0,
      config,
      resources,
      "other-label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ),
  )
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_true(resources.get_text_mask_cache().get("label") is None)
}

///|
test "Renderer cached text path uses RendererResources" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 1, 2, 2)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = renderer.draw_text_face_cached_with_renderer_resources(
    face,
    "A",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_true(first.did_render_mask())
  assert_eq(resources.get_text_mask_cache().len(), 1)

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_face_cached_with_renderer_resources(
    face,
    "O",
    1.0,
    1.0,
    config,
    resources,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_true(second.did_hit_cache())
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), @graphics.Color::black())
}

///|
test "Renderer::draw_text_face_atlas_with_resources reuses glyph resources" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(24, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererTextResources::with_capacities(16, 16, 4, 4)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = renderer.draw_text_face_atlas_with_resources(
    face,
    "AA",
    1.0,
    1.0,
    config,
    resources,
    "fixture",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(first.get_glyph_count(), 2)
  assert_eq(first.get_drawn_glyph_count(), 2)
  assert_eq(first.get_rasterized_glyph_count(), 1)
  assert_eq(first.get_cache_hit_count(), 1)
  assert_eq(first.get_atlas_inserted_count(), 1)
  assert_eq(first.get_atlas_hit_count(), 1)
  assert_eq(resources.get_glyph_mask_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_atlas().len(), 1)

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_face_atlas_with_resources(
    face,
    "AA",
    1.0,
    1.0,
    config,
    resources,
    "fixture",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(second.get_rasterized_glyph_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(second.get_atlas_inserted_count(), 0)
  assert_eq(second.get_atlas_hit_count(), 2)
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), @graphics.Color::black())
  assert_eq(canvas.get_pixmap().get_pixel(11, 1), @graphics.Color::black())
}

///|
test "Renderer atlas text path uses RendererResources" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(24, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::with_capacities(16, 16, 4, 4, 2)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let first = renderer.draw_text_face_atlas_with_renderer_resources(
    face,
    "AA",
    1.0,
    1.0,
    config,
    resources,
    "fixture",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(first.get_rasterized_glyph_count(), 1)
  assert_eq(first.get_cache_hit_count(), 1)
  assert_eq(first.get_atlas_inserted_count(), 1)
  assert_eq(first.get_atlas_hit_count(), 1)

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_face_atlas_with_renderer_resources(
    face,
    "AA",
    1.0,
    1.0,
    config,
    resources,
    "fixture",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_eq(second.get_rasterized_glyph_count(), 0)
  assert_eq(second.get_cache_hit_count(), 2)
  assert_eq(second.get_atlas_inserted_count(), 0)
  assert_eq(second.get_atlas_hit_count(), 2)
  assert_eq(resources.get_glyph_mask_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_atlas().len(), 1)
}

///|
test "RendererTextResources::clear drops all text draw resources" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(24, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererTextResources::new(16, 16)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  ignore(
    renderer.draw_text_face_cached_with_resources(
      face,
      "A",
      1.0,
      1.0,
      config,
      resources,
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ),
  )
  ignore(
    renderer.draw_text_face_atlas_with_resources(
      face,
      "A",
      1.0,
      1.0,
      config,
      resources,
      "fixture",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ),
  )
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_atlas().len(), 1)

  resources.clear()
  assert_true(resources.get_text_mask_cache().is_empty())
  assert_true(resources.get_glyph_mask_cache().is_empty())
  assert_true(resources.get_glyph_mask_atlas().is_empty())
}

///|
test "RendererResources::clear drops font text and image resources" {
  let canvas = @graphics.Canvas::new(24, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let resources = RendererResources::new(16, 16)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
  )
  let icon = @graphics.Pixmap::new(1, 1)
  icon.set_pixel(0, 0, @graphics.Color::green())
  ignore(resources.get_image_cache().insert("icon", icon))
  ignore(
    renderer.draw_font_bytes_cached_with_renderer_resources(
      make_minimal_ttf(),
      "A",
      1.0,
      1.0,
      config,
      resources,
      "ui-font",
      "label",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ),
  )
  ignore(
    renderer.draw_font_bytes_atlas_with_renderer_resources(
      b"not a font",
      "A",
      1.0,
      1.0,
      config,
      resources,
      "ui-font",
      "fixture",
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    ),
  )
  assert_eq(resources.get_font_face_cache().len(), 1)
  assert_eq(resources.get_text_mask_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_cache().len(), 1)
  assert_eq(resources.get_glyph_mask_atlas().len(), 1)
  assert_eq(resources.get_image_cache().len(), 1)

  resources.clear()
  assert_true(resources.get_font_face_cache().is_empty())
  assert_true(resources.get_text_mask_cache().is_empty())
  assert_true(resources.get_glyph_mask_cache().is_empty())
  assert_true(resources.get_glyph_mask_atlas().is_empty())
  assert_true(resources.get_image_cache().is_empty())
}

///|
test "Renderer::draw_text_face_cached reuses rendered text masks" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  let text_cache = @text.TextMaskCache::new()
  let first = renderer.draw_text_face_cached(
    face,
    "A",
    1.0,
    1.0,
    config,
    text_cache,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_true(first.did_render_mask())
  assert_true(!first.did_hit_cache())
  assert_eq(text_cache.len(), 1)
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())

  canvas.clear(@graphics.Color::white())
  let second = renderer.draw_text_face_cached(
    face,
    "O",
    1.0,
    1.0,
    config,
    text_cache,
    "label",
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_true(!second.did_render_mask())
  assert_true(second.did_hit_cache())
  assert_eq(text_cache.len(), 1)
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
}

///|
test "Renderer::draw_text preserves holes in parsed TTF glyphs" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  renderer.draw_text_face(
    face,
    "O",
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(2, 2), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(5, 5), @graphics.Color::white())
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
}

///|
test "Renderer::draw_text_face applies layout alignment" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(36, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=30.0,
    font_size=10.0,
    line_height=10.0,
    alignment=@text.TextAlign::Right,
  )
  renderer.draw_text_face(
    face,
    "A",
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(20, 1), @graphics.Color::white())
  assert_eq(pixmap.get_pixel(21, 1), @graphics.Color::black())
}

///|
test "Renderer::draw_text_face applies explicit newlines" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(12, 24)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=30.0,
    font_size=10.0,
    line_height=10.0,
  )
  renderer.draw_text_face(
    face,
    "A\nA",
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(1, 11), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
}

///|
test "Renderer::draw_text_face applies letter spacing" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(26, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=40.0,
    font_size=10.0,
    line_height=10.0,
    letter_spacing=3.0,
  )
  renderer.draw_text_face(
    face,
    "AA",
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(11, 1), @graphics.Color::white())
  assert_eq(pixmap.get_pixel(14, 1), @graphics.Color::black())
}

///|
test "Renderer::draw_text_face wraps after trailing space" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let canvas = @graphics.Canvas::new(14, 24)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  let config = @text.LayoutConfig::new(
    max_width=12.0,
    font_size=10.0,
    line_height=10.0,
  )
  renderer.draw_text_face(
    face,
    "A A",
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(11, 1), @graphics.Color::white())
  assert_eq(pixmap.get_pixel(1, 11), @graphics.Color::black())
}

///|
test "Renderer::draw_text covers a parsed TTF glyph matrix" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  assert_matrix_glyph(face, "A", (2, 2), None, config)
  assert_matrix_glyph(face, "O", (2, 2), Some((5, 5)), config)
  assert_matrix_glyph(face, "D", (2, 2), Some((6, 5)), config)
  assert_matrix_glyph(face, "o", (2, 5), Some((5, 5)), config)
  assert_matrix_glyph(face, "d", (2, 3), Some((6, 5)), config)
  assert_matrix_glyph(face, "0", (2, 2), Some((5, 5)), config)
  assert_matrix_glyph(face, "2", (5, 10), None, config)
  assert_matrix_glyph(face, "3", (7, 3), None, config)
  assert_matrix_glyph(face, "8", (2, 2), Some((5, 3)), config)
  assert_matrix_glyph(face, "i", (2, 3), Some((2, 6)), config)
  assert_matrix_glyph(face, "i", (2, 9), Some((2, 6)), config)
}

///|
test "Renderer::draw_text covers printable ASCII from parsed TTF bytes" {
  let face = unwrap_font_face(@text.FontFace::from_bytes(make_minimal_ttf()))
  let config = @text.LayoutConfig::new(
    max_width=20.0,
    font_size=10.0,
    line_height=10.0,
  )
  let ascii = printable_ascii_string()
  let mut glyph_count = 0
  for ch in ascii {
    let codepoint = ch.to_int()
    let glyph_id = face.char_to_glyph(codepoint)
    assert_true(glyph_id > 0)
    assert_eq(glyph_id, codepoint - 0x20 + 1)
    if ch is ' ' {
      assert_ascii_space_glyph(face, ch.to_string(), glyph_id, config)
    } else {
      assert_ascii_visible_glyph(face, ch.to_string(), glyph_id, config)
    }
    glyph_count = glyph_count + 1
  }
  assert_eq(glyph_count, printable_ascii_count())
}

///|
fn make_renderer_test_nine_patch_source() -> @graphics.Pixmap {
  let src = @graphics.Pixmap::new(3, 3)
  src.set_pixel(0, 0, @graphics.Color::new(r=10, g=0, b=0))
  src.set_pixel(1, 0, @graphics.Color::new(r=20, g=0, b=0))
  src.set_pixel(2, 0, @graphics.Color::new(r=30, g=0, b=0))
  src.set_pixel(0, 1, @graphics.Color::new(r=40, g=0, b=0))
  src.set_pixel(1, 1, @graphics.Color::new(r=50, g=0, b=0))
  src.set_pixel(2, 1, @graphics.Color::new(r=60, g=0, b=0))
  src.set_pixel(0, 2, @graphics.Color::new(r=70, g=0, b=0))
  src.set_pixel(1, 2, @graphics.Color::new(r=80, g=0, b=0))
  src.set_pixel(2, 2, @graphics.Color::new(r=90, g=0, b=0))
  src
}

///|
fn make_renderer_test_tile_source() -> @graphics.Pixmap {
  let src = @graphics.Pixmap::new(2, 1)
  src.set_pixel(0, 0, @graphics.Color::red())
  src.set_pixel(1, 0, @graphics.Color::green())
  src
}

///|
fn make_renderer_test_bicubic_source() -> @graphics.Pixmap {
  let src = @graphics.Pixmap::new(4, 1)
  src.set_pixel(0, 0, @graphics.Color::black())
  src.set_pixel(1, 0, @graphics.Color::red())
  src.set_pixel(2, 0, @graphics.Color::black())
  src.set_pixel(3, 0, @graphics.Color::red())
  src
}

///|
fn assert_matrix_glyph(
  face : @text.FontFace,
  text : String,
  filled : (Int, Int),
  hole : (Int, Int)?,
  config : @text.LayoutConfig,
) -> Unit raise {
  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  renderer.draw_text_face(
    face,
    text,
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  let pixmap = renderer.get_canvas().get_pixmap()
  let (filled_x, filled_y) = filled
  assert_eq(pixmap.get_pixel(filled_x, filled_y), @graphics.Color::black())
  match hole {
    Some((hole_x, hole_y)) =>
      assert_eq(
        pixmap.get_pixel(hole_x, hole_y),
        @graphics.Color::white(),
        msg="hole pixel should stay white for " + text,
      )
    None => ()
  }
  assert_eq(pixmap.get_pixel(0, 0), @graphics.Color::white())
}

///|
fn assert_ascii_visible_glyph(
  face : @text.FontFace,
  text : String,
  glyph_id : Int,
  config : @text.LayoutConfig,
) -> Unit raise {
  let layout = @text.TextLayout::layout(face, text, config)
  assert_eq(layout.run_count(), 1)
  assert_eq(layout.get_runs()[0].glyph_count(), 1)
  assert_eq(layout.get_runs()[0].get_glyphs()[0].glyph_id, glyph_id)

  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  renderer.draw_text_face(
    face,
    text,
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_true(pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
fn assert_ascii_space_glyph(
  face : @text.FontFace,
  text : String,
  glyph_id : Int,
  config : @text.LayoutConfig,
) -> Unit raise {
  let layout = @text.TextLayout::layout(face, text, config)
  assert_eq(layout.run_count(), 1)
  assert_eq(layout.get_runs()[0].glyph_count(), 1)
  assert_eq(layout.get_runs()[0].get_glyphs()[0].glyph_id, glyph_id)
  assert_eq(layout.get_runs()[0].get_width(), 5.0)

  let canvas = @graphics.Canvas::new(12, 12)
  canvas.clear(@graphics.Color::white())
  let renderer = Renderer::new(canvas)
  renderer.draw_text_face(
    face,
    text,
    1.0,
    1.0,
    config,
    @graphics.Paint::new().set_color(@graphics.Color::black()),
  )
  assert_true(!pixmap_has_ink(renderer.get_canvas().get_pixmap()))
}

///|
fn pixmap_has_ink(pixmap : @graphics.Pixmap) -> Bool {
  for y in 0..<pixmap.get_height() {
    for x in 0..<pixmap.get_width() {
      if pixmap.get_pixel(x, y) != @graphics.Color::white() {
        return true
      }
    }
  }
  false
}

///|
fn printable_ascii_string() -> String {
  let out = StringBuilder(size_hint=printable_ascii_count())
  for codepoint in 0x20..<=0x7E {
    out.write_char(codepoint.unsafe_to_char())
  }
  out.to_string()
}

///|
fn printable_ascii_count() -> Int {
  0x7E - 0x20 + 1
}

///|
fn unwrap_font_face(
  result : Result[@text.FontFace, @text.FontParseError],
) -> @text.FontFace {
  match result {
    Ok(face) => face
    Err(_) => abort("expected valid font face")
  }
}

///|
struct TestGlyph {
  codepoint : Int
  advance : Int
  bytes : Array[Byte]
}

///|
struct TestPoint {
  x : Int
  y : Int
  on_curve : Bool
}

///|
struct TestContour {
  points : Array[TestPoint]
}

///|
struct TestOutline {
  contours : Array[TestContour]
  xmin : Int
  ymin : Int
  xmax : Int
  ymax : Int
}

///|
fn make_minimal_ttf() -> Bytes {
  let glyphs = make_test_glyphs()
  make_ttf_with_glyphs(glyphs)
}

///|
fn make_ttf_for_codes(codepoints : Array[Int]) -> Bytes {
  let glyphs = []
  for codepoint in codepoints {
    glyphs.push(make_ascii_test_glyph(codepoint))
  }
  make_ttf_with_glyphs(glyphs)
}

///|
fn make_ttf_with_glyphs(glyphs : Array[TestGlyph]) -> Bytes {
  let tags : Array[Bytes] = [
    b"cmap", b"glyf", b"head", b"hhea", b"hmtx", b"loca", b"maxp",
  ]
  let tables = [
    make_cmap_table(glyphs),
    make_glyf_table(glyphs),
    make_head_table(),
    make_hhea_table(glyphs),
    make_hmtx_table(glyphs),
    make_loca_table(glyphs),
    make_maxp_table(glyphs),
  ]
  let offsets = []
  let mut current = 12 + tags.length() * 16
  for table in tables {
    offsets.push(current)
    current = align4(current + table.length())
  }

  let out : Array[Byte] = []
  append_u32(out, 0x00010000)
  append_u16(out, tags.length())
  append_u16(out, 0)
  append_u16(out, 0)
  append_u16(out, 0)

  for i in 0..<tags.length() {
    append_bytes(out, tags[i])
    append_u32(out, 0)
    append_u32(out, offsets[i])
    append_u32(out, tables[i].length())
  }

  for i in 0..<tables.length() {
    while out.length() < offsets[i] {
      append_byte(out, 0)
    }
    append_array(out, tables[i])
    pad4(out)
  }

  Bytes::from_array(out)
}

///|
fn make_test_glyphs() -> Array[TestGlyph] {
  let glyphs = []
  for codepoint in 0x20..<=0x7E {
    glyphs.push(make_ascii_test_glyph(codepoint))
  }
  glyphs.push({
    codepoint: 0xE000,
    advance: 10,
    bytes: make_small_square_glyph(),
  })
  glyphs
}

///|
fn make_ascii_test_glyph(codepoint : Int) -> TestGlyph {
  let bytes = match codepoint {
    0x20 => []
    65 => make_box_glyph()
    79 => make_ring_glyph()
    68 => make_d_glyph()
    111 => make_o_glyph()
    100 => make_lower_d_glyph()
    48 => make_ring_glyph()
    50 => make_two_glyph()
    51 => make_three_glyph()
    56 => make_eight_glyph()
    105 => make_composite_i_glyph()
    _ if codepoint >= 0x20 && codepoint <= 0x7E =>
      make_ascii_fallback_glyph(codepoint)
    _ => make_ascii_fallback_glyph(codepoint)
  }
  { codepoint, advance: if codepoint is 0x20 { 5 } else { 10 }, bytes }
}

///|
fn square_component_glyph_id() -> Int {
  printable_ascii_count() + 1
}

///|
fn make_head_table() -> Array[Byte] {
  let out : Array[Byte] = []
  append_u32(out, 0x00010000) // version
  append_u32(out, 0) // fontRevision
  append_u32(out, 0) // checkSumAdjustment
  append_u32(out, 0x5F0F3CF5) // magicNumber
  append_u16(out, 0) // flags
  append_u16(out, 10) // unitsPerEm
  append_zeroes(out, 16) // created + modified
  append_i16(out, 0) // xmin
  append_i16(out, 0) // ymin
  append_i16(out, 10) // xmax
  append_i16(out, 10) // ymax
  append_u16(out, 0) // macStyle
  append_u16(out, 0) // lowestRecPPEM
  append_i16(out, 2) // fontDirectionHint
  append_i16(out, 0) // indexToLocFormat: short
  append_i16(out, 0) // glyphDataFormat
  out
}

///|
fn make_hhea_table(glyphs : Array[TestGlyph]) -> Array[Byte] {
  let out : Array[Byte] = []
  append_u32(out, 0x00010000) // version
  append_i16(out, 10) // ascent
  append_i16(out, 0) // descent
  append_i16(out, 0) // lineGap
  append_u16(out, 10) // advanceWidthMax
  append_i16(out, 0) // minLeftSideBearing
  append_i16(out, 0) // minRightSideBearing
  append_i16(out, 10) // xMaxExtent
  append_i16(out, 1) // caretSlopeRise
  append_i16(out, 0) // caretSlopeRun
  append_i16(out, 0) // caretOffset
  append_zeroes(out, 8) // reserved
  append_i16(out, 0) // metricDataFormat
  append_u16(out, glyphs.length() + 1) // numOfLongHorMetrics
  out
}

///|
fn make_hmtx_table(glyphs : Array[TestGlyph]) -> Array[Byte] {
  let out : Array[Byte] = []
  append_u16(out, 0)
  append_i16(out, 0)
  for glyph in glyphs {
    append_u16(out, glyph.advance)
    append_i16(out, 0)
  }
  out
}

///|
fn make_maxp_table(glyphs : Array[TestGlyph]) -> Array[Byte] {
  let out : Array[Byte] = []
  append_u32(out, 0x00010000)
  append_u16(out, glyphs.length() + 1)
  out
}

///|
fn make_loca_table(glyphs : Array[TestGlyph]) -> Array[Byte] {
  let out : Array[Byte] = []
  append_u16(out, 0) // .notdef starts at 0 and is empty
  let mut offset = 0
  for glyph in glyphs {
    append_u16(out, offset / 2)
    offset = align2(offset + glyph.bytes.length())
  }
  append_u16(out, offset / 2)
  out
}

///|
fn make_glyf_table(glyphs : Array[TestGlyph]) -> Array[Byte] {
  let out : Array[Byte] = []
  for glyph in glyphs {
    append_array(out, glyph.bytes)
    while out.length() % 2 != 0 {
      append_byte(out, 0)
    }
  }
  out
}

///|
fn make_box_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 0, y: 10, on_curve: true },
          { x: 10, y: 10, on_curve: true },
          { x: 10, y: 0, on_curve: true },
          { x: 0, y: 0, on_curve: true },
        ],
      },
    ],
    xmin: 0,
    ymin: 0,
    xmax: 10,
    ymax: 10,
  })
}

///|
fn make_ring_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 0, y: 10, on_curve: true },
          { x: 10, y: 10, on_curve: true },
          { x: 10, y: 0, on_curve: true },
          { x: 0, y: 0, on_curve: true },
        ],
      },
      {
        points: [
          { x: 3, y: 7, on_curve: true },
          { x: 3, y: 3, on_curve: true },
          { x: 7, y: 3, on_curve: true },
          { x: 7, y: 7, on_curve: true },
        ],
      },
    ],
    xmin: 0,
    ymin: 0,
    xmax: 10,
    ymax: 10,
  })
}

///|
fn make_d_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 0, y: 10, on_curve: true },
          { x: 10, y: 10, on_curve: true },
          { x: 10, y: 0, on_curve: true },
          { x: 0, y: 0, on_curve: true },
        ],
      },
      {
        points: [
          { x: 4, y: 7, on_curve: true },
          { x: 4, y: 3, on_curve: true },
          { x: 8, y: 3, on_curve: true },
          { x: 8, y: 7, on_curve: true },
        ],
      },
    ],
    xmin: 0,
    ymin: 0,
    xmax: 10,
    ymax: 10,
  })
}

///|
fn make_eight_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 0, y: 10, on_curve: true },
          { x: 10, y: 10, on_curve: true },
          { x: 10, y: 0, on_curve: true },
          { x: 0, y: 0, on_curve: true },
        ],
      },
      {
        points: [
          { x: 3, y: 8, on_curve: true },
          { x: 3, y: 6, on_curve: true },
          { x: 7, y: 6, on_curve: true },
          { x: 7, y: 8, on_curve: true },
        ],
      },
      {
        points: [
          { x: 3, y: 4, on_curve: true },
          { x: 3, y: 2, on_curve: true },
          { x: 7, y: 2, on_curve: true },
          { x: 7, y: 4, on_curve: true },
        ],
      },
    ],
    xmin: 0,
    ymin: 0,
    xmax: 10,
    ymax: 10,
  })
}

///|
fn make_o_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 5, y: 10, on_curve: true },
          { x: 9, y: 10, on_curve: false },
          { x: 10, y: 5, on_curve: true },
          { x: 10, y: 1, on_curve: false },
          { x: 5, y: 0, on_curve: true },
          { x: 1, y: 0, on_curve: false },
          { x: 0, y: 5, on_curve: true },
          { x: 0, y: 9, on_curve: false },
        ],
      },
      {
        points: [
          { x: 5, y: 7, on_curve: true },
          { x: 3, y: 7, on_curve: false },
          { x: 3, y: 5, on_curve: true },
          { x: 3, y: 3, on_curve: false },
          { x: 5, y: 3, on_curve: true },
          { x: 7, y: 3, on_curve: false },
          { x: 7, y: 5, on_curve: true },
          { x: 7, y: 7, on_curve: false },
        ],
      },
    ],
    xmin: 0,
    ymin: 0,
    xmax: 10,
    ymax: 10,
  })
}

///|
fn make_lower_d_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 1, y: 10, on_curve: true },
          { x: 4, y: 10, on_curve: true },
          { x: 4, y: 7, on_curve: true },
          { x: 8, y: 7, on_curve: false },
          { x: 9, y: 4, on_curve: true },
          { x: 8, y: 1, on_curve: false },
          { x: 4, y: 1, on_curve: true },
          { x: 4, y: 0, on_curve: true },
          { x: 1, y: 0, on_curve: true },
        ],
      },
      {
        points: [
          { x: 5, y: 6, on_curve: true },
          { x: 4, y: 6, on_curve: false },
          { x: 4, y: 4, on_curve: true },
          { x: 4, y: 2, on_curve: false },
          { x: 6, y: 2, on_curve: true },
          { x: 8, y: 2, on_curve: false },
          { x: 8, y: 4, on_curve: true },
          { x: 8, y: 6, on_curve: false },
        ],
      },
    ],
    xmin: 1,
    ymin: 0,
    xmax: 9,
    ymax: 10,
  })
}

///|
fn make_ascii_fallback_glyph(codepoint : Int) -> Array[Byte] {
  let stem_x = 1 + codepoint % 4
  let stem_top = 2 + codepoint % 3
  let bar_y = 1 + codepoint % 7
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: stem_x, y: stem_top + 5, on_curve: true },
          { x: stem_x + 2, y: stem_top + 5, on_curve: true },
          { x: stem_x + 2, y: 0, on_curve: true },
          { x: stem_x, y: 0, on_curve: true },
        ],
      },
      {
        points: [
          { x: 1, y: bar_y + 1, on_curve: true },
          { x: 9, y: bar_y + 1, on_curve: true },
          { x: 9, y: bar_y, on_curve: true },
          { x: 1, y: bar_y, on_curve: true },
        ],
      },
    ],
    xmin: 1,
    ymin: 0,
    xmax: 9,
    ymax: stem_top + 5,
  })
}

///|
fn make_two_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 1, y: 8, on_curve: true },
          { x: 3, y: 10, on_curve: false },
          { x: 6, y: 10, on_curve: true },
          { x: 9, y: 10, on_curve: false },
          { x: 9, y: 7, on_curve: true },
          { x: 9, y: 5, on_curve: false },
          { x: 6, y: 4, on_curve: true },
          { x: 3, y: 2, on_curve: true },
          { x: 9, y: 2, on_curve: true },
          { x: 9, y: 0, on_curve: true },
          { x: 1, y: 0, on_curve: true },
          { x: 1, y: 2, on_curve: true },
          { x: 5, y: 5, on_curve: true },
          { x: 6, y: 6, on_curve: true },
          { x: 6, y: 7, on_curve: true },
          { x: 4, y: 7, on_curve: true },
          { x: 3, y: 6, on_curve: true },
          { x: 1, y: 6, on_curve: true },
        ],
      },
    ],
    xmin: 1,
    ymin: 0,
    xmax: 9,
    ymax: 10,
  })
}

///|
fn make_three_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 1, y: 9, on_curve: true },
          { x: 3, y: 10, on_curve: false },
          { x: 6, y: 10, on_curve: true },
          { x: 9, y: 10, on_curve: false },
          { x: 9, y: 7, on_curve: true },
          { x: 9, y: 6, on_curve: false },
          { x: 7, y: 5, on_curve: true },
          { x: 9, y: 4, on_curve: false },
          { x: 9, y: 1, on_curve: true },
          { x: 9, y: 0, on_curve: false },
          { x: 5, y: 0, on_curve: true },
          { x: 2, y: 0, on_curve: false },
          { x: 1, y: 2, on_curve: true },
          { x: 3, y: 3, on_curve: true },
          { x: 5, y: 2, on_curve: true },
          { x: 6, y: 3, on_curve: true },
          { x: 6, y: 4, on_curve: true },
          { x: 4, y: 4, on_curve: true },
          { x: 4, y: 6, on_curve: true },
          { x: 6, y: 6, on_curve: true },
          { x: 6, y: 7, on_curve: true },
          { x: 5, y: 8, on_curve: true },
          { x: 3, y: 8, on_curve: true },
        ],
      },
    ],
    xmin: 1,
    ymin: 0,
    xmax: 9,
    ymax: 10,
  })
}

///|
fn make_small_square_glyph() -> Array[Byte] {
  make_simple_glyph({
    contours: [
      {
        points: [
          { x: 1, y: 3, on_curve: true },
          { x: 4, y: 3, on_curve: true },
          { x: 4, y: 0, on_curve: true },
          { x: 1, y: 0, on_curve: true },
        ],
      },
    ],
    xmin: 1,
    ymin: 0,
    xmax: 4,
    ymax: 3,
  })
}

///|
fn make_composite_i_glyph() -> Array[Byte] {
  let out : Array[Byte] = []
  append_i16(out, -1) // numberOfContours: composite glyph
  append_i16(out, 0) // xmin
  append_i16(out, 0) // ymin
  append_i16(out, 10) // xmax
  append_i16(out, 10) // ymax

  append_u16(out, 0x0023) // words, xy values, more components
  append_u16(out, square_component_glyph_id()) // small square component glyph
  append_i16(out, 0)
  append_i16(out, 0)

  append_u16(out, 0x0003) // words, xy values
  append_u16(out, square_component_glyph_id()) // small square component glyph
  append_i16(out, 0)
  append_i16(out, 6)
  out
}

///|
fn make_simple_glyph(glyph : TestOutline) -> Array[Byte] {
  let out : Array[Byte] = []
  append_i16(out, glyph.contours.length())
  append_i16(out, glyph.xmin)
  append_i16(out, glyph.ymin)
  append_i16(out, glyph.xmax)
  append_i16(out, glyph.ymax)

  let points : Array[TestPoint] = []
  let mut end_point = -1
  for contour in glyph.contours {
    for point in contour.points {
      points.push(point)
      end_point = end_point + 1
    }
    append_u16(out, end_point)
  }
  append_u16(out, 0) // instructionLength

  let flags : Array[Int] = []
  let x_bytes : Array[Byte] = []
  let y_bytes : Array[Byte] = []
  let mut prev_x = 0
  let mut prev_y = 0
  for point in points {
    let dx = point.x - prev_x
    let dy = point.y - prev_y
    let mut flag = if point.on_curve { 0x01 } else { 0 }
    flag = flag.lor(encode_x_delta(dx, x_bytes))
    flag = flag.lor(encode_y_delta(dy, y_bytes))
    flags.push(flag)
    prev_x = point.x
    prev_y = point.y
  }

  for flag in flags {
    append_byte(out, flag)
  }
  append_array(out, x_bytes)
  append_array(out, y_bytes)
  while out.length() % 2 != 0 {
    append_byte(out, 0)
  }
  out
}

///|
fn encode_x_delta(delta : Int, out : Array[Byte]) -> Int {
  if delta == 0 {
    0x10
  } else if delta.abs() <= 255 {
    append_byte(out, delta.abs())
    if delta > 0 {
      0x12
    } else {
      0x02
    }
  } else {
    append_i16(out, delta)
    0
  }
}

///|
fn encode_y_delta(delta : Int, out : Array[Byte]) -> Int {
  if delta == 0 {
    0x20
  } else if delta.abs() <= 255 {
    append_byte(out, delta.abs())
    if delta > 0 {
      0x24
    } else {
      0x04
    }
  } else {
    append_i16(out, delta)
    0
  }
}

///|
fn make_cmap_table(glyphs : Array[TestGlyph]) -> Array[Byte] {
  let out : Array[Byte] = []
  append_u16(out, 0) // version
  append_u16(out, 1) // numTables
  append_u16(out, 3) // Windows platform
  append_u16(out, 10) // Unicode full repertoire
  append_u32(out, 12) // subtable offset
  append_u16(out, 12) // format
  append_u16(out, 0) // reserved
  append_u32(out, 16 + glyphs.length() * 12) // length
  append_u32(out, 0) // language
  append_u32(out, glyphs.length()) // nGroups
  for i in 0..<glyphs.length() {
    append_u32(out, glyphs[i].codepoint)
    append_u32(out, glyphs[i].codepoint)
    append_u32(out, i + 1)
  }
  out
}

///|
fn append_u16(out : Array[Byte], value : Int) -> Unit {
  append_byte(out, value >> 8)
  append_byte(out, value)
}

///|
fn append_i16(out : Array[Byte], value : Int) -> Unit {
  let unsigned = if value < 0 { value + 65536 } else { value }
  append_u16(out, unsigned)
}

///|
fn append_u32(out : Array[Byte], value : Int) -> Unit {
  append_byte(out, value >> 24)
  append_byte(out, value >> 16)
  append_byte(out, value >> 8)
  append_byte(out, value)
}

///|
fn append_byte(out : Array[Byte], value : Int) -> Unit {
  out.push(value.land(0xFF).to_byte())
}

///|
fn append_bytes(out : Array[Byte], bytes : Bytes) -> Unit {
  for i in 0..<bytes.length() {
    out.push(bytes[i])
  }
}

///|
fn append_array(out : Array[Byte], bytes : Array[Byte]) -> Unit {
  for byte in bytes {
    out.push(byte)
  }
}

///|
fn append_zeroes(out : Array[Byte], count : Int) -> Unit {
  for _ in 0..<count {
    append_byte(out, 0)
  }
}

///|
fn pad4(out : Array[Byte]) -> Unit {
  while out.length() % 4 != 0 {
    append_byte(out, 0)
  }
}

///|
fn align4(value : Int) -> Int {
  if value % 4 == 0 {
    value
  } else {
    value + 4 - value % 4
  }
}

///|
fn align2(value : Int) -> Int {
  if value % 2 == 0 {
    value
  } else {
    value + 1
  }
}
