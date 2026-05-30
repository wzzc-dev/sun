///|
let bench_width = 96

///|
let bench_height = 64

///|
let fill_iterations = 24

///|
let path_iterations = 8

///|
let stroke_iterations = 12

///|
let glyph_iterations = 10

///|
let blit_iterations = 10

///|
struct BenchSummary {
  fill_ops : Int
  path_ops : Int
  stroke_ops : Int
  glyph_ops : Int
  blit_ops : Int
  present_ops : Int
  checksum : Int
} derive(Debug)

///|
fn byte(value : Int) -> Byte {
  value.max(0).min(255).to_byte()
}

///|
fn run_fill_workload(canvas : @graphics.Canvas) -> Int {
  for i in 0..<fill_iterations {
    let x = 2.0 + (i * 7 % 72).to_double()
    let y = 2.0 + (i * 5 % 46).to_double()
    let w = 10.0 + (i % 5).to_double()
    let h = 5.0 + (i % 4).to_double()
    canvas.fill_rect(
      x,
      y,
      w,
      h,
      @graphics.Paint::new().set_color(
        @graphics.Color::new(
          r=byte(40 + i * 7),
          g=byte(90 + i * 3),
          b=byte(150 + i * 2),
        ),
      ),
    )
  }
  fill_iterations
}

///|
fn run_path_workload(canvas : @graphics.Canvas) -> Int {
  for i in 0..<path_iterations {
    let offset = i.to_double() * 3.0
    let path = @graphics.Path::new()
    ignore(path.move_to(8.0 + offset, 8.0))
    ignore(path.line_to(26.0 + offset, 12.0 + i.to_double()))
    ignore(path.quad_to(34.0 + offset, 22.0, 22.0 + offset, 32.0))
    ignore(
      path.cubic_to(12.0 + offset, 34.0, 4.0 + offset, 20.0, 8.0 + offset, 8.0),
    )
    ignore(path.close())
    canvas.fill_path(
      path,
      @graphics.Paint::new().set_color(
        @graphics.Color::new(r=190, g=byte(40 + i * 12), b=78),
      ),
    )
  }
  path_iterations
}

///|
fn run_stroke_workload(canvas : @graphics.Canvas) -> Int {
  let paint = @graphics.Paint::new()
    .set_color(@graphics.Color::new(r=24, g=38, b=62))
    .set_style(@graphics.PaintStyle::Stroke)
    .set_stroke_width(2.0)
    .set_stroke_cap(@graphics.StrokeCap::Round)
  for i in 0..<stroke_iterations {
    let y = 8.0 + (i * 4).to_double()
    canvas.stroke_line(4.0, y, 88.0, 54.0 - y / 2.0, paint)
  }
  stroke_iterations
}

///|
fn make_bench_glyph() -> @text.SimpleGlyph {
  @text.SimpleGlyph::new(
    [
      @text.GlyphContour::new([
        @text.GlyphPoint::new(x=0, y=0),
        @text.GlyphPoint::new(x=0, y=700),
        @text.GlyphPoint::new(x=120, y=700),
        @text.GlyphPoint::new(x=120, y=0),
      ]),
      @text.GlyphContour::new([
        @text.GlyphPoint::new(x=120, y=580),
        @text.GlyphPoint::new(x=440, y=580),
        @text.GlyphPoint::new(x=440, y=700),
        @text.GlyphPoint::new(x=120, y=700),
      ]),
      @text.GlyphContour::new([
        @text.GlyphPoint::new(x=120, y=300),
        @text.GlyphPoint::new(x=380, y=300),
        @text.GlyphPoint::new(x=380, y=420),
        @text.GlyphPoint::new(x=120, y=420),
      ]),
    ],
    xmin=0,
    ymin=0,
    xmax=440,
    ymax=700,
  )
}

///|
fn run_glyph_workload(canvas : @graphics.Canvas) -> Int {
  let glyph = make_bench_glyph()
  for i in 0..<glyph_iterations {
    let mask = @text.render_glyph_mask(
      glyph,
      18,
      24,
      1.0,
      22.0,
      0.026 + i.to_double() * 0.0008,
    )
    canvas.draw_mask(
      6 + i * 8,
      34,
      mask.get_width(),
      mask.get_height(),
      mask.get_pixels(),
      @graphics.Paint::new().set_color(@graphics.Color::black()),
    )
  }
  glyph_iterations
}

