///|
fn render_keyed_image_point_is_same(
  a_key : String,
  b_key : String,
  ax : Int,
  ay : Int,
  bx : Int,
  by : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_key == b_key &&
  ax == bx &&
  ay == by &&
  render_paint_is_same(a_paint, b_paint)
}

///|
fn render_keyed_image_rect_is_same(
  a_key : String,
  b_key : String,
  ax : Int,
  ay : Int,
  aw : Int,
  ah : Int,
  bx : Int,
  by : Int,
  bw : Int,
  bh : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_key == b_key &&
  ax == bx &&
  ay == by &&
  aw == bw &&
  ah == bh &&
  render_paint_is_same(a_paint, b_paint)
}

///|
fn render_keyed_image_dimensions_point_is_same(
  a_key : String,
  b_key : String,
  a_width : Int,
  a_height : Int,
  b_width : Int,
  b_height : Int,
  ax : Int,
  ay : Int,
  bx : Int,
  by : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_width == b_width &&
  a_height == b_height &&
  render_keyed_image_point_is_same(
    a_key, b_key, ax, ay, bx, by, a_paint, b_paint,
  )
}

///|
fn render_keyed_image_dimensions_rect_is_same(
  a_key : String,
  b_key : String,
  a_width : Int,
  a_height : Int,
  b_width : Int,
  b_height : Int,
  ax : Int,
  ay : Int,
  aw : Int,
  ah : Int,
  bx : Int,
  by : Int,
  bw : Int,
  bh : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_width == b_width &&
  a_height == b_height &&
  render_keyed_image_rect_is_same(
    a_key, b_key, ax, ay, aw, ah, bx, by, bw, bh, a_paint, b_paint,
  )
}

///|
fn render_keyed_image_source_point_is_same(
  a_key : String,
  b_key : String,
  a_src : @graphics.PixelRect,
  b_src : @graphics.PixelRect,
  ax : Int,
  ay : Int,
  bx : Int,
  by : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_src == b_src &&
  render_keyed_image_point_is_same(
    a_key, b_key, ax, ay, bx, by, a_paint, b_paint,
  )
}

///|
fn render_keyed_image_source_rect_is_same(
  a_key : String,
  b_key : String,
  a_src : @graphics.PixelRect,
  b_src : @graphics.PixelRect,
  ax : Int,
  ay : Int,
  aw : Int,
  ah : Int,
  bx : Int,
  by : Int,
  bw : Int,
  bh : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_src == b_src &&
  render_keyed_image_rect_is_same(
    a_key, b_key, ax, ay, aw, ah, bx, by, bw, bh, a_paint, b_paint,
  )
}

///|
fn render_keyed_image_dimensions_source_point_is_same(
  a_key : String,
  b_key : String,
  a_width : Int,
  a_height : Int,
  b_width : Int,
  b_height : Int,
  a_src : @graphics.PixelRect,
  b_src : @graphics.PixelRect,
  ax : Int,
  ay : Int,
  bx : Int,
  by : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_width == b_width &&
  a_height == b_height &&
  render_keyed_image_source_point_is_same(
    a_key, b_key, a_src, b_src, ax, ay, bx, by, a_paint, b_paint,
  )
}

///|
fn render_keyed_image_dimensions_source_rect_is_same(
  a_key : String,
  b_key : String,
  a_width : Int,
  a_height : Int,
  b_width : Int,
  b_height : Int,
  a_src : @graphics.PixelRect,
  b_src : @graphics.PixelRect,
  ax : Int,
  ay : Int,
  aw : Int,
  ah : Int,
  bx : Int,
  by : Int,
  bw : Int,
  bh : Int,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_width == b_width &&
  a_height == b_height &&
  render_keyed_image_source_rect_is_same(
    a_key, b_key, a_src, b_src, ax, ay, aw, ah, bx, by, bw, bh, a_paint, b_paint,
  )
}

