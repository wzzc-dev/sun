///|
/// Error returned when presenting RGBA pixels to a surface fails.
pub(all) enum PresentError {
  InvalidDimensions(Int, Int)
  SizeMismatch(Int, Int, Int, Int)
  RectOutOfBounds(Int, Int, Int, Int, Int, Int)
  InvalidRowBytes(Int, Int)
  PixelBufferTooSmall(Int, Int)
} derive(Eq, Debug)

///|
/// Validated geometry for a rectangle present call. Backends can use this to
/// share row-stride and buffer-size checks with the reference MemorySurface.
pub(all) struct PresentRectInfo {
  required_row_bytes : Int
  required_len : Int
} derive(Eq, Debug)

///|
pub fn PresentRectInfo::required_row_bytes(self : PresentRectInfo) -> Int {
  self.required_row_bytes
}

///|
pub fn PresentRectInfo::required_len(self : PresentRectInfo) -> Int {
  self.required_len
}

///|
/// Destination for CPU-rendered RGBA pixels.
pub(open) trait Surface {
  fn get_width(Self) -> Int
  fn get_height(Self) -> Int
  fn present_pixels(
    Self,
    width : Int,
    height : Int,
    row_bytes : Int,
    pixels : FixedArray[Byte],
  ) -> Result[Unit, PresentError]
  fn present_pixels_rect(
    Self,
    x : Int,
    y : Int,
    width : Int,
    height : Int,
    row_bytes : Int,
    pixels : FixedArray[Byte],
  ) -> Result[Unit, PresentError]
}

///|
/// In-memory surface used as the reference backend for tests and headless tools.
pub struct MemorySurface {
  width : Int
  height : Int
  pixels : FixedArray[Byte]
  mut present_count : Int
} derive(Debug)

///|
pub fn MemorySurface::new(width : Int, height : Int) -> MemorySurface {
  let safe_width = width.max(0)
  let safe_height = height.max(0)
  {
    width: safe_width,
    height: safe_height,
    pixels: FixedArray::make(safe_width * safe_height * 4, 0),
    present_count: 0,
  }
}

///|
pub fn MemorySurface::get_width(self : MemorySurface) -> Int {
  self.width
}

///|
pub fn MemorySurface::get_height(self : MemorySurface) -> Int {
  self.height
}

///|
pub fn MemorySurface::get_pixels(self : MemorySurface) -> FixedArray[Byte] {
  self.pixels
}

///|
pub fn MemorySurface::get_present_count(self : MemorySurface) -> Int {
  self.present_count
}

