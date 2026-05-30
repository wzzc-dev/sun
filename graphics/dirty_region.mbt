///|
/// Pixel-aligned rectangle used for dirty-region tracking.
pub struct PixelRect {
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Debug)

///|
/// Strategy selected for submitting a dirty region to a Surface.
pub(all) enum DirtyPresentPlanMode {
  Empty
  Rects
  Bounds
} derive(Eq, Debug)

///|
/// Scheduler-facing state for a dirty submit snapshot.
pub(all) enum DirtySubmitState {
  Clean
  Present
  DirtyClippedAway
} derive(Eq, Debug)

///|
/// A concrete dirty-present plan after clipping to the target bounds and
/// applying a rectangle-count limit.
pub struct DirtyPresentPlan {
  mode : DirtyPresentPlanMode
  rects : Array[PixelRect]
} derive(Debug)

///|
/// Dirty state snapshot for schedulers: logical dirty bounds plus the clipped
/// present plan that would be submitted to the current surface.
pub struct DirtySubmitPlan {
  dirty_bounds : PixelRect?
  present_plan : DirtyPresentPlan
} derive(Debug)

///|
pub fn DirtyPresentPlan::get_mode(
  self : DirtyPresentPlan,
) -> DirtyPresentPlanMode {
  self.mode
}

///|
pub fn DirtyPresentPlan::get_rects(self : DirtyPresentPlan) -> Array[PixelRect] {
  self.rects
}

///|
pub fn DirtyPresentPlan::get_rect_count(self : DirtyPresentPlan) -> Int {
  self.rects.length()
}

///|
pub fn DirtyPresentPlan::is_empty(self : DirtyPresentPlan) -> Bool {
  self.mode == DirtyPresentPlanMode::Empty || self.rects.length() == 0
}

///|
pub fn DirtyPresentPlan::uses_bounds_fallback(self : DirtyPresentPlan) -> Bool {
  self.mode == DirtyPresentPlanMode::Bounds
}

///|
pub fn DirtySubmitPlan::get_dirty_bounds(self : DirtySubmitPlan) -> PixelRect? {
  self.dirty_bounds
}

///|
pub fn DirtySubmitPlan::get_present_plan(
  self : DirtySubmitPlan,
) -> DirtyPresentPlan {
  self.present_plan
}

///|
pub fn DirtySubmitPlan::has_dirty(self : DirtySubmitPlan) -> Bool {
  match self.dirty_bounds {
    Some(_) => true
    None => false
  }
}

///|
pub fn DirtySubmitPlan::needs_present(self : DirtySubmitPlan) -> Bool {
  !self.present_plan.is_empty()
}

///|
pub fn DirtySubmitPlan::get_state(self : DirtySubmitPlan) -> DirtySubmitState {
  if self.needs_present() {
    return DirtySubmitState::Present
  }
  if self.has_dirty() {
    return DirtySubmitState::DirtyClippedAway
  }
  DirtySubmitState::Clean
}

///|
pub fn DirtySubmitPlan::get_present_rect_count(self : DirtySubmitPlan) -> Int {
  self.present_plan.get_rect_count()
}

///|
pub fn DirtySubmitPlan::uses_bounds_fallback(self : DirtySubmitPlan) -> Bool {
  self.present_plan.uses_bounds_fallback()
}

///|
pub fn PixelRect::new(
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
) -> PixelRect {
  { x, y, width, height }
}

///|
pub fn PixelRect::right(self : PixelRect) -> Int {
  self.x + self.width
}

///|
pub fn PixelRect::bottom(self : PixelRect) -> Int {
  self.y + self.height
}

///|
pub fn PixelRect::is_empty(self : PixelRect) -> Bool {
  self.width <= 0 || self.height <= 0
}

///|
pub fn PixelRect::contains(self : PixelRect, x : Int, y : Int) -> Bool {
  !self.is_empty() &&
  x >= self.x &&
  x < self.right() &&
  y >= self.y &&
  y < self.bottom()
}

///|
pub fn PixelRect::intersects(self : PixelRect, other : PixelRect) -> Bool {
  match self.intersection(other) {
    Some(_) => true
    None => false
  }
}

///|
pub fn PixelRect::intersection(
  self : PixelRect,
  other : PixelRect,
) -> PixelRect? {
  let left = self.x.max(other.x)
  let top = self.y.max(other.y)
  let right = self.right().min(other.right())
  let bottom = self.bottom().min(other.bottom())
  let width = right - left
  let height = bottom - top
  guard width > 0 && height > 0 else { return None }
  Some(PixelRect::new(x=left, y=top, width~, height~))
}

