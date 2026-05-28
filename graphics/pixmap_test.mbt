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
test "Pixmap::clear fills all pixels" {
  let pixmap = Pixmap::new(10, 10)
  let color = Color::new(r=0, g=255, b=0)
  pixmap.clear(color)
  // Check a few pixels
  assert_eq(pixmap.get_pixel(0, 0), color)
  assert_eq(pixmap.get_pixel(9, 9), color)
  assert_eq(pixmap.get_pixel(5, 5), color)
}
