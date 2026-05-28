///|
test "Path::new creates empty path" {
  let path = Path::new()
  assert_true(path.is_empty())
}

///|
test "Path::add_rect creates rectangle path" {
  let path = Path::new()
  ignore(path.add_rect(0.0, 0.0, 100.0, 50.0))
  let segments = path.get_segments()
  // move_to + 3 line_to + close = 5 segments
  inspect(segments.length(), content="5")
}

///|
test "Path::add_circle creates circle path" {
  let path = Path::new()
  ignore(path.add_circle(50.0, 50.0, 25.0))
  let segments = path.get_segments()
  // move_to + 4 cubic_to + close = 6 segments
  inspect(segments.length(), content="6")
}
