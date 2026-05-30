///|
struct App {
  mut window : @windows.Window?
  mut pixels : FixedArray[Byte]
  mut width : Int
  mut height : Int
  mut rendered : Bool
}

///|
fn render_hello_world(width : Int, height : Int) -> FixedArray[Byte] {
  let canvas = @graphics.Canvas::new(width, height)
  canvas.clear(@graphics.Color::white())

  // Load font
  let font_path = "C:/Windows/Fonts/arial.ttf"
  let font_data = try! @text.read_file(font_path)
  let face = match @text.FontFace::from_bytes(font_data) {
    Ok(face) => face
    Err(_) => abort("Failed to parse font")
  }

  let text = "Hello World 123!"
  let font_size = 48.0
  let config = @text.LayoutConfig::new(
    max_width=width.to_double() - 40.0,
    font_size~,
    line_height=font_size * 1.4,
  )
  let paint = @graphics.Paint::new().set_color(@graphics.Color::black())
  let renderer = @renderer.Renderer::new(canvas)
  renderer.draw_text_face(face, text, 20.0, 20.0, config, paint)
  canvas.get_pixmap().get_pixels()
}

///|
fn present_to_window(
  window : @windows.Window,
  pixels : FixedArray[Byte],
  width : Int,
  height : Int,
) -> Unit {
  let surface = @softbuffer.NativeSurface::new(
    window.window_handle(),
    width,
    height,
  ).with_pre_present_hook(fn() { window.pre_present_notify() })
  match @graphics.present_pixels(surface, width, height, width * 4, pixels) {
    Ok(_) => ()
    Err(_) => println("Present failed")
  }
}

///|
pub impl @windows.ApplicationHandler for App with fn can_create_surfaces(
  self,
  event_loop,
) {
  let attrs = @core.WindowAttributes::default().with_title("Hello World")
  let window : @windows.Window? = Some(event_loop.try_create_window(attrs)) catch {
    _ => {
      event_loop.exit()
      None
    }
  }

  match window {
    Some(w) => {
      let size = w.inner_size()
      self.width = size.width
      self.height = size.height
      self.pixels = render_hello_world(self.width, self.height)
      self.rendered = true
      present_to_window(w, self.pixels, self.width, self.height)
    }
    None => ()
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
    @core.WindowEvent::CloseRequested => event_loop.exit()
    @core.WindowEvent::RedrawRequested =>
      if self.rendered {
        match self.window {
          Some(w) => present_to_window(w, self.pixels, self.width, self.height)
          None => ()
        }
      }
    _ => ()
  }
}

///|
fn main {
  let event_loop = @windows.EventLoop::new()
  event_loop.run_app({
    window: None,
    pixels: FixedArray::make(0, 0b0),
    width: 0,
    height: 0,
    rendered: false,
  })
}
