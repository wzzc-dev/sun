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
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  let nearest = Pixmap::new(3, 1)
  let bilinear = Pixmap::new(3, 1)
  nearest.blend_sampled_pixmap(0, 0, 3, 1, src, 1.0, ImageSampling::Nearest)
  bilinear.blend_sampled_pixmap(0, 0, 3, 1, src, 1.0, ImageSampling::Bilinear)
  assert_eq(nearest.get_pixel(1, 0), Color::blue())
  assert_eq(bilinear.get_pixel(1, 0), Color::new(r=128, g=0, b=128, a=255))
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
test "Pixmap::blend_sampled_pixmap_rect dispatches sampling modes" {
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::white())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::white())
  let nearest = Pixmap::new(3, 1)
  let bilinear = Pixmap::new(3, 1)
  let rect = PixelRect::new(x=1, y=0, width=2, height=1)
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
  assert_eq(nearest.get_pixel(1, 0), Color::blue())
  assert_eq(bilinear.get_pixel(1, 0), Color::new(r=128, g=0, b=128, a=255))
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
