///|
test "Pixmap::new creates pixmap with correct dimensions" {
  let pixmap = Pixmap::new(100, 50)
  assert_eq(pixmap.get_width(), 100)
  assert_eq(pixmap.get_height(), 50)
}

///|
test "Pixmap::set_pixel and get_pixel" {
  let pixmap = Pixmap::new(10, 10)
  let color = Color::new(r=255, g=0, b=0)
  pixmap.set_pixel(5, 5, color)
  let got = pixmap.get_pixel(5, 5)
  assert_eq(got, color)
}

///|
test "Pixmap::copy duplicates raw pixel storage" {
  let pixmap = Pixmap::new(2, 1)
  pixmap.set_pixel(0, 0, Color::red())
  let copy = pixmap.copy()
  assert_eq(copy.get_width(), 2)
  assert_eq(copy.get_height(), 1)
  assert_eq(copy.get_pixel(0, 0), Color::red())
  let copy_pixels = copy.get_pixels()
  copy_pixels[0] = 0
  assert_eq(pixmap.get_pixel(0, 0), Color::red())
  assert_eq(copy.get_pixel(0, 0), Color::new(r=0, g=0, b=0, a=255))
}

///|
test "Pixmap::checksum reports deterministic raw byte checksum" {
  let pixmap = Pixmap::new(2, 1)
  pixmap.set_pixel(0, 0, Color::new(r=1, g=2, b=3, a=4))
  pixmap.set_pixel(1, 0, Color::new(r=5, g=6, b=7, a=8))
  assert_eq(pixmap.checksum(), 204)
}

///|
test "Pixmap::to_rgba_bytes exports raw RGBA bytes" {
  let pixmap = Pixmap::new(2, 1)
  pixmap.set_pixel(0, 0, Color::new(r=1, g=2, b=3, a=4))
  pixmap.set_pixel(1, 0, Color::new(r=5, g=6, b=7, a=8))
  let expected : Array[Byte] = [1, 2, 3, 4, 5, 6, 7, 8]
  assert_eq(pixmap.to_rgba_bytes(), Bytes::from_array(expected))
}

///|
test "Pixmap::from_rgba_bytes decodes packed raw pixels" {
  let bytes = Bytes::from_array([1, 2, 3, 4, 5, 6, 7, 8])
  match Pixmap::from_rgba_bytes(2, 1, bytes) {
    Ok(decoded) => {
      assert_eq(decoded.get_width(), 2)
      assert_eq(decoded.get_height(), 1)
      assert_eq(decoded.get_pixel(0, 0), Color::new(r=1, g=2, b=3, a=4))
      assert_eq(decoded.get_pixel(1, 0), Color::new(r=5, g=6, b=7, a=8))
      decoded.set_pixel(0, 0, Color::red())
      assert_eq(bytes, Bytes::from_array([1, 2, 3, 4, 5, 6, 7, 8]))
    }
    Err(_) => abort("expected RGBA decode")
  }

  match Pixmap::from_rgba_bytes(0, 0, Bytes::from_array([])) {
    Ok(empty) => {
      assert_eq(empty.get_width(), 0)
      assert_eq(empty.get_height(), 0)
      assert_eq(empty.to_rgba_bytes(), Bytes::from_array([]))
    }
    Err(_) => abort("expected empty RGBA decode")
  }
}

///|
test "Pixmap::from_rgba_bytes reports structural errors" {
  match Pixmap::from_rgba_bytes(-1, 1, Bytes::from_array([])) {
    Err(PixmapDecodeError::InvalidRgbaDimensions(-1, 1)) => ()
    _ => abort("expected RGBA dimensions error")
  }

  match Pixmap::from_rgba_bytes(2, 1, Bytes::from_array([1, 2, 3, 4])) {
    Err(PixmapDecodeError::RgbaByteLengthMismatch(8, 4)) => ()
    _ => abort("expected RGBA length mismatch")
  }
}

///|
test "Pixmap::to_ppm_bytes encodes deterministic P6 RGB output" {
  let pixmap = Pixmap::new(2, 1)
  pixmap.set_pixel(0, 0, Color::new(r=1, g=2, b=3, a=4))
  pixmap.set_pixel(1, 0, Color::new(r=250, g=251, b=252, a=253))
  let ppm = pixmap.to_ppm_bytes()
  let expected : Array[Byte] = [
    80, 54, 10, 50, 32, 49, 10, 50, 53, 53, 10, 1, 2, 3, 250, 251, 252,
  ]
  assert_eq(ppm, Bytes::from_array(expected))
}

///|
test "Pixmap::to_ppm_bytes encodes empty dimensions" {
  let pixmap = Pixmap::new(0, 0)
  let expected : Array[Byte] = [80, 54, 10, 48, 32, 48, 10, 50, 53, 53, 10]
  assert_eq(pixmap.to_ppm_bytes(), Bytes::from_array(expected))
}

///|
test "Pixmap::to_bmp_bytes encodes deterministic BGRA output" {
  let pixmap = Pixmap::new(2, 2)
  pixmap.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=255))
  pixmap.set_pixel(1, 0, Color::new(r=0, g=255, b=0, a=128))
  pixmap.set_pixel(0, 1, Color::new(r=0, g=0, b=255, a=64))
  pixmap.set_pixel(1, 1, Color::transparent())
  let expected : Array[Byte] = [
    66, 77, 70, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 2, 0, 0, 0, 2, 0,
    0, 0, 1, 0, 32, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 255, 0, 0, 64, 0, 0, 0, 0, 0, 0, 255, 255, 0, 255, 0, 128,
  ]
  assert_eq(pixmap.to_bmp_bytes(), Bytes::from_array(expected))
}

