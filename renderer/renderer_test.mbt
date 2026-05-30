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
  assert_true(result.did_clear_atlas())
  assert_eq(glyph_cache.len(), 2)
  assert_eq(atlas.len(), 1)
  assert_eq(pixmap.get_pixel(1, 1), @graphics.Color::black())
  assert_eq(pixmap.get_pixel(14, 4), @graphics.Color::black())
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
