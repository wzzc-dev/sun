///|
/// Glyph ID type (wraps Int)
pub struct GlyphId {
  id : Int
} derive(Eq, Debug)

///|
/// Create a glyph ID
pub fn GlyphId::new(id : Int) -> GlyphId {
  { id, }
}

///|
/// Get the underlying ID value
pub fn GlyphId::to_int(self : GlyphId) -> Int {
  self.id
}

///|
/// Glyph position with advance and offset
pub struct GlyphPosition {
  glyph_id : GlyphId
  x_advance : Int
  y_advance : Int
  x_offset : Int
  y_offset : Int
} derive(Eq, Debug)

///|
/// Create a glyph position
pub fn GlyphPosition::new(
  glyph_id~ : GlyphId,
  x_advance? : Int = 0,
  y_advance? : Int = 0,
  x_offset? : Int = 0,
  y_offset? : Int = 0,
) -> GlyphPosition {
  { glyph_id, x_advance, y_advance, x_offset, y_offset }
}

///|
/// Glyph info with cluster mapping
pub struct GlyphInfo {
  glyph_id : GlyphId
  cluster : Int
} derive(Eq, Debug)

///|
/// Create glyph info
pub fn GlyphInfo::new(glyph_id~ : GlyphId, cluster~ : Int) -> GlyphInfo {
  { glyph_id, cluster }
}

///|
/// Result of text shaping operation
pub struct ShapedText {
  glyphs : Array[GlyphInfo]
  positions : Array[GlyphPosition]
  width : Int
} derive(Debug)

///|
/// Get the total width of the shaped text
pub fn ShapedText::get_width(self : ShapedText) -> Int {
  self.width
}

///|
/// Get the glyph count
pub fn ShapedText::glyph_count(self : ShapedText) -> Int {
  self.glyphs.length()
}
