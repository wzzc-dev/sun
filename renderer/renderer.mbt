///|
/// Renderer core that composes vector drawing, text masks, and pixmap output.
pub struct Renderer {
  canvas : @graphics.Canvas
} derive(Debug)

///|
/// Create a renderer around an existing canvas.
pub fn Renderer::new(canvas : @graphics.Canvas) -> Renderer {
  { canvas, }
}

///|
/// Get the renderer canvas.
pub fn Renderer::get_canvas(self : Renderer) -> @graphics.Canvas {
  self.canvas
}

///|
/// Draw text through the real text rasterization pipeline.
pub fn Renderer::draw_text(
  self : Renderer,
  font : @text.Font,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let pixmap = self.canvas.get_pixmap()
  draw_text(
    self.canvas,
    font,
    text,
    x,
    y,
    pixmap.get_width(),
    pixmap.get_height(),
    config,
    paint,
  )
}

///|
/// Draw text through the stable font-face layout pipeline.
pub fn Renderer::draw_text_face(
  self : Renderer,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let pixmap = self.canvas.get_pixmap()
  draw_text_face(
    self.canvas,
    face,
    text,
    x,
    y,
    pixmap.get_width(),
    pixmap.get_height(),
    config,
    paint,
  )
}

///|
/// Composite an existing text coverage mask on the renderer canvas.
pub fn Renderer::draw_coverage_mask(
  self : Renderer,
  mask : @text.CoverageMask,
  paint : @graphics.Paint,
) -> Unit {
  draw_coverage_mask(self.canvas, mask, paint)
}

///|
/// Rasterize text through the text package and composite it on a canvas.
pub fn draw_text(
  canvas : @graphics.Canvas,
  font : @text.Font,
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let mask = @text.render_text_mask(font, text, width, height, x, y, config)
  draw_coverage_mask(canvas, mask, paint)
}

///|
/// Rasterize font-face text and composite it on a canvas.
pub fn draw_text_face(
  canvas : @graphics.Canvas,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  width : Int,
  height : Int,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> Unit {
  let mask = @text.render_text_mask_face(
    face, text, width, height, x, y, config,
  )
  draw_coverage_mask(canvas, mask, paint)
}

///|
/// Composite a text coverage mask on a canvas.
pub fn draw_coverage_mask(
  canvas : @graphics.Canvas,
  mask : @text.CoverageMask,
  paint : @graphics.Paint,
) -> Unit {
  canvas.draw_mask(
    0,
    0,
    mask.get_width(),
    mask.get_height(),
    mask.get_pixels(),
    paint,
  )
}
