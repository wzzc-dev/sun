///|
/// A frame-sized drawing target with a z-ordered layer tree and a dirty-present
/// policy. This is the small unit an event loop can submit to a Surface.
pub struct RenderFrame {
  mut canvas : Canvas
  layer_tree : LayerTree
  mut dirty_rect_limit : Int
} derive(Debug)

///|
/// Strategy-aware dry-run plan for submitting a RenderFrame to a Surface.
pub struct RenderFrameSubmitPlan {
  dirty_submit_plan : DirtySubmitPlan
  strategy : DirtyPresentStrategy
  present_rect_count : Int
  present_pixel_count : Int
  present_byte_count : Int
} derive(Debug)

///|
/// Result of submitting a RenderFrame through the strategy-aware scheduler.
pub struct RenderFrameSubmitResult {
  submit_plan : RenderFrameSubmitPlan
  presented_rect_count : Int
} derive(Debug)

///|
/// Request to resize one frame-owned layer cache and clear it to a color.
pub struct RenderFrameLayerClearRequest {
  layer_index : Int
  color : Color
} derive(Eq, Debug)

///|
/// Create a layer clear request for a RenderFrame resize lifecycle operation.
pub fn RenderFrameLayerClearRequest::new(
  layer_index : Int,
  color : Color,
) -> RenderFrameLayerClearRequest {
  { layer_index, color }
}

///|
/// Return the target layer index.
pub fn RenderFrameLayerClearRequest::get_layer_index(
  self : RenderFrameLayerClearRequest,
) -> Int {
  self.layer_index
}

///|
/// Return the clear color for the target layer.
pub fn RenderFrameLayerClearRequest::get_color(
  self : RenderFrameLayerClearRequest,
) -> Color {
  self.color
}

///|
pub fn RenderFrameSubmitPlan::get_dirty_submit_plan(
  self : RenderFrameSubmitPlan,
) -> DirtySubmitPlan {
  self.dirty_submit_plan
}

///|
pub fn RenderFrameSubmitPlan::get_present_strategy(
  self : RenderFrameSubmitPlan,
) -> DirtyPresentStrategy {
  self.strategy
}

///|
pub fn RenderFrameSubmitPlan::get_state(
  self : RenderFrameSubmitPlan,
) -> DirtySubmitState {
  self.dirty_submit_plan.get_state()
}

///|
pub fn RenderFrameSubmitPlan::get_dirty_bounds(
  self : RenderFrameSubmitPlan,
) -> PixelRect? {
  self.dirty_submit_plan.get_dirty_bounds()
}

///|
pub fn RenderFrameSubmitPlan::has_dirty(self : RenderFrameSubmitPlan) -> Bool {
  self.dirty_submit_plan.has_dirty()
}

///|
pub fn RenderFrameSubmitPlan::needs_present(
  self : RenderFrameSubmitPlan,
) -> Bool {
  self.dirty_submit_plan.needs_present()
}

///|
pub fn RenderFrameSubmitPlan::was_clipped_away(
  self : RenderFrameSubmitPlan,
) -> Bool {
  self.get_state() == DirtySubmitState::DirtyClippedAway
}

///|
pub fn RenderFrameSubmitPlan::uses_bounds_fallback(
  self : RenderFrameSubmitPlan,
) -> Bool {
  self.dirty_submit_plan.uses_bounds_fallback()
}

///|
pub fn RenderFrameSubmitPlan::get_present_rect_count(
  self : RenderFrameSubmitPlan,
) -> Int {
  self.present_rect_count
}

///|
pub fn RenderFrameSubmitPlan::get_present_pixel_count(
  self : RenderFrameSubmitPlan,
) -> Int {
  self.present_pixel_count
}

///|
pub fn RenderFrameSubmitPlan::get_present_byte_count(
  self : RenderFrameSubmitPlan,
) -> Int {
  self.present_byte_count
}

///|
pub fn RenderFrameSubmitPlan::saves_full_present_pixels(
  self : RenderFrameSubmitPlan,
) -> Bool {
  self.strategy == DirtyPresentStrategy::Partial
}

