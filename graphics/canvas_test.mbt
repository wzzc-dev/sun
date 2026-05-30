///|
test "Canvas::draw_mask composites coverage with paint opacity" {
  let canvas = Canvas::new(2, 2)
  canvas.clear(Color::white())
  let mask : FixedArray[Byte] = FixedArray::make(4, 0)
  mask[0] = 0
  mask[1] = 128
  mask[2] = 255
  mask[3] = 64
  let paint = Paint::new().set_color(Color::black()).set_opacity(0.5)
  canvas.draw_mask(0, 0, 2, 2, mask, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=191, g=191, b=191, a=255))
  assert_eq(pixmap.get_pixel(0, 1), Color::new(r=127, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(1, 1), Color::new(r=223, g=223, b=223, a=255))
}

///|
test "Canvas tracks dirty region for clear and clipped rect" {
  let canvas = Canvas::new(3, 2)
  assert_true(canvas.get_dirty_region().is_empty())
  canvas.clear(Color::white())
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=0, y=0, width=3, height=2)),
  )
  canvas.clear_dirty_region()
  assert_true(canvas.get_dirty_region().is_empty())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=1.0, height=2.0))
  canvas.fill_rect(0.0, 0.0, 3.0, 2.0, Paint::new().set_color(Color::black()))
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=0, width=1, height=2)),
  )
}

///|
test "Canvas tracks dirty region for pixel and sampled pixmap" {
  let canvas = Canvas::new(4, 2)
  canvas.draw_pixel(3, 1, Color::red())
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=3, y=1, width=1, height=1)),
  )
  canvas.clear_dirty_region()
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=2.0, height=2.0))
  let src = Pixmap::new(1, 1)
  src.set_pixel(0, 0, Color::blue())
  canvas.draw_sampled_pixmap(
    src,
    0,
    0,
    4,
    2,
    Paint::new(),
    ImageSampling::Nearest,
  )
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=0, width=2, height=2)),
  )
}

///|
test "Canvas::save and restore preserve transform and clip state" {
  let canvas = Canvas::new(3, 1)
  assert_eq(canvas.get_save_count(), 0)
  assert_true(!canvas.restore())
  assert_true(canvas.get_transform() == Transform::identity())
  assert_true(canvas.get_clip_rect() == None)

  let base_transform = Transform::translate(tx=1.0, ty=0.0)
  let base_clip = Rect::new(x=0.0, y=0.0, width=2.0, height=1.0)
  canvas.set_transform(base_transform)
  canvas.set_clip_rect(base_clip)
  canvas.save()
  assert_eq(canvas.get_save_count(), 1)

  canvas.set_transform(Transform::translate(tx=2.0, ty=0.0))
  canvas.set_clip_rect(Rect::new(x=2.0, y=0.0, width=1.0, height=1.0))
  canvas.save()
  assert_eq(canvas.get_save_count(), 2)

  canvas.clear_clip()
  canvas.set_transform(Transform::identity())
  assert_true(canvas.restore())
  assert_eq(canvas.get_save_count(), 1)
  assert_true(canvas.get_transform() == Transform::translate(tx=2.0, ty=0.0))
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=2.0, y=0.0, width=1.0, height=1.0)),
  )

  assert_true(canvas.restore())
  assert_eq(canvas.get_save_count(), 0)
  assert_true(canvas.get_transform() == base_transform)
  assert_true(canvas.get_clip_rect() == Some(base_clip))
  assert_true(!canvas.restore())
  assert_true(canvas.get_transform() == base_transform)
  assert_true(canvas.get_clip_rect() == Some(base_clip))
}

///|
test "Canvas::restore affects subsequent path drawing" {
  let canvas = Canvas::new(3, 1)
  canvas.clear(Color::white())
  canvas.set_transform(Transform::translate(tx=1.0, ty=0.0))
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=1.0, height=1.0))
  canvas.save()

  canvas.set_transform(Transform::identity())
  canvas.clear_clip()
  canvas.fill_path(
    Path::new().add_rect(0.0, 0.0, 1.0, 1.0),
    Paint::new().set_color(Color::black()),
  )

  assert_true(canvas.restore())
  canvas.fill_path(
    Path::new().add_rect(0.0, 0.0, 1.0, 1.0),
    Paint::new().set_color(Color::blue()),
  )

  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::black())
  assert_eq(pixmap.get_pixel(1, 0), Color::blue())
  assert_eq(pixmap.get_pixel(2, 0), Color::white())
}

