///|
/// RGBA color representation
pub(all) struct Color {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
} derive(Eq, Debug)

///|
pub impl Show for Color with fn output(self, logger) {
  logger.write_string("Color::new(r=")
  logger.write_object(self.r)
  logger.write_string(", g=")
  logger.write_object(self.g)
  logger.write_string(", b=")
  logger.write_object(self.b)
  logger.write_string(", a=")
  logger.write_object(self.a)
  logger.write_string(")")
}

///|
/// Create a color from RGBA values
pub fn Color::new(r~ : Byte, g~ : Byte, b~ : Byte, a? : Byte = 255) -> Color {
  { r, g, b, a }
}

///|
/// Predefined colors
pub fn Color::white() -> Color {
  Color::new(r=255, g=255, b=255)
}

///|
pub fn Color::black() -> Color {
  Color::new(r=0, g=0, b=0)
}

///|
pub fn Color::red() -> Color {
  Color::new(r=255, g=0, b=0)
}

///|
pub fn Color::green() -> Color {
  Color::new(r=0, g=255, b=0)
}

///|
pub fn Color::blue() -> Color {
  Color::new(r=0, g=0, b=255)
}

///|
pub fn Color::transparent() -> Color {
  Color::new(r=0, g=0, b=0, a=0)
}

///|
/// Return this color with a replaced alpha channel
pub fn Color::with_alpha(self : Color, alpha : Byte) -> Color {
  { r: self.r, g: self.g, b: self.b, a: alpha }
}

///|
/// Return this color with its alpha multiplied by opacity
pub fn Color::scale_alpha(self : Color, opacity : Double) -> Color {
  let clamped = if opacity < 0.0 {
    0.0
  } else if opacity > 1.0 {
    1.0
  } else {
    opacity
  }
  let alpha = (self.a.to_int().to_double() * clamped + 0.5).to_int()
  self.with_alpha(clamp_byte(alpha))
}

///|
/// Composite this straight-alpha source color over a destination color
pub fn Color::blend_over(self : Color, dst : Color) -> Color {
  let src_a = self.a.to_int()
  let dst_a = dst.a.to_int()
  let inv_src_a = 255 - src_a
  let out_a = src_a + div_round(dst_a * inv_src_a, 255)

  guard out_a > 0 else { return Color::transparent() }

  let r_premul = self.r.to_int() * src_a +
    div_round(dst.r.to_int() * dst_a * inv_src_a, 255)
  let g_premul = self.g.to_int() * src_a +
    div_round(dst.g.to_int() * dst_a * inv_src_a, 255)
  let b_premul = self.b.to_int() * src_a +
    div_round(dst.b.to_int() * dst_a * inv_src_a, 255)

  Color::new(
    r=clamp_byte(div_round(r_premul, out_a)),
    g=clamp_byte(div_round(g_premul, out_a)),
    b=clamp_byte(div_round(b_premul, out_a)),
    a=clamp_byte(out_a),
  )
}

///|
fn div_round(numerator : Int, denominator : Int) -> Int {
  guard denominator > 0 else { return 0 }
  (numerator + denominator / 2) / denominator
}

///|
fn clamp_byte(value : Int) -> Byte {
  value.max(0).min(255).to_byte()
}
