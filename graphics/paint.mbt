///|
/// Fill rule for path filling
pub(all) enum FillRule {
  NonZero
  EvenOdd
} derive(Eq, Debug)

///|
/// Paint style
pub(all) enum PaintStyle {
  Fill
  Stroke
} derive(Eq, Debug)

///|
/// Stroke cap style
pub(all) enum StrokeCap {
  Butt
  Round
  Square
} derive(Eq, Debug)

///|
/// Stroke join style
pub(all) enum StrokeJoin {
  Miter
  Round
  Bevel
} derive(Eq, Debug)

///|
/// Paint configuration for drawing operations
pub struct Paint {
  mut color : Color
  mut style : PaintStyle
  mut stroke_width : Double
  mut stroke_cap : StrokeCap
  mut stroke_join : StrokeJoin
  mut miter_limit : Double
  mut stroke_dash_pattern : Array[Double]
  mut stroke_dash_offset : Double
  mut fill_rule : FillRule
  mut opacity : Double
} derive(Debug)

///|
/// Create a default paint
pub fn Paint::new() -> Paint {
  {
    color: Color::black(),
    style: PaintStyle::Fill,
    stroke_width: 1.0,
    stroke_cap: StrokeCap::Butt,
    stroke_join: StrokeJoin::Miter,
    miter_limit: 4.0,
    stroke_dash_pattern: [],
    stroke_dash_offset: 0.0,
    fill_rule: FillRule::NonZero,
    opacity: 1.0,
  }
}

///|
/// Set the paint color
pub fn Paint::set_color(self : Paint, color : Color) -> Paint {
  self.color = color
  self
}

///|
/// Set the paint style
pub fn Paint::set_style(self : Paint, style : PaintStyle) -> Paint {
  self.style = style
  self
}

///|
/// Set stroke width
pub fn Paint::set_stroke_width(self : Paint, width : Double) -> Paint {
  self.stroke_width = width
  self
}

///|
/// Set stroke cap style
pub fn Paint::set_stroke_cap(self : Paint, cap : StrokeCap) -> Paint {
  self.stroke_cap = cap
  self
}

///|
/// Set stroke join style
pub fn Paint::set_stroke_join(self : Paint, join : StrokeJoin) -> Paint {
  self.stroke_join = join
  self
}

///|
/// Set stroke miter limit. Values below 1.0 are clamped to the minimum
/// meaningful ratio.
pub fn Paint::set_miter_limit(self : Paint, limit : Double) -> Paint {
  self.miter_limit = if limit > 1.0 { limit } else { 1.0 }
  self
}

///|
/// Set stroke dash pattern and phase offset. Empty or non-positive-only
/// patterns draw a solid stroke.
pub fn Paint::set_stroke_dash(
  self : Paint,
  pattern : Array[Double],
  offset : Double,
) -> Paint {
  self.stroke_dash_pattern = normalize_dash_pattern(pattern)
  self.stroke_dash_offset = offset
  self
}

///|
/// Clear stroke dash pattern and return to solid strokes.
pub fn Paint::clear_stroke_dash(self : Paint) -> Paint {
  self.stroke_dash_pattern = []
  self.stroke_dash_offset = 0.0
  self
}

///|
/// Configure a round dotted stroke using the current stroke width.
pub fn Paint::set_dotted_stroke(self : Paint) -> Paint {
  let dot_length = 0.0001
  let gap = (self.stroke_width * 2.0).max(dot_length)
  self.stroke_cap = StrokeCap::Round
  self.stroke_dash_pattern = [dot_length, gap]
  self.stroke_dash_offset = 0.0
  self
}

///|
/// Set fill rule
pub fn Paint::set_fill_rule(self : Paint, fill_rule : FillRule) -> Paint {
  self.fill_rule = fill_rule
  self
}

///|
/// Set opacity (0.0 to 1.0)
pub fn Paint::set_opacity(self : Paint, opacity : Double) -> Paint {
  self.opacity = opacity
  self
}

///|
fn normalize_dash_pattern(pattern : Array[Double]) -> Array[Double] {
  let normalized = []
  let mut total = 0.0
  for value in pattern {
    if value > 0.0 {
      normalized.push(value)
      total = total + value
    }
  }
  guard normalized.length() > 0 && total > 0.0 else { return [] }
  if normalized.length() % 2 == 1 {
    let original_len = normalized.length()
    for i in 0..<original_len {
      normalized.push(normalized[i])
    }
  }
  normalized
}
