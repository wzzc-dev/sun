///|
/// Pixel buffer for 2D rendering (RGBA format)
pub struct Pixmap {
  width : Int
  height : Int
  pixels : FixedArray[Byte]
} derive(Debug)

///|
/// Sampling mode used when scaling source pixmaps.
pub(all) enum ImageSampling {
  Nearest
  Bilinear
} derive(Eq, Debug)

///|
/// Insets used for nine-patch image scaling.
pub struct NinePatchInsets {
  left : Int
  top : Int
  right : Int
  bottom : Int
} derive(Eq, Debug)

///|
pub fn NinePatchInsets::new(
  left~ : Int,
  top~ : Int,
  right~ : Int,
  bottom~ : Int,
) -> NinePatchInsets {
  { left, top, right, bottom }
}

///|
struct NinePatchSlices {
  src_left : Int
  src_right : Int
  src_top : Int
  src_bottom : Int
  dst_left : Int
  dst_right : Int
  dst_top : Int
  dst_bottom : Int
} derive(Debug)

///|
/// Create a new pixmap filled with transparent pixels
pub fn Pixmap::new(width : Int, height : Int) -> Pixmap {
  let size = width * height * 4
  { width, height, pixels: FixedArray::make(size, 0) }
}

///|
/// Get the width of the pixmap
pub fn Pixmap::get_width(self : Pixmap) -> Int {
  self.width
}

///|
/// Get the height of the pixmap
pub fn Pixmap::get_height(self : Pixmap) -> Int {
  self.height
}

///|
/// Get the raw pixel data
pub fn Pixmap::get_pixels(self : Pixmap) -> FixedArray[Byte] {
  self.pixels
}

///|
/// Set a pixel at the given coordinates
pub fn Pixmap::set_pixel(
  self : Pixmap,
  x : Int,
  y : Int,
  color : Color,
) -> Unit {
  guard x >= 0 && x < self.width && y >= 0 && y < self.height else { return }
  let idx = (y * self.width + x) * 4
  self.pixels[idx] = color.r
  self.pixels[idx + 1] = color.g
  self.pixels[idx + 2] = color.b
  self.pixels[idx + 3] = color.a
}

///|
/// Composite a pixel over the existing pixel at the given coordinates
pub fn Pixmap::blend_pixel(
  self : Pixmap,
  x : Int,
  y : Int,
  color : Color,
) -> Unit {
  guard x >= 0 && x < self.width && y >= 0 && y < self.height else { return }
  self.set_pixel(x, y, color.blend_over(self.get_pixel(x, y)))
}

///|
/// Get the color at the given coordinates
pub fn Pixmap::get_pixel(self : Pixmap, x : Int, y : Int) -> Color {
  guard x >= 0 && x < self.width && y >= 0 && y < self.height else {
    return Color::transparent()
  }
  let idx = (y * self.width + x) * 4
  Color::new(
    r=self.pixels[idx],
    g=self.pixels[idx + 1],
    b=self.pixels[idx + 2],
    a=self.pixels[idx + 3],
  )
}

///|
/// Clear the pixmap with a color
pub fn Pixmap::clear(self : Pixmap, color : Color) -> Unit {
  for y in 0..<self.height {
    for x in 0..<self.width {
      self.set_pixel(x, y, color)
    }
  }
}

///|
/// Fill a rectangle with a color
pub fn Pixmap::fill_rect(
  self : Pixmap,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  color : Color,
) -> Unit {
  for dy in 0..<h {
    for dx in 0..<w {
      self.set_pixel(x + dx, y + dy, color)
    }
  }
}

///|
/// Composite a rectangle over the existing pixels
pub fn Pixmap::blend_rect(
  self : Pixmap,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  color : Color,
) -> Unit {
  for dy in 0..<h {
    for dx in 0..<w {
      self.blend_pixel(x + dx, y + dy, color)
    }
  }
}

///|
/// Composite a grayscale coverage mask over the existing pixels
pub fn Pixmap::blend_mask(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  mask : FixedArray[Byte],
  color : Color,
) -> Unit {
  guard width > 0 && height > 0 && mask.length() >= width * height else {
    return
  }
  for my in 0..<height {
    for mx in 0..<width {
      let coverage = mask[my * width + mx].to_int()
      if coverage > 0 {
        let alpha = (color.a.to_int() * coverage + 127) / 255
        self.blend_pixel(x + mx, y + my, color.with_alpha(clamp_byte(alpha)))
      }
    }
  }
}