///|
pub fn MemorySurface::get_pixel(
  self : MemorySurface,
  x : Int,
  y : Int,
) -> Color {
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
pub fn MemorySurface::present_pixels(
  self : MemorySurface,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, PresentError] {
  guard width > 0 && height > 0 else {
    return Err(PresentError::InvalidDimensions(width, height))
  }
  guard width == self.width && height == self.height else {
    return Err(
      PresentError::SizeMismatch(self.width, self.height, width, height),
    )
  }
  self.present_pixels_rect(0, 0, width, height, row_bytes, pixels)
}

///|
pub fn MemorySurface::present_pixels_rect(
  self : MemorySurface,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, PresentError] {
  match
    validate_present_rect(
      self.width,
      self.height,
      x,
      y,
      width,
      height,
      row_bytes,
      pixels,
    ) {
    Err(error) => return Err(error)
    Ok(info) => {
      for row in 0..<height {
        let src_row = row * row_bytes
        let dst_row = ((y + row) * self.width + x) * 4
        for column in 0..<info.required_row_bytes() {
          self.pixels[dst_row + column] = pixels[src_row + column]
        }
      }
      self.present_count = self.present_count + 1
      Ok(())
    }
  }
}

///|
pub fn validate_present_rect(
  surface_width : Int,
  surface_height : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[PresentRectInfo, PresentError] {
  guard width > 0 && height > 0 else {
    return Err(PresentError::InvalidDimensions(width, height))
  }
  guard x >= 0 &&
    y >= 0 &&
    width <= surface_width - x &&
    height <= surface_height - y else {
    return Err(
      PresentError::RectOutOfBounds(
        x, y, width, height, surface_width, surface_height,
      ),
    )
  }
  let required_row_bytes = width * 4
  guard row_bytes >= required_row_bytes else {
    return Err(PresentError::InvalidRowBytes(row_bytes, required_row_bytes))
  }
  let required_len = row_bytes * (height - 1) + required_row_bytes
  guard pixels.length() >= required_len else {
    return Err(PresentError::PixelBufferTooSmall(pixels.length(), required_len))
  }
  Ok({ required_row_bytes, required_len })
}

///|
pub impl Surface for MemorySurface with fn get_width(self) {
  self.get_width()
}

///|
pub impl Surface for MemorySurface with fn get_height(self) {
  self.get_height()
}

///|
pub impl Surface for MemorySurface with fn present_pixels(
  self,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels(width, height, row_bytes, pixels)
}

///|
pub impl Surface for MemorySurface with fn present_pixels_rect(
  self,
  x,
  y,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels_rect(x, y, width, height, row_bytes, pixels)
}

///|
pub fn[S : Surface] present_pixels(
  surface : S,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, PresentError] {
  surface.present_pixels(width, height, row_bytes, pixels)
}

///|
pub fn[S : Surface] present_pixels_rect(
  surface : S,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, PresentError] {
  surface.present_pixels_rect(x, y, width, height, row_bytes, pixels)
}

///|
pub fn[S : Surface] Pixmap::present_to(
  self : Pixmap,
  surface : S,
) -> Result[Unit, PresentError] {
  surface.present_pixels(
    self.get_width(),
    self.get_height(),
    self.get_width() * 4,
    self.get_pixels(),
  )
}

///|
pub fn[S : Surface] Pixmap::present_rect_to(
  self : Pixmap,
  surface : S,
  rect : PixelRect,
) -> Result[Unit, PresentError] {
  guard !rect.is_empty() else {
    return Err(PresentError::InvalidDimensions(rect.width, rect.height))
  }
  guard rect.x >= 0 &&
    rect.y >= 0 &&
    rect.width <= self.get_width() - rect.x &&
    rect.height <= self.get_height() - rect.y else {
    return Err(
      PresentError::RectOutOfBounds(
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        self.get_width(),
        self.get_height(),
      ),
    )
  }
  let row_bytes = rect.width * 4
  surface.present_pixels_rect(
    rect.x,
    rect.y,
    rect.width,
    rect.height,
    row_bytes,
    copy_pixmap_rect(self, rect),
  )
}

///|
pub fn[S : Surface] Canvas::present_to(
  self : Canvas,
  surface : S,
) -> Result[Unit, PresentError] {
  self.get_pixmap().present_to(surface)
}

///|
pub fn[S : Surface] Canvas::present_dirty_to(
  self : Canvas,
  surface : S,
) -> Result[Int, PresentError] {
  self.present_dirty_to_with_limit(surface, default_dirty_present_rect_limit)
}

///|
pub fn[S : Surface] Canvas::present_dirty_to_with_limit(
  self : Canvas,
  surface : S,
  max_rects : Int,
) -> Result[Int, PresentError] {
  let dirty_region = self.get_dirty_region()
  guard !dirty_region.is_empty() else { return Ok(0) }
  let surface_bounds = PixelRect::new(
    x=0,
    y=0,
    width=surface.get_width(),
    height=surface.get_height(),
  )
  let pixmap_bounds = PixelRect::new(
    x=0,
    y=0,
    width=self.get_pixmap().get_width(),
    height=self.get_pixmap().get_height(),
  )
  let bounds = surface_bounds.intersection(pixmap_bounds)
  let mut presented = 0
  match bounds {
    None => {
      self.clear_dirty_region()
      Ok(0)
    }
    Some(present_bounds) => {
      let present_rects = dirty_region.present_rects(present_bounds, max_rects)
      for rect in present_rects {
        match self.get_pixmap().present_rect_to(surface, rect) {
          Ok(_) => presented = presented + 1
          Err(error) => return Err(error)
        }
      }
      self.clear_dirty_region()
      Ok(presented)
    }
  }
}

///|
let default_dirty_present_rect_limit = 32

///|
fn copy_pixmap_rect(pixmap : Pixmap, rect : PixelRect) -> FixedArray[Byte] {
  let row_bytes = rect.width * 4
  let packed : FixedArray[Byte] = FixedArray::make(row_bytes * rect.height, 0)
  let source_row_bytes = pixmap.get_width() * 4
  let source = pixmap.get_pixels()
  for row in 0..<rect.height {
    let source_row = (rect.y + row) * source_row_bytes + rect.x * 4
    let packed_row = row * row_bytes
    for column in 0..<row_bytes {
      packed[packed_row + column] = source[source_row + column]
    }
  }
  packed
}
