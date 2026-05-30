///|
test "ShapingBuffer::new creates buffer" {
  let font = FontData::new(b"fake_font_data")
  let buffer = ShapingBuffer::new("Hello", font_size=16.0)
  let shaped = buffer.shape(font)
  assert_eq(shaped.glyph_count(), 5) // "Hello" has 5 characters
}

///|
test "ShapingBuffer::shape calculates width" {
  let font = FontData::new(b"fake_font_data")
  let buffer = ShapingBuffer::new("Hi", font_size=10.0)
  let shaped = buffer.shape(font)
  // Each char is 10.0 * 0.6 = 6 pixels wide
  assert_eq(shaped.get_width(), 12)
}

///|
test "ShapingBuffer::shape keeps LTR clusters in logical order" {
  let font = FontData::new(b"fake_font_data")
  let buffer = ShapingBuffer::new(
    "abc",
    direction=TextDirection::left_to_right(),
    font_size=10.0,
  )
  let shaped = buffer.shape(font)
  let glyphs = shaped.get_glyphs()
  let positions = shaped.get_positions()
  assert_eq(glyphs[0].glyph_id.to_int(), 0)
  assert_eq(glyphs[0].cluster, 0)
  assert_eq(glyphs[1].glyph_id.to_int(), 1)
  assert_eq(glyphs[1].cluster, 1)
  assert_eq(glyphs[2].glyph_id.to_int(), 2)
  assert_eq(glyphs[2].cluster, 2)
  assert_eq(positions[0].glyph_id.to_int(), 0)
}

///|
test "ShapingBuffer::shape reverses cluster order for basic RTL shaping" {
  let font = FontData::new(b"fake_font_data")
  let buffer = ShapingBuffer::new(
    "abc",
    direction=TextDirection::right_to_left(),
    font_size=10.0,
  )
  let shaped = buffer.shape(font)
  let glyphs = shaped.get_glyphs()
  let positions = shaped.get_positions()
  assert_eq(glyphs[0].glyph_id.to_int(), 2)
  assert_eq(glyphs[0].cluster, 2)
  assert_eq(glyphs[1].glyph_id.to_int(), 1)
  assert_eq(glyphs[1].cluster, 1)
  assert_eq(glyphs[2].glyph_id.to_int(), 0)
  assert_eq(glyphs[2].cluster, 0)
  assert_eq(positions[0].glyph_id.to_int(), 2)
  assert_eq(shaped.get_width(), 18)
}
