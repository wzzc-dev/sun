///|
/// Ordered collection of cached layers. Layers added later are composited above
/// earlier layers.
pub struct LayerTree {
  layers : Array[Layer]
  invalidation : DirtyRegion
} derive(Debug)

///|
pub fn LayerTree::new() -> LayerTree {
  { layers: [], invalidation: DirtyRegion::new() }
}

///|
pub fn LayerTree::add_layer(self : LayerTree, layer : Layer) -> Int {
  let index = self.layers.length()
  self.layers.push(layer)
  index
}

///|
pub fn LayerTree::remove_layer(self : LayerTree, index : Int) -> Layer? {
  guard is_valid_layer_index(self, index) else { return None }
  let layer = self.layers.remove(index)
  if layer_is_compositable(layer) {
    self.invalidate_rect(layer_target_bounds(layer))
  }
  Some(layer)
}

///|
pub fn LayerTree::replace_layer(
  self : LayerTree,
  index : Int,
  layer : Layer,
) -> Layer? {
  guard is_valid_layer_index(self, index) else { return None }
  let old_layer = self.layers.remove(index)
  insert_layer_at(self.layers, index, layer)
  invalidate_layer_swap(self, old_layer, layer)
  Some(old_layer)
}

///|
pub fn LayerTree::reorder_layer(
  self : LayerTree,
  from_index : Int,
  to_index : Int,
) -> Bool {
  guard is_valid_layer_index(self, from_index) &&
    is_valid_layer_index(self, to_index) else {
    return false
  }
  guard from_index != to_index else { return true }
  let layer = self.layers.remove(from_index)
  insert_layer_at(self.layers, to_index, layer)
  if layer_is_compositable(layer) {
    self.invalidate_rect(layer_target_bounds(layer))
  }
  true
}

///|
pub fn LayerTree::get_layer_count(self : LayerTree) -> Int {
  self.layers.length()
}

///|
pub fn LayerTree::get_layer(self : LayerTree, index : Int) -> Layer? {
  guard is_valid_layer_index(self, index) else { return None }
  Some(self.layers[index])
}

///|
pub fn LayerTree::clear_dirty_regions(self : LayerTree) -> Unit {
  self.invalidation.clear()
  for layer in self.layers {
    layer.clear_dirty_region()
  }
}

///|
pub fn LayerTree::invalidate_rect(self : LayerTree, rect : PixelRect) -> Unit {
  self.invalidation.add_rect(rect)
}

///|
pub fn LayerTree::invalidate_layer(self : LayerTree, index : Int) -> Bool {
  match self.get_layer(index) {
    Some(layer) => {
      self.invalidate_rect(layer_target_bounds(layer))
      true
    }
    None => false
  }
}

///|
pub fn LayerTree::set_layer_position(
  self : LayerTree,
  index : Int,
  x : Int,
  y : Int,
) -> Bool {
  match self.get_layer(index) {
    Some(layer) => {
      let old_bounds = layer_target_bounds(layer)
      let was_compositable = layer_is_compositable(layer)
      ignore(layer.set_position(x, y))
      if was_compositable {
        self.invalidate_rect(old_bounds)
        self.invalidate_rect(layer_target_bounds(layer))
      }
      true
    }
    None => false
  }
}

///|
pub fn LayerTree::set_layer_visible(
  self : LayerTree,
  index : Int,
  visible : Bool,
) -> Bool {
  match self.get_layer(index) {
    Some(layer) => {
      let old_visible = layer.is_visible()
      guard old_visible != visible else { return true }
      let affected_bounds = layer_target_bounds(layer)
      let opacity = layer.get_opacity()
      ignore(layer.set_visible(visible))
      if opacity > 0.0 {
        self.invalidate_rect(affected_bounds)
      }
      true
    }
    None => false
  }
}

///|
pub fn LayerTree::set_layer_opacity(
  self : LayerTree,
  index : Int,
  opacity : Double,
) -> Bool {
  match self.get_layer(index) {
    Some(layer) => {
      let old_opacity = layer.get_opacity()
      let new_opacity = clamp_opacity(opacity)
      guard old_opacity != new_opacity else { return true }
      let visible = layer.is_visible()
      let affected_bounds = layer_target_bounds(layer)
      ignore(layer.set_opacity(new_opacity))
      if visible && (old_opacity > 0.0 || new_opacity > 0.0) {
        self.invalidate_rect(affected_bounds)
      }
      true
    }
    None => false
  }
}

