///|
test "Layer tracks dirty bounds in layer and target coordinates" {
  let layer = Layer::new(4, 3).set_position(10, 20)
  layer.get_canvas().draw_pixel(1, 2, Color::red())
  assert_true(
    layer.dirty_bounds() == Some(PixelRect::new(x=1, y=2, width=1, height=1)),
  )
  assert_true(
    layer.translated_dirty_bounds() ==
    Some(PixelRect::new(x=11, y=22, width=1, height=1)),
  )
  let rects = layer.translated_dirty_rects(8)
  assert_eq(rects.length(), 1)
  assert_true(rects[0] == PixelRect::new(x=11, y=22, width=1, height=1))
}

///|
test "Layer::resize preserves overlapping pixels and marks new bounds dirty" {
  let layer = Layer::new(2, 1)
  layer.get_canvas().draw_pixel(0, 0, Color::red())
  layer.get_canvas().draw_pixel(1, 0, Color::blue())
  layer.clear_dirty_region()

  ignore(layer.resize(3, 2))
  assert_eq(layer.get_width(), 3)
  assert_eq(layer.get_height(), 2)
  assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::red())
  assert_eq(layer.get_pixmap().get_pixel(1, 0), Color::blue())
  assert_eq(layer.get_pixmap().get_pixel(2, 1), Color::transparent())
  assert_true(
    layer.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=3, height=2)),
  )

  ignore(layer.resize(1, 1))
  assert_eq(layer.get_width(), 1)
  assert_eq(layer.get_height(), 1)
  assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::red())
  assert_true(
    layer.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=1, height=1)),
  )
}

///|
test "Layer::composite_dirty_to draws only dirty cache pixels and clears dirty state" {
  let target = Canvas::new(5, 3)
  target.clear(Color::white())
  target.clear_dirty_region()

  let layer = Layer::new(3, 2).set_position(1, 1)
  layer.get_canvas().draw_pixel(0, 0, Color::red())
  layer.get_canvas().draw_pixel(2, 0, Color::blue())

  let presented = layer.composite_dirty_to(target, 8)
  assert_eq(presented, 2)
  assert_eq(target.get_pixmap().get_pixel(1, 1), Color::red())
  assert_eq(target.get_pixmap().get_pixel(3, 1), Color::blue())
  assert_eq(target.get_pixmap().get_pixel(2, 1), Color::white())
  assert_true(layer.get_dirty_region().is_empty())
  assert_true(
    target.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=1, width=3, height=1)),
  )
}

///|
test "Layer::composite_dirty_to uses bounds fallback over limit" {
  let target = Canvas::new(8, 2)
  let layer = Layer::new(8, 2)
  layer.get_canvas().draw_pixel(0, 0, Color::red())
  layer.get_canvas().draw_pixel(3, 0, Color::green())
  layer.get_canvas().draw_pixel(6, 0, Color::blue())
  let presented = layer.composite_dirty_to(target, 2)
  assert_eq(presented, 1)
  assert_eq(target.get_pixmap().get_pixel(0, 0), Color::red())
  assert_eq(target.get_pixmap().get_pixel(3, 0), Color::green())
  assert_eq(target.get_pixmap().get_pixel(6, 0), Color::blue())
}

///|
test "Layer visibility and opacity control composition" {
  let hidden_target = Canvas::new(1, 1)
  hidden_target.clear(Color::white())
  let hidden = Layer::new(1, 1).set_visible(false)
  hidden.get_canvas().draw_pixel(0, 0, Color::red())
  assert_eq(hidden.composite_dirty_to(hidden_target, 8), 0)
  assert_eq(hidden_target.get_pixmap().get_pixel(0, 0), Color::white())

  let target = Canvas::new(1, 1)
  target.clear(Color::white())
  let layer = Layer::new(1, 1).set_opacity(0.5)
  layer.get_canvas().draw_pixel(0, 0, Color::blue())
  assert_eq(layer.composite_dirty_to(target, 8), 1)
  assert_eq(
    target.get_pixmap().get_pixel(0, 0),
    Color::new(r=127, g=127, b=255, a=255),
  )
}

///|
test "Layer::composite_to draws full cache" {
  let target = Canvas::new(3, 1)
  let layer = Layer::new(2, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, Color::red())
  layer.get_canvas().draw_pixel(1, 0, Color::blue())
  assert_eq(layer.composite_to(target), 1)
  assert_eq(target.get_pixmap().get_pixel(1, 0), Color::red())
  assert_eq(target.get_pixmap().get_pixel(2, 0), Color::blue())
}
