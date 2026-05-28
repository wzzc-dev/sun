///|
test "GlyphId::new creates glyph id" {
  let id = GlyphId::new(42)
  assert_eq(id.to_int(), 42)
}

///|
test "GlyphPosition::new with defaults" {
  let pos = GlyphPosition::new(glyph_id=GlyphId::new(1))
  assert_eq(pos.x_advance, 0)
  assert_eq(pos.y_advance, 0)
}

///|
test "GlyphInfo::new creates glyph info" {
  let info = GlyphInfo::new(glyph_id=GlyphId::new(5), cluster=10)
  assert_eq(info.glyph_id.to_int(), 5)
  assert_eq(info.cluster, 10)
}
