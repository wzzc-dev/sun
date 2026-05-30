///|
test "CoverageMask stores dimensions and pixels" {
  let pixels : FixedArray[Byte] = FixedArray::make(4, 0)
  pixels[1] = 128
  let mask = CoverageMask::new(2, 2, pixels)
  assert_eq(mask.get_width(), 2)
  assert_eq(mask.get_height(), 2)
  assert_eq(mask.get_pixels()[1], 128)
}

///|
test "CoverageMask::copy duplicates pixel storage" {
  let pixels : FixedArray[Byte] = FixedArray::make(4, 0)
  pixels[0] = 64
  let mask = CoverageMask::new(2, 2, pixels)
  let copy = mask.copy()
  let copy_pixels = copy.get_pixels()
  copy_pixels[0] = 192
  assert_eq(mask.get_pixels()[0], 64)
  assert_eq(copy.get_pixels()[0], 192)
}

///|
test "TextMaskCache stores copies and clears entries" {
  let cache = TextMaskCache::new()
  assert_true(cache.is_empty())
  let pixels : FixedArray[Byte] = FixedArray::make(4, 0)
  pixels[0] = 96
  let mask = CoverageMask::new(2, 2, pixels)
  let inserted = cache.insert("label", mask)
  assert_eq(cache.len(), 1)
  assert_eq(inserted.get_pixels()[0], 96)

  pixels[0] = 12
  match cache.get("label") {
    Some(cached) => {
      assert_eq(cached.get_width(), 2)
      assert_eq(cached.get_height(), 2)
      assert_eq(cached.get_pixels()[0], 96)
      let cached_pixels = cached.get_pixels()
      cached_pixels[0] = 200
    }
    None => abort("expected cached text mask")
  }

  match cache.get("label") {
    Some(cached) => assert_eq(cached.get_pixels()[0], 96)
    None => abort("expected cached text mask")
  }

  cache.remove("label")
  assert_true(cache.is_empty())
  assert_true(cache.get("label") is None)

  ignore(cache.insert("label", mask))
  assert_eq(cache.len(), 1)
  cache.clear()
  assert_true(cache.is_empty())
}

///|
test "Rasterizer::to_mask snapshots grayscale pixels" {
  let rasterizer = Rasterizer::new(4, 4)
  rasterizer.draw_line(1.0, 1.0, 1.0, 1.0)
  let mask = rasterizer.to_mask()
  assert_eq(rasterizer.get_width(), 4)
  assert_eq(rasterizer.get_height(), 4)
  assert_eq(mask.get_width(), 4)
  assert_eq(mask.get_height(), 4)
  assert_eq(mask.get_pixels()[1 * 4 + 1], 255)
  rasterizer.clear()
  assert_eq(mask.get_pixels()[1 * 4 + 1], 255)
}