///|
pub fn RenderFrameSubmitResult::get_submit_plan(
  self : RenderFrameSubmitResult,
) -> RenderFrameSubmitPlan {
  self.submit_plan
}

///|
pub fn RenderFrameSubmitResult::get_present_strategy(
  self : RenderFrameSubmitResult,
) -> DirtyPresentStrategy {
  self.submit_plan.get_present_strategy()
}

///|
pub fn RenderFrameSubmitResult::get_present_rect_count(
  self : RenderFrameSubmitResult,
) -> Int {
  self.submit_plan.get_present_rect_count()
}

///|
pub fn RenderFrameSubmitResult::get_presented_rect_count(
  self : RenderFrameSubmitResult,
) -> Int {
  self.presented_rect_count
}

///|
pub fn RenderFrameSubmitResult::get_state(
  self : RenderFrameSubmitResult,
) -> DirtySubmitState {
  self.submit_plan.get_state()
}

///|
pub fn RenderFrameSubmitResult::get_dirty_bounds(
  self : RenderFrameSubmitResult,
) -> PixelRect? {
  self.submit_plan.get_dirty_bounds()
}

///|
pub fn RenderFrameSubmitResult::has_dirty(
  self : RenderFrameSubmitResult,
) -> Bool {
  self.submit_plan.has_dirty()
}

///|
pub fn RenderFrameSubmitResult::needs_present(
  self : RenderFrameSubmitResult,
) -> Bool {
  self.submit_plan.needs_present()
}

///|
pub fn RenderFrameSubmitResult::was_clipped_away(
  self : RenderFrameSubmitResult,
) -> Bool {
  self.submit_plan.was_clipped_away()
}

///|
pub fn RenderFrameSubmitResult::uses_bounds_fallback(
  self : RenderFrameSubmitResult,
) -> Bool {
  self.submit_plan.uses_bounds_fallback()
}

///|
pub fn RenderFrameSubmitResult::did_present(
  self : RenderFrameSubmitResult,
) -> Bool {
  self.presented_rect_count > 0
}

///|
pub fn RenderFrameSubmitResult::get_present_pixel_count(
  self : RenderFrameSubmitResult,
) -> Int {
  self.submit_plan.get_present_pixel_count()
}

///|
pub fn RenderFrameSubmitResult::get_present_byte_count(
  self : RenderFrameSubmitResult,
) -> Int {
  self.submit_plan.get_present_byte_count()
}

///|
pub fn RenderFrameSubmitResult::saves_full_present_pixels(
  self : RenderFrameSubmitResult,
) -> Bool {
  self.submit_plan.saves_full_present_pixels()
}

///|
fn render_frame_submit_plan(
  dirty_submit_plan : DirtySubmitPlan,
  strategy : DirtyPresentStrategy,
  present_rect_count : Int,
  present_pixel_count : Int,
  present_byte_count : Int,
) -> RenderFrameSubmitPlan {
  {
    dirty_submit_plan,
    strategy,
    present_rect_count,
    present_pixel_count,
    present_byte_count,
  }
}

///|
fn render_frame_submit_result(
  submit_plan : RenderFrameSubmitPlan,
  presented_rect_count : Int,
) -> RenderFrameSubmitResult {
  { submit_plan, presented_rect_count }
}

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
/// Resize the frame and a layer-sized background cache, then clear that layer.
/// Intended for GUI resize handlers that keep a full-frame background layer at
/// a stable index while other layers are replaced or redrawn separately.
pub fn RenderFrame::resize_and_clear_layer(
  self : RenderFrame,
  layer_index : Int,
  width : Int,
  height : Int,
  color : Color,
) -> Bool {
  self.resize_and_clear_layers(width, height, [
    RenderFrameLayerClearRequest::new(layer_index, color),
  ])
}