///|
fn make_source_pixmap() -> @graphics.Pixmap {
  let src = @graphics.Pixmap::new(8, 8)
  for y in 0..<8 {
    for x in 0..<8 {
      src.set_pixel(
        x,
        y,
        @graphics.Color::new(
          r=byte(32 + x * 22),
          g=byte(48 + y * 20),
          b=byte(210 - (x + y) * 8),
        ),
      )
    }
  }
  src
}

///|
fn run_blit_workload(canvas : @graphics.Canvas) -> Int {
  let src = make_source_pixmap()
  for i in 0..<blit_iterations {
    canvas.draw_quality_pixmap(
      src,
      50 + i * 2,
      4 + i,
      18,
      14,
      @graphics.Paint::new().set_opacity(0.82),
      @graphics.ImageQuality::Balanced,
    )
  }
  blit_iterations
}

///|
fn checksum_pixels(pixels : FixedArray[Byte]) -> Int {
  let mut checksum = 0
  for i in 0..<pixels.length() {
    checksum = (checksum + pixels[i].to_int() * (i % 251 + 1)) % 1000003
  }
  checksum
}

///|
fn run_bench() -> BenchSummary {
  let canvas = @graphics.Canvas::new(bench_width, bench_height)
  canvas.clear(@graphics.Color::new(r=238, g=241, b=246))
  let fill_ops = run_fill_workload(canvas)
  let path_ops = run_path_workload(canvas)
  let stroke_ops = run_stroke_workload(canvas)
  let glyph_ops = run_glyph_workload(canvas)
  let blit_ops = run_blit_workload(canvas)

  let surface = @graphics.MemorySurface::new(bench_width, bench_height)
  match canvas.get_pixmap().present_to(surface) {
    Ok(_) => ()
    Err(_) => abort("render benchmark present failed")
  }
  guard surface.get_present_count() == 1 else {
    abort("render benchmark should use one full present")
  }
  guard surface.get_present_pixel_count() == bench_width * bench_height else {
    abort("render benchmark present pixel count mismatch")
  }
  guard surface.get_present_byte_count() == bench_width * bench_height * 4 else {
    abort("render benchmark present byte count mismatch")
  }
  guard surface.get_pixel(4, 4) != @graphics.Color::transparent() else {
    abort("render benchmark did not draw the background")
  }
  guard surface.get_pixel(60, 12) != @graphics.Color::transparent() else {
    abort("render benchmark did not draw pixmap workload")
  }
  guard surface.get_pixel(10, 40) != @graphics.Color::transparent() else {
    abort("render benchmark did not draw glyph workload")
  }

  {
    fill_ops,
    path_ops,
    stroke_ops,
    glyph_ops,
    blit_ops,
    present_ops: surface.get_present_count(),
    checksum: checksum_pixels(surface.get_pixels()),
  }
}

///|
fn main {
  let summary = run_bench()
  guard summary.fill_ops == fill_iterations else {
    abort("fill benchmark did not run")
  }
  guard summary.path_ops == path_iterations else {
    abort("path benchmark did not run")
  }
  guard summary.stroke_ops == stroke_iterations else {
    abort("stroke benchmark did not run")
  }
  guard summary.glyph_ops == glyph_iterations else {
    abort("glyph benchmark did not run")
  }
  guard summary.blit_ops == blit_iterations else {
    abort("blit benchmark did not run")
  }
  guard summary.present_ops == 1 else { abort("present benchmark did not run") }
  guard summary.checksum > 0 else {
    abort("render benchmark checksum is empty")
  }
  println(
    "render bench ok fill=\{summary.fill_ops} path=\{summary.path_ops} stroke=\{summary.stroke_ops} glyph=\{summary.glyph_ops} blit=\{summary.blit_ops} present=\{summary.present_ops} checksum=\{summary.checksum}",
  )
}
