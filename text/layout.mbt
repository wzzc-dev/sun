///|
/// Layout metrics for text
pub struct LayoutMetrics {
  width : Double
  height : Double
  baseline : Double
} derive(Eq, Debug)

///|
/// Create layout metrics
pub fn LayoutMetrics::new(
  width~ : Double,
  height~ : Double,
  baseline~ : Double,
) -> LayoutMetrics {
  { width, height, baseline }
}

///|
/// Text layout configuration
pub struct LayoutConfig {
  max_width : Double
  font_size : Double
  line_height : Double
  alignment : TextAlign
} derive(Debug)

///|
/// Create a layout config with default values
pub fn LayoutConfig::new(
  max_width? : Double = 800.0,
  font_size? : Double = 16.0,
  line_height? : Double = 24.0,
  alignment? : TextAlign = TextAlign::Left,
) -> LayoutConfig {
  { max_width, font_size, line_height, alignment }
}

///|
/// A positioned glyph for rendering
pub struct PositionedGlyph {
  glyph_id : Int
  x : Double
  y : Double
  advance_width : Double
} derive(Debug)

///|
/// A line of positioned glyphs
pub struct LayoutLine {
  glyphs : Array[PositionedGlyph]
  width : Double
  y : Double
} derive(Debug)

///|
/// Layout result containing positioned glyphs
pub struct LayoutResult {
  lines : Array[LayoutLine]
  total_width : Double
  total_height : Double
} derive(Debug)

///|
/// Layout text using the font's actual metrics
pub fn layout_text(
  font : Font,
  text : String,
  config : LayoutConfig,
) -> LayoutResult {
  let lines = []
  let units_per_em = font.get_units_per_em().to_double()
  let scale = config.font_size / units_per_em
  let (ascent, descent, _) = font.get_metrics()
  let line_height = config.line_height

  // Word wrap: break text into lines that fit within max_width
  let words = split_into_words(text)
  let mut current_line_glyphs = []
  let mut current_line_width = 0.0
  let mut current_y = ascent.to_double() * scale

  for word in words {
    // Calculate word width
    let word_width = calculate_word_width(font, word, scale)

    // Check if word fits on current line
    let needs_break = current_line_glyphs.length() > 0 &&
      current_line_width + word_width > config.max_width

    if needs_break {
      // Finish current line
      if current_line_glyphs.length() > 0 {
        lines.push({
          glyphs: current_line_glyphs,
          width: current_line_width,
          y: current_y,
        })
        current_line_glyphs = []
        current_line_width = 0.0
        current_y = current_y + line_height
      }
    }

    // Add word glyphs to current line
    let word_glyphs = shape_word(font, word, scale, current_line_width)
    for g in word_glyphs {
      current_line_glyphs.push(g)
    }
    current_line_width = current_line_width + word_width
  }

  // Add final line
  if current_line_glyphs.length() > 0 {
    lines.push({
      glyphs: current_line_glyphs,
      width: current_line_width,
      y: current_y,
    })
  }

  // Calculate total dimensions
  let mut total_width = 0.0
  for line in lines {
    if line.width > total_width {
      total_width = line.width
    }
  }
  let total_height = if lines.length() > 0 {
    current_y + descent.to_double() * scale
  } else {
    0.0
  }

  { lines, total_width, total_height }
}

///|
/// Split text into words (preserving spaces)
fn split_into_words(text : String) -> Array[String] {
  let words = []
  let mut current_word = ""
  let mut i = 0
  let len = text.length()

  while i < len {
    let ch = text.get_char(i)
    match ch {
      Some(c) =>
        if c is ' ' || c is '\n' || c is '\t' {
          // End current word
          if current_word.length() > 0 {
            words.push(current_word)
            current_word = ""
          }
          // Add space as separate word
          if c is ' ' {
            words.push(" ")
          }
        } else {
          current_word = current_word + c.to_string()
        }
      None => ignore(0)
    }
    i = i + 1
  }

  // Add final word
  if current_word.length() > 0 {
    words.push(current_word)
  }

  words
}

///|
/// Calculate the width of a word using font metrics with kerning
fn calculate_word_width(font : Font, word : String, scale : Double) -> Double {
  let mut width = 0.0
  let mut prev_glyph_id = -1

  for ch in word {
    let char_code = ch.to_int()
    let glyph_id = font.char_to_glyph(char_code)
    let (advance, _) = font.get_h_metrics(glyph_id)

    // Apply kerning
    if prev_glyph_id >= 0 {
      let kern = font.get_kerning(prev_glyph_id, glyph_id)
      width = width + kern.to_double() * scale
    }

    width = width + advance.to_double() * scale
    prev_glyph_id = glyph_id
  }

  width
}

///|
/// Shape a word into positioned glyphs with kerning
fn shape_word(
  font : Font,
  word : String,
  scale : Double,
  start_x : Double,
) -> Array[PositionedGlyph] {
  let glyphs = []
  let mut cursor_x = start_x
  let mut prev_glyph_id = -1

  for ch in word {
    let char_code = ch.to_int()
    let glyph_id = font.char_to_glyph(char_code)
    let (advance, lsb) = font.get_h_metrics(glyph_id)
    let advance_width = advance.to_double() * scale

    // Apply kerning
    if prev_glyph_id >= 0 {
      let kern = font.get_kerning(prev_glyph_id, glyph_id)
      cursor_x = cursor_x + kern.to_double() * scale
    }

    glyphs.push({
      glyph_id,
      x: cursor_x + lsb.to_double() * scale,
      y: 0.0, // Will be set by line layout
      advance_width,
    })

    cursor_x = cursor_x + advance_width
    prev_glyph_id = glyph_id
  }

  glyphs
}

///|
/// Layout a paragraph of text (legacy API)
pub fn layout_paragraph(
  text : String,
  font : FontData,
  config : LayoutConfig,
) -> Paragraph {
  let buffer = ShapingBuffer::new(text, font_size=config.font_size)
  let _ = buffer.shape(font)
  let lines = []

  // Simple line breaking: split on newlines or when exceeding max width
  let char_width = (config.font_size * 0.6).to_int()
  let max_chars_per_line = (config.max_width / char_width.to_double()).to_int()

  let mut start = 0
  let text_len = text.length()

  for i in 0..<text_len {
    let ch = text.get_char(i)
    let should_break = ch == Some('\n') || i - start >= max_chars_per_line

    if should_break && i > start {
      let line_glyphs = []
      let line_positions = []
      let mut line_width = 0

      for j in start..<i {
        let glyph_id = GlyphId::new(j)
        line_glyphs.push(GlyphInfo::new(glyph_id~, cluster=j))
        line_positions.push(GlyphPosition::new(glyph_id~, x_advance=char_width))
        line_width = line_width + char_width
      }

      lines.push(TextLine::new(line_glyphs, line_positions, line_width))
      start = i + 1
    }
  }

  // Handle remaining text
  if start < text_len {
    let line_glyphs = []
    let line_positions = []
    let mut line_width = 0

    for j in start..<text_len {
      let glyph_id = GlyphId::new(j)
      line_glyphs.push(GlyphInfo::new(glyph_id~, cluster=j))
      line_positions.push(GlyphPosition::new(glyph_id~, x_advance=char_width))
      line_width = line_width + char_width
    }

    lines.push(TextLine::new(line_glyphs, line_positions, line_width))
  }

  {
    text,
    lines,
    alignment: config.alignment,
    font_size: config.font_size,
    line_height: config.line_height,
  }
}
