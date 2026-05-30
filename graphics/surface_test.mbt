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
  assert_eq(surface.get_present_pixel_count(), 4)
  assert_eq(surface.get_present_byte_count(), 16)
  assert_eq(surface.get_present_source_byte_count(), 16)
  assert_eq(surface.get_present_records().length(), 1)
  match surface.get_last_present_record() {
    Some(record) => {
      assert_true(
        record.get_rect() == PixelRect::new(x=0, y=0, width=2, height=2),
      )
      assert_eq(record.get_row_bytes(), 8)
      assert_eq(record.get_present_pixel_count(), 4)
      assert_eq(record.get_present_byte_count(), 16)
      assert_eq(record.get_source_byte_count(), 16)
    }
    None => abort("expected full present record")
  }
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
  assert_eq(surface.get_present_pixel_count(), 2)
  assert_eq(surface.get_present_byte_count(), 8)
  assert_eq(surface.get_present_source_byte_count(), 16)
  match surface.get_last_present_record() {
    Some(record) => {
      assert_true(
        record.get_rect() == PixelRect::new(x=0, y=0, width=1, height=2),
      )
      assert_eq(record.get_row_bytes(), 8)
      assert_eq(record.get_present_pixel_count(), 2)
      assert_eq(record.get_present_byte_count(), 8)
      assert_eq(record.get_source_byte_count(), 16)
    }
    None => abort("expected padded present record")
  }
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
  assert_eq(surface.get_present_pixel_count(), 4)
  assert_eq(surface.get_present_byte_count(), 16)
  assert_eq(surface.get_present_source_byte_count(), 16)
  match surface.get_last_present_record() {
    Some(record) => {
      assert_true(
        record.get_rect() == PixelRect::new(x=1, y=1, width=2, height=2),
      )
      assert_eq(record.get_row_bytes(), 8)
      assert_eq(record.get_present_pixel_count(), 4)
      assert_eq(record.get_present_byte_count(), 16)
      assert_eq(record.get_source_byte_count(), 16)
    }
    None => abort("expected rect present record")
  }
  assert_eq(surface.get_pixel(0, 0), Color::transparent())
  assert_eq(surface.get_pixel(1, 1), Color::red())
  assert_eq(surface.get_pixel(2, 1), Color::green())
  assert_eq(surface.get_pixel(1, 2), Color::blue())
  assert_eq(surface.get_pixel(2, 2), Color::white())
}

///|
test "MemorySurface::to_pixmap snapshots pixels with isolated storage" {
  let surface = MemorySurface::new(2, 1)
  let pixels : FixedArray[Byte] = FixedArray::make(8, 0)
  write_rgba(pixels, 0, Color::red())
  write_rgba(pixels, 4, Color::blue())
  assert_true(surface.present_pixels(2, 1, 8, pixels) == Ok(()))

  let pixmap = surface.to_pixmap()
  assert_eq(pixmap.get_width(), 2)
  assert_eq(pixmap.get_height(), 1)
  assert_eq(pixmap.get_pixel(0, 0), Color::red())
  assert_eq(pixmap.get_pixel(1, 0), Color::blue())

  pixmap.set_pixel(0, 0, Color::green())
  assert_eq(surface.get_pixel(0, 0), Color::red())
}

