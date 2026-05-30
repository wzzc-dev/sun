///|
/// Window creation attributes
pub struct WindowAttributes {
  mut width : Int
  mut height : Int
  mut title : String
}

///|
/// Create default window attributes
pub fn WindowAttributes::new() -> WindowAttributes {
  { width: 800, height: 600, title: "MoonBit Window" }
}

///|
/// Set window width
pub fn WindowAttributes::with_width(
  self : WindowAttributes,
  width : Int,
) -> WindowAttributes {
  self.width = width
  self
}

///|
/// Set window height
pub fn WindowAttributes::with_height(
  self : WindowAttributes,
  height : Int,
) -> WindowAttributes {
  self.height = height
  self
}

///|
/// Set window title
pub fn WindowAttributes::with_title(
  self : WindowAttributes,
  title : String,
) -> WindowAttributes {
  self.title = title
  self
}

///|
/// A native window
pub struct Window {
  handle : UInt64
}

///|
/// Create a new window
pub fn Window::new(attrs : WindowAttributes) -> Window {
  let handle = renderer_create_window(
    attrs.width,
    attrs.height,
    @utf8.encode(attrs.title),
  )
  { handle, }
}

///|
/// Check if window is valid
pub fn Window::is_valid(self : Window) -> Bool {
  renderer_is_window_valid(self.handle) == 1
}

///|
/// Get the native window handle used by the softbuffer backend.
pub fn Window::handle(self : Window) -> UInt64 {
  self.handle
}

///|
/// Get window width
pub fn Window::width(self : Window) -> Int {
  renderer_get_window_width(self.handle)
}

///|
/// Get window height
pub fn Window::height(self : Window) -> Int {
  renderer_get_window_height(self.handle)
}

///|
/// Set window title
pub fn Window::set_title(self : Window, title : String) -> Unit {
  renderer_set_window_title(self.handle, @utf8.encode(title))
}

///|
/// Request window redraw
pub fn Window::request_redraw(self : Window) -> Unit {
  renderer_request_redraw(self.handle)
}

///|
/// Present pixels to window
pub fn Window::present(
  self : Window,
  pixels : FixedArray[Byte],
  width : Int,
  height : Int,
) -> Unit {
  renderer_present(self.handle, pixels, width, height)
}

///|
/// Present a tightly packed RGBA rectangle to the window at a destination offset.
pub fn Window::present_rect(
  self : Window,
  pixels : FixedArray[Byte],
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit {
  renderer_present_rect(self.handle, pixels, x, y, width, height)
}

///|
/// Destroy the window
pub fn Window::destroy(self : Window) -> Unit {
  renderer_destroy_window(self.handle)
}
