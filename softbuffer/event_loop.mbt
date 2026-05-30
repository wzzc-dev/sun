///|
/// Process all pending window events (non-blocking)
/// Returns false if quit was requested
pub fn process_events() -> Bool {
  renderer_process_events() == 1
}

///|
/// Run a simple event loop with a render callback
pub fn run_event_loop(window : Window, render_fn : (Window) -> Unit) -> Unit {
  while window.is_valid() {
    if !process_events() {
      break
    }
    render_fn(window)
  }
  window.destroy()
}