///|
test "MemorySurface::to_ppm_bytes exports current RGB pixels" {
  let surface = MemorySurface::new(1, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(8, 0)
  write_rgba(pixels, 0, Color::new(r=9, g=8, b=7, a=6))
  write_rgba(pixels, 4, Color::new(r=1, g=2, b=3, a=4))
  assert_true(surface.present_pixels(1, 2, 4, pixels) == Ok(()))

  let expected : Array[Byte] = [
    80, 54, 10, 49, 32, 50, 10, 50, 53, 53, 10, 9, 8, 7, 1, 2, 3,
  ]
  assert_eq(surface.to_ppm_bytes(), Bytes::from_array(expected))
}

///|
test "MemorySurface::checksum reports deterministic raw byte checksum" {
  let surface = MemorySurface::new(2, 1)
  let pixels : FixedArray[Byte] = FixedArray::make(8, 0)
  write_rgba(pixels, 0, Color::new(r=1, g=2, b=3, a=4))
  write_rgba(pixels, 4, Color::new(r=5, g=6, b=7, a=8))
  assert_true(surface.present_pixels(2, 1, 8, pixels) == Ok(()))
  assert_eq(surface.checksum(), 204)
}

///|
test "MemorySurface::to_rgba_bytes exports current raw bytes" {
  let surface = MemorySurface::new(2, 1)
  let pixels : FixedArray[Byte] = FixedArray::make(8, 0)
  write_rgba(pixels, 0, Color::new(r=1, g=2, b=3, a=4))
  write_rgba(pixels, 4, Color::new(r=5, g=6, b=7, a=8))
  assert_true(surface.present_pixels(2, 1, 8, pixels) == Ok(()))

  let expected : Array[Byte] = [1, 2, 3, 4, 5, 6, 7, 8]
  assert_eq(surface.to_rgba_bytes(), Bytes::from_array(expected))
}

///|
test "MemorySurface::to_pixmap_rect snapshots a clipped-free rectangle" {
  let surface = MemorySurface::new(3, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(24, 0)
  write_rgba(pixels, 0, Color::red())
  write_rgba(pixels, 4, Color::green())
  write_rgba(pixels, 8, Color::blue())
  write_rgba(pixels, 12, Color::white())
  write_rgba(pixels, 16, Color::black())
  write_rgba(pixels, 20, Color::transparent())
  assert_true(surface.present_pixels(3, 2, 12, pixels) == Ok(()))

  match surface.to_pixmap_rect(PixelRect::new(x=1, y=0, width=2, height=2)) {
    Ok(snapshot) => {
      assert_eq(snapshot.get_width(), 2)
      assert_eq(snapshot.get_height(), 2)
      assert_eq(snapshot.get_pixel(0, 0), Color::green())
      assert_eq(snapshot.get_pixel(1, 0), Color::blue())
      assert_eq(snapshot.get_pixel(0, 1), Color::black())
      assert_eq(snapshot.get_pixel(1, 1), Color::transparent())
      snapshot.set_pixel(0, 0, Color::red())
      assert_eq(surface.get_pixel(1, 0), Color::green())
    }
    Err(_) => abort("expected surface rect snapshot")
  }
}

///|
test "MemorySurface::to_ppm_rect_bytes exports a surface rectangle" {
  let surface = MemorySurface::new(3, 1)
  let pixels : FixedArray[Byte] = FixedArray::make(12, 0)
  write_rgba(pixels, 0, Color::red())
  write_rgba(pixels, 4, Color::green())
  write_rgba(pixels, 8, Color::blue())
  assert_true(surface.present_pixels(3, 1, 12, pixels) == Ok(()))

  let expected : Array[Byte] = [
    80, 54, 10, 50, 32, 49, 10, 50, 53, 53, 10, 0, 255, 0, 0, 0, 255,
  ]
  match surface.to_ppm_rect_bytes(PixelRect::new(x=1, y=0, width=2, height=1)) {
    Ok(ppm) => assert_eq(ppm, Bytes::from_array(expected))
    Err(_) => abort("expected surface rect ppm")
  }
}

///|
test "MemorySurface::to_rgba_rect_bytes exports packed surface rectangle" {
  let surface = MemorySurface::new(3, 1)
  let pixels : FixedArray[Byte] = FixedArray::make(12, 0)
  write_rgba(pixels, 0, Color::red())
  write_rgba(pixels, 4, Color::green())
  write_rgba(pixels, 8, Color::blue())
  assert_true(surface.present_pixels(3, 1, 12, pixels) == Ok(()))

  let expected : Array[Byte] = [0, 255, 0, 255, 0, 0, 255, 255]
  match
    surface.to_rgba_rect_bytes(PixelRect::new(x=1, y=0, width=2, height=1)) {
    Ok(bytes) => assert_eq(bytes, Bytes::from_array(expected))
    Err(_) => abort("expected surface rect rgba bytes")
  }
}

///|
test "MemorySurface::checksum_rect reports deterministic rect checksum" {
  let surface = MemorySurface::new(3, 1)
  let pixels : FixedArray[Byte] = FixedArray::make(12, 0)
  write_rgba(pixels, 0, Color::red())
  write_rgba(pixels, 4, Color::green())
  write_rgba(pixels, 8, Color::blue())
  assert_true(surface.present_pixels(3, 1, 12, pixels) == Ok(()))

  match surface.checksum_rect(PixelRect::new(x=1, y=0, width=2, height=1)) {
    Ok(checksum) => assert_eq(checksum, 5355)
    Err(_) => abort("expected surface rect checksum")
  }
}

///|
test "MemorySurface rect snapshots reject invalid rectangles" {
  let surface = MemorySurface::new(2, 2)
  match surface.to_pixmap_rect(PixelRect::new(x=1, y=1, width=2, height=1)) {
    Err(PresentError::RectOutOfBounds(1, 1, 2, 1, 2, 2)) => ()
    _ => abort("expected surface rect snapshot bounds error")
  }
  match surface.to_ppm_rect_bytes(PixelRect::new(x=0, y=0, width=0, height=1)) {
    Err(PresentError::InvalidDimensions(0, 1)) => ()
    _ => abort("expected surface rect ppm dimension error")
  }
  match
    surface.to_rgba_rect_bytes(PixelRect::new(x=0, y=0, width=1, height=0)) {
    Err(PresentError::InvalidDimensions(1, 0)) => ()
    _ => abort("expected surface rect rgba dimension error")
  }
  match surface.checksum_rect(PixelRect::new(x=0, y=0, width=3, height=1)) {
    Err(PresentError::RectOutOfBounds(0, 0, 3, 1, 2, 2)) => ()
    _ => abort("expected surface rect checksum bounds error")
  }
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
  assert_eq(surface.get_present_count(), 0)
  assert_eq(surface.get_present_pixel_count(), 0)
  assert_eq(surface.get_present_byte_count(), 0)
  assert_eq(surface.get_present_source_byte_count(), 0)
  assert_eq(surface.get_present_records().length(), 0)
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
test "Pixmap::present_rect_payload materializes packed pixels" {
  let pixmap = Pixmap::new(3, 2)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(1, 0, Color::green())
  pixmap.set_pixel(2, 0, Color::blue())
  pixmap.set_pixel(0, 1, Color::white())
  pixmap.set_pixel(1, 1, Color::black())
  pixmap.set_pixel(2, 1, Color::transparent())

  match
    pixmap.present_rect_payload(PixelRect::new(x=1, y=0, width=2, height=2)) {
    Ok(payload) => {
      assert_true(
        payload.get_rect() == PixelRect::new(x=1, y=0, width=2, height=2),
      )
      assert_eq(payload.get_row_bytes(), 8)
      assert_eq(payload.get_present_pixel_count(), 4)
      assert_eq(payload.get_present_byte_count(), 16)
      let pixels = payload.get_pixels()
      assert_eq(pixels.length(), 16)
      assert_rgba(pixels, 0, Color::green())
      assert_rgba(pixels, 4, Color::blue())
      assert_rgba(pixels, 8, Color::black())
      assert_rgba(pixels, 12, Color::transparent())
    }
    Err(_) => abort("expected packed present payload")
  }
}

///|
test "Pixmap::copy_rect snapshots a source rectangle" {
  let pixmap = Pixmap::new(3, 2)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(1, 0, Color::green())
  pixmap.set_pixel(2, 0, Color::blue())
  pixmap.set_pixel(1, 1, Color::black())
  pixmap.set_pixel(2, 1, Color::white())

  match pixmap.copy_rect(PixelRect::new(x=1, y=0, width=2, height=2)) {
    Ok(snapshot) => {
      assert_eq(snapshot.get_width(), 2)
      assert_eq(snapshot.get_height(), 2)
      assert_eq(snapshot.get_pixel(0, 0), Color::green())
      assert_eq(snapshot.get_pixel(1, 0), Color::blue())
      assert_eq(snapshot.get_pixel(0, 1), Color::black())
      assert_eq(snapshot.get_pixel(1, 1), Color::white())
      snapshot.set_pixel(0, 0, Color::red())
      assert_eq(pixmap.get_pixel(1, 0), Color::green())
    }
    Err(_) => abort("expected pixmap rect snapshot")
  }
}

///|
test "Pixmap::to_ppm_rect_bytes exports a source rectangle" {
  let pixmap = Pixmap::new(3, 1)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(1, 0, Color::new(r=4, g=5, b=6, a=7))
  pixmap.set_pixel(2, 0, Color::new(r=8, g=9, b=10, a=11))
  let expected : Array[Byte] = [
    80, 54, 10, 50, 32, 49, 10, 50, 53, 53, 10, 4, 5, 6, 8, 9, 10,
  ]

  match pixmap.to_ppm_rect_bytes(PixelRect::new(x=1, y=0, width=2, height=1)) {
    Ok(ppm) => assert_eq(ppm, Bytes::from_array(expected))
    Err(_) => abort("expected pixmap rect ppm")
  }
}

///|
test "Pixmap::checksum_rect reports deterministic rect checksum" {
  let pixmap = Pixmap::new(3, 1)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(1, 0, Color::green())
  pixmap.set_pixel(2, 0, Color::blue())

  match pixmap.checksum_rect(PixelRect::new(x=1, y=0, width=2, height=1)) {
    Ok(checksum) => assert_eq(checksum, 5355)
    Err(_) => abort("expected pixmap rect checksum")
  }
}

///|
test "Pixmap::to_rgba_rect_bytes exports packed source rectangle" {
  let pixmap = Pixmap::new(3, 1)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(1, 0, Color::green())
  pixmap.set_pixel(2, 0, Color::blue())
  let expected : Array[Byte] = [0, 255, 0, 255, 0, 0, 255, 255]

  match pixmap.to_rgba_rect_bytes(PixelRect::new(x=1, y=0, width=2, height=1)) {
    Ok(bytes) => assert_eq(bytes, Bytes::from_array(expected))
    Err(_) => abort("expected pixmap rect rgba bytes")
  }
}

///|
test "Pixmap rect snapshots reuse present rect validation" {
  let pixmap = Pixmap::new(2, 2)
  match pixmap.copy_rect(PixelRect::new(x=-1, y=0, width=1, height=1)) {
    Err(PresentError::RectOutOfBounds(-1, 0, 1, 1, 2, 2)) => ()
    _ => abort("expected pixmap rect snapshot bounds error")
  }
  match pixmap.to_ppm_rect_bytes(PixelRect::new(x=0, y=0, width=1, height=0)) {
    Err(PresentError::InvalidDimensions(1, 0)) => ()
    _ => abort("expected pixmap rect ppm dimension error")
  }
  match
    pixmap.to_rgba_rect_bytes(PixelRect::new(x=-1, y=0, width=1, height=1)) {
    Err(PresentError::RectOutOfBounds(-1, 0, 1, 1, 2, 2)) => ()
    _ => abort("expected pixmap rect rgba bounds error")
  }
  match pixmap.checksum_rect(PixelRect::new(x=2, y=0, width=1, height=1)) {
    Err(PresentError::RectOutOfBounds(2, 0, 1, 1, 2, 2)) => ()
    _ => abort("expected pixmap rect checksum bounds error")
  }
}

///|
test "Pixmap::present_batch materializes dirty present plan" {
  let pixmap = Pixmap::new(4, 2)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(2, 1, Color::blue())
  let region = DirtyRegion::new()
  region.add_rect(PixelRect::new(x=0, y=0, width=1, height=1))
  region.add_rect(PixelRect::new(x=2, y=1, width=1, height=1))
  let plan = region.present_plan(PixelRect::new(x=0, y=0, width=4, height=2), 4)

  match pixmap.present_batch(plan) {
    Ok(batch) => {
      assert_true(!batch.is_empty())
      assert_eq(batch.get_rect_count(), 2)
      assert_eq(batch.get_present_pixel_count(), 2)
      assert_eq(batch.get_present_byte_count(), 8)
      let payloads = batch.get_payloads()
      assert_true(
        payloads[0].get_rect() == PixelRect::new(x=0, y=0, width=1, height=1),
      )
      assert_true(
        payloads[1].get_rect() == PixelRect::new(x=2, y=1, width=1, height=1),
      )
      let surface = MemorySurface::new(4, 2)
      assert_true(batch.submit_to(surface) == Ok(2))
      assert_eq(surface.get_present_count(), 2)
      assert_eq(surface.get_present_pixel_count(), 2)
      assert_eq(surface.get_present_byte_count(), 8)
      assert_eq(surface.get_present_source_byte_count(), 8)
      let records = surface.get_present_records()
      assert_eq(records.length(), 2)
      assert_true(
        records[0].get_rect() == PixelRect::new(x=0, y=0, width=1, height=1),
      )
      assert_true(
        records[1].get_rect() == PixelRect::new(x=2, y=1, width=1, height=1),
      )
      assert_eq(records[0].get_row_bytes(), 4)
      assert_eq(records[1].get_row_bytes(), 4)
      assert_eq(records[0].get_present_pixel_count(), 1)
      assert_eq(records[1].get_present_byte_count(), 4)
      assert_eq(records[0].get_source_byte_count(), 4)
      assert_eq(records[1].get_source_byte_count(), 4)
      assert_eq(surface.get_pixel(0, 0), Color::red())
      assert_eq(surface.get_pixel(2, 1), Color::blue())
      assert_true(batch.validate_for(surface) == Ok(()))
    }
    Err(_) => abort("expected dirty present batch")
  }
}

///|
test "PresentBatch::submit_to preflights every payload before presenting" {
  let pixmap = Pixmap::new(4, 2)
  pixmap.set_pixel(0, 0, Color::red())
  pixmap.set_pixel(2, 1, Color::blue())
  let region = DirtyRegion::new()
  region.add_rect(PixelRect::new(x=0, y=0, width=1, height=1))
  region.add_rect(PixelRect::new(x=2, y=1, width=1, height=1))
  let plan = region.present_plan(PixelRect::new(x=0, y=0, width=4, height=2), 4)

  match pixmap.present_batch(plan) {
    Ok(batch) => {
      let surface = MemorySurface::new(2, 2)
      assert_true(
        batch.validate_for(surface) ==
        Err(PresentError::RectOutOfBounds(2, 1, 1, 1, 2, 2)),
      )
      assert_true(
        batch.submit_to(surface) ==
        Err(PresentError::RectOutOfBounds(2, 1, 1, 1, 2, 2)),
      )
      assert_eq(surface.get_present_count(), 0)
      assert_eq(surface.get_present_records().length(), 0)
      assert_eq(surface.get_pixel(0, 0), Color::transparent())
    }
    Err(_) => abort("expected dirty present batch")
  }
}

///|
test "Pixmap::present_batch rejects out-of-bounds rects" {
  let pixmap = Pixmap::new(2, 2)
  let region = DirtyRegion::new()
  region.add_rect(PixelRect::new(x=1, y=1, width=2, height=1))
  let plan = region.present_plan(PixelRect::new(x=0, y=0, width=3, height=2), 4)
  match pixmap.present_batch(plan) {
    Err(PresentError::RectOutOfBounds(1, 1, 2, 1, 2, 2)) => ()
    _ => abort("expected out-of-bounds present batch error")
  }
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
  assert_eq(surface.get_present_records().length(), 2)
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
  assert_eq(surface.get_present_pixel_count(), 7)
  assert_eq(surface.get_present_byte_count(), 28)
  assert_eq(surface.get_present_source_byte_count(), 28)
  match surface.get_last_present_record() {
    Some(record) => {
      assert_true(
        record.get_rect() == PixelRect::new(x=0, y=0, width=7, height=1),
      )
      assert_eq(record.get_present_pixel_count(), 7)
      assert_eq(record.get_present_byte_count(), 28)
      assert_eq(record.get_source_byte_count(), 28)
    }
    None => abort("expected dirty bounds present record")
  }
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(3, 0), Color::green())
  assert_eq(surface.get_pixel(6, 0), Color::blue())
  assert_true(canvas.get_dirty_region().is_empty())
}

///|
test "Canvas::dirty_present_plan matches bounded dirty submit strategy" {
  let canvas = Canvas::new(8, 2)
  canvas.draw_pixel(0, 0, Color::red())
  canvas.draw_pixel(3, 0, Color::green())
  canvas.draw_pixel(6, 0, Color::blue())

  let surface = MemorySurface::new(8, 2)
  let rect_plan = canvas.dirty_present_plan(surface, 4)
  assert_true(rect_plan.get_mode() == DirtyPresentPlanMode::Rects)
  assert_eq(rect_plan.get_rect_count(), 3)
  assert_true(
    rect_plan.get_rects()[2] == PixelRect::new(x=6, y=0, width=1, height=1),
  )

  let bounds_plan = canvas.dirty_present_plan(surface, 2)
  assert_true(bounds_plan.get_mode() == DirtyPresentPlanMode::Bounds)
  assert_true(bounds_plan.uses_bounds_fallback())
  assert_eq(bounds_plan.get_rect_count(), 1)
  assert_true(
    bounds_plan.get_rects()[0] == PixelRect::new(x=0, y=0, width=7, height=1),
  )
  assert_true(!canvas.get_dirty_region().is_empty())

  assert_true(canvas.present_dirty_to_with_limit(surface, 2) == Ok(1))
  assert_true(canvas.get_dirty_region().is_empty())

  let empty_plan = canvas.dirty_present_plan(surface, 2)
  assert_true(empty_plan.is_empty())
  assert_true(empty_plan.get_mode() == DirtyPresentPlanMode::Empty)
}

///|
test "Canvas::dirty_present_batch materializes without clearing dirty" {
  let canvas = Canvas::new(8, 2)
  canvas.draw_pixel(0, 0, Color::red())
  canvas.draw_pixel(3, 0, Color::green())
  canvas.draw_pixel(6, 0, Color::blue())
  let surface = MemorySurface::new(8, 2)

  match canvas.dirty_present_batch(surface, 2) {
    Ok(batch) => {
      assert_eq(batch.get_rect_count(), 1)
      assert_eq(batch.get_present_pixel_count(), 7)
      assert_eq(batch.get_present_byte_count(), 28)
      let payloads = batch.get_payloads()
      assert_true(
        payloads[0].get_rect() == PixelRect::new(x=0, y=0, width=7, height=1),
      )
      assert_eq(payloads[0].get_row_bytes(), 28)
    }
    Err(_) => abort("expected dirty present batch")
  }

  assert_eq(surface.get_present_count(), 0)
  assert_true(!canvas.get_dirty_region().is_empty())
  assert_true(canvas.present_dirty_to_with_limit(surface, 2) == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_true(canvas.get_dirty_region().is_empty())
}

///|
test "Canvas::dirty_present_batch returns empty batch for clipped dirty" {
  let canvas = Canvas::new(3, 3)
  canvas.draw_pixel(2, 2, Color::white())
  let surface = MemorySurface::new(2, 2)

  match canvas.dirty_present_batch(surface, 4) {
    Ok(batch) => {
      assert_true(batch.is_empty())
      assert_eq(batch.get_rect_count(), 0)
      assert_eq(batch.get_present_pixel_count(), 0)
      assert_eq(batch.get_present_byte_count(), 0)
    }
    Err(_) => abort("expected empty dirty present batch")
  }

  assert_eq(surface.get_present_count(), 0)
  assert_true(!canvas.get_dirty_region().is_empty())
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

///|
fn assert_rgba(
  pixels : FixedArray[Byte],
  offset : Int,
  color : Color,
) -> Unit raise {
  assert_eq(pixels[offset], color.r)
  assert_eq(pixels[offset + 1], color.g)
  assert_eq(pixels[offset + 2], color.b)
  assert_eq(pixels[offset + 3], color.a)
}
