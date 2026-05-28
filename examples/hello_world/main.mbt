///|
struct App {
  mut window : @windows.Window?
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
fn render_and_display(hwnd : UInt64, width : Int, height : Int) -> Unit {
  let size = width * height * 4
  let pixels : FixedArray[Byte] = FixedArray::make(size, 0b0)

  // Fill white background
  let white : Byte = 255
  for i in 0..<(width * height) {
    let idx = i * 4
    pixels[idx] = white
    pixels[idx + 1] = white
    pixels[idx + 2] = white
    pixels[idx + 3] = white
  }

  // Draw "Hello World!" text
  let text = "Hello World!"
  let color_r : Byte = 50
  let color_g : Byte = 50
  let color_b : Byte = 200
  let scale = 4
  let char_width = 8 * scale
  let start_x = (width - text.length() * char_width) / 2
  let start_y = (height - 8 * scale) / 2

  for i in 0..<text.length() {
    let ch = match text.get_char(i) {
      Some(c) => c
      None => ' '
    }
    for row in 0..<8 {
      for col in 0..<8 {
        let is_set = get_char_pixel(ch, row, col)
        if is_set {
          for sy in 0..<scale {
            for sx in 0..<scale {
              let px = start_x + i * char_width + col * scale + sx
              let py = start_y + row * scale + sy
              if px >= 0 && px < width && py >= 0 && py < height {
                let idx = (py * width + px) * 4
                pixels[idx] = color_r
                pixels[idx + 1] = color_g
                pixels[idx + 2] = color_b
                pixels[idx + 3] = white
              }
            }
          }
        }
      }
    }
  }

  @softbuffer.display_pixels(hwnd, pixels, width, height)
}

///|
pub impl @windows.ApplicationHandler for App with can_create_surfaces(
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
      let hwnd = w.native_handle()
      render_and_display(hwnd, self.width, self.height)
      println("Hello World displayed!")
    }
    None => println("Failed to create window")
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
    @core.WindowEvent::CloseRequested => {
      println("Window closed")
      event_loop.exit()
    }
    @core.WindowEvent::SurfaceResized(size) => {
      self.width = size.width
      self.height = size.height

      match self.window {
        Some(w) => {
          let hwnd = w.native_handle()
          render_and_display(hwnd, self.width, self.height)
        }
        None => ()
      }
    }
    @core.WindowEvent::RedrawRequested =>
      match self.window {
        Some(w) => {
          let hwnd = w.native_handle()
          render_and_display(hwnd, self.width, self.height)
          w.pre_present_notify()
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
  event_loop.run_app({ window: None, width: 0, height: 0 })
}