///|
test "Canvas::intersect_clip_rect narrows current clip" {
  let canvas = Canvas::new(5, 1)
  canvas.intersect_clip_rect(Rect::new(x=0.0, y=0.0, width=4.0, height=1.0))
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=0.0, y=0.0, width=4.0, height=1.0)),
  )
  canvas.intersect_clip_rect(Rect::new(x=1.0, y=0.0, width=2.0, height=1.0))
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=1.0, y=0.0, width=2.0, height=1.0)),
  )

  canvas.clear(Color::white())
  canvas.clear_dirty_region()
  canvas.fill_rect(0.0, 0.0, 5.0, 1.0, Paint::new().set_color(Color::black()))
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::black())
  assert_eq(pixmap.get_pixel(2, 0), Color::black())
  assert_eq(pixmap.get_pixel(3, 0), Color::white())
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=0, width=2, height=1)),
  )
}

///|
test "Canvas::intersect_clip_rect supports save restore and empty clips" {
  let canvas = Canvas::new(4, 1)
  canvas.set_clip_rect(Rect::new(x=0.0, y=0.0, width=3.0, height=1.0))
  canvas.save()
  canvas.intersect_clip_rect(Rect::new(x=2.0, y=0.0, width=2.0, height=1.0))
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=2.0, y=0.0, width=1.0, height=1.0)),
  )
  canvas.intersect_clip_rect(Rect::new(x=4.0, y=0.0, width=1.0, height=1.0))
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=0.0, y=0.0, width=0.0, height=0.0)),
  )
  assert_true(canvas.restore())
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=0.0, y=0.0, width=3.0, height=1.0)),
  )

  canvas.intersect_clip_rect(Rect::new(x=0.0, y=0.0, width=0.0, height=1.0))
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=0.0, y=0.0, width=0.0, height=0.0)),
  )
}

///|
test "Canvas::draw_mask ignores stroke paint" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let mask : FixedArray[Byte] = FixedArray::make(1, 255)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
  canvas.draw_mask(0, 0, 1, 1, mask, paint)
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "Canvas::draw_mask respects clip rect" {
  let canvas = Canvas::new(3, 1)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=1.0, height=1.0))
  let mask : FixedArray[Byte] = FixedArray::make(3, 255)
  let paint = Paint::new().set_color(Color::black())
  canvas.draw_mask(0, 0, 3, 1, mask, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::black())
  assert_eq(pixmap.get_pixel(2, 0), Color::white())
}

///|
test "Canvas::draw_pixmap composites source pixels" {
  let canvas = Canvas::new(2, 1)
  canvas.clear(Color::white())
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::new(r=255, g=0, b=0, a=128))
  src.set_pixel(1, 0, Color::blue())
  canvas.draw_pixmap(src, 0, 0, Paint::new())
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::new(r=255, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(1, 0), Color::blue())
}

///|
test "Canvas::draw_pixmap respects clip rect and paint opacity" {
  let canvas = Canvas::new(3, 1)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=1.0, height=1.0))
  let src = Pixmap::new(3, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  src.set_pixel(2, 0, Color::green())
  canvas.draw_pixmap(src, 0, 0, Paint::new().set_opacity(0.5))
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=127, g=127, b=255, a=255))
  assert_eq(pixmap.get_pixel(2, 0), Color::white())
}

///|
test "Canvas::draw_pixmap ignores stroke paint" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let src = Pixmap::new(1, 1)
  src.set_pixel(0, 0, Color::black())
  canvas.draw_pixmap(src, 0, 0, Paint::new().set_style(PaintStyle::Stroke))
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "Canvas::draw_scaled_pixmap scales source pixels" {
  let canvas = Canvas::new(4, 2)
  canvas.clear(Color::white())
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  canvas.draw_scaled_pixmap(src, 0, 0, 4, 2, Paint::new())
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::red())
  assert_eq(pixmap.get_pixel(1, 1), Color::red())
  assert_eq(pixmap.get_pixel(2, 0), Color::blue())
  assert_eq(pixmap.get_pixel(3, 1), Color::blue())
}