///|
/// Resize the frame and multiple layer-sized caches, then clear each layer.
/// This validates all requested layers before mutating frame or layer state.
pub fn RenderFrame::resize_and_clear_layers(
  self : RenderFrame,
  width : Int,
  height : Int,
  requests : Array[RenderFrameLayerClearRequest],
) -> Bool {
  guard width > 0 && height > 0 else { return false }
  guard requests.length() > 0 else { return false }
  for request in requests {
    guard self.layer_tree.get_layer(request.get_layer_index()) is Some(_) else {
      return false
    }
  }
  ignore(self.resize(width, height))
  for request in requests {
    let layer_index = request.get_layer_index()
    ignore(self.layer_tree.resize_layer(layer_index, width, height))
    match self.layer_tree.get_layer(layer_index) {
      Some(layer) => layer.clear(request.get_color())
      None => return false
    }
  }
  true
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
  self.dirty_submit_plan(surface).get_present_plan()
}

///|
pub fn[S : Surface] RenderFrame::dirty_submit_plan(
  self : RenderFrame,
  surface : S,
) -> DirtySubmitPlan {
  self.layer_tree.dirty_submit_plan(self.canvas, surface, self.dirty_rect_limit)
}

///|
pub fn[S : Surface] RenderFrame::dirty_present_batch(
  self : RenderFrame,
  surface : S,
) -> Result[PresentBatch, PresentError] {
  self.layer_tree.dirty_present_batch(
    self.canvas,
    surface,
    self.dirty_rect_limit,
  )
}

///|
pub fn[S : Surface] RenderFrame::present_strategy(
  self : RenderFrame,
  surface : S,
) -> DirtyPresentStrategy {
  self
  .dirty_submit_plan(surface)
  .get_present_strategy(surface.get_width(), surface.get_height())
}

///|
pub fn[S : Surface] RenderFrame::submit_by_strategy_plan(
  self : RenderFrame,
  surface : S,
) -> RenderFrameSubmitPlan {
  let dirty_plan = self.dirty_submit_plan(surface)
  let strategy = dirty_plan.get_present_strategy(
    surface.get_width(),
    surface.get_height(),
  )
  match strategy {
    DirtyPresentStrategy::Full => {
      let present_pixels = surface.get_width().max(0) *
        surface.get_height().max(0)
      let present_rect_count = if present_pixels > 0 { 1 } else { 0 }
      render_frame_submit_plan(
        dirty_plan,
        strategy,
        present_rect_count,
        present_pixels,
        present_pixels * 4,
      )
    }
    _ =>
      render_frame_submit_plan(
        dirty_plan,
        strategy,
        dirty_plan.get_present_rect_count(),
        dirty_plan.get_present_pixel_count(),
        dirty_plan.get_present_byte_count(),
      )
  }
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
pub fn[S : Surface] RenderFrame::submit_dirty_to(
  self : RenderFrame,
  surface : S,
) -> Result[DirtySubmitResult, PresentError] {
  let submit_plan = self.dirty_submit_plan(surface)
  match self.present_dirty_to(surface) {
    Ok(presented) => Ok({ submit_plan, presented_rect_count: presented })
    Err(error) => Err(error)
  }
}

///|
pub fn[S : Surface] RenderFrame::submit_by_strategy_to(
  self : RenderFrame,
  surface : S,
) -> Result[RenderFrameSubmitResult, PresentError] {
  let submit_plan = self.submit_by_strategy_plan(surface)
  match submit_plan.get_present_strategy() {
    DirtyPresentStrategy::Skip =>
      if self.has_dirty() {
        match self.submit_dirty_to(surface) {
          Ok(result) =>
            Ok(
              render_frame_submit_result(
                submit_plan,
                result.get_presented_rect_count(),
              ),
            )
          Err(error) => Err(error)
        }
      } else {
        Ok(render_frame_submit_result(submit_plan, 0))
      }
    DirtyPresentStrategy::Partial =>
      match self.submit_dirty_to(surface) {
        Ok(result) =>
          Ok(
            render_frame_submit_result(
              submit_plan,
              result.get_presented_rect_count(),
            ),
          )
        Err(error) => Err(error)
      }
    DirtyPresentStrategy::Full =>
      match self.present_all_to(surface) {
        Ok(presented) => Ok(render_frame_submit_result(submit_plan, presented))
        Err(error) => Err(error)
      }
  }
}

///|
pub fn[S : Surface] RenderFrame::present_all_to(
  self : RenderFrame,
  surface : S,
) -> Result[Int, PresentError] {
  self.mark_all_dirty()
  self.present_dirty_to(surface)
}
