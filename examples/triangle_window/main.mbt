///|
struct App {
  mut window : @windows.Window?
  mut pixels : FixedArray[Byte]
  mut width : Int
  mut height : Int
  mut rendered : Bool
}

///|
fn render_triangle(width : Int, height : Int) -> FixedArray[Byte] {
  let rasterizer = @graphics.ScanlineRasterizer::new(width, height)

  // Clear with white background
  rasterizer.clear(@graphics.Color::white())

  // Define triangle vertices
  let cx = width.to_double() / 2.0
  let cy = height.to_double() / 2.0
  let size = if width < height {
    width.to_double() * 0.4
  } else {
    height.to_double() * 0.4
  }

  let x0 = cx
  let y0 = cy - size
  let x1 = cx - size * 0.866
  let y1 = cy + size * 0.5
  let x2 = cx + size * 0.866
  let y2 = cy + size * 0.5

  // Fill triangle with red color
  rasterizer.fill_triangle(x0, y0, x1, y1, x2, y2, @graphics.Color::red())

  // Draw outline
  let outline_color = @graphics.Color::new(r=180, g=0, b=0)
  rasterizer.draw_line(
    x0.to_int(),
    y0.to_int(),
    x1.to_int(),
    y1.to_int(),
    outline_color,
  )
  rasterizer.draw_line(
    x1.to_int(),
    y1.to_int(),
    x2.to_int(),
    y2.to_int(),
    outline_color,
  )
  rasterizer.draw_line(
    x2.to_int(),
    y2.to_int(),
    x0.to_int(),
    y0.to_int(),
    outline_color,
  )

  rasterizer.get_pixels()
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
  println("Creating window...")
  let attrs = @core.WindowAttributes::default().with_title(
    "MoonBit Triangle - Window Demo",
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

      println("Rendering triangle...")
      self.pixels = render_triangle(self.width, self.height)
      self.rendered = true

      // Display pixels using softbuffer
      println("Displaying pixels...")
      present_to_window(w, self.pixels, self.width, self.height)
      println("Triangle displayed!")
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
      println("Window closed by user")
      event_loop.exit()
    }
    @core.WindowEvent::SurfaceResized(size) => {
      self.width = size.width
      self.height = size.height
      self.pixels = render_triangle(self.width, self.height)

      match self.window {
        Some(w) => present_to_window(w, self.pixels, self.width, self.height)
        None => ()
      }
    }
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
  println("=== MoonBit Triangle Window Demo ===")
  println("")

  let event_loop = @windows.EventLoop::new()
  event_loop.run_app({
    window: None,
    pixels: FixedArray::make(0, 0b0),
    width: 0,
    height: 0,
    rendered: false,
  })
}
