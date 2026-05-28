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
