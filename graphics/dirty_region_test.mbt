///|
test "PixelRect geometry helpers" {
  let rect = PixelRect::new(x=1, y=2, width=3, height=4)
  assert_eq(rect.right(), 4)
  assert_eq(rect.bottom(), 6)
  assert_true(rect.contains(1, 2))
  assert_true(rect.contains(3, 5))
  assert_true(!rect.contains(4, 5))
  assert_true(!PixelRect::new(x=0, y=0, width=0, height=1).contains(0, 0))
}

///|
test "PixelRect intersection and union" {
  let a = PixelRect::new(x=1, y=1, width=3, height=3)
  let b = PixelRect::new(x=3, y=0, width=3, height=3)
  assert_true(a.intersects(b))
  assert_true(
    a.intersection(b) == Some(PixelRect::new(x=3, y=1, width=1, height=2)),
  )
  assert_true(a.union(b) == PixelRect::new(x=1, y=0, width=5, height=4))
  assert_true(
    a.intersection(PixelRect::new(x=8, y=8, width=1, height=1)) == None,
  )
}

///|
test "DirtyRegion accumulates clipped rectangles and bounds" {
  let region = DirtyRegion::new()
  assert_true(region.is_empty())
  region.add_rect(PixelRect::new(x=0, y=0, width=0, height=2))
  assert_eq(region.get_rect_count(), 0)
  region.add_clipped_rect(
    PixelRect::new(x=-1, y=1, width=4, height=4),
    PixelRect::new(x=0, y=0, width=3, height=3),
  )
  region.add_rect(PixelRect::new(x=4, y=0, width=2, height=1))
  assert_eq(region.get_rect_count(), 2)
  assert_true(
    region.bounds() == Some(PixelRect::new(x=0, y=0, width=6, height=3)),
  )
  region.clear()
  assert_true(region.is_empty())
  assert_true(region.bounds() == None)
}

///|
test "DirtyRegion merges overlapping and edge-adjacent rectangles" {
  let region = DirtyRegion::new()
  region.add_rect(PixelRect::new(x=0, y=0, width=2, height=2))
  region.add_rect(PixelRect::new(x=2, y=0, width=2, height=2))
  assert_eq(region.get_rect_count(), 1)
  assert_true(
    region.bounds() == Some(PixelRect::new(x=0, y=0, width=4, height=2)),
  )
  region.add_rect(PixelRect::new(x=1, y=1, width=2, height=3))
  assert_eq(region.get_rect_count(), 1)
  assert_true(
    region.bounds() == Some(PixelRect::new(x=0, y=0, width=4, height=4)),
  )
}

///|
test "DirtyRegion keeps diagonally touching rectangles separate" {
  let region = DirtyRegion::new()
  region.add_rect(PixelRect::new(x=0, y=0, width=1, height=1))
  region.add_rect(PixelRect::new(x=1, y=1, width=1, height=1))
  assert_eq(region.get_rect_count(), 2)
}

///|
test "DirtyRegion::present_rects clips and falls back to bounds over limit" {
  let region = DirtyRegion::new()
  region.add_rect(PixelRect::new(x=0, y=0, width=1, height=1))
  region.add_rect(PixelRect::new(x=3, y=0, width=1, height=1))
  region.add_rect(PixelRect::new(x=6, y=0, width=1, height=1))
  let bounds = PixelRect::new(x=0, y=0, width=7, height=2)
  let rects = region.present_rects(bounds, 4)
  assert_eq(rects.length(), 3)
  let fallback = region.present_rects(bounds, 2)
  assert_eq(fallback.length(), 1)
  assert_true(fallback[0] == PixelRect::new(x=0, y=0, width=7, height=1))
}

///|
test "DirtyRegion::present_plan exposes dirty present strategy" {
  let region = DirtyRegion::new()
  region.add_rect(PixelRect::new(x=0, y=0, width=1, height=1))
  region.add_rect(PixelRect::new(x=3, y=0, width=1, height=1))
  region.add_rect(PixelRect::new(x=6, y=0, width=1, height=1))

  let empty = region.present_plan(
    PixelRect::new(x=10, y=0, width=1, height=1),
    4,
  )
  assert_true(empty.is_empty())
  assert_true(empty.get_mode() == DirtyPresentPlanMode::Empty)
  assert_eq(empty.get_rect_count(), 0)

  let rect_plan = region.present_plan(
    PixelRect::new(x=0, y=0, width=7, height=2),
    4,
  )
  assert_true(!rect_plan.is_empty())
  assert_true(rect_plan.get_mode() == DirtyPresentPlanMode::Rects)
  assert_true(!rect_plan.uses_bounds_fallback())
  assert_eq(rect_plan.get_rect_count(), 3)
  assert_true(
    rect_plan.get_rects()[1] == PixelRect::new(x=3, y=0, width=1, height=1),
  )

  let bounds_plan = region.present_plan(
    PixelRect::new(x=0, y=0, width=7, height=2),
    2,
  )
  assert_true(bounds_plan.get_mode() == DirtyPresentPlanMode::Bounds)
  assert_true(bounds_plan.uses_bounds_fallback())
  assert_eq(bounds_plan.get_rect_count(), 1)
  assert_true(
    bounds_plan.get_rects()[0] == PixelRect::new(x=0, y=0, width=7, height=1),
  )
}
