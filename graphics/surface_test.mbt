///|
test "MemorySurface::present_pixels copies RGBA rows" {
  let surface = MemorySurface::new(2, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  write_rgba(pixels, 0, Color::red())
  write_rgba(pixels, 4, Color::green())
  write_rgba(pixels, 8, Color::blue())
  write_rgba(pixels, 12, Color::white())
  let result = surface.present_pixels(2, 2, 8, pixels)
  assert_true(result == Ok(()))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(1, 0), Color::green())
  assert_eq(surface.get_pixel(0, 1), Color::blue())
  assert_eq(surface.get_pixel(1, 1), Color::white())
}

///|
test "MemorySurface::present_pixels supports padded row bytes" {
  let surface = MemorySurface::new(1, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(12, 0)
  write_rgba(pixels, 0, Color::red())
  pixels[4] = 99
  pixels[5] = 98
  pixels[6] = 97
  pixels[7] = 96
  write_rgba(pixels, 8, Color::blue())
  let result = surface.present_pixels(1, 2, 8, pixels)
  assert_true(result == Ok(()))
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(0, 1), Color::blue())
  assert_eq(surface.get_pixels().length(), 8)
}

///|
test "MemorySurface::present_pixels_rect updates only destination rectangle" {
  let surface = MemorySurface::new(3, 3)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  write_rgba(pixels, 0, Color::red())
  write_rgba(pixels, 4, Color::green())
  write_rgba(pixels, 8, Color::blue())
  write_rgba(pixels, 12, Color::white())
  let result = surface.present_pixels_rect(1, 1, 2, 2, 8, pixels)
  assert_true(result == Ok(()))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(0, 0), Color::transparent())
  assert_eq(surface.get_pixel(1, 1), Color::red())
  assert_eq(surface.get_pixel(2, 1), Color::green())
  assert_eq(surface.get_pixel(1, 2), Color::blue())
  assert_eq(surface.get_pixel(2, 2), Color::white())
}

///|
test "MemorySurface::present_pixels_rect validates destination bounds" {
  let surface = MemorySurface::new(3, 3)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  assert_true(
    surface.present_pixels_rect(2, 1, 2, 2, 8, pixels) ==
    Err(PresentError::RectOutOfBounds(2, 1, 2, 2, 3, 3)),
  )
  assert_true(
    surface.present_pixels_rect(-1, 0, 1, 1, 4, pixels) ==
    Err(PresentError::RectOutOfBounds(-1, 0, 1, 1, 3, 3)),
  )
}

///|
test "validate_present_rect reports shared row-stride contract" {
  let pixels : FixedArray[Byte] = FixedArray::make(20, 0)
  match validate_present_rect(4, 3, 1, 1, 2, 2, 12, pixels) {
    Ok(info) => {
      assert_eq(info.required_row_bytes(), 8)
      assert_eq(info.required_len(), 20)
    }
    Err(_) => abort("expected valid present rect")
  }
  assert_true(
    validate_present_rect(4, 3, 3, 1, 2, 1, 8, pixels) ==
    Err(PresentError::RectOutOfBounds(3, 1, 2, 1, 4, 3)),
  )
  assert_true(
    validate_present_rect(4, 3, 1, 1, 2, 2, 4, pixels) ==
    Err(PresentError::InvalidRowBytes(4, 8)),
  )
  let short_pixels : FixedArray[Byte] = FixedArray::make(19, 0)
  assert_true(
    validate_present_rect(4, 3, 1, 1, 2, 2, 12, short_pixels) ==
    Err(PresentError::PixelBufferTooSmall(19, 20)),
  )
}

///|
test "MemorySurface::present_pixels validates dimensions and buffer" {
  let surface = MemorySurface::new(2, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  assert_true(
    surface.present_pixels(0, 2, 8, pixels) ==
    Err(PresentError::InvalidDimensions(0, 2)),
  )
  assert_true(
    surface.present_pixels(1, 2, 4, pixels) ==
    Err(PresentError::SizeMismatch(2, 2, 1, 2)),
  )
  assert_true(
    surface.present_pixels(2, 2, 4, pixels) ==
    Err(PresentError::InvalidRowBytes(4, 8)),
  )
  let short_pixels : FixedArray[Byte] = FixedArray::make(15, 0)
  assert_true(
    surface.present_pixels(2, 2, 8, short_pixels) ==
    Err(PresentError::PixelBufferTooSmall(15, 16)),
  )
}

///|
test "Pixmap::present_to presents pixmap pixels to surface" {
  let pixmap = Pixmap::new(2, 1)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(1, 0, Color::blue())
  let surface = MemorySurface::new(2, 1)
  let result = pixmap.present_to(surface)
  assert_true(result == Ok(()))
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(1, 0), Color::blue())
}