///|
fn render_keyed_transformed_image_rect_is_same(
  a_key : String,
  b_key : String,
  ax : Double,
  ay : Double,
  aw : Double,
  ah : Double,
  bx : Double,
  by : Double,
  bw : Double,
  bh : Double,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_key == b_key &&
  ax == bx &&
  ay == by &&
  aw == bw &&
  ah == bh &&
  render_paint_is_same(a_paint, b_paint)
}

///|
fn render_keyed_transformed_image_source_rect_is_same(
  a_key : String,
  b_key : String,
  a_src : @graphics.PixelRect,
  b_src : @graphics.PixelRect,
  ax : Double,
  ay : Double,
  aw : Double,
  ah : Double,
  bx : Double,
  by : Double,
  bw : Double,
  bh : Double,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_src == b_src &&
  render_keyed_transformed_image_rect_is_same(
    a_key, b_key, ax, ay, aw, ah, bx, by, bw, bh, a_paint, b_paint,
  )
}

///|
fn render_keyed_transformed_image_dimensions_rect_is_same(
  a_key : String,
  b_key : String,
  a_width : Int,
  a_height : Int,
  b_width : Int,
  b_height : Int,
  ax : Double,
  ay : Double,
  aw : Double,
  ah : Double,
  bx : Double,
  by : Double,
  bw : Double,
  bh : Double,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_width == b_width &&
  a_height == b_height &&
  render_keyed_transformed_image_rect_is_same(
    a_key, b_key, ax, ay, aw, ah, bx, by, bw, bh, a_paint, b_paint,
  )
}

///|
fn render_keyed_transformed_image_dimensions_source_rect_is_same(
  a_key : String,
  b_key : String,
  a_width : Int,
  a_height : Int,
  b_width : Int,
  b_height : Int,
  a_src : @graphics.PixelRect,
  b_src : @graphics.PixelRect,
  ax : Double,
  ay : Double,
  aw : Double,
  ah : Double,
  bx : Double,
  by : Double,
  bw : Double,
  bh : Double,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
) -> Bool {
  a_width == b_width &&
  a_height == b_height &&
  render_keyed_transformed_image_source_rect_is_same(
    a_key, b_key, a_src, b_src, ax, ay, aw, ah, bx, by, bw, bh, a_paint, b_paint,
  )
}

///|
fn render_keyed_nine_patch_image_is_same(
  a_key : String,
  b_key : String,
  ax : Int,
  ay : Int,
  aw : Int,
  ah : Int,
  bx : Int,
  by : Int,
  bw : Int,
  bh : Int,
  a_insets : @graphics.NinePatchInsets,
  b_insets : @graphics.NinePatchInsets,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
  a_sampling : @graphics.ImageSampling,
  b_sampling : @graphics.ImageSampling,
) -> Bool {
  render_keyed_image_rect_is_same(
    a_key, b_key, ax, ay, aw, ah, bx, by, bw, bh, a_paint, b_paint,
  ) &&
  a_insets == b_insets &&
  a_sampling == b_sampling
}

///|
fn render_keyed_nine_patch_image_dimensions_is_same(
  a_key : String,
  b_key : String,
  a_width : Int,
  a_height : Int,
  b_width : Int,
  b_height : Int,
  ax : Int,
  ay : Int,
  aw : Int,
  ah : Int,
  bx : Int,
  by : Int,
  bw : Int,
  bh : Int,
  a_insets : @graphics.NinePatchInsets,
  b_insets : @graphics.NinePatchInsets,
  a_paint : @graphics.Paint,
  b_paint : @graphics.Paint,
  a_sampling : @graphics.ImageSampling,
  b_sampling : @graphics.ImageSampling,
) -> Bool {
  render_keyed_image_dimensions_rect_is_same(
    a_key, b_key, a_width, a_height, b_width, b_height, ax, ay, aw, ah, bx, by, bw,
    bh, a_paint, b_paint,
  ) &&
  a_insets == b_insets &&
  a_sampling == b_sampling
}