///|
/// Composite another pixmap over this pixmap at the given destination position.
pub fn Pixmap::blend_pixmap(
  self : Pixmap,
  x : Int,
  y : Int,
  src : Pixmap,
  opacity : Double,
) -> Unit {
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let x_start = x.max(0)
  let y_start = y.max(0)
  let x_end = (x + src.get_width()).min(self.width)
  let y_end = (y + src.get_height()).min(self.height)
  guard x_start < x_end && y_start < y_end else { return }
  for py in y_start..<y_end {
    for px in x_start..<x_end {
      let src_color = src.get_pixel(px - x, py - y).scale_alpha(opacity)
      if src_color.a.to_int() > 0 {
        self.blend_pixel(px, py, src_color)
      }
    }
  }
}

///|
/// Composite a source pixmap rectangle over this pixmap at the destination
/// position corresponding to the requested source rectangle's top-left corner.
pub fn Pixmap::blend_pixmap_rect(
  self : Pixmap,
  x : Int,
  y : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
) -> Unit {
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let src_bounds = PixelRect::new(
    x=0,
    y=0,
    width=src.get_width(),
    height=src.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) => {
      let dst_x = x + clipped_src.x - src_rect.x
      let dst_y = y + clipped_src.y - src_rect.y
      let x_start = dst_x.max(0)
      let y_start = dst_y.max(0)
      let x_end = (dst_x + clipped_src.width).min(self.width)
      let y_end = (dst_y + clipped_src.height).min(self.height)
      guard x_start < x_end && y_start < y_end else { return }
      for py in y_start..<y_end {
        for px in x_start..<x_end {
          let src_x = clipped_src.x + px - dst_x
          let src_y = clipped_src.y + py - dst_y
          let src_color = src.get_pixel(src_x, src_y).scale_alpha(opacity)
          if src_color.a.to_int() > 0 {
            self.blend_pixel(px, py, src_color)
          }
        }
      }
    }
    None => ()
  }
}

///|
/// Composite another pixmap scaled to the given destination size.
pub fn Pixmap::blend_scaled_pixmap(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  opacity : Double,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let x_start = x.max(0)
  let y_start = y.max(0)
  let x_end = (x + width).min(self.width)
  let y_end = (y + height).min(self.height)
  guard x_start < x_end && y_start < y_end else { return }
  blend_scaled_pixmap_region(
    self, x, y, width, height, src, opacity, x_start, y_start, x_end, y_end,
  )
}

///|
/// Composite another pixmap scaled with bilinear sampling.
pub fn Pixmap::blend_scaled_pixmap_bilinear(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  opacity : Double,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let x_start = x.max(0)
  let y_start = y.max(0)
  let x_end = (x + width).min(self.width)
  let y_end = (y + height).min(self.height)
  guard x_start < x_end && y_start < y_end else { return }
  blend_scaled_pixmap_bilinear_region(
    self, x, y, width, height, src, opacity, x_start, y_start, x_end, y_end,
  )
}

///|
/// Composite another pixmap scaled with an explicit sampling mode.
pub fn Pixmap::blend_sampled_pixmap(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  opacity : Double,
  sampling : ImageSampling,
) -> Unit {
  match sampling {
    ImageSampling::Nearest =>
      self.blend_scaled_pixmap(x, y, width, height, src, opacity)
    ImageSampling::Bilinear =>
      self.blend_scaled_pixmap_bilinear(x, y, width, height, src, opacity)
  }
}

///|
/// Composite a source pixmap rectangle scaled to the given destination size.
pub fn Pixmap::blend_scaled_pixmap_rect(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
) -> Unit {
  self.blend_sampled_pixmap_rect(
    x,
    y,
    width,
    height,
    src,
    src_rect,
    opacity,
    ImageSampling::Nearest,
  )
}

///|
/// Composite a source pixmap rectangle scaled with bilinear sampling.
pub fn Pixmap::blend_scaled_pixmap_rect_bilinear(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
) -> Unit {
  self.blend_sampled_pixmap_rect(
    x,
    y,
    width,
    height,
    src,
    src_rect,
    opacity,
    ImageSampling::Bilinear,
  )
}