///|
test "Pixmap::to_bmp_bytes encodes empty dimensions" {
  let pixmap = Pixmap::new(0, 0)
  let expected : Array[Byte] = [
    66, 77, 54, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0,
  ]
  assert_eq(pixmap.to_bmp_bytes(), Bytes::from_array(expected))
}

///|
test "Pixmap::to_png_bytes encodes deterministic RGBA output" {
  let pixmap = Pixmap::new(1, 1)
  pixmap.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=255))
  match pixmap.to_png_bytes() {
    Ok(png) => assert_eq(png, Bytes::from_array(make_pixmap_test_red_png()))
    Err(_) => abort("expected PNG encode")
  }
}

///|
test "Pixmap::to_png_bytes rejects empty dimensions" {
  match Pixmap::new(0, 0).to_png_bytes() {
    Err(PixmapEncodeError::InvalidPngDimensions(0, 0)) => ()
    _ => abort("expected PNG dimensions error")
  }
}

///|
test "Pixmap::from_png_bytes decodes exported RGBA PNG bytes" {
  let pixmap = Pixmap::new(2, 2)
  pixmap.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=255))
  pixmap.set_pixel(1, 0, Color::new(r=0, g=255, b=0, a=128))
  pixmap.set_pixel(0, 1, Color::new(r=0, g=0, b=255, a=64))
  pixmap.set_pixel(1, 1, Color::new(r=10, g=20, b=30, a=40))

  match pixmap.to_png_bytes() {
    Ok(png) =>
      match Pixmap::from_png_bytes(png) {
        Ok(decoded) => {
          assert_eq(decoded.get_width(), 2)
          assert_eq(decoded.get_height(), 2)
          assert_eq(decoded.to_rgba_bytes(), pixmap.to_rgba_bytes())
        }
        Err(_) => abort("expected PNG decode")
      }
    Err(_) => abort("expected PNG encode")
  }
}

///|
test "Pixmap::from_png_bytes reports structural errors" {
  match Pixmap::from_png_bytes(Bytes::from_array([137, 80])) {
    Err(PixmapDecodeError::UnexpectedEndOfData(0, 8, 2)) => ()
    _ => abort("expected short PNG error")
  }

  let bad_signature = make_pixmap_test_red_png()
  bad_signature[0] = 0
  match Pixmap::from_png_bytes(Bytes::from_array(bad_signature)) {
    Err(PixmapDecodeError::InvalidPngSignature) => ()
    _ => abort("expected PNG signature error")
  }

  let bad_crc = make_pixmap_test_red_png()
  bad_crc[32] = 0
  match Pixmap::from_png_bytes(Bytes::from_array(bad_crc)) {
    Err(PixmapDecodeError::PngCrcMismatch(0x1F15C400, 0x1F15C489)) => ()
    _ => abort("expected PNG CRC mismatch")
  }
}

///|
test "Pixmap::from_bmp_bytes decodes exported 32-bit BMP bytes" {
  let pixmap = Pixmap::new(2, 2)
  pixmap.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=255))
  pixmap.set_pixel(1, 0, Color::new(r=0, g=255, b=0, a=128))
  pixmap.set_pixel(0, 1, Color::new(r=0, g=0, b=255, a=64))
  pixmap.set_pixel(1, 1, Color::new(r=10, g=20, b=30, a=40))

  match Pixmap::from_bmp_bytes(pixmap.to_bmp_bytes()) {
    Ok(decoded) => {
      assert_eq(decoded.get_width(), 2)
      assert_eq(decoded.get_height(), 2)
      assert_eq(decoded.to_rgba_bytes(), pixmap.to_rgba_bytes())
    }
    Err(_) => abort("expected BMP decode to succeed")
  }
}

///|
test "Pixmap::from_bmp_bytes accepts top-down BMP row order" {
  let top_down_bmp : Array[Byte] = [
    66, 77, 62, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 1, 0, 0, 0, 254, 255,
    255, 255, 1, 0, 32, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 7, 8, 9, 6, 3, 2, 1, 4,
  ]

  match Pixmap::from_bmp_bytes(Bytes::from_array(top_down_bmp)) {
    Ok(decoded) => {
      assert_eq(decoded.get_width(), 1)
      assert_eq(decoded.get_height(), 2)
      assert_eq(decoded.get_pixel(0, 0), Color::new(r=9, g=8, b=7, a=6))
      assert_eq(decoded.get_pixel(0, 1), Color::new(r=1, g=2, b=3, a=4))
    }
    Err(_) => abort("expected top-down BMP decode")
  }
}

///|
test "Pixmap::from_bmp_bytes decodes padded 24-bit BMP rows" {
  let bmp : Array[Byte] = [
    66, 77, 70, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 2, 0, 0, 0, 2, 0,
    0, 0, 1, 0, 24, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 255, 0, 0, 255, 255, 255, 12, 34, 0, 0, 255, 0, 255, 0, 56, 78,
  ]

  match Pixmap::from_bmp_bytes(Bytes::from_array(bmp)) {
    Ok(decoded) => {
      assert_eq(decoded.get_width(), 2)
      assert_eq(decoded.get_height(), 2)
      assert_eq(decoded.get_pixel(0, 0), Color::red())
      assert_eq(decoded.get_pixel(1, 0), Color::green())
      assert_eq(decoded.get_pixel(0, 1), Color::blue())
      assert_eq(decoded.get_pixel(1, 1), Color::white())
    }
    Err(_) => abort("expected padded 24-bit BMP decode")
  }
}

