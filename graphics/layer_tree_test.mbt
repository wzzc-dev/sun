///|
test "LayerTree stores layers in z order" {
  let tree = LayerTree::new()
  let bottom = Layer::new(1, 1)
  let top = Layer::new(1, 1).set_position(1, 0)
  assert_eq(tree.add_layer(bottom), 0)
  assert_eq(tree.add_layer(top), 1)
  assert_eq(tree.get_layer_count(), 2)
  match tree.get_layer(0) {
    Some(layer) => assert_eq(layer.get_x(), 0)
    None => abort("expected layer 0")
  }
  match tree.get_layer(1) {
    Some(layer) => assert_eq(layer.get_x(), 1)
    None => abort("expected layer 1")
  }
  match tree.get_layer(2) {
    Some(_) => abort("unexpected layer 2")
    None => ()
  }
}

///|
test "LayerTree::composite_to draws later layers above earlier layers" {
  let target = Canvas::new(2, 1)
  target.clear(Color::white())

  let bottom = Layer::new(2, 1)
  bottom.get_canvas().draw_pixel(0, 0, Color::red())
  bottom.get_canvas().draw_pixel(1, 0, Color::red())

  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(bottom))
  ignore(tree.add_layer(top))

  assert_eq(tree.composite_to(target), 2)
  assert_eq(target.get_pixmap().get_pixel(0, 0), Color::red())
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::blue())
}

///|
test "LayerTree propagates translated dirty rectangles" {
  let tree = LayerTree::new()
  let left = Layer::new(3, 2).set_position(10, 1)
  let right = Layer::new(4, 2).set_position(20, 4)
  left.get_canvas().draw_pixel(1, 0, Color::red())
  right.get_canvas().draw_pixel(2, 1, Color::blue())
  ignore(tree.add_layer(left))
  ignore(tree.add_layer(right))

  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=11, y=1, width=12, height=5)),
  )
  let rects = tree.dirty_rects(8)
  assert_eq(rects.length(), 2)
  assert_true(rects[0] == PixelRect::new(x=11, y=1, width=1, height=1))
  assert_true(rects[1] == PixelRect::new(x=22, y=5, width=1, height=1))
  let fallback = tree.dirty_rects(1)
  assert_eq(fallback.length(), 1)
  assert_true(fallback[0] == PixelRect::new(x=11, y=1, width=12, height=5))
}

///|
test "LayerTree::composite_dirty_to redraws dirty target area in z order and clears visible dirty state" {
  let target = Canvas::new(3, 1)
  target.clear(Color::white())
  target.clear_dirty_region()

  let bottom = Layer::new(3, 1)
  bottom.get_canvas().draw_pixel(0, 0, Color::red())
  bottom.get_canvas().draw_pixel(1, 0, Color::red())
  bottom.get_canvas().draw_pixel(2, 0, Color::red())
  bottom.clear_dirty_region()

  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(bottom))
  ignore(tree.add_layer(top))

  let draws = tree.composite_dirty_to(target, 8)
  assert_eq(draws, 2)
  assert_eq(target.get_pixmap().get_pixel(0, 0), Color::white())
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::blue())
  assert_eq(target.get_pixmap().get_pixel(2, 0), Color::white())
  assert_true(bottom.get_dirty_region().is_empty())
  assert_true(top.get_dirty_region().is_empty())
  assert_true(
    target.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )
}

///|
test "LayerTree keeps hidden layer dirty until it can be composited" {
  let target = Canvas::new(1, 1)
  target.clear(Color::white())

  let hidden = Layer::new(1, 1).set_visible(false)
  hidden.get_canvas().draw_pixel(0, 0, Color::red())

  let transparent = Layer::new(1, 1).set_opacity(0.0)
  transparent.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(hidden))
  ignore(tree.add_layer(transparent))

  assert_true(tree.dirty_bounds() == None)
  assert_eq(tree.composite_dirty_to(target, 8), 0)
  assert_eq(target.get_pixmap().get_pixel(0, 0), Color::white())
  assert_true(!hidden.get_dirty_region().is_empty())
  assert_true(!transparent.get_dirty_region().is_empty())
}

///|
test "LayerTree::clear_dirty_regions clears every child" {
  let tree = LayerTree::new()
  let visible = Layer::new(1, 1)
  let hidden = Layer::new(1, 1).set_visible(false)
  visible.get_canvas().draw_pixel(0, 0, Color::red())
  hidden.get_canvas().draw_pixel(0, 0, Color::blue())
  ignore(tree.add_layer(visible))
  ignore(tree.add_layer(hidden))

  tree.clear_dirty_regions()
  assert_true(visible.get_dirty_region().is_empty())
  assert_true(hidden.get_dirty_region().is_empty())
}