///|
test "Canvas::draw_scaled_pixmap respects clip rect and opacity" {
  let canvas = Canvas::new(4, 1)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=2.0, height=1.0))
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  canvas.draw_scaled_pixmap(src, 0, 0, 4, 1, Paint::new().set_opacity(0.5))
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=255, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(2, 0), Color::new(r=127, g=127, b=255, a=255))
  assert_eq(pixmap.get_pixel(3, 0), Color::white())
}

///|
test "Canvas::draw_scaled_pixmap ignores stroke paint and invalid size" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let src = Pixmap::new(1, 1)
  src.set_pixel(0, 0, Color::black())
  canvas.draw_scaled_pixmap(
    src,
    0,
    0,
    1,
    1,
    Paint::new().set_style(PaintStyle::Stroke),
  )
  canvas.draw_scaled_pixmap(src, 0, 0, 0, 1, Paint::new())
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "Canvas::draw_scaled_pixmap_bilinear interpolates source pixels" {
  let canvas = Canvas::new(3, 3)
  let src = Pixmap::new(2, 2)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::green())
  src.set_pixel(0, 1, Color::blue())
  src.set_pixel(1, 1, Color::white())
  canvas.draw_scaled_pixmap_bilinear(src, 0, 0, 3, 3, Paint::new())
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::red())
  assert_eq(pixmap.get_pixel(2, 0), Color::green())
  assert_eq(pixmap.get_pixel(1, 1), Color::new(r=128, g=128, b=128, a=255))
}

///|
test "Canvas::draw_scaled_pixmap_bilinear respects clip rect and opacity" {
  let canvas = Canvas::new(4, 1)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=2.0, height=1.0))
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  canvas.draw_scaled_pixmap_bilinear(
    src,
    0,
    0,
    4,
    1,
    Paint::new().set_opacity(0.5),
  )
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=223, g=127, b=159, a=255))
  assert_eq(pixmap.get_pixel(2, 0), Color::new(r=159, g=127, b=223, a=255))
  assert_eq(pixmap.get_pixel(3, 0), Color::white())
}

///|
test "Canvas::draw_scaled_pixmap_bilinear ignores stroke paint and invalid size" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let src = Pixmap::new(1, 1)
  src.set_pixel(0, 0, Color::black())
  canvas.draw_scaled_pixmap_bilinear(
    src,
    0,
    0,
    1,
    1,
    Paint::new().set_style(PaintStyle::Stroke),
  )
  canvas.draw_scaled_pixmap_bilinear(src, 0, 0, 0, 1, Paint::new())
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "Canvas::draw_sampled_pixmap dispatches sampling modes" {
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  let nearest = Canvas::new(3, 1)
  let bilinear = Canvas::new(3, 1)
  nearest.draw_sampled_pixmap(
    src,
    0,
    0,
    3,
    1,
    Paint::new(),
    ImageSampling::Nearest,
  )
  bilinear.draw_sampled_pixmap(
    src,
    0,
    0,
    3,
    1,
    Paint::new(),
    ImageSampling::Bilinear,
  )
  assert_eq(nearest.get_pixmap().get_pixel(1, 0), Color::blue())
  assert_eq(
    bilinear.get_pixmap().get_pixel(1, 0),
    Color::new(r=128, g=0, b=128, a=255),
  )
}

///|
test "Canvas::draw_scaled_pixmap_rect scales atlas region" {
  let canvas = Canvas::new(4, 2)
  canvas.clear(Color::white())
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::black())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::green())
  canvas.draw_scaled_pixmap_rect(
    src,
    PixelRect::new(x=1, y=0, width=2, height=1),
    0,
    0,
    4,
    2,
    Paint::new(),
  )
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::red())
  assert_eq(pixmap.get_pixel(1, 1), Color::red())
  assert_eq(pixmap.get_pixel(2, 0), Color::blue())
  assert_eq(pixmap.get_pixel(3, 1), Color::blue())
}