///|
test "Pixmap::from_bmp_bytes reports structural errors" {
  match Pixmap::from_bmp_bytes(Bytes::from_array([66, 77])) {
    Err(PixmapDecodeError::UnexpectedEndOfData(0, 54, 2)) => ()
    _ => abort("expected BMP short-data error")
  }

  let bad_signature : Array[Byte] = [
    0, 0, 54, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0,
  ]
  match Pixmap::from_bmp_bytes(Bytes::from_array(bad_signature)) {
    Err(PixmapDecodeError::InvalidBmpSignature(0, 0)) => ()
    _ => abort("expected BMP signature error")
  }

  let unsupported_bpp : Array[Byte] = [
    66, 77, 54, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 1, 0, 0, 0, 1, 0,
    0, 0, 1, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0,
  ]
  match Pixmap::from_bmp_bytes(Bytes::from_array(unsupported_bpp)) {
    Err(PixmapDecodeError::UnsupportedBmpBitsPerPixel(16)) => ()
    _ => abort("expected BMP bits-per-pixel error")
  }

  let truncated_pixels : Array[Byte] = [
    66, 77, 54, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 1, 0, 0, 0, 1, 0,
    0, 0, 1, 0, 32, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0,
  ]
  match Pixmap::from_bmp_bytes(Bytes::from_array(truncated_pixels)) {
    Err(PixmapDecodeError::BmpPixelDataOutOfBounds(54, 58, 54)) => ()
    _ => abort("expected BMP pixel-data bounds error")
  }
}

///|
test "PixmapCache stores copies and manages entries" {
  let cache = PixmapCache::new()
  assert_true(cache.is_empty())
  assert_true(!cache.is_capacity_bounded())
  assert_eq(cache.capacity(), 0)
  let pixmap = Pixmap::new(2, 1)
  pixmap.set_pixel(0, 0, Color::red())
  let inserted = cache.insert("icon", pixmap)
  assert_eq(cache.len(), 1)
  assert_eq(inserted.get_pixel(0, 0), Color::red())

  pixmap.set_pixel(0, 0, Color::blue())
  match cache.get("icon") {
    Some(cached) => {
      assert_eq(cached.get_width(), 2)
      assert_eq(cached.get_height(), 1)
      assert_eq(cached.get_pixel(0, 0), Color::red())
      cached.set_pixel(0, 0, Color::green())
    }
    None => abort("expected cached pixmap")
  }

  match cache.get("icon") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::red())
    None => abort("expected cached pixmap")
  }

  let replacement = Pixmap::new(1, 1)
  replacement.set_pixel(0, 0, Color::black())
  ignore(cache.insert("icon", replacement))
  assert_eq(cache.len(), 1)
  match cache.get("icon") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::black())
    None => abort("expected replacement pixmap")
  }

  cache.remove("icon")
  assert_true(cache.is_empty())
  assert_true(cache.get("icon") is None)

  ignore(cache.insert("icon", pixmap))
  assert_eq(cache.len(), 1)
  cache.clear()
  assert_true(cache.is_empty())
}

///|
test "PixmapCache::get_or_insert reuses cached pixmaps" {
  let cache = PixmapCache::new()
  let red = Pixmap::new(1, 1)
  red.set_pixel(0, 0, Color::red())
  let first = cache.get_or_insert("status", red)
  assert_eq(first.get_pixel(0, 0), Color::red())
  assert_eq(cache.len(), 1)

  first.set_pixel(0, 0, Color::green())
  match cache.get("status") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::red())
    None => abort("expected cached pixmap")
  }

  let blue = Pixmap::new(1, 1)
  blue.set_pixel(0, 0, Color::blue())
  let second = cache.get_or_insert("status", blue)
  assert_eq(second.get_pixel(0, 0), Color::red())
  assert_eq(cache.len(), 1)
}

///|
test "PixmapCache::get_or_insert_result reports cache hits" {
  let cache = PixmapCache::new()
  let red = Pixmap::new(1, 1)
  red.set_pixel(0, 0, Color::red())
  let first = cache.get_or_insert_result("icon", red)
  assert_true(first.did_insert())
  assert_true(!first.did_hit_cache())
  assert_eq(first.get_pixmap().get_pixel(0, 0), Color::red())
  assert_eq(cache.len(), 1)

  let first_pixmap = first.get_pixmap()
  first_pixmap.set_pixel(0, 0, Color::green())
  match cache.get("icon") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::red())
    None => abort("expected cached pixmap")
  }

  let blue = Pixmap::new(1, 1)
  blue.set_pixel(0, 0, Color::blue())
  let second = cache.get_or_insert_result("icon", blue)
  assert_true(!second.did_insert())
  assert_true(second.did_hit_cache())
  assert_eq(second.get_pixmap().get_pixel(0, 0), Color::red())
  assert_eq(cache.len(), 1)
}

///|
test "PixmapCache::get_or_decode_bmp_result decodes misses and reports hits" {
  let cache = PixmapCache::new()
  let source = Pixmap::new(1, 1)
  source.set_pixel(0, 0, Color::red())
  match cache.get_or_decode_bmp_result("icon", source.to_bmp_bytes()) {
    Ok(first) => {
      assert_true(first.did_decode())
      assert_true(!first.did_hit_cache())
      assert_eq(first.get_pixmap().get_pixel(0, 0), Color::red())
      let first_pixmap = first.get_pixmap()
      first_pixmap.set_pixel(0, 0, Color::green())
    }
    Err(_) => abort("expected BMP cache decode")
  }
  assert_eq(cache.len(), 1)
  match cache.get("icon") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::red())
    None => abort("expected cached decoded pixmap")
  }

  match cache.get_or_decode_bmp_result("icon", Bytes::from_array([0, 0])) {
    Ok(second) => {
      assert_true(!second.did_decode())
      assert_true(second.did_hit_cache())
      assert_eq(second.get_pixmap().get_pixel(0, 0), Color::red())
    }
    Err(_) => abort("expected cached BMP pixmap hit")
  }
  assert_eq(cache.len(), 1)
}