///|
pub fn LayerTree::resize_layer(
  self : LayerTree,
  index : Int,
  width : Int,
  height : Int,
) -> Bool {
  match self.get_layer(index) {
    Some(layer) => {
      let safe_width = width.max(0)
      let safe_height = height.max(0)
      guard safe_width != layer.get_width() || safe_height != layer.get_height() else {
        return true
      }
      let old_bounds = layer_target_bounds(layer)
      let was_compositable = layer_is_compositable(layer)
      ignore(layer.resize(safe_width, safe_height))
      if was_compositable {
        self.invalidate_rect(old_bounds)
        self.invalidate_rect(layer_target_bounds(layer))
      }
      true
    }
    None => false
  }
}

///|
pub fn LayerTree::dirty_bounds(self : LayerTree) -> PixelRect? {
  self.collect_dirty_region().bounds()
}

///|
pub fn LayerTree::dirty_rects(
  self : LayerTree,
  max_rects : Int,
) -> Array[PixelRect] {
  let region = self.collect_dirty_region()
  match region.bounds() {
    Some(bounds) => region.present_rects(bounds, max_rects)
    None => []
  }
}

///|
pub fn[S : Surface] LayerTree::dirty_present_plan(
  self : LayerTree,
  target : Canvas,
  surface : S,
  max_rects : Int,
) -> DirtyPresentPlan {
  let region = self.combined_dirty_region(target)
  dirty_present_plan_for_region(region, target, surface, max_rects)
}

///|
pub fn[S : Surface] LayerTree::dirty_submit_plan(
  self : LayerTree,
  target : Canvas,
  surface : S,
  max_rects : Int,
) -> DirtySubmitPlan {
  let region = self.combined_dirty_region(target)
  {
    dirty_bounds: region.bounds(),
    present_plan: dirty_present_plan_for_region(
      region, target, surface, max_rects,
    ),
  }
}

///|
fn[S : Surface] dirty_present_plan_for_region(
  region : DirtyRegion,
  target : Canvas,
  surface : S,
  max_rects : Int,
) -> DirtyPresentPlan {
  let target_bounds = PixelRect::new(
    x=0,
    y=0,
    width=target.get_pixmap().get_width(),
    height=target.get_pixmap().get_height(),
  )
  let surface_bounds = PixelRect::new(
    x=0,
    y=0,
    width=surface.get_width(),
    height=surface.get_height(),
  )
  match target_bounds.intersection(surface_bounds) {
    Some(bounds) => region.present_plan(bounds, max_rects)
    None => { mode: DirtyPresentPlanMode::Empty, rects: [] }
  }
}

///|
pub fn LayerTree::composite_to(self : LayerTree, target : Canvas) -> Int {
  let mut count = 0
  for layer in self.layers {
    count = count + layer.composite_to(target)
  }
  count
}

///|
pub fn LayerTree::composite_dirty_to(
  self : LayerTree,
  target : Canvas,
  max_rects : Int,
) -> Int {
  let rects = self.dirty_rects(max_rects)
  guard rects.length() > 0 else { return 0 }
  let target_bounds = PixelRect::new(
    x=0,
    y=0,
    width=target.get_pixmap().get_width(),
    height=target.get_pixmap().get_height(),
  )
  let mut draw_count = 0
  for rect in rects {
    match rect.clip_to(target_bounds) {
      Some(clipped_rect) =>
        for layer in self.layers {
          if layer_is_compositable(layer) {
            draw_count = draw_count +
              composite_layer_rect(layer, target, clipped_rect)
          }
        }
      None => ()
    }
  }
  for layer in self.layers {
    if layer_is_compositable(layer) {
      layer.clear_dirty_region()
    }
  }
  self.invalidation.clear()
  draw_count
}

///|
pub fn[S : Surface] LayerTree::present_dirty_to(
  self : LayerTree,
  target : Canvas,
  surface : S,
) -> Result[Int, PresentError] {
  self.present_dirty_to_with_limit(
    target, surface, default_dirty_present_rect_limit,
  )
}