///|
test "Canvas::draw_scaled_pixmap_rect respects clip opacity and dirty region" {
  let canvas = Canvas::new(4, 1)
  canvas.clear(Color::white())
  canvas.clear_dirty_region()
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=2.0, height=1.0))
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::green())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::black())
  canvas.draw_scaled_pixmap_rect(
    src,
    PixelRect::new(x=1, y=0, width=2, height=1),
    0,
    0,
    4,
    1,
    Paint::new().set_opacity(0.5),
  )
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=127, g=255, b=127, a=255))
  assert_eq(pixmap.get_pixel(2, 0), Color::new(r=127, g=127, b=255, a=255))
  assert_eq(pixmap.get_pixel(3, 0), Color::white())
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=0, width=2, height=1)),
  )
}

///|
test "Canvas::draw_scaled_pixmap_rect_bilinear samples source rect" {
  let canvas = Canvas::new(3, 1)
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::white())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::white())
  canvas.draw_scaled_pixmap_rect_bilinear(
    src,
    PixelRect::new(x=1, y=0, width=2, height=1),
    0,
    0,
    3,
    1,
    Paint::new(),
  )
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::red())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=128, g=0, b=128, a=255))
  assert_eq(pixmap.get_pixel(2, 0), Color::blue())
}

///|
test "Canvas::draw_sampled_pixmap_rect dispatches sampling modes" {
  let src = Pixmap::new(4, 1)
  src.set_pixel(0, 0, Color::white())
  src.set_pixel(1, 0, Color::red())
  src.set_pixel(2, 0, Color::blue())
  src.set_pixel(3, 0, Color::white())
  let nearest = Canvas::new(3, 1)
  let bilinear = Canvas::new(3, 1)
  let rect = PixelRect::new(x=1, y=0, width=2, height=1)
  nearest.draw_sampled_pixmap_rect(
    src,
    rect,
    0,
    0,
    3,
    1,
    Paint::new(),
    ImageSampling::Nearest,
  )
  bilinear.draw_sampled_pixmap_rect(
    src,
    rect,
    0,
    0,
    3,
    1,
    Paint::new(),
    ImageSampling::Bilinear,
  )
  assert_eq(nearest.get_pixmap().get_pixel(1, 0), Color::blue())
  assert_eq(
    bilinear.get_pixmap().get_pixel(1, 0),
    Color::new(r=128, g=0, b=128, a=255),
  )
}

///|
test "Canvas::draw_sampled_pixmap_rect ignores stroke paint and invalid size" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let src = Pixmap::new(1, 1)
  src.set_pixel(0, 0, Color::black())
  let rect = PixelRect::new(x=0, y=0, width=1, height=1)
  canvas.draw_sampled_pixmap_rect(
    src,
    rect,
    0,
    0,
    1,
    1,
    Paint::new().set_style(PaintStyle::Stroke),
    ImageSampling::Nearest,
  )
  canvas.draw_sampled_pixmap_rect(
    src,
    rect,
    0,
    0,
    0,
    1,
    Paint::new(),
    ImageSampling::Nearest,
  )
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "Canvas::draw_tiled_pixmap_rect respects clip opacity and dirty region" {
  let canvas = Canvas::new(5, 1)
  canvas.clear(Color::white())
  canvas.clear_dirty_region()
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=3.0, height=1.0))
  let src = Pixmap::new(2, 1)
  src.set_pixel(0, 0, Color::red())
  src.set_pixel(1, 0, Color::blue())
  canvas.draw_tiled_pixmap_rect(
    src,
    PixelRect::new(x=0, y=0, width=2, height=1),
    0,
    0,
    5,
    1,
    Paint::new().set_opacity(0.5),
  )
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::new(r=127, g=127, b=255, a=255))
  assert_eq(pixmap.get_pixel(2, 0), Color::new(r=255, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(3, 0), Color::new(r=127, g=127, b=255, a=255))
  assert_eq(pixmap.get_pixel(4, 0), Color::white())
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=0, width=3, height=1)),
  )
}

