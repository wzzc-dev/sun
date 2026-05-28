///|
/// Text alignment
pub(all) enum TextAlign {
  Left
  Center
  Right
  Justify
} derive(Eq, Debug)

///|
/// A paragraph of text
pub struct Paragraph {
  text : String
  lines : Array[TextLine]
  alignment : TextAlign
  font_size : Double
  line_height : Double
} derive(Debug)

///|
/// Get the lines of the paragraph
pub fn Paragraph::get_lines(self : Paragraph) -> Array[TextLine] {
  self.lines
}

///|
/// Get the total height of the paragraph
pub fn Paragraph::total_height(self : Paragraph) -> Double {
  let line_count = self.lines.length()
  if line_count is 0 {
    0.0
  } else {
    line_count.to_double() * self.line_height
  }
}
