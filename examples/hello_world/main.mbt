///|
struct App {
  mut window : @windows.Window?
  mut frame : @graphics.RenderFrame?
  mut width : Int
  mut height : Int
}

///|
fn get_char_pixel(ch : Char, row : Int, col : Int) -> Bool {
  let patterns : Array[Array[Int]] = match ch {
    'H' =>
      [
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
      ]
    'e' =>
      [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 0, 0],
        [1, 0, 0, 0, 0, 0, 1, 0],
        [1, 1, 1, 1, 1, 1, 0, 0],
        [1, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    'l' =>
      [
        [0, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    'o' =>
      [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 0, 0],
        [1, 0, 0, 0, 0, 0, 1, 0],
        [1, 0, 0, 0, 0, 0, 1, 0],
        [1, 0, 0, 0, 0, 0, 1, 0],
        [0, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    ' ' =>
      [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    'W' =>
      [
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 1, 0, 0, 0, 1],
        [1, 0, 1, 0, 1, 0, 0, 1],
        [1, 1, 0, 0, 0, 1, 1, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    'r' =>
      [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [1, 0, 1, 1, 1, 0, 0, 0],
        [1, 1, 0, 0, 0, 1, 0, 0],
        [1, 0, 0, 0, 0, 0, 0, 0],
        [1, 0, 0, 0, 0, 0, 0, 0],
        [1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    'd' =>
      [
        [0, 0, 0, 0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 0, 0],
        [1, 0, 0, 0, 0, 1, 0, 0],
        [1, 0, 0, 0, 0, 1, 0, 0],
        [1, 0, 0, 0, 0, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    '!' =>
      [
        [0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
      ]
    _ =>
      [
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
      ]
  }

  if row >= 0 && row < 8 && col >= 0 && col < 8 {
    patterns[row][col] == 1
  } else {
    false
  }
}

///|
fn draw_bitmap_text(
  canvas : @graphics.Canvas,
  text : String,
  scale : Int,
  color : @graphics.Color,
) -> Unit {
  let paint = @graphics.Paint::new().set_color(color)
  let char_width = 8 * scale
  let scale_size = scale.to_double()

  for i in 0..<text.length() {
    let ch = match text.get_char(i) {
      Some(c) => c
      None => ' '
    }
    for row in 0..<8 {
      for col in 0..<8 {
        let is_set = get_char_pixel(ch, row, col)
        if is_set {
          canvas.fill_rect(
            (i * char_width + col * scale).to_double(),
            (row * scale).to_double(),
            scale_size,
            scale_size,
            paint,
          )
        }
      }
    }
  }
}

///|
fn hello_world_text() -> String {
  "Hello World!"
}

///|
fn hello_world_text_scale() -> Int {
  4
}

///|
fn hello_world_text_size() -> (Int, Int) {
  let scale = hello_world_text_scale()
  let char_width = 8 * scale
  (hello_world_text().length() * char_width, 8 * scale)
}

///|
fn hello_world_text_position(width : Int, height : Int) -> (Int, Int) {
  let (text_width, text_height) = hello_world_text_size()
  ((width - text_width) / 2, (height - text_height) / 2)
}

///|
fn build_background_layer(width : Int, height : Int) -> @graphics.Layer {
  let background = @graphics.Layer::new(width, height)
  background.clear(@graphics.Color::white())
  background
}

///|
fn build_text_layer(width : Int, height : Int) -> @graphics.Layer {
  let text = hello_world_text()
  let scale = hello_world_text_scale()
  let (text_width, text_height) = hello_world_text_size()
  let (start_x, start_y) = hello_world_text_position(width, height)
  let text_layer = @graphics.Layer::new(text_width.max(1), text_height.max(1)).set_position(
    start_x, start_y,
  )

  draw_bitmap_text(
    text_layer.get_canvas(),
    text,
    scale,
    @graphics.Color::new(r=50, g=50, b=200),
  )
  text_layer
}

///|
fn build_hello_world_frame(width : Int, height : Int) -> @graphics.RenderFrame {
  let frame = @graphics.RenderFrame::new(width, height)

  let tree = frame.get_layer_tree()
  ignore(tree.add_layer(build_background_layer(width, height)))
  ignore(tree.add_layer(build_text_layer(width, height)))

  frame
}

///|
fn update_hello_world_frame(
  frame : @graphics.RenderFrame,
  width : Int,
  height : Int,
) -> Bool {
  guard width > 0 && height > 0 else { return false }

  frame.resize_clear_and_replace_layers(
    width,
    height,
    [@graphics.RenderFrameLayerClearRequest::new(0, @graphics.Color::white())],
    [
      @graphics.RenderFrameLayerReplacementRequest::new(
        1,
        build_text_layer(width, height),
      ),
    ],
  )
}

///|
fn present_frame(
  window : @windows.Window,
  frame : @graphics.RenderFrame,
) -> Unit {
  let surface = frame_native_surface(window, frame)
  let schedule = surface.frame_schedule(frame)
  match surface.submit_frame_schedule(frame, schedule) {
    Ok(result) => handle_frame_submit_result(result)
    Err(_) => println("Present failed")
  }
}

///|
fn frame_native_surface(
  window : @windows.Window,
  frame : @graphics.RenderFrame,
) -> @softbuffer.NativeSurface {
  @softbuffer.NativeSurface::from_frame(window.window_handle(), frame).with_pre_present_hook(fn() {
      window.pre_present_notify()
    },
  )
}

///|
fn handle_frame_submit_result(
  result : @softbuffer.NativeFrameSubmitResult,
) -> Unit {
  if result.did_present() {
    ignore(result.get_presented_rect_count())
  }
}

///|
fn render_and_display(
  window : @windows.Window,
  width : Int,
  height : Int,
) -> @graphics.RenderFrame? {
  guard width > 0 && height > 0 else { return None }
  let frame = build_hello_world_frame(width, height)
  present_frame(window, frame)
  Some(frame)
}

///|
fn resize_and_display(
  window : @windows.Window,
  frame : @graphics.RenderFrame?,
  width : Int,
  height : Int,
) -> @graphics.RenderFrame? {
  guard width > 0 && height > 0 else { return None }
  match frame {
    Some(existing) =>
      if update_hello_world_frame(existing, width, height) {
        present_frame(window, existing)
        Some(existing)
      } else {
        render_and_display(window, width, height)
      }
    None => render_and_display(window, width, height)
  }
}

///|
fn present_cached_frame(
  window : @windows.Window,
  frame : @graphics.RenderFrame,
) -> Unit {
  let surface = frame_native_surface(window, frame)
  match
    surface.submit_frame_by_policy(
      frame,
      @softbuffer.NativeFrameSubmitPolicy::CachedRedraw,
    ) {
    Ok(result) => handle_frame_submit_result(result)
    Err(_) => println("Present failed")
  }
}

///|
pub impl @windows.ApplicationHandler for App with fn can_create_surfaces(
  self,
  event_loop,
) {
  println("Creating window...")
  let attrs = @core.WindowAttributes::default().with_title(
    "Hello World - MoonBit",
  )
  let window : @windows.Window? = Some(event_loop.try_create_window(attrs)) catch {
    err => {
      println("Error creating window: \{err}")
      event_loop.exit()
      None
    }
  }

  match window {
    Some(w) => {
      let size = w.inner_size()
      self.width = size.width
      self.height = size.height
      println("Window size: \{self.width}x\{self.height}")

      println("Rendering Hello World...")
      self.frame = render_and_display(w, self.width, self.height)
      println("Hello World displayed!")
    }
    None => println("Failed to create window")
  }

  self.window = window
}

///|
pub impl @windows.ApplicationHandler for App with fn window_event(
  self,
  event_loop,
  _id,
  event,
) {
  match event {
    @core.WindowEvent::CloseRequested => {
      println("Window closed")
      event_loop.exit()
    }
    @core.WindowEvent::SurfaceResized(size) => {
      self.width = size.width
      self.height = size.height

      match self.window {
        Some(w) =>
          self.frame = resize_and_display(
            w,
            self.frame,
            self.width,
            self.height,
          )
        None => ()
      }
    }
    @core.WindowEvent::RedrawRequested =>
      match self.window {
        Some(w) =>
          match self.frame {
            Some(frame) => present_cached_frame(w, frame)
            None => self.frame = render_and_display(w, self.width, self.height)
          }
        None => ()
      }
    _ => ()
  }
}

///|
fn main {
  println("=== Hello World Demo ===")
  println("")

  let event_loop = @windows.EventLoop::new()
  event_loop.run_app({ window: None, frame: None, width: 0, height: 0 })
}