///|
test "PixmapCache::get_or_decode_rgba_result decodes misses and reports hits" {
  let cache = PixmapCache::new()
  let pixels = Bytes::from_array([0, 255, 0, 255])

  match cache.get_or_decode_rgba_result("icon", 1, 1, pixels) {
    Ok(first) => {
      assert_true(first.did_decode())
      assert_true(!first.did_hit_cache())
      assert_eq(first.get_pixmap().get_pixel(0, 0), Color::green())
      let first_pixmap = first.get_pixmap()
      first_pixmap.set_pixel(0, 0, Color::red())
    }
    Err(_) => abort("expected RGBA cache decode")
  }
  assert_eq(cache.len(), 1)
  match cache.get("icon") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::green())
    None => abort("expected cached decoded RGBA pixmap")
  }

  match cache.get_or_decode_rgba_result("icon", 1, 1, Bytes::from_array([])) {
    Ok(second) => {
      assert_true(!second.did_decode())
      assert_true(second.did_hit_cache())
      assert_eq(second.get_pixmap().get_pixel(0, 0), Color::green())
    }
    Err(_) => abort("expected cached RGBA pixmap hit")
  }
  assert_eq(cache.len(), 1)
}

///|
test "PixmapCache::get_or_decode_png_result decodes misses and reports hits" {
  let cache = PixmapCache::new()
  let source = Pixmap::new(1, 1)
  source.set_pixel(0, 0, Color::green())

  match source.to_png_bytes() {
    Ok(png) =>
      match cache.get_or_decode_png_result("icon", png) {
        Ok(first) => {
          assert_true(first.did_decode())
          assert_true(!first.did_hit_cache())
          assert_eq(first.get_pixmap().get_pixel(0, 0), Color::green())
          let first_pixmap = first.get_pixmap()
          first_pixmap.set_pixel(0, 0, Color::red())
        }
        Err(_) => abort("expected PNG cache decode")
      }
    Err(_) => abort("expected PNG encode")
  }
  assert_eq(cache.len(), 1)
  match cache.get("icon") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::green())
    None => abort("expected cached decoded PNG pixmap")
  }

  match cache.get_or_decode_png_result("icon", Bytes::from_array([0, 0])) {
    Ok(second) => {
      assert_true(!second.did_decode())
      assert_true(second.did_hit_cache())
      assert_eq(second.get_pixmap().get_pixel(0, 0), Color::green())
    }
    Err(_) => abort("expected cached PNG pixmap hit")
  }
  assert_eq(cache.len(), 1)
}

///|
test "PixmapCache::get_or_decode_rgba leaves cache unchanged on decode errors" {
  let cache = PixmapCache::new()
  match cache.get_or_decode_rgba("bad", 2, 1, Bytes::from_array([1, 2, 3, 4])) {
    Err(PixmapDecodeError::RgbaByteLengthMismatch(8, 4)) => ()
    _ => abort("expected RGBA cache decode error")
  }
  assert_true(cache.is_empty())
  assert_true(!cache.contains("bad"))
}

///|
test "PixmapCache::get_or_decode_png leaves cache unchanged on decode errors" {
  let cache = PixmapCache::new()
  match cache.get_or_decode_png("bad", Bytes::from_array([137, 80])) {
    Err(PixmapDecodeError::UnexpectedEndOfData(0, 8, 2)) => ()
    _ => abort("expected PNG cache decode error")
  }
  assert_true(cache.is_empty())
  assert_true(!cache.contains("bad"))
}

///|
test "PixmapCache::get_or_decode_bmp leaves cache unchanged on decode errors" {
  let cache = PixmapCache::new()
  match cache.get_or_decode_bmp("bad", Bytes::from_array([66, 77])) {
    Err(PixmapDecodeError::UnexpectedEndOfData(0, 54, 2)) => ()
    _ => abort("expected BMP cache decode error")
  }
  assert_true(cache.is_empty())
  assert_true(!cache.contains("bad"))
}

///|
test "PixmapCache::contains reports membership without refreshing LRU" {
  let cache = PixmapCache::with_capacity(2)
  let red = Pixmap::new(1, 1)
  red.set_pixel(0, 0, Color::red())
  let green = Pixmap::new(1, 1)
  green.set_pixel(0, 0, Color::green())
  let blue = Pixmap::new(1, 1)
  blue.set_pixel(0, 0, Color::blue())
  ignore(cache.insert("red", red))
  ignore(cache.insert("green", green))
  assert_true(cache.contains("red"))
  assert_true(!cache.contains("blue"))

  ignore(cache.insert("blue", blue))
  assert_eq(cache.len(), 2)
  assert_true(!cache.contains("red"))
  assert_true(cache.contains("green"))
  assert_true(cache.contains("blue"))
}

///|
test "PixmapCache::with_capacity evicts least recently used pixmaps" {
  let cache = PixmapCache::with_capacity(2)
  assert_true(cache.is_capacity_bounded())
  assert_eq(cache.capacity(), 2)
  let red = Pixmap::new(1, 1)
  red.set_pixel(0, 0, Color::red())
  let green = Pixmap::new(1, 1)
  green.set_pixel(0, 0, Color::green())
  let blue = Pixmap::new(1, 1)
  blue.set_pixel(0, 0, Color::blue())
  ignore(cache.insert("red", red))
  ignore(cache.insert("green", green))
  match cache.get("red") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::red())
    None => abort("expected red pixmap")
  }
  ignore(cache.insert("blue", blue))
  assert_eq(cache.len(), 2)
  assert_true(cache.get("green") is None)
  assert_true(cache.get("red") is Some(_))
  assert_true(cache.get("blue") is Some(_))
}