///|
test "LayerTree::set_layer_position invalidates old and new bounds" {
  let target = Canvas::new(4, 1)
  let background = Layer::new(4, 1)
  background.clear(Color::white())

  let moving = Layer::new(1, 1).set_position(1, 0)
  moving.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(background))
  assert_eq(tree.add_layer(moving), 1)
  ignore(tree.composite_to(target))
  tree.clear_dirty_regions()
  target.clear_dirty_region()

  assert_true(tree.set_layer_position(1, 2, 0))
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=2, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 2)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::white())
  assert_eq(target.get_pixmap().get_pixel(2, 0), Color::blue())
  assert_true(tree.dirty_bounds() == None)
}

///|
test "LayerTree::set_layer_visible invalidates layer bounds" {
  let target = Canvas::new(3, 1)
  let background = Layer::new(3, 1)
  background.clear(Color::white())

  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::red())

  let tree = LayerTree::new()
  ignore(tree.add_layer(background))
  ignore(tree.add_layer(top))
  ignore(tree.composite_to(target))
  tree.clear_dirty_regions()

  assert_true(tree.set_layer_visible(1, false))
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 1)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::white())

  assert_true(tree.set_layer_visible(1, true))
  assert_eq(tree.composite_dirty_to(target, 8), 2)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::red())
}

///|
test "LayerTree::set_layer_opacity invalidates and reblends layer bounds" {
  let target = Canvas::new(1, 1)
  let background = Layer::new(1, 1)
  background.clear(Color::white())

  let top = Layer::new(1, 1)
  top.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(background))
  ignore(tree.add_layer(top))
  ignore(tree.composite_to(target))
  tree.clear_dirty_regions()

  assert_true(tree.set_layer_opacity(1, 0.5))
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=1, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 2)
  assert_eq(
    target.get_pixmap().get_pixel(0, 0),
    Color::new(r=127, g=127, b=255, a=255),
  )

  assert_true(tree.set_layer_opacity(1, 0.0))
  assert_eq(tree.composite_dirty_to(target, 8), 1)
  assert_eq(target.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "LayerTree::resize_layer invalidates old and new bounds" {
  let target = Canvas::new(4, 1)
  let background = Layer::new(4, 1)
  background.clear(Color::white())

  let top = Layer::new(2, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::red())
  top.get_canvas().draw_pixel(1, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(background))
  assert_eq(tree.add_layer(top), 1)
  ignore(tree.composite_to(target))
  tree.clear_dirty_regions()
  target.clear_dirty_region()

  assert_true(tree.resize_layer(1, 1, 1))
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=2, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 2)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::red())
  assert_eq(target.get_pixmap().get_pixel(2, 0), Color::white())

  assert_true(tree.resize_layer(1, 3, 1))
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=3, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 2)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::red())
  assert_eq(target.get_pixmap().get_pixel(2, 0), Color::white())
  assert_eq(target.get_pixmap().get_pixel(3, 0), Color::white())
}

///|
test "LayerTree::remove_layer invalidates removed layer bounds" {
  let target = Canvas::new(3, 1)
  let background = Layer::new(3, 1)
  background.clear(Color::white())

  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::red())

  let tree = LayerTree::new()
  ignore(tree.add_layer(background))
  assert_eq(tree.add_layer(top), 1)
  ignore(tree.composite_to(target))
  tree.clear_dirty_regions()
  target.clear_dirty_region()

  match tree.remove_layer(1) {
    Some(layer) => assert_eq(layer.get_x(), 1)
    None => abort("expected removed layer")
  }
  assert_eq(tree.get_layer_count(), 1)
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 1)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::white())
}

///|
test "LayerTree::replace_layer invalidates old and new layer bounds" {
  let target = Canvas::new(4, 1)
  let background = Layer::new(4, 1)
  background.clear(Color::white())

  let old_top = Layer::new(1, 1).set_position(1, 0)
  old_top.get_canvas().draw_pixel(0, 0, Color::red())

  let new_top = Layer::new(1, 1).set_position(2, 0)
  new_top.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(background))
  assert_eq(tree.add_layer(old_top), 1)
  ignore(tree.composite_to(target))
  tree.clear_dirty_regions()
  target.clear_dirty_region()

  match tree.replace_layer(1, new_top) {
    Some(layer) => assert_eq(layer.get_x(), 1)
    None => abort("expected replaced layer")
  }
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=2, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 2)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::white())
  assert_eq(target.get_pixmap().get_pixel(2, 0), Color::blue())
}

