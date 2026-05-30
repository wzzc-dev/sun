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
