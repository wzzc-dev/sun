///|
/// Font header (head table)
pub struct FontHead {
  units_per_em : Int
  index_to_loc_format : Int // 0 = short, 1 = long
} derive(Eq, Debug)

///|
/// Horizontal header (hhea table)
pub struct FontHhea {
  ascent : Int
  descent : Int
  line_gap : Int
  num_h_metrics : Int
} derive(Eq, Debug)

///|
/// Horizontal metrics
pub struct LongHorMetric {
  advance_width : Int
  lsb : Int // left side bearing
} derive(Eq, Debug)

///|
/// Simple glyph point
pub struct GlyphPoint {
  x : Int
  y : Int
  on_curve : Bool
} derive(Eq, Debug)

///|
/// Glyph contour
pub struct GlyphContour {
  points : Array[GlyphPoint]
} derive(Debug)

///|
/// Simple glyph data
pub struct SimpleGlyph {
  contours : Array[GlyphContour]
  xmin : Int
  ymin : Int
  xmax : Int
  ymax : Int
} derive(Debug)

///|
/// Glyph data (simple or composite)
pub enum GlyphData {
  Simple(SimpleGlyph)
  Empty
} derive(Debug)

///|
/// Table record in font file
pub struct TableRecord {
  tag : String
  checksum : UInt
  offset : UInt
  length : UInt
} derive(Eq, Debug)

///|
/// Kerning pair
pub struct KernPair {
  left : Int
  right : Int
  value : Int
} derive(Eq, Debug)

///|
/// Parsed font data
pub struct Font {
  head : FontHead
  hhea : FontHhea
  hmtx : Array[LongHorMetric]
  cmap : Map[Int, Int] // char code -> glyph index
  glyphs : Array[GlyphData]
  glyph_count : Int
  kern : Array[KernPair] // kerning pairs
} derive(Debug)

///|
/// Get font metrics
pub fn Font::get_metrics(self : Font) -> (Int, Int, Int) {
  (self.hhea.ascent, self.hhea.descent, self.hhea.line_gap)
}

///|
/// Get units per em
pub fn Font::get_units_per_em(self : Font) -> Int {
  self.head.units_per_em
}

///|
/// Map character to glyph index
pub fn Font::char_to_glyph(self : Font, char_code : Int) -> Int {
  match self.cmap.get(char_code) {
    Some(idx) => idx
    None => 0 // .notdef glyph
  }
}

///|
/// Get glyph data
pub fn Font::get_glyph(self : Font, glyph_id : Int) -> GlyphData {
  guard glyph_id >= 0 && glyph_id < self.glyph_count else {
    return GlyphData::Empty
  }
  self.glyphs[glyph_id]
}

///|
/// Get horizontal metrics for a glyph
pub fn Font::get_h_metrics(self : Font, glyph_id : Int) -> (Int, Int) {
  let idx = if glyph_id < self.hmtx.length() {
    glyph_id
  } else {
    self.hmtx.length() - 1
  }
  let m = self.hmtx[idx]
  (m.advance_width, m.lsb)
}

///|
/// Get kerning value between two glyphs
pub fn Font::get_kerning(
  self : Font,
  left_glyph : Int,
  right_glyph : Int,
) -> Int {
  for pair in self.kern {
    if pair.left == left_glyph && pair.right == right_glyph {
      return pair.value
    }
  }
  0
}