///|
test "PixmapCache::with_capacity clamps invalid capacity" {
  let cache = PixmapCache::with_capacity(0)
  assert_true(cache.is_capacity_bounded())
  assert_eq(cache.capacity(), 1)
  let red = Pixmap::new(1, 1)
  red.set_pixel(0, 0, Color::red())
  let blue = Pixmap::new(1, 1)
  blue.set_pixel(0, 0, Color::blue())
  let inserted = cache.get_or_insert_result("red", red)
  assert_true(inserted.did_insert())
  assert_eq(cache.len(), 1)
  ignore(cache.insert("blue", blue))
  assert_eq(cache.len(), 1)
  assert_true(cache.get("red") is None)
  match cache.get("blue") {
    Some(cached) => assert_eq(cached.get_pixel(0, 0), Color::blue())
    None => abort("expected blue pixmap")
  }
}

///|
test "Pixmap::clear fills all pixels" {
  let pixmap = Pixmap::new(10, 10)
  let color = Color::new(r=0, g=255, b=0)
  pixmap.clear(color)
  // Check a few pixels
  assert_eq(pixmap.get_pixel(0, 0), color)
  assert_eq(pixmap.get_pixel(9, 9), color)
  assert_eq(pixmap.get_pixel(5, 5), color)
}

///|
test "Pixmap::blend_pixel composites over existing pixel" {
  let pixmap = Pixmap::new(2, 2)
  pixmap.set_pixel(0, 0, Color::blue())
  pixmap.blend_pixel(0, 0, Color::new(r=255, g=0, b=0, a=128))
  assert_eq(pixmap.get_pixel(0, 0), Color::new(r=128, g=0, b=127, a=255))
}

///|
test "Pixmap::blend_rect composites clipped rectangle" {
  let pixmap = Pixmap::new(2, 2)
  pixmap.clear(Color::white())
  pixmap.blend_rect(-1, 0, 2, 1, Color::new(r=0, g=0, b=0, a=128))
  assert_eq(pixmap.get_pixel(0, 0), Color::new(r=127, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(1, 0), Color::white())
}

///|
test "Pixmap::blend_mask composites grayscale coverage" {
  let pixmap = Pixmap::new(2, 2)
  pixmap.clear(Color::white())
  let mask : FixedArray[Byte] = FixedArray::make(4, 0)
  mask[0] = 0
  mask[1] = 128
  mask[2] = 255
  mask[3] = 64
  pixmap.blend_mask(0, 0, 2, 2, mask, Color::black())
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=127, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(0, 1), Color::black())
  assert_eq(pixmap.get_pixel(1, 1), Color::new(r=191, g=191, b=191, a=255))
}

///|
test "Pixmap::blend_mask_rect composites source rect" {
  let pixmap = Pixmap::new(3, 2)
  pixmap.clear(Color::white())
  let mask : FixedArray[Byte] = FixedArray::make(6, 0)
  mask[0] = 255
  mask[1] = 64
  mask[2] = 0
  mask[3] = 128
  mask[4] = 255
  mask[5] = 0
  pixmap.blend_mask_rect(
    1,
    0,
    3,
    2,
    mask,
    PixelRect::new(x=1, y=0, width=2, height=2),
    Color::black(),
  )
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=191, g=191, b=191, a=255))
  assert_eq(pixmap.get_pixel(2, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 1), Color::black())
  assert_eq(pixmap.get_pixel(2, 1), Color::white())
}

///|
test "Pixmap::blend_mask_rect clips source and destination" {
  let pixmap = Pixmap::new(2, 1)
  pixmap.clear(Color::white())
  let mask : FixedArray[Byte] = FixedArray::make(4, 0)
  mask[0] = 255
  mask[1] = 128
  mask[2] = 64
  mask[3] = 32
  pixmap.blend_mask_rect(
    -1,
    0,
    2,
    2,
    mask,
    PixelRect::new(x=0, y=0, width=3, height=1),
    Color::black(),
  )
  assert_eq(pixmap.get_pixel(0, 0), Color::new(r=127, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(1, 0), Color::white())
}

///|
test "Pixmap::blend_pixmap composites source alpha" {
  let dst = Pixmap::new(2, 1)
  dst.clear(Color::white())
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=128))
  src.set_pixel(1, 0, Color::blue())
  dst.blend_pixmap(0, 0, src, 1.0)
  assert_eq(dst.get_pixel(0, 0), Color::new(r=255, g=127, b=127, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::blue())
}

///|
test "Pixmap::blend_pixmap clips destination bounds and opacity" {
  let dst = Pixmap::new(2, 1)
  dst.clear(Color::white())
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  dst.blend_pixmap(-1, 0, src, 0.5)
  assert_eq(dst.get_pixel(0, 0), Color::new(r=127, g=127, b=255, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::white())
}

///|
test "Pixmap::blend_pixmap_rect composites only source rectangle" {
  let dst = Pixmap::new(4, 2)
  dst.clear(Color::white())
  let src = Pixmap::new(4, 2)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::green())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::black())
  src.set_pixel(2, 1, Color::new(r=255, g=0, b=0, a=128))
  dst.blend_pixmap_rect(
    1,
    0,
    src,
    PixelRect::new(x=1, y=0, width=2, height=2),
    1.0,
  )
  assert_eq(dst.get_pixel(0, 0), Color::white())
  assert_eq(dst.get_pixel(1, 0), Color::green())
  assert_eq(dst.get_pixel(2, 0), Color::blue())
  assert_eq(dst.get_pixel(3, 0), Color::white())
  assert_eq(dst.get_pixel(2, 1), Color::new(r=255, g=127, b=127, a=255))
}

///|
test "Pixmap::blend_scaled_pixmap scales up with nearest sampling" {
  let dst = Pixmap::new(4, 2)
  dst.clear(Color::white())
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  dst.blend_scaled_pixmap(0, 0, 4, 2, src, 1.0)
  assert_eq(dst.get_pixel(0, 0), Color::red())
  assert_eq(dst.get_pixel(1, 1), Color::red())
  assert_eq(dst.get_pixel(2, 0), Color::blue())
  assert_eq(dst.get_pixel(3, 1), Color::blue())
}