///|
/// Composite a source pixmap rectangle scaled with an explicit sampling mode.
pub fn Pixmap::blend_sampled_pixmap_rect(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
  sampling : ImageSampling,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let src_bounds = PixelRect::new(
    x=0,
    y=0,
    width=src.get_width(),
    height=src.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) => {
      let x_start = x.max(0)
      let y_start = y.max(0)
      let x_end = (x + width).min(self.width)
      let y_end = (y + height).min(self.height)
      guard x_start < x_end && y_start < y_end else { return }
      blend_sampled_pixmap_rect_region(
        self, x, y, width, height, src, clipped_src, opacity, sampling, x_start,
        y_start, x_end, y_end,
      )
    }
    None => ()
  }
}

///|
/// Composite a source pixmap rectangle repeatedly into the destination area.
pub fn Pixmap::blend_tiled_pixmap_rect(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let src_bounds = PixelRect::new(
    x=0,
    y=0,
    width=src.get_width(),
    height=src.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) => {
      let x_start = x.max(0)
      let y_start = y.max(0)
      let x_end = (x + width).min(self.width)
      let y_end = (y + height).min(self.height)
      guard x_start < x_end && y_start < y_end else { return }
      blend_tiled_pixmap_rect_region(
        self, x, y, width, height, src, clipped_src, opacity, x_start, y_start, x_end,
        y_end,
      )
    }
    None => ()
  }
}

///|
/// Composite a source pixmap using nine-patch scaling.
pub fn Pixmap::blend_nine_patch_pixmap(
  self : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  insets : NinePatchInsets,
  opacity : Double,
  sampling : ImageSampling,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src.get_width() > 0 && src.get_height() > 0 else { return }
  let x_start = x.max(0)
  let y_start = y.max(0)
  let x_end = (x + width).min(self.width)
  let y_end = (y + height).min(self.height)
  guard x_start < x_end && y_start < y_end else { return }
  blend_nine_patch_pixmap_region(
    self, x, y, width, height, src, insets, opacity, sampling, x_start, y_start,
    x_end, y_end,
  )
}

