///|
test "Color::new creates color with correct values" {
  let color = Color::new(r=100, g=150, b=200, a=255)
  assert_eq(color.r, 100)
  assert_eq(color.g, 150)
  assert_eq(color.b, 200)
  assert_eq(color.a, 255)
}

///|
test "Color::white creates white color" {
  let color = Color::white()
  assert_eq(color, Color::new(r=255, g=255, b=255))
}

///|
test "Color::black creates black color" {
  let color = Color::black()
  assert_eq(color, Color::new(r=0, g=0, b=0))
}

///|
test "Color::transparent creates transparent color" {
  let color = Color::transparent()
  assert_eq(color, Color::new(r=0, g=0, b=0, a=0))
}

///|
test "Color::with_alpha replaces alpha" {
  let color = Color::red().with_alpha(128)
  assert_eq(color, Color::new(r=255, g=0, b=0, a=128))
}

///|
test "Color::scale_alpha clamps opacity" {
  assert_eq(Color::red().scale_alpha(0.5).a, 128)
  assert_eq(Color::red().scale_alpha(-1.0).a, 0)
  assert_eq(Color::red().scale_alpha(2.0).a, 255)
}

///|
test "Color::blend_over composites straight alpha" {
  let src = Color::new(r=255, g=0, b=0, a=128)
  let dst = Color::blue()
  assert_eq(src.blend_over(dst), Color::new(r=128, g=0, b=127, a=255))
}

///|
test "Color::blend_over preserves transparent source and opaque source" {
  let dst = Color::new(r=10, g=20, b=30, a=200)
  assert_eq(Color::transparent().blend_over(dst), dst)
  assert_eq(Color::green().blend_over(dst), Color::green())
}
