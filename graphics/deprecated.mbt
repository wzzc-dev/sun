///|
/// Draw text-like placeholder boxes at the given position.
#deprecated("Use Canvas::draw_placeholder_text for debug boxes or renderer.Renderer::draw_text for real text rendering")
pub fn Canvas::draw_text(
  self : Canvas,
  text : String,
  x : Double,
  y : Double,
  font_size : Double,
  color : Color,
) -> Unit {
  self.draw_placeholder_text(text, x, y, font_size, color)
}