///|
test "Canvas::draw_tiled_pixmap_rect ignores stroke paint and invalid size" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let src = Pixmap::new(1, 1)
  src.set_pixel(0, 0, Color::black())
  let rect = PixelRect::new(x=0, y=0, width=1, height=1)
  canvas.draw_tiled_pixmap_rect(
    src,
    rect,
    0,
    0,
    1,
    1,
    Paint::new().set_style(PaintStyle::Stroke),
  )
  canvas.draw_tiled_pixmap_rect(src, rect, 0, 0, 0, 1, Paint::new())
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "Canvas::draw_nine_patch_pixmap respects clip and dirty region" {
  let canvas = Canvas::new(5, 5)
  canvas.clear(Color::white())
  canvas.clear_dirty_region()
  canvas.set_clip_rect(Rect::new(x=1.0, y=1.0, width=3.0, height=3.0))
  let src = make_canvas_test_nine_patch_source()
  canvas.draw_nine_patch_pixmap(
    src,
    0,
    0,
    5,
    5,
    NinePatchInsets::new(left=1, top=1, right=1, bottom=1),
    Paint::new(),
    ImageSampling::Nearest,
  )
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 1), Color::new(r=50, g=0, b=0))
  assert_eq(pixmap.get_pixel(3, 3), Color::new(r=50, g=0, b=0))
  assert_eq(pixmap.get_pixel(4, 4), Color::white())
  assert_true(
    canvas.get_dirty_region().bounds() ==
    Some(PixelRect::new(x=1, y=1, width=3, height=3)),
  )
}

///|
test "Canvas::draw_nine_patch_pixmap ignores stroke paint and invalid size" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let src = make_canvas_test_nine_patch_source()
  let insets = NinePatchInsets::new(left=1, top=1, right=1, bottom=1)
  canvas.draw_nine_patch_pixmap(
    src,
    0,
    0,
    1,
    1,
    insets,
    Paint::new().set_style(PaintStyle::Stroke),
    ImageSampling::Nearest,
  )
  canvas.draw_nine_patch_pixmap(
    src,
    0,
    0,
    0,
    1,
    insets,
    Paint::new(),
    ImageSampling::Nearest,
  )
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
}

///|
test "Canvas::draw_placeholder_text composites instead of overwriting" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  canvas.draw_placeholder_text(
    "A",
    0.0,
    0.0,
    1.0,
    Color::new(r=255, g=0, b=0, a=128),
  )
  assert_eq(
    canvas.get_pixmap().get_pixel(0, 0),
    Color::new(r=255, g=127, b=127, a=255),
  )
}

///|
test "Canvas::draw_placeholder_text respects clip rect" {
  let canvas = Canvas::new(3, 1)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=1.0, height=1.0))
  canvas.draw_placeholder_text("A", 0.0, 0.0, 2.0, Color::black())
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::black())
  assert_eq(pixmap.get_pixel(2, 0), Color::white())
}

///|
test "Canvas::fill_rect respects and clears clip rect" {
  let canvas = Canvas::new(3, 1)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=1.0, height=1.0))
  canvas.fill_rect(0.0, 0.0, 3.0, 1.0, Paint::new().set_color(Color::black()))
  assert_true(
    canvas.get_clip_rect() ==
    Some(Rect::new(x=1.0, y=0.0, width=1.0, height=1.0)),
  )
  let clipped = canvas.get_pixmap()
  assert_eq(clipped.get_pixel(0, 0), Color::white())
  assert_eq(clipped.get_pixel(1, 0), Color::black())
  assert_eq(clipped.get_pixel(2, 0), Color::white())
  canvas.clear_clip()
  assert_true(canvas.get_clip_rect() == None)
  canvas.fill_rect(2.0, 0.0, 1.0, 1.0, Paint::new().set_color(Color::black()))
  assert_eq(canvas.get_pixmap().get_pixel(2, 0), Color::black())
}

///|
test "Canvas::draw_pixel respects clip rect" {
  let canvas = Canvas::new(3, 1)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=1.0, height=1.0))
  canvas.draw_pixel(0, 0, Color::black())
  canvas.draw_pixel(1, 0, Color::black())
  assert_eq(canvas.get_pixmap().get_pixel(0, 0), Color::white())
  assert_eq(canvas.get_pixmap().get_pixel(1, 0), Color::black())
}

///|
test "Canvas::fill_path fills rectangular path" {
  let canvas = Canvas::new(4, 4)
  canvas.clear(Color::white())
  let path = Path::new().add_rect(1.0, 1.0, 2.0, 2.0)
  let paint = Paint::new().set_color(Color::black())
  canvas.fill_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 1), Color::black())
  assert_eq(pixmap.get_pixel(2, 2), Color::black())
  assert_eq(pixmap.get_pixel(3, 3), Color::white())
}

