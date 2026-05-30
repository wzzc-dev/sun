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
  ignore(self.composite_dirty_to(target, max_rects))
  target.present_dirty_to_with_limit(surface, max_rects)
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