///|
fn blend_nine_patch_pixmap_region(
  dst : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  insets : NinePatchInsets,
  opacity : Double,
  sampling : ImageSampling,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  let slices = make_nine_patch_slices(
    src.get_width(),
    src.get_height(),
    width,
    height,
    insets,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    0,
    0,
    slices.dst_left,
    slices.dst_top,
    src,
    PixelRect::new(x=0, y=0, width=slices.src_left, height=slices.src_top),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    slices.dst_left,
    0,
    width - slices.dst_left - slices.dst_right,
    slices.dst_top,
    src,
    PixelRect::new(
      x=slices.src_left,
      y=0,
      width=src.get_width() - slices.src_left - slices.src_right,
      height=slices.src_top,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    width - slices.dst_right,
    0,
    slices.dst_right,
    slices.dst_top,
    src,
    PixelRect::new(
      x=src.get_width() - slices.src_right,
      y=0,
      width=slices.src_right,
      height=slices.src_top,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    0,
    slices.dst_top,
    slices.dst_left,
    height - slices.dst_top - slices.dst_bottom,
    src,
    PixelRect::new(
      x=0,
      y=slices.src_top,
      width=slices.src_left,
      height=src.get_height() - slices.src_top - slices.src_bottom,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    slices.dst_left,
    slices.dst_top,
    width - slices.dst_left - slices.dst_right,
    height - slices.dst_top - slices.dst_bottom,
    src,
    PixelRect::new(
      x=slices.src_left,
      y=slices.src_top,
      width=src.get_width() - slices.src_left - slices.src_right,
      height=src.get_height() - slices.src_top - slices.src_bottom,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    width - slices.dst_right,
    slices.dst_top,
    slices.dst_right,
    height - slices.dst_top - slices.dst_bottom,
    src,
    PixelRect::new(
      x=src.get_width() - slices.src_right,
      y=slices.src_top,
      width=slices.src_right,
      height=src.get_height() - slices.src_top - slices.src_bottom,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    0,
    height - slices.dst_bottom,
    slices.dst_left,
    slices.dst_bottom,
    src,
    PixelRect::new(
      x=0,
      y=src.get_height() - slices.src_bottom,
      width=slices.src_left,
      height=slices.src_bottom,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    slices.dst_left,
    height - slices.dst_bottom,
    width - slices.dst_left - slices.dst_right,
    slices.dst_bottom,
    src,
    PixelRect::new(
      x=slices.src_left,
      y=src.get_height() - slices.src_bottom,
      width=src.get_width() - slices.src_left - slices.src_right,
      height=slices.src_bottom,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
  blend_nine_patch_segment(
    dst,
    x,
    y,
    width - slices.dst_right,
    height - slices.dst_bottom,
    slices.dst_right,
    slices.dst_bottom,
    src,
    PixelRect::new(
      x=src.get_width() - slices.src_right,
      y=src.get_height() - slices.src_bottom,
      width=slices.src_right,
      height=slices.src_bottom,
    ),
    opacity,
    sampling,
    x_start,
    y_start,
    x_end,
    y_end,
  )
}

///|
fn make_nine_patch_slices(
  src_width : Int,
  src_height : Int,
  dst_width : Int,
  dst_height : Int,
  insets : NinePatchInsets,
) -> NinePatchSlices {
  let (src_left, src_right) = clamp_edge_pair(
    src_width,
    insets.left,
    insets.right,
  )
  let (src_top, src_bottom) = clamp_edge_pair(
    src_height,
    insets.top,
    insets.bottom,
  )
  let (dst_left, dst_right) = clamp_edge_pair(dst_width, src_left, src_right)
  let (dst_top, dst_bottom) = clamp_edge_pair(dst_height, src_top, src_bottom)
  {
    src_left,
    src_right,
    src_top,
    src_bottom,
    dst_left,
    dst_right,
    dst_top,
    dst_bottom,
  }
}

///|
fn clamp_edge_pair(total : Int, start : Int, end : Int) -> (Int, Int) {
  guard total > 0 else { return (0, 0) }
  let clamped_start = start.max(0).min(total)
  let clamped_end = end.max(0).min(total - clamped_start)
  (clamped_start, clamped_end)
}

///|
fn blend_nine_patch_segment(
  dst : Pixmap,
  patch_x : Int,
  patch_y : Int,
  dst_offset_x : Int,
  dst_offset_y : Int,
  dst_width : Int,
  dst_height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
  sampling : ImageSampling,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  guard dst_width > 0 && dst_height > 0 else { return }
  guard src_rect.width > 0 && src_rect.height > 0 else { return }
  let dst_x = patch_x + dst_offset_x
  let dst_y = patch_y + dst_offset_y
  let segment_x_start = x_start.max(dst_x)
  let segment_y_start = y_start.max(dst_y)
  let segment_x_end = x_end.min(dst_x + dst_width)
  let segment_y_end = y_end.min(dst_y + dst_height)
  guard segment_x_start < segment_x_end && segment_y_start < segment_y_end else {
    return
  }
  blend_sampled_pixmap_rect_region(
    dst, dst_x, dst_y, dst_width, dst_height, src, src_rect, opacity, sampling, segment_x_start,
    segment_y_start, segment_x_end, segment_y_end,
  )
}

///|
fn blend_sampled_pixmap_rect_region(
  dst : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
  sampling : ImageSampling,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  match sampling {
    ImageSampling::Nearest =>
      blend_scaled_pixmap_rect_region(
        dst, x, y, width, height, src, src_rect, opacity, x_start, y_start, x_end,
        y_end,
      )
    ImageSampling::Bilinear =>
      blend_scaled_pixmap_rect_bilinear_region(
        dst, x, y, width, height, src, src_rect, opacity, x_start, y_start, x_end,
        y_end,
      )
  }
}

///|
fn blend_tiled_pixmap_rect_region(
  dst : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src_rect.width > 0 && src_rect.height > 0 else { return }
  for py in y_start..<y_end {
    let src_y = src_rect.y + positive_mod(py - y, src_rect.height)
    for px in x_start..<x_end {
      let src_x = src_rect.x + positive_mod(px - x, src_rect.width)
      let src_color = src.get_pixel(src_x, src_y).scale_alpha(opacity)
      if src_color.a.to_int() > 0 {
        dst.blend_pixel(px, py, src_color)
      }
    }
  }
}

///|
fn blend_scaled_pixmap_rect_region(
  dst : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src_rect.width > 0 && src_rect.height > 0 else { return }
  for py in y_start..<y_end {
    let src_y = src_rect.y +
      scaled_source_index(py - y, height, src_rect.height)
    for px in x_start..<x_end {
      let src_x = src_rect.x +
        scaled_source_index(px - x, width, src_rect.width)
      let src_color = src.get_pixel(src_x, src_y).scale_alpha(opacity)
      if src_color.a.to_int() > 0 {
        dst.blend_pixel(px, py, src_color)
      }
    }
  }
}

///|
fn blend_scaled_pixmap_rect_bilinear_region(
  dst : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  src_rect : PixelRect,
  opacity : Double,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  guard width > 0 && height > 0 else { return }
  guard src_rect.width > 0 && src_rect.height > 0 else { return }
  for py in y_start..<y_end {
    let src_y = src_rect.y.to_double() +
      scaled_source_position(py - y, height, src_rect.height)
    for px in x_start..<x_end {
      let src_x = src_rect.x.to_double() +
        scaled_source_position(px - x, width, src_rect.width)
      let src_color = sample_bilinear_rect(src, src_x, src_y, src_rect).scale_alpha(
        opacity,
      )
      if src_color.a.to_int() > 0 {
        dst.blend_pixel(px, py, src_color)
      }
    }
  }
}

///|
fn blend_scaled_pixmap_region(
  dst : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  opacity : Double,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  for py in y_start..<y_end {
    let src_y = scaled_source_index(py - y, height, src.get_height())
    for px in x_start..<x_end {
      let src_x = scaled_source_index(px - x, width, src.get_width())
      let src_color = src.get_pixel(src_x, src_y).scale_alpha(opacity)
      if src_color.a.to_int() > 0 {
        dst.blend_pixel(px, py, src_color)
      }
    }
  }
}

///|
fn scaled_source_index(dst_offset : Int, dst_size : Int, src_size : Int) -> Int {
  guard dst_size > 0 && src_size > 0 else { return 0 }
  let numerator = (dst_offset * 2 + 1) * src_size
  let denominator = dst_size * 2
  (numerator / denominator).max(0).min(src_size - 1)
}

///|
fn blend_scaled_pixmap_bilinear_region(
  dst : Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  src : Pixmap,
  opacity : Double,
  x_start : Int,
  y_start : Int,
  x_end : Int,
  y_end : Int,
) -> Unit {
  for py in y_start..<y_end {
    let src_y = scaled_source_position(py - y, height, src.get_height())
    for px in x_start..<x_end {
      let src_x = scaled_source_position(px - x, width, src.get_width())
      let src_color = sample_bilinear(src, src_x, src_y).scale_alpha(opacity)
      if src_color.a.to_int() > 0 {
        dst.blend_pixel(px, py, src_color)
      }
    }
  }
}

///|
fn scaled_source_position(
  dst_offset : Int,
  dst_size : Int,
  src_size : Int,
) -> Double {
  guard dst_size > 0 && src_size > 0 else { return 0.0 }
  (dst_offset.to_double() + 0.5) * src_size.to_double() / dst_size.to_double() -
  0.5
}

///|
fn sample_bilinear(src : Pixmap, x : Double, y : Double) -> Color {
  let x_floor = floor_to_int(x)
  let y_floor = floor_to_int(y)
  let x0 = x_floor.max(0).min(src.get_width() - 1)
  let y0 = y_floor.max(0).min(src.get_height() - 1)
  let x1 = (x_floor + 1).max(0).min(src.get_width() - 1)
  let y1 = (y_floor + 1).max(0).min(src.get_height() - 1)
  let tx = (x - x_floor.to_double()).max(0.0).min(1.0)
  let ty = (y - y_floor.to_double()).max(0.0).min(1.0)
  let c00 = src.get_pixel(x0, y0)
  let c10 = src.get_pixel(x1, y0)
  let c01 = src.get_pixel(x0, y1)
  let c11 = src.get_pixel(x1, y1)
  let alpha = bilinear_value(
    c00.a.to_int().to_double(),
    c10.a.to_int().to_double(),
    c01.a.to_int().to_double(),
    c11.a.to_int().to_double(),
    tx,
    ty,
  )
  Color::new(
    r=unpremul_channel(
      bilinear_value(
        premul_channel(c00.r, c00.a),
        premul_channel(c10.r, c10.a),
        premul_channel(c01.r, c01.a),
        premul_channel(c11.r, c11.a),
        tx,
        ty,
      ),
      alpha,
    ),
    g=unpremul_channel(
      bilinear_value(
        premul_channel(c00.g, c00.a),
        premul_channel(c10.g, c10.a),
        premul_channel(c01.g, c01.a),
        premul_channel(c11.g, c11.a),
        tx,
        ty,
      ),
      alpha,
    ),
    b=unpremul_channel(
      bilinear_value(
        premul_channel(c00.b, c00.a),
        premul_channel(c10.b, c10.a),
        premul_channel(c01.b, c01.a),
        premul_channel(c11.b, c11.a),
        tx,
        ty,
      ),
      alpha,
    ),
    a=round_to_byte(alpha),
  )
}

///|
fn sample_bilinear_rect(
  src : Pixmap,
  x : Double,
  y : Double,
  rect : PixelRect,
) -> Color {
  let x_floor = floor_to_int(x)
  let y_floor = floor_to_int(y)
  let left = rect.x.max(0).min(src.get_width() - 1)
  let top = rect.y.max(0).min(src.get_height() - 1)
  let right = rect.right().max(left + 1).min(src.get_width())
  let bottom = rect.bottom().max(top + 1).min(src.get_height())
  let x0 = x_floor.max(left).min(right - 1)
  let y0 = y_floor.max(top).min(bottom - 1)
  let x1 = (x_floor + 1).max(left).min(right - 1)
  let y1 = (y_floor + 1).max(top).min(bottom - 1)
  let tx = (x - x_floor.to_double()).max(0.0).min(1.0)
  let ty = (y - y_floor.to_double()).max(0.0).min(1.0)
  let c00 = src.get_pixel(x0, y0)
  let c10 = src.get_pixel(x1, y0)
  let c01 = src.get_pixel(x0, y1)
  let c11 = src.get_pixel(x1, y1)
  let alpha = bilinear_value(
    c00.a.to_int().to_double(),
    c10.a.to_int().to_double(),
    c01.a.to_int().to_double(),
    c11.a.to_int().to_double(),
    tx,
    ty,
  )
  Color::new(
    r=unpremul_channel(
      bilinear_value(
        premul_channel(c00.r, c00.a),
        premul_channel(c10.r, c10.a),
        premul_channel(c01.r, c01.a),
        premul_channel(c11.r, c11.a),
        tx,
        ty,
      ),
      alpha,
    ),
    g=unpremul_channel(
      bilinear_value(
        premul_channel(c00.g, c00.a),
        premul_channel(c10.g, c10.a),
        premul_channel(c01.g, c01.a),
        premul_channel(c11.g, c11.a),
        tx,
        ty,
      ),
      alpha,
    ),
    b=unpremul_channel(
      bilinear_value(
        premul_channel(c00.b, c00.a),
        premul_channel(c10.b, c10.a),
        premul_channel(c01.b, c01.a),
        premul_channel(c11.b, c11.a),
        tx,
        ty,
      ),
      alpha,
    ),
    a=round_to_byte(alpha),
  )
}

///|
fn floor_to_int(value : Double) -> Int {
  let truncated = value.to_int()
  if truncated.to_double() > value {
    truncated - 1
  } else {
    truncated
  }
}

///|
fn positive_mod(value : Int, modulus : Int) -> Int {
  guard modulus > 0 else { return 0 }
  let mut result = value % modulus
  if result < 0 {
    result = result + modulus
  }
  result
}

///|
fn bilinear_value(
  v00 : Double,
  v10 : Double,
  v01 : Double,
  v11 : Double,
  tx : Double,
  ty : Double,
) -> Double {
  let top = v00 * (1.0 - tx) + v10 * tx
  let bottom = v01 * (1.0 - tx) + v11 * tx
  top * (1.0 - ty) + bottom * ty
}

///|
fn premul_channel(channel : Byte, alpha : Byte) -> Double {
  channel.to_int().to_double() * alpha.to_int().to_double() / 255.0
}

///|
fn unpremul_channel(premul : Double, alpha : Double) -> Byte {
  guard alpha > 0.0 else { return clamp_byte(0) }
  round_to_byte(premul * 255.0 / alpha)
}

///|
fn round_to_byte(value : Double) -> Byte {
  clamp_byte((value + 0.5).to_int())
}
