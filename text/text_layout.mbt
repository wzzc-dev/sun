///|
/// Positioned glyphs for a single shaped and laid-out line.
pub struct GlyphRun {
  glyphs : Array[PositionedGlyph]
  width : Double
  baseline_y : Double
} derive(Debug)

///|
/// Create a glyph run from positioned glyphs.
pub fn GlyphRun::new(
  glyphs : Array[PositionedGlyph],
  width~ : Double,
  baseline_y~ : Double,
) -> GlyphRun {
  { glyphs, width, baseline_y }
}

///|
/// Get positioned glyphs in this run.
pub fn GlyphRun::get_glyphs(self : GlyphRun) -> Array[PositionedGlyph] {
  self.glyphs
}

///|
/// Get run width in pixels.
pub fn GlyphRun::get_width(self : GlyphRun) -> Double {
  self.width
}

///|
/// Get baseline position in pixels from the layout origin.
pub fn GlyphRun::get_baseline_y(self : GlyphRun) -> Double {
  self.baseline_y
}

///|
/// Get glyph count in this run.
pub fn GlyphRun::glyph_count(self : GlyphRun) -> Int {
  self.glyphs.length()
}

///|
/// Stable text layout facade used by higher-level renderers and GUI code.
pub struct TextLayout {
  runs : Array[GlyphRun]
  metrics : LayoutMetrics
} derive(Debug)

///|
/// Create a text layout from glyph runs and metrics.
pub fn TextLayout::new(
  runs : Array[GlyphRun],
  metrics : LayoutMetrics,
) -> TextLayout {
  { runs, metrics }
}

///|
/// Layout text with a parsed font face.
pub fn TextLayout::layout(
  face : FontFace,
  text : String,
  config : LayoutConfig,
) -> TextLayout {
  layout_text_face(face, text, config)
}

///|
/// Get glyph runs for this layout.
pub fn TextLayout::get_runs(self : TextLayout) -> Array[GlyphRun] {
  self.runs
}

///|
/// Get layout metrics.
pub fn TextLayout::get_metrics(self : TextLayout) -> LayoutMetrics {
  self.metrics
}

///|
/// Get total layout width.
pub fn TextLayout::get_width(self : TextLayout) -> Double {
  self.metrics.width
}

///|
/// Get total layout height.
pub fn TextLayout::get_height(self : TextLayout) -> Double {
  self.metrics.height
}

///|
/// Get the first baseline from the layout origin.
pub fn TextLayout::get_baseline(self : TextLayout) -> Double {
  self.metrics.baseline
}

///|
/// Get the number of glyph runs.
pub fn TextLayout::run_count(self : TextLayout) -> Int {
  self.runs.length()
}

///|
/// Layout text with a parsed font face.
pub fn layout_text_face(
  face : FontFace,
  text : String,
  config : LayoutConfig,
) -> TextLayout {
  TextLayout::from_layout_result(layout_text(face.get_font(), text, config))
}

///|
/// Convert the current low-level layout result into the stable layout facade.
pub fn TextLayout::from_layout_result(result : LayoutResult) -> TextLayout {
  let runs = []
  let mut baseline = 0.0
  for line in result.lines {
    if runs.length() is 0 {
      baseline = line.y
    }
    runs.push(GlyphRun::new(line.glyphs, width=line.width, baseline_y=line.y))
  }
  TextLayout::new(
    runs,
    LayoutMetrics::new(
      width=result.total_width,
      height=result.total_height,
      baseline~,
    ),
  )
}
