///|
/// Off-screen drawing cache backed by a Canvas. Layers are intended for GUI
/// subtrees that can redraw locally and then composite their dirty pixels into a
/// parent canvas.
pub struct Layer {
  mut canvas : Canvas
  mut x : Int
  mut y : Int
  mut visible : Bool
  mut opacity : Double
} derive(Debug)

///|
pub fn Layer::new(width : Int, height : Int) -> Layer {
  {
    canvas: Canvas::new(width, height),
    x: 0,
    y: 0,
    visible: true,
    opacity: 1.0,
  }
}

///|
pub fn Layer::get_canvas(self : Layer) -> Canvas {
  self.canvas
}

///|
pub fn Layer::get_pixmap(self : Layer) -> Pixmap {
  self.canvas.get_pixmap()
}

///|
pub fn Layer::get_width(self : Layer) -> Int {
  self.canvas.get_pixmap().get_width()
}

///|
pub fn Layer::get_height(self : Layer) -> Int {
  self.canvas.get_pixmap().get_height()
}

///|
pub fn Layer::resize(self : Layer, width : Int, height : Int) -> Layer {
  let safe_width = width.max(0)
  let safe_height = height.max(0)
  guard safe_width != self.get_width() || safe_height != self.get_height() else {
    return self
  }
  let old_pixmap = self.canvas.get_pixmap()
  let new_canvas = Canvas::new(safe_width, safe_height)
  let copy_width = old_pixmap.get_width().min(safe_width)
  let copy_height = old_pixmap.get_height().min(safe_height)
  if copy_width > 0 && copy_height > 0 {
    new_canvas.draw_pixmap_rect(
      old_pixmap,
      PixelRect::new(x=0, y=0, width=copy_width, height=copy_height),
      0,
      0,
      Paint::new(),
    )
  }
  new_canvas.get_dirty_region().add_all(safe_width, safe_height)
  self.canvas = new_canvas
  self
}

///|
pub fn Layer::set_position(self : Layer, x : Int, y : Int) -> Layer {
  self.x = x
  self.y = y
  self
}

///|
pub fn Layer::get_x(self : Layer) -> Int {
  self.x
}

///|
pub fn Layer::get_y(self : Layer) -> Int {
  self.y
}

///|
pub fn Layer::set_visible(self : Layer, visible : Bool) -> Layer {
  self.visible = visible
  self
}

///|
pub fn Layer::is_visible(self : Layer) -> Bool {
  self.visible
}

///|
pub fn Layer::set_opacity(self : Layer, opacity : Double) -> Layer {
  self.opacity = opacity.max(0.0).min(1.0)
  self
}

///|
pub fn Layer::get_opacity(self : Layer) -> Double {
  self.opacity
}

///|
pub fn Layer::clear(self : Layer, color : Color) -> Unit {
  self.canvas.clear(color)
}

///|
pub fn Layer::clear_dirty_region(self : Layer) -> Unit {
  self.canvas.clear_dirty_region()
}

///|
pub fn Layer::get_dirty_region(self : Layer) -> DirtyRegion {
  self.canvas.get_dirty_region()
}

///|
pub fn Layer::dirty_bounds(self : Layer) -> PixelRect? {
  self.canvas.get_dirty_region().bounds()
}

///|
pub fn Layer::translated_dirty_bounds(self : Layer) -> PixelRect? {
  match self.dirty_bounds() {
    Some(bounds) => Some(translate_pixel_rect(bounds, self.x, self.y))
    None => None
  }
}

///|
pub fn Layer::translated_dirty_rects(
  self : Layer,
  max_rects : Int,
) -> Array[PixelRect] {
  let layer_bounds = PixelRect::new(
    x=0,
    y=0,
    width=self.get_width(),
    height=self.get_height(),
  )
  let rects = []
  for
    rect in self.canvas
    .get_dirty_region()
    .present_rects(layer_bounds, max_rects) {
    rects.push(translate_pixel_rect(rect, self.x, self.y))
  }
  rects
}

///|
pub fn Layer::composite_to(self : Layer, target : Canvas) -> Int {
  guard self.visible && self.opacity > 0.0 else { return 0 }
  target.draw_pixmap(
    self.canvas.get_pixmap(),
    self.x,
    self.y,
    Paint::new().set_opacity(self.opacity),
  )
  1
}

///|
pub fn Layer::composite_dirty_to(
  self : Layer,
  target : Canvas,
  max_rects : Int,
) -> Int {
  guard self.visible && self.opacity > 0.0 else { return 0 }
  let layer_bounds = PixelRect::new(
    x=0,
    y=0,
    width=self.get_width(),
    height=self.get_height(),
  )
  let rects = self.canvas
    .get_dirty_region()
    .present_rects(layer_bounds, max_rects)
  guard rects.length() > 0 else { return 0 }
  let paint = Paint::new().set_opacity(self.opacity)
  for rect in rects {
    target.draw_pixmap_rect(
      self.canvas.get_pixmap(),
      rect,
      self.x + rect.x,
      self.y + rect.y,
      paint,
    )
  }
  self.canvas.clear_dirty_region()
  rects.length()
}

///|
fn translate_pixel_rect(rect : PixelRect, x : Int, y : Int) -> PixelRect {
  PixelRect::new(
    x=rect.x + x,
    y=rect.y + y,
    width=rect.width,
    height=rect.height,
  )
}
