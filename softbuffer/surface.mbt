///|
/// A surface for rendering pixels to a window
pub struct Surface {
  window : Window
  mut width : Int
  mut height : Int
}

///|
/// A present target backed by a native window handle from another windowing
/// package.
pub struct NativeSurface {
  handle : UInt64
  mut width : Int
  mut height : Int
}

///|
/// Create a new surface for the given window
pub fn Surface::new(window : Window) -> Surface {
  { window, width: window.width(), height: window.height() }
}

///|
/// Get surface width
pub fn Surface::width(self : Surface) -> Int {
  self.width
}

///|
/// Get surface height
pub fn Surface::height(self : Surface) -> Int {
  self.height
}

///|
/// Get surface width using the common graphics surface naming convention.
pub fn Surface::get_width(self : Surface) -> Int {
  self.width
}

///|
/// Get surface height using the common graphics surface naming convention.
pub fn Surface::get_height(self : Surface) -> Int {
  self.height
}

///|
/// Resize the surface to match window size
pub fn Surface::resize(self : Surface) -> Unit {
  self.width = self.window.width()
  self.height = self.window.height()
}

///|
/// Present RGBA pixels to the surface
pub fn Surface::present(self : Surface, pixels : FixedArray[Byte]) -> Unit {
  self.window.present(pixels, self.width, self.height)
}

///|
/// Present RGBA pixels to the surface with validation and optional row padding.
pub fn Surface::present_pixels(
  self : Surface,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  guard width > 0 && height > 0 else {
    return Err(@graphics.PresentError::InvalidDimensions(width, height))
  }
  guard width == self.width && height == self.height else {
    return Err(
      @graphics.PresentError::SizeMismatch(
        self.width,
        self.height,
        width,
        height,
      ),
    )
  }
  present_rect_to_handle(
    self.window.handle(),
    self.width,
    self.height,
    0,
    0,
    width,
    height,
    row_bytes,
    pixels,
  )
}

///|
/// Present a tightly packed or padded RGBA rectangle to the surface.
pub fn Surface::present_pixels_rect(
  self : Surface,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  present_rect_to_handle(
    self.window.handle(),
    self.width,
    self.height,
    x,
    y,
    width,
    height,
    row_bytes,
    pixels,
  )
}

///|
pub impl @graphics.Surface for Surface with fn get_width(self) {
  self.get_width()
}

///|
pub impl @graphics.Surface for Surface with fn get_height(self) {
  self.get_height()
}

///|
pub impl @graphics.Surface for Surface with fn present_pixels(
  self,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels(width, height, row_bytes, pixels)
}

///|
pub impl @graphics.Surface for Surface with fn present_pixels_rect(
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
/// Create a surface around a native window handle and an explicit pixel size.
pub fn NativeSurface::new(
  handle : UInt64,
  width : Int,
  height : Int,
) -> NativeSurface {
  { handle, width, height }
}

///|
pub fn NativeSurface::from_frame(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> NativeSurface {
  NativeSurface::new(handle, frame.get_width(), frame.get_height())
}

///|
pub fn NativeSurface::get_width(self : NativeSurface) -> Int {
  self.width
}

///|
pub fn NativeSurface::get_height(self : NativeSurface) -> Int {
  self.height
}

///|
pub fn NativeSurface::handle(self : NativeSurface) -> UInt64 {
  self.handle
}

///|
pub fn NativeSurface::resize(
  self : NativeSurface,
  width : Int,
  height : Int,
) -> Unit {
  self.width = width
  self.height = height
}

///|
pub fn NativeSurface::present(
  self : NativeSurface,
  pixels : FixedArray[Byte],
) -> Unit {
  display_pixels(self.handle, pixels, self.width, self.height)
}

///|
pub fn NativeSurface::present_pixels(
  self : NativeSurface,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  guard width > 0 && height > 0 else {
    return Err(@graphics.PresentError::InvalidDimensions(width, height))
  }
  guard width == self.width && height == self.height else {
    return Err(
      @graphics.PresentError::SizeMismatch(
        self.width,
        self.height,
        width,
        height,
      ),
    )
  }
  present_rect_to_handle(
    self.handle,
    self.width,
    self.height,
    0,
    0,
    width,
    height,
    row_bytes,
    pixels,
  )
}

///|
pub fn NativeSurface::present_pixels_rect(
  self : NativeSurface,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  present_rect_to_handle(
    self.handle,
    self.width,
    self.height,
    x,
    y,
    width,
    height,
    row_bytes,
    pixels,
  )
}

///|
pub fn NativeSurface::present_frame_dirty(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  frame.present_dirty_to(self)
}

///|
pub fn NativeSurface::present_frame_all(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  frame.present_all_to(self)
}

///|
pub fn present_render_frame_dirty(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  NativeSurface::from_frame(handle, frame).present_frame_dirty(frame)
}

///|
pub fn present_render_frame_all(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  NativeSurface::from_frame(handle, frame).present_frame_all(frame)
}

///|
pub impl @graphics.Surface for NativeSurface with fn get_width(self) {
  self.get_width()
}

///|
pub impl @graphics.Surface for NativeSurface with fn get_height(self) {
  self.get_height()
}

///|
pub impl @graphics.Surface for NativeSurface with fn present_pixels(
  self,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels(width, height, row_bytes, pixels)
}

///|
pub impl @graphics.Surface for NativeSurface with fn present_pixels_rect(
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
fn present_rect_to_handle(
  handle : UInt64,
  surface_width : Int,
  surface_height : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  match
    @graphics.validate_present_rect(
      surface_width, surface_height, x, y, width, height, row_bytes, pixels,
    ) {
    Err(error) => Err(error)
    Ok(info) => {
      if row_bytes == info.required_row_bytes() {
        display_pixels_rect(handle, pixels, x, y, width, height)
      } else {
        display_pixels_rect(
          handle,
          copy_tightly_packed_rows(
            height,
            row_bytes,
            info.required_row_bytes(),
            pixels,
          ),
          x,
          y,
          width,
          height,
        )
      }
      Ok(())
    }
  }
}

///|
fn copy_tightly_packed_rows(
  height : Int,
  row_bytes : Int,
  packed_row_bytes : Int,
  pixels : FixedArray[Byte],
) -> FixedArray[Byte] {
  let packed : FixedArray[Byte] = FixedArray::make(
    packed_row_bytes * height,
    0b0,
  )
  for y in 0..<height {
    let src_row = y * row_bytes
    let dst_row = y * packed_row_bytes
    for x in 0..<packed_row_bytes {
      packed[dst_row + x] = pixels[src_row + x]
    }
  }
  packed
}
