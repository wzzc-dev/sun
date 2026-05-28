///|
test "Transform::identity" {
  let t = Transform::identity()
  let (x, y) = t.apply(10.0, 20.0)
  assert_eq(x, 10.0)
  assert_eq(y, 20.0)
}

///|
test "Transform::translate" {
  let t = Transform::translate(tx=5.0, ty=10.0)
  let (x, y) = t.apply(10.0, 20.0)
  assert_eq(x, 15.0)
  assert_eq(y, 30.0)
}

///|
test "Transform::scale" {
  let t = Transform::scale(sx=2.0, sy=3.0)
  let (x, y) = t.apply(10.0, 20.0)
  assert_eq(x, 20.0)
  assert_eq(y, 60.0)
}