///|
pub fn[S : Surface] LayerTree::present_dirty_to_with_limit(
  self : LayerTree,
  target : Canvas,
  surface : S,
  max_rects : Int,
) -> Result[Int, PresentError] {
  let rects = self.dirty_target_rects(target, max_rects)
  guard rects.length() > 0 else {
    return target.present_dirty_to_with_limit(surface, max_rects)
  }
  let submit_plan = self.dirty_submit_plan(target, surface, max_rects)
  let plan = submit_plan.get_present_plan()
  let dirty_snapshot = snapshot_canvas_dirty_region(target)
  let pixel_snapshot = snapshot_canvas_pixels(target, rects)
  ignore(self.composite_rects_to(target, rects))
  guard !plan.is_empty() else {
    target.clear_dirty_region()
    self.clear_dirty_regions()
    return Ok(0)
  }
  match target.present_dirty_plan_to(surface, plan) {
    Ok(presented) => {
      target.clear_dirty_region()
      self.clear_composited_dirty_regions()
      Ok(presented)
    }
    Err(error) => {
      restore_canvas_pixels(target, rects, pixel_snapshot)
      restore_canvas_dirty_region(target, dirty_snapshot)
      Err(error)
    }
  }
}

///|
pub fn[S : Surface] LayerTree::dirty_present_batch(
  self : LayerTree,
  target : Canvas,
  surface : S,
  max_rects : Int,
) -> Result[PresentBatch, PresentError] {
  let rects = self.dirty_target_rects(target, max_rects)
  guard rects.length() > 0 else {
    return target.dirty_present_batch(surface, max_rects)
  }
  let submit_plan = self.dirty_submit_plan(target, surface, max_rects)
  let plan = submit_plan.get_present_plan()
  let dirty_snapshot = snapshot_canvas_dirty_region(target)
  let pixel_snapshot = snapshot_canvas_pixels(target, rects)
  ignore(self.composite_rects_to(target, rects))
  let result = target.get_pixmap().present_batch(plan)
  restore_canvas_pixels(target, rects, pixel_snapshot)
  restore_canvas_dirty_region(target, dirty_snapshot)
  result
}

///|
fn LayerTree::combined_dirty_region(
  self : LayerTree,
  target : Canvas,
) -> DirtyRegion {
  let region = DirtyRegion::new()
  for rect in target.get_dirty_region().get_rects() {
    region.add_rect(rect)
  }
  for rect in self.collect_dirty_region().get_rects() {
    region.add_rect(rect)
  }
  region
}

///|
fn LayerTree::collect_dirty_region(self : LayerTree) -> DirtyRegion {
  let region = DirtyRegion::new()
  for rect in self.invalidation.get_rects() {
    region.add_rect(rect)
  }
  for layer in self.layers {
    if layer_is_compositable(layer) {
      for rect in layer.translated_dirty_rects(0) {
        region.add_rect(rect)
      }
    }
  }
  region
}

///|
fn LayerTree::dirty_target_rects(
  self : LayerTree,
  target : Canvas,
  max_rects : Int,
) -> Array[PixelRect] {
  let target_bounds = PixelRect::new(
    x=0,
    y=0,
    width=target.get_pixmap().get_width(),
    height=target.get_pixmap().get_height(),
  )
  let rects = []
  for rect in self.dirty_rects(max_rects) {
    match rect.clip_to(target_bounds) {
      Some(clipped_rect) => rects.push(clipped_rect)
      None => ()
    }
  }
  rects
}

///|
fn LayerTree::composite_rects_to(
  self : LayerTree,
  target : Canvas,
  rects : Array[PixelRect],
) -> Int {
  let mut draw_count = 0
  for rect in rects {
    for layer in self.layers {
      if layer_is_compositable(layer) {
        draw_count = draw_count + composite_layer_rect(layer, target, rect)
      }
    }
  }
  draw_count
}

///|
fn LayerTree::clear_composited_dirty_regions(self : LayerTree) -> Unit {
  for layer in self.layers {
    if layer_is_compositable(layer) {
      layer.clear_dirty_region()
    }
  }
  self.invalidation.clear()
}

