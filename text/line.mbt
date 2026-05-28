///|
/// A single line of shaped text
pub struct TextLine {
  glyphs : Array[GlyphInfo]
  positions : Array[GlyphPosition]
  width : Int
  y_offset : Int
} derive(Debug)

///|
/// Create a text line
pub fn TextLine::new(
  glyphs : Array[GlyphInfo],
  positions : Array[GlyphPosition],
  width : Int,
  y_offset? : Int = 0,
) -> TextLine {
  { glyphs, positions, width, y_offset }
}

///|
/// Get the width of the line
pub fn TextLine::get_width(self : TextLine) -> Int {
  self.width
}

///|
/// Get the number of glyphs
pub fn TextLine::glyph_count(self : TextLine) -> Int {
  self.glyphs.length()
}