///|
test "Pixmap::blend_scaled_pixmap scales down and clips destination bounds" {
  let dst = Pixmap::new(2, 1)
  dst.clear(Color::white())
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::green())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::black())
  dst.blend_scaled_pixmap(-1, 0, 4, 1, src, 0.5)
  assert_eq(dst.get_pixel(0, 0), Color::new(r=127, g=255, b=127, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::new(r=127, g=127, b=255, a=255))
}

///|
test "Pixmap::blend_scaled_pixmap_bilinear interpolates source pixels" {
  let dst = Pixmap::new(3, 3)
  let src = Pixmap::new(2, 2)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::green())
  src.set_pixel(0, 1, Color::blue())
  src.set_pixel(1, 1, Color::white())
  dst.blend_scaled_pixmap_bilinear(0, 0, 3, 3, src, 1.0)
  assert_eq(dst.get_pixel(0, 0), Color::red())
  assert_eq(dst.get_pixel(2, 0), Color::green())
  assert_eq(dst.get_pixel(0, 2), Color::blue())
  assert_eq(dst.get_pixel(2, 2), Color::white())
  assert_eq(dst.get_pixel(1, 1), Color::new(r=128, g=128, b=128, a=255))
}

///|
test "Pixmap::blend_scaled_pixmap_bilinear samples premultiplied alpha" {
  let dst = Pixmap::new(3, 1)
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=0))
  src.set_pixel(1, 0, Color::blue())
  dst.blend_scaled_pixmap_bilinear(0, 0, 3, 1, src, 1.0)
  assert_eq(dst.get_pixel(0, 0), Color::transparent())
  assert_eq(dst.get_pixel(1, 0), Color::new(r=0, g=0, b=255, a=128))
  assert_eq(dst.get_pixel(2, 0), Color::blue())
}

///|
test "Pixmap::blend_scaled_pixmap_bicubic interpolates source pixels" {
  let dst = Pixmap::new(3, 1)
  let src = make_pixmap_test_bicubic_source()
  dst.blend_scaled_pixmap_bicubic(0, 0, 3, 1, src, 1.0)
  assert_eq(dst.get_pixel(0, 0), Color::new(r=34, g=0, b=0, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::new(r=128, g=0, b=0, a=255))
  assert_eq(dst.get_pixel(2, 0), Color::new(r=221, g=0, b=0, a=255))
}

///|
test "Pixmap::blend_scaled_pixmap_bicubic samples premultiplied alpha" {
  let dst = Pixmap::new(3, 1)
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=0))
  src.set_pixel(1, 0, Color::blue())
  src.set_pixel(2, 0, Color::new(r=0, g=255, b=0, a=0))
  src.set_pixel(3, 0, Color::blue())
  dst.blend_scaled_pixmap_bicubic(0, 0, 3, 1, src, 1.0)
  assert_eq(dst.get_pixel(0, 0), Color::new(r=0, g=0, b=255, a=34))
  assert_eq(dst.get_pixel(1, 0), Color::new(r=0, g=0, b=255, a=128))
  assert_eq(dst.get_pixel(2, 0), Color::new(r=0, g=0, b=255, a=221))
}

///|
test "Pixmap::blend_scaled_pixmap_bilinear clips destination bounds and opacity" {
  let dst = Pixmap::new(2, 1)
  dst.clear(Color::white())
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  dst.blend_scaled_pixmap_bilinear(-1, 0, 4, 1, src, 0.5)
  assert_eq(dst.get_pixel(0, 0), Color::new(r=223, g=127, b=159, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::new(r=159, g=127, b=223, a=255))
}

///|
test "Pixmap::blend_sampled_pixmap dispatches sampling modes" {
  let src = make_pixmap_test_bicubic_source()
  let nearest = Pixmap::new(3, 1)
  let bilinear = Pixmap::new(3, 1)
  let bicubic = Pixmap::new(3, 1)
  nearest.blend_sampled_pixmap(0, 0, 3, 1, src, 1.0, ImageSampling::Nearest)
  bilinear.blend_sampled_pixmap(0, 0, 3, 1, src, 1.0, ImageSampling::Bilinear)
  bicubic.blend_sampled_pixmap(0, 0, 3, 1, src, 1.0, ImageSampling::Bicubic)
  assert_eq(nearest.get_pixel(1, 0), Color::black())
  assert_eq(bilinear.get_pixel(1, 0), Color::new(r=128, g=0, b=0, a=255))
  assert_eq(bicubic.get_pixel(0, 0), Color::new(r=34, g=0, b=0, a=255))
}

///|
test "ImageQuality maps to concrete sampling modes" {
  assert_true(ImageQuality::Fast.to_sampling() == ImageSampling::Nearest)
  assert_true(ImageQuality::Balanced.to_sampling() == ImageSampling::Bilinear)
  assert_true(ImageQuality::High.to_sampling() == ImageSampling::Bicubic)
}

///|
test "Pixmap::blend_quality_pixmap dispatches quality strategies" {
  let src = make_pixmap_test_bicubic_source()
  let fast = Pixmap::new(3, 1)
  let balanced = Pixmap::new(3, 1)
  let high = Pixmap::new(3, 1)
  fast.blend_quality_pixmap(0, 0, 3, 1, src, 1.0, ImageQuality::Fast)
  balanced.blend_quality_pixmap(0, 0, 3, 1, src, 1.0, ImageQuality::Balanced)
  high.blend_quality_pixmap(0, 0, 3, 1, src, 1.0, ImageQuality::High)
  assert_eq(fast.get_pixel(1, 0), Color::black())
  assert_eq(balanced.get_pixel(1, 0), Color::new(r=128, g=0, b=0, a=255))
  assert_eq(high.get_pixel(0, 0), Color::new(r=34, g=0, b=0, a=255))
}

///|
test "Pixmap::blend_scaled_pixmap_rect scales a source atlas region" {
  let dst = Pixmap::new(4, 2)
  dst.clear(Color::white())
  let src = Pixmap::new(4, 2)
  src.set_pixel(0, 0, Color::black())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::green())
  src.set_pixel(3, 0, Color::blue())
  src.set_pixel(0, 1, Color::white())
  src.set_pixel(1, 1, Color::new(r=20, g=0, b=0))
  src.set_pixel(2, 1, Color::new(r=40, g=0, b=0))
  src.set_pixel(3, 1, Color::transparent())
  dst.blend_scaled_pixmap_rect(
    0,
    0,
    4,
    2,
    src,
    PixelRect::new(x=1, y=0, width=2, height=1),
    1.0,
  )
  assert_eq(dst.get_pixel(0, 0), Color::red())
  assert_eq(dst.get_pixel(1, 1), Color::red())
  assert_eq(dst.get_pixel(2, 0), Color::green())
  assert_eq(dst.get_pixel(3, 1), Color::green())
}

