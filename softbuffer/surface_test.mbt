///|
test "NativeSurface exposes size and handle" {
  let surface = NativeSurface::new(42, 3, 2)
  assert_eq(surface.get_width(), 3)
  assert_eq(surface.get_height(), 2)
  assert_eq(surface.handle(), 42)
  surface.resize(4, 5)
  assert_eq(surface.get_width(), 4)
  assert_eq(surface.get_height(), 5)
}

///|
test "NativeSurface validates present parameters" {
  let surface = NativeSurface::new(42, 2, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  assert_true(
    surface.present_pixels(0, 2, 8, pixels) ==
    Err(@graphics.PresentError::InvalidDimensions(0, 2)),
  )
  assert_true(
    surface.present_pixels(1, 2, 4, pixels) ==
    Err(@graphics.PresentError::SizeMismatch(2, 2, 1, 2)),
  )
  assert_true(
    surface.present_pixels_rect(2, 1, 1, 1, 4, pixels) ==
    Err(@graphics.PresentError::RectOutOfBounds(2, 1, 1, 1, 2, 2)),
  )
  assert_true(
    surface.present_pixels(2, 2, 4, pixels) ==
    Err(@graphics.PresentError::InvalidRowBytes(4, 8)),
  )
  let short_pixels : FixedArray[Byte] = FixedArray::make(15, 0)
  assert_true(
    surface.present_pixels(2, 2, 8, short_pixels) ==
    Err(@graphics.PresentError::PixelBufferTooSmall(15, 16)),
  )
}

///|
test "NativeSurface dispatches through graphics Surface trait" {
  let surface = NativeSurface::new(42, 2, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  let result = @graphics.present_pixels(surface, 2, 2, 4, pixels)
  assert_true(result == Err(@graphics.PresentError::InvalidRowBytes(4, 8)))
  let rect_result = @graphics.present_pixels_rect(
    surface, 1, 1, 1, 1, 4, pixels,
  )
  assert_true(rect_result == Ok(()))
}

///|
test "NativeSurface accepts padded row bytes through shared validation" {
  let surface = NativeSurface::new(42, 1, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(12, 0)
  let result = surface.present_pixels(1, 2, 8, pixels)
  assert_true(result == Ok(()))
}

///|
test "NativeSurface calls pre-present hook only after validation" {
  let count = Ref(0)
  let surface = NativeSurface::new(42, 2, 2).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)

  assert_true(
    surface.present_pixels(2, 2, 4, pixels) ==
    Err(@graphics.PresentError::InvalidRowBytes(4, 8)),
  )
  assert_eq(count.val, 0)

  assert_true(surface.present_pixels(2, 2, 8, pixels) == Ok(()))
  assert_eq(count.val, 1)

  assert_true(surface.present_pixels_rect(1, 1, 1, 1, 4, pixels) == Ok(()))
  assert_eq(count.val, 2)

  let padded : FixedArray[Byte] = FixedArray::make(12, 0)
  assert_true(surface.present_pixels_rect(0, 0, 1, 2, 8, padded) == Ok(()))
  assert_eq(count.val, 3)

  let without_hook = surface.clear_pre_present_hook()
  assert_true(without_hook.present_pixels(2, 2, 8, pixels) == Ok(()))
  assert_eq(count.val, 3)
}

///|
test "NativeSurface builds from RenderFrame dimensions" {
  let frame = @graphics.RenderFrame::new(3, 2)
  let surface = NativeSurface::from_frame(42, frame)
  assert_eq(surface.handle(), 42)
  assert_eq(surface.get_width(), 3)
  assert_eq(surface.get_height(), 2)
}

///|
test "NativeSurface presents dirty and full RenderFrame paths" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(2, 1)
  layer.clear(@graphics.Color::white())
  layer.get_canvas().draw_pixel(1, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))

  let surface = NativeSurface::from_frame(42, frame)
  assert_true(surface.present_frame_dirty(frame) == Ok(1))
  assert_true(!frame.has_dirty())
  assert_true(surface.present_frame_dirty(frame) == Ok(0))
  assert_true(surface.present_frame_all(frame) == Ok(1))
  assert_true(!frame.has_dirty())
}

///|
test "NativeSurface exposes RenderFrame dirty submit plans" {
  let frame = @graphics.RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  frame.get_canvas().draw_pixel(0, 0, @graphics.Color::red())

  let middle = @graphics.Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, @graphics.Color::green())
  let right = @graphics.Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(middle))
  ignore(frame.get_layer_tree().add_layer(right))

  let surface = NativeSurface::from_frame(42, frame)
  let submit_plan = surface.dirty_frame_submit_plan(frame)
  assert_true(submit_plan.has_dirty())
  assert_true(submit_plan.needs_present())
  assert_true(submit_plan.uses_bounds_fallback())
  assert_eq(submit_plan.get_present_rect_count(), 1)
  assert_true(
    submit_plan.get_present_plan().get_rects()[0] ==
    @graphics.PixelRect::new(x=0, y=0, width=7, height=1),
  )
  assert_true(frame.has_dirty())

  let constructed_plan = dirty_render_frame_submit_plan(42, frame)
  assert_true(
    constructed_plan.get_present_plan().get_rects()[0] ==
    submit_plan.get_present_plan().get_rects()[0],
  )
}

///|
test "NativeSurface dirty submit plan preserves clipped-away dirty without presenting" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.mark_dirty_rect(@graphics.PixelRect::new(x=3, y=0, width=1, height=1))
  let surface = NativeSurface::new(42, 2, 1).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })

  let submit_plan = surface.dirty_frame_submit_plan(frame)
  assert_true(submit_plan.has_dirty())
  assert_true(!submit_plan.needs_present())
  assert_eq(submit_plan.get_present_rect_count(), 0)
  assert_true(
    submit_plan.get_present_plan().get_mode() ==
    @graphics.DirtyPresentPlanMode::Empty,
  )
  assert_eq(count.val, 0)
  assert_true(frame.has_dirty())
}

///|
test "render frame present helpers construct NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, @graphics.Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  assert_true(present_render_frame_dirty(42, frame) == Ok(1))
  assert_true(!frame.has_dirty())
  assert_true(present_render_frame_dirty(42, frame) == Ok(0))
  assert_true(present_render_frame_all(42, frame) == Ok(1))
}
