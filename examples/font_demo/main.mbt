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
  // Create RGBA pixel buffer (white background)
  let rgba : FixedArray[Byte] = FixedArray::make(width * height * 4, 255)

  // Load font
  let font_path = "C:/Windows/Fonts/arial.ttf"
  let font_data = try! @text.read_file(font_path)
  let font = @text.parse_font(font_data)

  // Create text rasterizer
  let rasterizer = @text.Rasterizer::new(width, height)
  rasterizer.clear()

  // Layout text
  let text = "Hello World 123!"
  let font_size = 48.0
  let config = @text.LayoutConfig::new(
    max_width=width.to_double() - 40.0,
    font_size~,
    line_height=font_size * 1.4,
  )
  let result = @text.layout_text(font, text, config)

  // Rasterize each glyph
  let units_per_em = font.get_units_per_em().to_double()
  let scale = font_size / units_per_em

  for line in result.lines {
    for glyph in line.glyphs {
      let glyph_data = font.get_glyph(glyph.glyph_id)
      match glyph_data {
        @text.GlyphData::Simple(simple_glyph) =>
          rasterizer.rasterize_glyph(
            simple_glyph,
            20.0 + glyph.x,
            20.0 + line.y,
            scale,
          )
        _ => ignore(0)
      }
    }
  }

  // Convert grayscale to RGBA
  let gray = rasterizer.get_pixels()
  for y in 0..<height {
    for x in 0..<width {
      let gray_idx = y * width + x
      let rgba_idx = gray_idx * 4
      let g = gray[gray_idx]
      rgba[rgba_idx] = 255 - g
      rgba[rgba_idx + 1] = 255 - g
      rgba[rgba_idx + 2] = 255 - g
      rgba[rgba_idx + 3] = 255
    }
  }

  rgba
}

///|
pub impl @windows.ApplicationHandler for App with can_create_surfaces(
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
      let hwnd = w.native_handle()
      @softbuffer.display_pixels(hwnd, self.pixels, self.width, self.height)
    }
    None => ()
  }

  self.window = window
}

///|
pub impl @windows.ApplicationHandler for App with window_event(
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
          Some(w) => {
            let hwnd = w.native_handle()
            @softbuffer.display_pixels(
              hwnd,
              self.pixels,
              self.width,
              self.height,
            )
            w.pre_present_notify()
          }
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