///|
test "Pixmap::blend_scaled_pixmap_rect clips destination bounds and opacity" {
  let dst = Pixmap::new(2, 1)
  dst.clear(Color::white())
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::green())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::black())
  dst.blend_scaled_pixmap_rect(
    -1,
    0,
    4,
    1,
    src,
    PixelRect::new(x=0, y=0, width=4, height=1),
    0.5,
  )
  assert_eq(dst.get_pixel(0, 0), Color::new(r=127, g=255, b=127, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::new(r=127, g=127, b=255, a=255))
}

///|
test "Pixmap::blend_scaled_pixmap_rect clips source rect to pixmap bounds" {
  let dst = Pixmap::new(3, 1)
  dst.clear(Color::white())
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::green())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::black())
  dst.blend_scaled_pixmap_rect(
    0,
    0,
    3,
    1,
    src,
    PixelRect::new(x=2, y=0, width=4, height=1),
    1.0,
  )
  assert_eq(dst.get_pixel(0, 0), Color::blue())
  assert_eq(dst.get_pixel(1, 0), Color::black())
  assert_eq(dst.get_pixel(2, 0), Color::black())
}

///|
test "Pixmap::blend_scaled_pixmap_rect_bilinear samples within source rect" {
  let dst = Pixmap::new(3, 1)
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::white())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::white())
  dst.blend_scaled_pixmap_rect_bilinear(
    0,
    0,
    3,
    1,
    src,
    PixelRect::new(x=1, y=0, width=2, height=1),
    1.0,
  )
  assert_eq(dst.get_pixel(0, 0), Color::red())
  assert_eq(dst.get_pixel(1, 0), Color::new(r=128, g=0, b=128, a=255))
  assert_eq(dst.get_pixel(2, 0), Color::blue())
}

///|
test "Pixmap::blend_scaled_pixmap_rect_bicubic samples within source rect" {
  let dst = Pixmap::new(3, 1)
  let src = make_pixmap_test_bicubic_rect_source()
  dst.blend_scaled_pixmap_rect_bicubic(
    0,
    0,
    3,
    1,
    src,
    PixelRect::new(x=1, y=0, width=4, height=1),
    1.0,
  )
  assert_eq(dst.get_pixel(0, 0), Color::new(r=34, g=0, b=0, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::new(r=128, g=0, b=0, a=255))
  assert_eq(dst.get_pixel(2, 0), Color::new(r=221, g=0, b=0, a=255))
}

///|
test "Pixmap::blend_sampled_pixmap_rect dispatches sampling modes" {
  let src = make_pixmap_test_bicubic_rect_source()
  let nearest = Pixmap::new(3, 1)
  let bilinear = Pixmap::new(3, 1)
  let bicubic = Pixmap::new(3, 1)
  let rect = PixelRect::new(x=1, y=0, width=4, height=1)
  nearest.blend_sampled_pixmap_rect(
    0,
    0,
    3,
    1,
    src,
    rect,
    1.0,
    ImageSampling::Nearest,
  )
  bilinear.blend_sampled_pixmap_rect(
    0,
    0,
    3,
    1,
    src,
    rect,
    1.0,
    ImageSampling::Bilinear,
  )
  bicubic.blend_sampled_pixmap_rect(
    0,
    0,
    3,
    1,
    src,
    rect,
    1.0,
    ImageSampling::Bicubic,
  )
  assert_eq(nearest.get_pixel(1, 0), Color::black())
  assert_eq(bilinear.get_pixel(1, 0), Color::new(r=128, g=0, b=0, a=255))
  assert_eq(bicubic.get_pixel(0, 0), Color::new(r=34, g=0, b=0, a=255))
}

///|
test "Pixmap::blend_quality_pixmap_rect dispatches quality strategies" {
  let src = make_pixmap_test_bicubic_rect_source()
  let fast = Pixmap::new(3, 1)
  let balanced = Pixmap::new(3, 1)
  let high = Pixmap::new(3, 1)
  let rect = PixelRect::new(x=1, y=0, width=4, height=1)
  fast.blend_quality_pixmap_rect(0, 0, 3, 1, src, rect, 1.0, ImageQuality::Fast)
  balanced.blend_quality_pixmap_rect(
    0,
    0,
    3,
    1,
    src,
    rect,
    1.0,
    ImageQuality::Balanced,
  )
  high.blend_quality_pixmap_rect(0, 0, 3, 1, src, rect, 1.0, ImageQuality::High)
  assert_eq(fast.get_pixel(1, 0), Color::black())
  assert_eq(balanced.get_pixel(1, 0), Color::new(r=128, g=0, b=0, a=255))
  assert_eq(high.get_pixel(0, 0), Color::new(r=34, g=0, b=0, a=255))
}

///|
test "Pixmap::blend_tiled_pixmap_rect repeats source atlas region" {
  let dst = Pixmap::new(5, 2)
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::white())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::green())
  dst.blend_tiled_pixmap_rect(
    0,
    0,
    5,
    2,
    src,
    PixelRect::new(x=1, y=0, width=2, height=1),
    1.0,
  )
  assert_eq(dst.get_pixel(0, 0), Color::red())
  assert_eq(dst.get_pixel(1, 0), Color::blue())
  assert_eq(dst.get_pixel(2, 0), Color::red())
  assert_eq(dst.get_pixel(3, 1), Color::blue())
  assert_eq(dst.get_pixel(4, 1), Color::red())
}

