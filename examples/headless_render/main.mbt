///|
let frame_width = 64

///|
let frame_height = 48

///|
fn render_frame() -> @graphics.RenderFrame {
  let frame = @graphics.RenderFrame::new(frame_width, frame_height)
  let canvas = frame.get_canvas()

  canvas.clear(@graphics.Color::new(r=245, g=247, b=250))
  canvas.fill_rounded_rect(
    4.0,
    4.0,
    56.0,
    40.0,
    6.0,
    @graphics.Paint::new().set_color(@graphics.Color::white()),
  )
  canvas.stroke_rounded_rect(
    4.5,
    4.5,
    55.0,
    39.0,
    6.0,
    @graphics.Paint::new()
    .set_color(@graphics.Color::new(r=80, g=96, b=120))
    .set_style(@graphics.PaintStyle::Stroke)
    .set_stroke_width(1.0),
  )
  canvas.fill_rect(
    12.0,
    30.0,
    32.0,
    4.0,
    @graphics.Paint::new().set_color(@graphics.Color::new(r=64, g=132, b=245)),
  )
  canvas.stroke_arc(
    50.0,
    22.0,
    8.0,
    -1.5707963267948966,
    4.71238898038469,
    @graphics.Paint::new()
    .set_color(@graphics.Color::new(r=44, g=160, b=120))
    .set_style(@graphics.PaintStyle::Stroke)
    .set_stroke_width(3.0)
    .set_stroke_cap(@graphics.StrokeCap::Round),
  )

  let badge = @graphics.Layer::new(14, 14).set_position(12, 12)
  badge.clear(@graphics.Color::transparent())
  badge
  .get_canvas()
  .fill_circle(
    7.0,
    7.0,
    6.0,
    @graphics.Paint::new().set_color(@graphics.Color::new(r=234, g=92, b=90)),
  )
  ignore(frame.get_layer_tree().add_layer(badge))
  frame
}

///|
fn present_headless(frame : @graphics.RenderFrame) -> @graphics.MemorySurface {
  let surface = @graphics.MemorySurface::new(
    frame.get_width(),
    frame.get_height(),
  )
  match frame.submit_dirty_to(surface) {
    Ok(result) => {
      guard result.get_state() == @graphics.DirtySubmitState::Present else {
        abort("expected dirty submit to present")
      }
      guard result.needs_present() else {
        abort("expected dirty submit to need present")
      }
      guard result.get_presented_rect_count() > 0 else {
        abort("expected dirty rects to present")
      }
      surface
    }
    Err(_) => abort("headless present failed")
  }
}

///|
fn assert_pixel(
  surface : @graphics.MemorySurface,
  x : Int,
  y : Int,
  expected : @graphics.Color,
) -> Unit {
  let actual = surface.get_pixel(x, y)
  guard actual == expected else { abort("unexpected headless pixel") }
}

///|
fn main {
  let frame = render_frame()
  let surface = present_headless(frame)

  assert_pixel(surface, 0, 0, @graphics.Color::new(r=245, g=247, b=250))
  assert_pixel(surface, 12, 30, @graphics.Color::new(r=64, g=132, b=245))
  assert_pixel(surface, 19, 19, @graphics.Color::new(r=234, g=92, b=90))
  guard surface.get_present_count() > 0 else {
    abort("surface was not presented")
  }
  guard !frame.has_dirty() else { abort("dirty regions should be clear") }

  println("headless render ok")
}