///|
test "Canvas::fill_path composites paint opacity" {
  let canvas = Canvas::new(2, 2)
  canvas.clear(Color::white())
  let path = Path::new().add_rect(0.0, 0.0, 2.0, 2.0)
  let paint = Paint::new().set_color(Color::black()).set_opacity(0.5)
  canvas.fill_path(path, paint)
  assert_eq(
    canvas.get_pixmap().get_pixel(0, 0),
    Color::new(r=127, g=127, b=127, a=255),
  )
}

///|
test "Canvas::fill_path uses subpixel coverage" {
  let canvas = Canvas::new(2, 1)
  canvas.clear(Color::white())
  let path = Path::new().add_rect(0.5, 0.0, 0.5, 1.0)
  canvas.fill_path(path, Paint::new().set_color(Color::black()))
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::new(r=127, g=127, b=127, a=255))
  assert_eq(pixmap.get_pixel(1, 0), Color::white())
}

///|
test "Canvas::fill_path applies transform" {
  let canvas = Canvas::new(4, 4)
  canvas.clear(Color::white())
  canvas.set_transform(Transform::translate(tx=1.0, ty=1.0))
  let path = Path::new().add_rect(0.0, 0.0, 1.0, 1.0)
  canvas.fill_path(path, Paint::new().set_color(Color::black()))
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 1), Color::black())
}

///|
test "Canvas::fill_path supports even odd holes" {
  let canvas = Canvas::new(5, 5)
  canvas.clear(Color::white())
  let path = Path::new()
    .add_rect(0.0, 0.0, 5.0, 5.0)
    .add_rect(1.0, 1.0, 3.0, 3.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_fill_rule(FillRule::EvenOdd)
  canvas.fill_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::black())
  assert_eq(pixmap.get_pixel(2, 2), Color::white())
}

///|
test "Canvas::fill_path respects clip rect" {
  let canvas = Canvas::new(4, 2)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=2.0, height=2.0))
  let path = Path::new().add_rect(0.0, 0.0, 4.0, 2.0)
  canvas.fill_path(path, Paint::new().set_color(Color::black()))
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 0), Color::white())
  assert_eq(pixmap.get_pixel(1, 0), Color::black())
  assert_eq(pixmap.get_pixel(2, 1), Color::black())
  assert_eq(pixmap.get_pixel(3, 1), Color::white())
}

///|
test "Canvas::stroke_path draws stroked lines" {
  let canvas = Canvas::new(5, 4)
  canvas.clear(Color::white())
  let path = Path::new().move_to(0.0, 1.0).line_to(4.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(2, 0), Color::black())
  assert_eq(pixmap.get_pixel(2, 1), Color::black())
  assert_eq(pixmap.get_pixel(2, 3), Color::white())
}