///|
fn snapshot_canvas_dirty_region(target : Canvas) -> Array[PixelRect] {
  let rects = []
  for rect in target.get_dirty_region().get_rects() {
    rects.push(rect)
  }
  rects
}

///|
fn restore_canvas_dirty_region(
  target : Canvas,
  rects : Array[PixelRect],
) -> Unit {
  let dirty_region = target.get_dirty_region()
  dirty_region.clear()
  for rect in rects {
    dirty_region.add_rect(rect)
  }
}

///|
fn snapshot_canvas_pixels(
  target : Canvas,
  rects : Array[PixelRect],
) -> Array[FixedArray[Byte]] {
  let snapshots = []
  let pixmap = target.get_pixmap()
  for rect in rects {
    let row_bytes = rect.width * 4
    let pixels : FixedArray[Byte] = FixedArray::make(row_bytes * rect.height, 0)
    for row in 0..<rect.height {
      for column in 0..<rect.width {
        let color = pixmap.get_pixel(rect.x + column, rect.y + row)
        write_snapshot_color(pixels, row * row_bytes + column * 4, color)
      }
    }
    snapshots.push(pixels)
  }
  snapshots
}

///|
fn restore_canvas_pixels(
  target : Canvas,
  rects : Array[PixelRect],
  snapshots : Array[FixedArray[Byte]],
) -> Unit {
  let pixmap = target.get_pixmap()
  let count = rects.length().min(snapshots.length())
  for i in 0..<count {
    let rect = rects[i]
    let snapshot = snapshots[i]
    let row_bytes = rect.width * 4
    for row in 0..<rect.height {
      for column in 0..<rect.width {
        let offset = row * row_bytes + column * 4
        pixmap.set_pixel(
          rect.x + column,
          rect.y + row,
          Color::new(
            r=snapshot[offset],
            g=snapshot[offset + 1],
            b=snapshot[offset + 2],
            a=snapshot[offset + 3],
          ),
        )
      }
    }
  }
}

///|
fn write_snapshot_color(
  pixels : FixedArray[Byte],
  offset : Int,
  color : Color,
) -> Unit {
  pixels[offset] = color.r
  pixels[offset + 1] = color.g
  pixels[offset + 2] = color.b
  pixels[offset + 3] = color.a
}

///|
fn is_valid_layer_index(tree : LayerTree, index : Int) -> Bool {
  index >= 0 && index < tree.layers.length()
}

///|
fn insert_layer_at(layers : Array[Layer], index : Int, layer : Layer) -> Unit {
  let tail = []
  while layers.length() > index {
    tail.push(layers.remove(index))
  }
  layers.push(layer)
  while tail.length() > 0 {
    layers.push(tail.remove(tail.length() - 1))
  }
}

///|
fn invalidate_layer_swap(
  tree : LayerTree,
  old_layer : Layer,
  new_layer : Layer,
) -> Unit {
  if layer_is_compositable(old_layer) {
    tree.invalidate_rect(layer_target_bounds(old_layer))
  }
  if layer_is_compositable(new_layer) {
    tree.invalidate_rect(layer_target_bounds(new_layer))
  }
}

///|
fn layer_is_compositable(layer : Layer) -> Bool {
  layer.is_visible() && layer.get_opacity() > 0.0
}

///|
fn clamp_opacity(opacity : Double) -> Double {
  opacity.max(0.0).min(1.0)
}

///|
fn layer_target_bounds(layer : Layer) -> PixelRect {
  PixelRect::new(
    x=layer.get_x(),
    y=layer.get_y(),
    width=layer.get_width(),
    height=layer.get_height(),
  )
}

///|
fn composite_layer_rect(
  layer : Layer,
  target : Canvas,
  target_rect : PixelRect,
) -> Int {
  match layer_target_bounds(layer).intersection(target_rect) {
    Some(intersection) => {
      let src_rect = PixelRect::new(
        x=intersection.x - layer.get_x(),
        y=intersection.y - layer.get_y(),
        width=intersection.width,
        height=intersection.height,
      )
      target.draw_pixmap_rect(
        layer.get_pixmap(),
        src_rect,
        intersection.x,
        intersection.y,
        Paint::new().set_opacity(layer.get_opacity()),
      )
      1
    }
    None => 0
  }
}
