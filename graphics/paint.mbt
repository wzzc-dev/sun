///|
/// Fill rule for path filling
pub enum FillRule {
  NonZero
  EvenOdd
} derive(Eq, Debug)

///|
/// Paint style
pub enum PaintStyle {
  Fill
  Stroke
} derive(Eq, Debug)

///|
/// Stroke cap style
pub enum StrokeCap {
  Butt
  Round
  Square
} derive(Eq, Debug)

///|
/// Stroke join style
pub enum StrokeJoin {
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
  stroke_cap : StrokeCap
  stroke_join : StrokeJoin
  fill_rule : FillRule
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
/// Set opacity (0.0 to 1.0)
pub fn Paint::set_opacity(self : Paint, opacity : Double) -> Paint {
  self.opacity = opacity
  self
}