///|
test "Canvas::stroke_path composites paint opacity" {
  let canvas = Canvas::new(3, 3)
  canvas.clear(Color::white())
  let path = Path::new().move_to(0.0, 1.0).line_to(3.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_opacity(0.5)
  canvas.stroke_path(path, paint)
  assert_eq(
    canvas.get_pixmap().get_pixel(1, 1),
    Color::new(r=127, g=127, b=127, a=255),
  )
}

///|
test "Canvas::stroke_path uses subpixel coverage" {
  let canvas = Canvas::new(1, 1)
  canvas.clear(Color::white())
  let path = Path::new().move_to(0.0, 0.0).line_to(1.0, 0.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(1.0)
  canvas.stroke_path(path, paint)
  assert_eq(
    canvas.get_pixmap().get_pixel(0, 0),
    Color::new(r=127, g=127, b=127, a=255),
  )
}

///|
test "Canvas::stroke_path applies transform" {
  let canvas = Canvas::new(4, 4)
  canvas.clear(Color::white())
  canvas.set_transform(Transform::translate(tx=0.0, ty=1.0))
  let path = Path::new().move_to(0.0, 0.0).line_to(3.0, 0.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), Color::black())
  assert_eq(pixmap.get_pixel(1, 3), Color::white())
}

///|
test "Canvas::stroke_path respects clip rect" {
  let canvas = Canvas::new(5, 3)
  canvas.clear(Color::white())
  canvas.set_clip_rect(Rect::new(x=1.0, y=0.0, width=2.0, height=3.0))
  let path = Path::new().move_to(0.0, 1.0).line_to(5.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(0, 1), Color::white())
  assert_eq(pixmap.get_pixel(1, 1), Color::black())
  assert_eq(pixmap.get_pixel(2, 1), Color::black())
  assert_eq(pixmap.get_pixel(3, 1), Color::white())
}

///|
test "Canvas::stroke_path uses butt caps by default" {
  let canvas = Canvas::new(6, 3)
  canvas.clear(Color::white())
  let path = Path::new().move_to(2.0, 1.0).line_to(4.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(2, 1), Color::black())
  assert_eq(pixmap.get_pixel(1, 1), Color::white())
  assert_eq(pixmap.get_pixel(4, 1), Color::white())
}

///|
test "Canvas::stroke_path supports square caps" {
  let canvas = Canvas::new(6, 3)
  canvas.clear(Color::white())
  let path = Path::new().move_to(2.0, 1.0).line_to(4.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_stroke_cap(StrokeCap::Square)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_not_white(pixmap.get_pixel(1, 1))
  assert_not_white(pixmap.get_pixel(4, 1))
}

///|
test "Canvas::stroke_path supports round caps" {
  let canvas = Canvas::new(6, 3)
  canvas.clear(Color::white())
  let path = Path::new().move_to(2.0, 1.0).line_to(4.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_stroke_cap(StrokeCap::Round)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_not_white(pixmap.get_pixel(1, 1))
  assert_eq(pixmap.get_pixel(0, 1), Color::white())
  assert_true(pixmap.get_pixel(1, 0) != Color::black())
}

///|
test "Canvas::stroke_path round caps keep corners lighter than square caps" {
  let square_canvas = Canvas::new(6, 3)
  square_canvas.clear(Color::white())
  let round_canvas = Canvas::new(6, 3)
  round_canvas.clear(Color::white())
  let path = Path::new().move_to(2.0, 1.0).line_to(4.0, 1.0)
  let base = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  square_canvas.stroke_path(path, base.set_stroke_cap(StrokeCap::Square))
  round_canvas.stroke_path(path, base.set_stroke_cap(StrokeCap::Round))
  assert_true(
    square_canvas.get_pixmap().get_pixel(1, 0).r <
    round_canvas.get_pixmap().get_pixel(1, 0).r,
  )
}

///|
test "Canvas::stroke_path ignores cap style on closed paths" {
  let butt_canvas = Canvas::new(5, 5)
  butt_canvas.clear(Color::white())
  let square_canvas = Canvas::new(5, 5)
  square_canvas.clear(Color::white())
  let path = Path::new()
    .move_to(1.0, 1.0)
    .line_to(3.0, 1.0)
    .line_to(3.0, 3.0)
    .close()
  let butt_paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  let square_paint = butt_paint.set_stroke_cap(StrokeCap::Square)
  butt_canvas.stroke_path(path, butt_paint)
  square_canvas.stroke_path(path, square_paint)
  assert_same_pixmap(butt_canvas.get_pixmap(), square_canvas.get_pixmap())
}

///|
test "Canvas::stroke_path supports round joins" {
  let canvas = Canvas::new(6, 6)
  canvas.clear(Color::white())
  let path = Path::new().move_to(1.0, 3.0).line_to(3.0, 3.0).line_to(3.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_stroke_join(StrokeJoin::Round)
  canvas.stroke_path(path, paint)
  assert_not_white(canvas.get_pixmap().get_pixel(3, 3))
}

///|
test "Canvas::stroke_path round joins cover more outer corner than bevel joins" {
  let bevel_canvas = Canvas::new(6, 6)
  bevel_canvas.clear(Color::white())
  let round_canvas = Canvas::new(6, 6)
  round_canvas.clear(Color::white())
  let path = Path::new().move_to(1.0, 3.0).line_to(3.0, 3.0).line_to(3.0, 1.0)
  let base = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  bevel_canvas.stroke_path(path, base.set_stroke_join(StrokeJoin::Bevel))
  round_canvas.stroke_path(path, base.set_stroke_join(StrokeJoin::Round))
  assert_true(
    round_canvas.get_pixmap().get_pixel(3, 3).r <
    bevel_canvas.get_pixmap().get_pixel(3, 3).r,
  )
}

///|
test "Canvas::stroke_path miter joins extend past bevel joins" {
  let bevel_canvas = Canvas::new(6, 6)
  bevel_canvas.clear(Color::white())
  let miter_canvas = Canvas::new(6, 6)
  miter_canvas.clear(Color::white())
  let path = Path::new().move_to(1.0, 3.0).line_to(3.0, 3.0).line_to(3.0, 1.0)
  let base = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  bevel_canvas.stroke_path(path, base.set_stroke_join(StrokeJoin::Bevel))
  miter_canvas.stroke_path(path, base.set_stroke_join(StrokeJoin::Miter))
  assert_true(
    miter_canvas.get_pixmap().get_pixel(3, 3).r <
    bevel_canvas.get_pixmap().get_pixel(3, 3).r,
  )
}

///|
test "Canvas::stroke_path miter limit falls back to bevel joins" {
  let bevel_canvas = Canvas::new(6, 6)
  bevel_canvas.clear(Color::white())
  let limited_canvas = Canvas::new(6, 6)
  limited_canvas.clear(Color::white())
  let path = Path::new().move_to(1.0, 3.0).line_to(3.0, 3.0).line_to(3.0, 1.0)
  let base = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
  bevel_canvas.stroke_path(path, base.set_stroke_join(StrokeJoin::Bevel))
  limited_canvas.stroke_path(
    path,
    base.set_stroke_join(StrokeJoin::Miter).set_miter_limit(1.0),
  )
  assert_same_pixmap(bevel_canvas.get_pixmap(), limited_canvas.get_pixmap())
}

///|
test "Canvas::stroke_path supports dashed strokes" {
  let canvas = Canvas::new(9, 3)
  canvas.clear(Color::white())
  let path = Path::new().move_to(0.0, 1.0).line_to(8.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_stroke_cap(StrokeCap::Butt)
    .set_stroke_dash([2.0, 2.0], 0.0)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), Color::black())
  assert_eq(pixmap.get_pixel(3, 1), Color::white())
  assert_eq(pixmap.get_pixel(5, 1), Color::black())
}

///|
test "Canvas::stroke_path applies dash offset" {
  let canvas = Canvas::new(6, 3)
  canvas.clear(Color::white())
  let path = Path::new().move_to(0.0, 1.0).line_to(6.0, 1.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_stroke_cap(StrokeCap::Butt)
    .set_stroke_dash([2.0, 2.0], 2.0)
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_eq(pixmap.get_pixel(1, 1), Color::white())
  assert_eq(pixmap.get_pixel(3, 1), Color::black())
}

///|
test "Canvas::stroke_path supports dotted strokes" {
  let canvas = Canvas::new(8, 5)
  canvas.clear(Color::white())
  let path = Path::new().move_to(1.0, 2.0).line_to(7.0, 2.0)
  let paint = Paint::new()
    .set_color(Color::black())
    .set_style(PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_dotted_stroke()
  canvas.stroke_path(path, paint)
  let pixmap = canvas.get_pixmap()
  assert_not_white(pixmap.get_pixel(1, 2))
  assert_eq(pixmap.get_pixel(3, 2), Color::white())
  assert_not_white(pixmap.get_pixel(5, 2))
}

///|
fn assert_not_white(color : Color) -> Unit raise {
  assert_true(color != Color::white())
}

///|
fn assert_same_pixmap(left : Pixmap, right : Pixmap) -> Unit raise {
  assert_eq(left.get_width(), right.get_width())
  assert_eq(left.get_height(), right.get_height())
  for y in 0..<left.get_height() {
    for x in 0..<left.get_width() {
      assert_eq(left.get_pixel(x, y), right.get_pixel(x, y))
    }
  }
}

///|
fn make_canvas_test_nine_patch_source() -> Pixmap {
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
test "Canvas::stroke_path ignores fill paint" {
  let canvas = Canvas::new(3, 3)
  canvas.clear(Color::white())
  let path = Path::new().move_to(0.0, 1.0).line_to(3.0, 1.0)
  canvas.stroke_path(path, Paint::new().set_color(Color::black()))
  assert_eq(canvas.get_pixmap().get_pixel(1, 1), Color::white())
}
