///|
/// Low-level FFI bindings for native renderer
#borrow(title)
extern "c" fn renderer_create_window(
  width : Int,
  height : Int,
  title : Bytes,
) -> UInt64 = "renderer_create_window"

///|
extern "c" fn renderer_destroy_window(window : UInt64) -> Unit = "renderer_destroy_window"

///|
#borrow(pixels)
extern "c" fn renderer_present(
  window : UInt64,
  pixels : FixedArray[Byte],
  width : Int,
  height : Int,
) -> Unit = "renderer_present"

///|
extern "c" fn renderer_process_events() -> Int = "renderer_process_events"

///|
extern "c" fn renderer_is_window_valid(window : UInt64) -> Int = "renderer_is_window_valid"

///|
extern "c" fn renderer_get_window_width(window : UInt64) -> Int = "renderer_get_window_width"

///|
extern "c" fn renderer_get_window_height(window : UInt64) -> Int = "renderer_get_window_height"

///|
#borrow(title)
extern "c" fn renderer_set_window_title(window : UInt64, title : Bytes) -> Unit = "renderer_set_window_title"

///|
extern "c" fn renderer_request_redraw(window : UInt64) -> Unit = "renderer_request_redraw"

///|
/// Display pixels to a window using its native handle (HWND on Windows)
/// This is useful when using external window libraries
pub fn display_pixels(
  hwnd : UInt64,
  pixels : FixedArray[Byte],
  width : Int,
  height : Int,
) -> Unit {
  renderer_present(hwnd, pixels, width, height)
}