///|
test "LayerTree::reorder_layer changes z order and invalidates layer bounds" {
  let target = Canvas::new(1, 1)
  let bottom = Layer::new(1, 1)
  bottom.get_canvas().draw_pixel(0, 0, Color::red())
  let top = Layer::new(1, 1)
  top.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(bottom))
  ignore(tree.add_layer(top))
  ignore(tree.composite_to(target))
  assert_eq(target.get_pixmap().get_pixel(0, 0), Color::blue())
  tree.clear_dirty_regions()
  target.clear_dirty_region()

  assert_true(tree.reorder_layer(1, 0))
  assert_true(
    tree.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=1, height=1)),
  )
  assert_eq(tree.composite_dirty_to(target, 8), 2)
  assert_eq(target.get_pixmap().get_pixel(0, 0), Color::red())
  match tree.get_layer(0) {
    Some(layer) => assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::blue())
    None => abort("expected reordered layer")
  }
}

///|
test "LayerTree layer mutation helpers report invalid indexes" {
  let tree = LayerTree::new()
  assert_true(!tree.invalidate_layer(0))
  assert_true(!tree.set_layer_position(0, 1, 1))
  assert_true(!tree.set_layer_visible(0, false))
  assert_true(!tree.set_layer_opacity(0, 0.5))
  assert_true(!tree.resize_layer(0, 1, 1))
  match tree.remove_layer(0) {
    Some(_) => abort("unexpected removed layer")
    None => ()
  }
  match tree.replace_layer(0, Layer::new(1, 1)) {
    Some(_) => abort("unexpected replaced layer")
    None => ()
  }
  assert_true(!tree.reorder_layer(0, 0))
}

///|
test "LayerTree::present_dirty_to composites and presents dirty frame rects" {
  let target = Canvas::new(4, 1)
  let surface = MemorySurface::new(4, 1)

  let background = Layer::new(4, 1)
  background.clear(Color::white())

  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::red())

  let tree = LayerTree::new()
  ignore(tree.add_layer(background))
  assert_eq(tree.add_layer(top), 1)

  assert_true(tree.present_dirty_to(target, surface) == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(1, 0), Color::red())
  assert_true(tree.dirty_bounds() == None)
  assert_true(target.get_dirty_region().is_empty())

  assert_true(tree.set_layer_position(1, 2, 0))
  assert_true(tree.present_dirty_to(target, surface) == Ok(1))
  assert_eq(surface.get_present_count(), 2)
  assert_eq(surface.get_pixel(1, 0), Color::white())
  assert_eq(surface.get_pixel(2, 0), Color::red())
}

///|
test "LayerTree::present_dirty_to_with_limit falls back to dirty bounds" {
  let target = Canvas::new(8, 1)
  let surface = MemorySurface::new(8, 1)

  let left = Layer::new(1, 1)
  left.get_canvas().draw_pixel(0, 0, Color::red())

  let middle = Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, Color::green())

  let right = Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(left))
  ignore(tree.add_layer(middle))
  ignore(tree.add_layer(right))

  assert_true(tree.present_dirty_to_with_limit(target, surface, 2) == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(3, 0), Color::green())
  assert_eq(surface.get_pixel(6, 0), Color::blue())
}

///|
test "LayerTree::present_dirty_to preserves canvas dirty state on surface error" {
  let target = Canvas::new(2, 1)
  let surface = FailingSurface::new(2, 1)

  let layer = Layer::new(2, 1)
  layer.get_canvas().draw_pixel(1, 0, Color::blue())

  let tree = LayerTree::new()
  ignore(tree.add_layer(layer))

  match tree.present_dirty_to(target, surface) {
    Err(PresentError::InvalidDimensions(0, 0)) => ()
    _ => abort("expected rect out of bounds")
  }
  assert_true(tree.dirty_bounds() == None)
  assert_true(!target.get_dirty_region().is_empty())
}

///|
struct FailingSurface {
  width : Int
  height : Int
} derive(Debug)

///|
fn FailingSurface::new(width : Int, height : Int) -> FailingSurface {
  { width, height }
}

///|
impl Surface for FailingSurface with fn get_width(self) {
  self.width
}

///|
impl Surface for FailingSurface with fn get_height(self) {
  self.height
}

///|
impl Surface for FailingSurface with fn present_pixels(
  self,
  width,
  height,
  row_bytes,
  pixels,
) {
  ignore(self)
  ignore(width)
  ignore(height)
  ignore(row_bytes)
  ignore(pixels)
  Err(PresentError::InvalidDimensions(0, 0))
}

///|
impl Surface for FailingSurface with fn present_pixels_rect(
  self,
  x,
  y,
  width,
  height,
  row_bytes,
  pixels,
) {
  ignore(self)
  ignore(x)
  ignore(y)
  ignore(width)
  ignore(height)
  ignore(row_bytes)
  ignore(pixels)
  Err(PresentError::InvalidDimensions(0, 0))
}
