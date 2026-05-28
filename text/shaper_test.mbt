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
