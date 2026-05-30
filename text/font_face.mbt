///|
/// Parsed font face used by higher-level layout and rendering APIs.
pub struct FontFace {
  font : Font
} derive(Debug)

///|
/// Wrap an already parsed font as a face.
pub fn FontFace::from_font(font : Font) -> FontFace {
  { font, }
}

///|
/// Parse TTF bytes into a checked font face.
pub fn FontFace::from_bytes(data : Bytes) -> Result[FontFace, FontParseError] {
  match parse_font_result(data) {
    Ok(font) => Ok(FontFace::from_font(font))
    Err(error) => Err(error)
  }
}

///|
/// Parse a raw font-data container into a checked font face.
pub fn FontFace::from_data(data : FontData) -> Result[FontFace, FontParseError] {
  FontFace::from_bytes(data.get_data())
}

///|
/// Parse this raw font-data container into a checked font face.
pub fn FontData::parse(self : FontData) -> Result[FontFace, FontParseError] {
  FontFace::from_data(self)
}

///|
/// Get the parsed font backing this face.
pub fn FontFace::get_font(self : FontFace) -> Font {
  self.font
}

///|
/// Get face-wide metrics in font units.
pub fn FontFace::get_metrics(self : FontFace) -> FontMetrics {
  let (ascent, descent, line_gap) = self.font.get_metrics()
  FontMetrics::new(
    units_per_em=self.font.get_units_per_em(),
    ascent~,
    descent~,
    line_gap~,
  )
}

///|
/// Get units per em for the face.
pub fn FontFace::get_units_per_em(self : FontFace) -> Int {
  self.font.get_units_per_em()
}

///|
/// Map a Unicode codepoint to a glyph id.
pub fn FontFace::char_to_glyph(self : FontFace, char_code : Int) -> Int {
  self.font.char_to_glyph(char_code)
}

///|
/// Get resolved glyph data for a glyph id.
pub fn FontFace::get_glyph(self : FontFace, glyph_id : Int) -> GlyphData {
  self.font.get_glyph(glyph_id)
}

///|
/// Get horizontal metrics for a glyph id.
pub fn FontFace::get_h_metrics(self : FontFace, glyph_id : Int) -> (Int, Int) {
  self.font.get_h_metrics(glyph_id)
}

///|
/// Get kerning in font units between two glyph ids.
pub fn FontFace::get_kerning(
  self : FontFace,
  left_glyph : Int,
  right_glyph : Int,
) -> Int {
  self.font.get_kerning(left_glyph, right_glyph)
}
