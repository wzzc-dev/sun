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
test "Path::add_rounded_rect creates cubic corner path" {
  let path = Path::new()
  ignore(path.add_rounded_rect(0.0, 0.0, 10.0, 6.0, 2.0))
  let segments = path.get_segments()
  inspect(segments.length(), content="10")
  assert_move_to(segments[0], 2.0, 0.0)
  assert_line_to(segments[1], 8.0, 0.0)
  assert_cubic_to_end(segments[2], 10.0, 2.0)
  assert_line_to(segments[3], 10.0, 4.0)
  assert_close(segments[9])
}

///|
test "Path::add_rounded_rect clamps radius and falls back to rect" {
  let pill = Path::new().add_rounded_rect(0.0, 0.0, 10.0, 4.0, 9.0)
  let segments = pill.get_segments()
  assert_move_to(segments[0], 2.0, 0.0)
  assert_line_to(segments[1], 8.0, 0.0)

  let rect = Path::new().add_rounded_rect(0.0, 0.0, 10.0, 4.0, 0.0)
  assert_true(rect.get_segments().length() == 5)
}

///|
test "Path::add_circle creates circle path" {
  let path = Path::new()
  ignore(path.add_circle(50.0, 50.0, 25.0))
  let segments = path.get_segments()
  // move_to + 4 cubic_to + close = 6 segments
  inspect(segments.length(), content="6")
}

///|
test "Path::add_ellipse creates ellipse path" {
  let path = Path::new()
  ignore(path.add_ellipse(10.0, 8.0, 6.0, 3.0))
  let segments = path.get_segments()
  // move_to + 4 cubic_to + close = 6 segments
  inspect(segments.length(), content="6")
  assert_move_to(segments[0], 16.0, 8.0)
  assert_cubic_to_end(segments[1], 10.0, 5.0)
  assert_cubic_to_end(segments[2], 4.0, 8.0)
  assert_cubic_to_end(segments[3], 10.0, 11.0)
  assert_cubic_to_end(segments[4], 16.0, 8.0)
  assert_close(segments[5])
}

///|
fn assert_move_to(
  segment : PathSegment,
  expected_x : Double,
  expected_y : Double,
) -> Unit raise {
  match segment {
    PathSegment::MoveTo(x, y) => {
      assert_eq(x, expected_x)
      assert_eq(y, expected_y)
    }
    _ => abort("expected MoveTo")
  }
}

///|
fn assert_line_to(
  segment : PathSegment,
  expected_x : Double,
  expected_y : Double,
) -> Unit raise {
  match segment {
    PathSegment::LineTo(x, y) => {
      assert_eq(x, expected_x)
      assert_eq(y, expected_y)
    }
    _ => abort("expected LineTo")
  }
}

///|
fn assert_cubic_to_end(
  segment : PathSegment,
  expected_x : Double,
  expected_y : Double,
) -> Unit raise {
  match segment {
    PathSegment::CubicTo(_, _, _, _, x, y) => {
      assert_eq(x, expected_x)
      assert_eq(y, expected_y)
    }
    _ => abort("expected CubicTo")
  }
}

///|
fn assert_close(segment : PathSegment) -> Unit {
  match segment {
    PathSegment::Close => ()
    _ => abort("expected Close")
  }
}
