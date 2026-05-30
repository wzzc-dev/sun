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