///|
pub fn PixelRect::union(self : PixelRect, other : PixelRect) -> PixelRect {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let left = self.x.min(other.x)
  let top = self.y.min(other.y)
  let right = self.right().max(other.right())
  let bottom = self.bottom().max(other.bottom())
  PixelRect::new(x=left, y=top, width=right - left, height=bottom - top)
}

///|
pub fn PixelRect::clip_to(self : PixelRect, bounds : PixelRect) -> PixelRect? {
  self.intersection(bounds)
}

///|
fn pixel_rects_can_merge(a : PixelRect, b : PixelRect) -> Bool {
  guard !a.is_empty() && !b.is_empty() else { return false }
  if a.intersects(b) {
    return true
  }
  let horizontal_touch = a.right() == b.x || b.right() == a.x
  let vertical_touch = a.bottom() == b.y || b.bottom() == a.y
  (horizontal_touch && ranges_overlap(a.y, a.bottom(), b.y, b.bottom())) ||
  (vertical_touch && ranges_overlap(a.x, a.right(), b.x, b.right()))
}

///|
fn ranges_overlap(
  a_start : Int,
  a_end : Int,
  b_start : Int,
  b_end : Int,
) -> Bool {
  a_start.max(b_start) < a_end.min(b_end)
}

///|
/// Accumulates pixel-aligned dirty rectangles for incremental rendering.
pub struct DirtyRegion {
  mut rects : Array[PixelRect]
} derive(Debug)

///|
pub fn DirtyRegion::new() -> DirtyRegion {
  { rects: [] }
}

///|
pub fn DirtyRegion::is_empty(self : DirtyRegion) -> Bool {
  self.rects.length() == 0
}

///|
pub fn DirtyRegion::clear(self : DirtyRegion) -> Unit {
  self.rects = []
}

///|
pub fn DirtyRegion::get_rect_count(self : DirtyRegion) -> Int {
  self.rects.length()
}

///|
pub fn DirtyRegion::get_rects(self : DirtyRegion) -> Array[PixelRect] {
  self.rects
}

///|
pub fn DirtyRegion::add_rect(self : DirtyRegion, rect : PixelRect) -> Unit {
  guard !rect.is_empty() else { return }
  let mut merged = rect
  let mut pending = self.rects
  let mut changed = true
  while changed {
    changed = false
    let remaining = []
    for existing in pending {
      if pixel_rects_can_merge(merged, existing) {
        merged = merged.union(existing)
        changed = true
      } else {
        remaining.push(existing)
      }
    }
    pending = remaining
  }
  pending.push(merged)
  self.rects = pending
}

///|
pub fn DirtyRegion::add_clipped_rect(
  self : DirtyRegion,
  rect : PixelRect,
  bounds : PixelRect,
) -> Unit {
  match rect.clip_to(bounds) {
    Some(clipped) => self.add_rect(clipped)
    None => ()
  }
}

///|
pub fn DirtyRegion::add_all(
  self : DirtyRegion,
  width : Int,
  height : Int,
) -> Unit {
  self.add_rect(PixelRect::new(x=0, y=0, width~, height~))
}

///|
pub fn DirtyRegion::bounds(self : DirtyRegion) -> PixelRect? {
  guard self.rects.length() > 0 else { return None }
  let mut bounds = self.rects[0]
  for i in 1..<self.rects.length() {
    bounds = bounds.union(self.rects[i])
  }
  Some(bounds)
}

///|
pub fn DirtyRegion::present_rects(
  self : DirtyRegion,
  bounds : PixelRect,
  max_rects : Int,
) -> Array[PixelRect] {
  self.present_plan(bounds, max_rects).get_rects()
}

///|
pub fn DirtyRegion::present_plan(
  self : DirtyRegion,
  bounds : PixelRect,
  max_rects : Int,
) -> DirtyPresentPlan {
  let clipped = []
  for rect in self.rects {
    match rect.clip_to(bounds) {
      Some(value) => clipped.push(value)
      None => ()
    }
  }
  guard clipped.length() > 0 else {
    return { mode: DirtyPresentPlanMode::Empty, rects: [] }
  }
  guard max_rects <= 0 || clipped.length() <= max_rects else {
    let region = DirtyRegion::new()
    for rect in clipped {
      region.add_rect(rect)
    }
    match region.bounds() {
      Some(value) => { mode: DirtyPresentPlanMode::Bounds, rects: [value] }
      None => { mode: DirtyPresentPlanMode::Empty, rects: [] }
    }
  }
  { mode: DirtyPresentPlanMode::Rects, rects: clipped }
}