///|
test "Pixmap::present_rect_to presents a packed sub-rectangle" {
  let pixmap = Pixmap::new(3, 2)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(1, 0, Color::green())
  pixmap.set_pixel(2, 0, Color::blue())
  pixmap.set_pixel(0, 1, Color::white())
  pixmap.set_pixel(1, 1, Color::black())
  pixmap.set_pixel(2, 1, Color::transparent())
  let surface = MemorySurface::new(3, 2)
  let result = pixmap.present_rect_to(
    surface,
    PixelRect::new(x=1, y=0, width=2, height=2),
  )
  assert_true(result == Ok(()))
  assert_eq(surface.get_pixel(0, 0), Color::transparent())
  assert_eq(surface.get_pixel(1, 0), Color::green())
  assert_eq(surface.get_pixel(2, 0), Color::blue())
  assert_eq(surface.get_pixel(1, 1), Color::black())
  assert_eq(surface.get_pixel(2, 1), Color::transparent())
}

///|
test "Canvas::present_to presents rendered canvas pixels to surface" {
  let canvas = Canvas::new(2, 1)
  canvas.clear(Color::white())
  canvas.fill_rect(0.0, 0.0, 1.0, 1.0, Paint::new().set_color(Color::black()))
  let surface = MemorySurface::new(2, 1)
  let result = canvas.present_to(surface)
  assert_true(result == Ok(()))
  assert_eq(surface.get_pixel(0, 0), Color::black())
  assert_eq(surface.get_pixel(1, 0), Color::white())
}

///|
test "Canvas::present_dirty_to presents dirty rectangles and clears tracking" {
  let canvas = Canvas::new(4, 3)
  canvas.draw_pixel(1, 1, Color::red())
  canvas.draw_pixel(3, 2, Color::blue())
  let surface = MemorySurface::new(4, 3)
  let result = canvas.present_dirty_to(surface)
  assert_true(result == Ok(2))
  assert_eq(surface.get_present_count(), 2)
  assert_eq(surface.get_pixel(1, 1), Color::red())
  assert_eq(surface.get_pixel(3, 2), Color::blue())
  assert_true(canvas.get_dirty_region().is_empty())
  assert_true(canvas.present_dirty_to(surface) == Ok(0))
}

///|
test "Canvas::present_dirty_to presents merged adjacent dirty rectangles" {
  let canvas = Canvas::new(4, 2)
  canvas.draw_pixel(1, 0, Color::red())
  canvas.draw_pixel(2, 0, Color::green())
  let surface = MemorySurface::new(4, 2)
  let result = canvas.present_dirty_to(surface)
  assert_true(result == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(1, 0), Color::red())
  assert_eq(surface.get_pixel(2, 0), Color::green())
}

///|
test "Canvas::present_dirty_to_with_limit falls back to dirty bounds" {
  let canvas = Canvas::new(8, 2)
  canvas.draw_pixel(0, 0, Color::red())
  canvas.draw_pixel(3, 0, Color::green())
  canvas.draw_pixel(6, 0, Color::blue())
  let surface = MemorySurface::new(8, 2)
  let result = canvas.present_dirty_to_with_limit(surface, 2)
  assert_true(result == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(3, 0), Color::green())
  assert_eq(surface.get_pixel(6, 0), Color::blue())
  assert_true(canvas.get_dirty_region().is_empty())
}

///|
test "Canvas::present_dirty_to clips dirty rectangles to surface bounds" {
  let canvas = Canvas::new(3, 3)
  canvas.draw_pixel(2, 2, Color::white())
  let surface = MemorySurface::new(2, 2)
  let result = canvas.present_dirty_to(surface)
  assert_true(result == Ok(0))
  assert_true(canvas.get_dirty_region().is_empty())
  assert_eq(surface.get_present_count(), 0)
}

///|
test "present_pixels helper dispatches through Surface trait" {
  let surface = MemorySurface::new(1, 1)
  let pixels : FixedArray[Byte] = FixedArray::make(4, 0)
  write_rgba(pixels, 0, Color::green())
  let result = present_pixels(surface, 1, 1, 4, pixels)
  assert_true(result == Ok(()))
  assert_eq(surface.get_pixel(0, 0), Color::green())
}

///|
test "present_pixels_rect helper dispatches through Surface trait" {
  let surface = MemorySurface::new(2, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(4, 0)
  write_rgba(pixels, 0, Color::blue())
  let result = present_pixels_rect(surface, 1, 1, 1, 1, 4, pixels)
  assert_true(result == Ok(()))
  assert_eq(surface.get_pixel(1, 1), Color::blue())
}

///|
fn write_rgba(pixels : FixedArray[Byte], offset : Int, color : Color) -> Unit {
  pixels[offset] = color.r
  pixels[offset + 1] = color.g
  pixels[offset + 2] = color.b
  pixels[offset + 3] = color.a
}
