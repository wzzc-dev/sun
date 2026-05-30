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

///|
test "SimpleGlyph constructors expose public glyph fixtures" {
  let p0 = GlyphPoint::new(x=0, y=0)
  let p1 = GlyphPoint::new(x=10, y=0, on_curve=false)
  assert_eq(p0.x, 0)
  assert_eq(p0.y, 0)
  assert_true(p0.on_curve)
  assert_true(!p1.on_curve)

  let contour = GlyphContour::new([p0, p1, GlyphPoint::new(x=10, y=10)])
  assert_eq(contour.points.length(), 3)

  let glyph = SimpleGlyph::new([contour], xmin=0, ymin=0, xmax=10, ymax=10)
  assert_eq(glyph.contours.length(), 1)
  assert_eq(glyph.xmax, 10)
  assert_eq(glyph.ymax, 10)
}
