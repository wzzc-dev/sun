///|
/// A frame-sized drawing target with a z-ordered layer tree and a dirty-present
/// policy. This is the small unit an event loop can submit to a Surface.
pub struct RenderFrame {
  mut canvas : Canvas
  layer_tree : LayerTree
  mut dirty_rect_limit : Int
} derive(Debug)

///|
pub fn RenderFrame::new(width : Int, height : Int) -> RenderFrame {
  {
    canvas: Canvas::new(width, height),
    layer_tree: LayerTree::new(),
    dirty_rect_limit: default_dirty_present_rect_limit,
  }
}

///|
pub fn RenderFrame::get_canvas(self : RenderFrame) -> Canvas {
  self.canvas
}

///|
pub fn RenderFrame::get_layer_tree(self : RenderFrame) -> LayerTree {
  self.layer_tree
}

///|
pub fn RenderFrame::get_width(self : RenderFrame) -> Int {
  self.canvas.get_pixmap().get_width()
}

///|
pub fn RenderFrame::get_height(self : RenderFrame) -> Int {
  self.canvas.get_pixmap().get_height()
}

///|
pub fn RenderFrame::resize(
  self : RenderFrame,
  width : Int,
  height : Int,
) -> RenderFrame {
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
pub fn RenderFrame::get_dirty_rect_limit(self : RenderFrame) -> Int {
  self.dirty_rect_limit
}

///|
pub fn RenderFrame::set_dirty_rect_limit(
  self : RenderFrame,
  limit : Int,
) -> RenderFrame {
  self.dirty_rect_limit = limit
  self
}

///|
pub fn RenderFrame::mark_dirty_rect(
  self : RenderFrame,
  rect : PixelRect,
) -> Unit {
  self.canvas.get_dirty_region().add_rect(rect)
}

///|
pub fn RenderFrame::mark_all_dirty(self : RenderFrame) -> Unit {
  self.canvas.get_dirty_region().add_all(self.get_width(), self.get_height())
}

///|
pub fn RenderFrame::dirty_bounds(self : RenderFrame) -> PixelRect? {
  match self.canvas.get_dirty_region().bounds() {
    Some(canvas_bounds) =>
      match self.layer_tree.dirty_bounds() {
        Some(layer_bounds) => Some(canvas_bounds.union(layer_bounds))
        None => Some(canvas_bounds)
      }
    None => self.layer_tree.dirty_bounds()
  }
}

///|
pub fn RenderFrame::has_dirty(self : RenderFrame) -> Bool {
  match self.dirty_bounds() {
    Some(_) => true
    None => false
  }
}

///|
pub fn RenderFrame::clear_dirty_regions(self : RenderFrame) -> Unit {
  self.canvas.clear_dirty_region()
  self.layer_tree.clear_dirty_regions()
}

///|
pub fn[S : Surface] RenderFrame::dirty_present_plan(
  self : RenderFrame,
  surface : S,
) -> DirtyPresentPlan {
  self.layer_tree.dirty_present_plan(
    self.canvas,
    surface,
    self.dirty_rect_limit,
  )
}

///|
pub fn[S : Surface] RenderFrame::present_dirty_to(
  self : RenderFrame,
  surface : S,
) -> Result[Int, PresentError] {
  self.layer_tree.present_dirty_to_with_limit(
    self.canvas,
    surface,
    self.dirty_rect_limit,
  )
}

///|
pub fn[S : Surface] RenderFrame::present_all_to(
  self : RenderFrame,
  surface : S,
) -> Result[Int, PresentError] {
  self.mark_all_dirty()
  self.present_dirty_to(surface)
}