///|
test "Pixmap::blend_tiled_pixmap_rect clips destination and applies opacity" {
  let dst = Pixmap::new(3, 1)
  dst.clear(Color::white())
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  dst.blend_tiled_pixmap_rect(
    -1,
    0,
    4,
    1,
    src,
    PixelRect::new(x=0, y=0, width=2, height=1),
    0.5,
  )
  assert_eq(dst.get_pixel(0, 0), Color::new(r=127, g=127, b=255, a=255))
  assert_eq(dst.get_pixel(1, 0), Color::new(r=255, g=127, b=127, a=255))
  assert_eq(dst.get_pixel(2, 0), Color::new(r=127, g=127, b=255, a=255))
}

///|
test "Pixmap::blend_nine_patch_pixmap preserves corners and stretches segments" {
  let dst = Pixmap::new(5, 5)
  let src = make_pixmap_test_nine_patch_source()
  dst.blend_nine_patch_pixmap(
    0,
    0,
    5,
    5,
    src,
    NinePatchInsets::new(left=1, top=1, right=1, bottom=1),
    1.0,
    ImageSampling::Nearest,
  )
  assert_eq(dst.get_pixel(0, 0), Color::new(r=10, g=0, b=0))
  assert_eq(dst.get_pixel(4, 0), Color::new(r=30, g=0, b=0))
  assert_eq(dst.get_pixel(0, 4), Color::new(r=70, g=0, b=0))
  assert_eq(dst.get_pixel(4, 4), Color::new(r=90, g=0, b=0))
  assert_eq(dst.get_pixel(2, 0), Color::new(r=20, g=0, b=0))
  assert_eq(dst.get_pixel(0, 2), Color::new(r=40, g=0, b=0))
  assert_eq(dst.get_pixel(2, 2), Color::new(r=50, g=0, b=0))
  assert_eq(dst.get_pixel(4, 2), Color::new(r=60, g=0, b=0))
  assert_eq(dst.get_pixel(2, 4), Color::new(r=80, g=0, b=0))
}

///|
test "Pixmap::blend_nine_patch_pixmap clips destination and applies opacity" {
  let dst = Pixmap::new(2, 2)
  dst.clear(Color::white())
  let src = make_pixmap_test_nine_patch_source()
  dst.blend_nine_patch_pixmap(
    -1,
    -1,
    5,
    5,
    src,
    NinePatchInsets::new(left=1, top=1, right=1, bottom=1),
    0.5,
    ImageSampling::Nearest,
  )
  assert_eq(dst.get_pixel(0, 0), Color::new(r=152, g=127, b=127, a=255))
  assert_eq(dst.get_pixel(1, 1), Color::new(r=152, g=127, b=127, a=255))
}

///|
test "Pixmap::blend_quality_nine_patch_pixmap composes with quality strategy" {
  let dst = Pixmap::new(5, 5)
  let src = make_pixmap_test_nine_patch_source()
  dst.blend_quality_nine_patch_pixmap(
    0,
    0,
    5,
    5,
    src,
    NinePatchInsets::new(left=1, top=1, right=1, bottom=1),
    1.0,
    ImageQuality::High,
  )
  assert_eq(dst.get_pixel(0, 0), Color::new(r=10, g=0, b=0))
  assert_eq(dst.get_pixel(2, 2), Color::new(r=50, g=0, b=0))
  assert_eq(dst.get_pixel(4, 4), Color::new(r=90, g=0, b=0))
}

///|
fn make_pixmap_test_nine_patch_source() -> Pixmap {
  let src = Pixmap::new(3, 3)
  src.set_pixel(0, 0, Color::new(r=10, g=0, b=0))
  src.set_pixel(1, 0, Color::new(r=20, g=0, b=0))
  src.set_pixel(2, 0, Color::new(r=30, g=0, b=0))
  src.set_pixel(0, 1, Color::new(r=40, g=0, b=0))
  src.set_pixel(1, 1, Color::new(r=50, g=0, b=0))
  src.set_pixel(2, 1, Color::new(r=60, g=0, b=0))
  src.set_pixel(0, 2, Color::new(r=70, g=0, b=0))
  src.set_pixel(1, 2, Color::new(r=80, g=0, b=0))
  src.set_pixel(2, 2, Color::new(r=90, g=0, b=0))
  src
}

///|
fn make_pixmap_test_bicubic_source() -> Pixmap {
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::black())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::black())
  src.set_pixel(3, 0, Color::red())
  src
}

///|
fn make_pixmap_test_bicubic_rect_source() -> Pixmap {
  let src = Pixmap::new(6, 1)
  src.set_pixel(0, 0, Color::white())
  src.set_pixel(1, 0, Color::black())
  src.set_pixel(2, 0, Color::red())
  src.set_pixel(3, 0, Color::black())
  src.set_pixel(4, 0, Color::red())
  src.set_pixel(5, 0, Color::black())
  src
}

///|
fn make_pixmap_test_red_png() -> Array[Byte] {
  [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0,
    0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 16, 73, 68, 65, 84, 120, 1,
    1, 5, 0, 250, 255, 0, 255, 0, 0, 255, 5, 0, 1, 255, 250, 92, 136, 209, 0, 0,
    0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
  ]
}
