///|
/// A surface for rendering pixels to a window
pub struct Surface {
  window : Window
  mut width : Int
  mut height : Int
}

///|
/// A present target backed by a native window handle from another windowing
/// package.
pub struct NativeSurface {
  handle : UInt64
  mut width : Int
  mut height : Int
  mut pre_present_hook : (() -> Unit)?
}

///|
/// Strategy-aware dry-run plan for submitting a RenderFrame through a
/// NativeSurface.
pub struct NativeFrameSubmitPlan {
  strategy : @graphics.DirtyPresentStrategy
  state : @graphics.DirtySubmitState
  present_pixel_count : Int
  present_byte_count : Int
} derive(Debug)

///|
/// Result of submitting a RenderFrame through NativeSurface's strategy-aware
/// present scheduler.
pub struct NativeFrameSubmitResult {
  submit_plan : NativeFrameSubmitPlan
  presented_rect_count : Int
} derive(Debug)

///|
pub fn NativeFrameSubmitPlan::get_present_strategy(
  self : NativeFrameSubmitPlan,
) -> @graphics.DirtyPresentStrategy {
  self.strategy
}

///|
pub fn NativeFrameSubmitPlan::get_state(
  self : NativeFrameSubmitPlan,
) -> @graphics.DirtySubmitState {
  self.state
}

///|
pub fn NativeFrameSubmitPlan::has_dirty(self : NativeFrameSubmitPlan) -> Bool {
  self.state != @graphics.DirtySubmitState::Clean
}

///|
pub fn NativeFrameSubmitPlan::needs_present(
  self : NativeFrameSubmitPlan,
) -> Bool {
  self.state == @graphics.DirtySubmitState::Present
}

///|
pub fn NativeFrameSubmitPlan::was_clipped_away(
  self : NativeFrameSubmitPlan,
) -> Bool {
  self.state == @graphics.DirtySubmitState::DirtyClippedAway
}

///|
pub fn NativeFrameSubmitPlan::get_present_pixel_count(
  self : NativeFrameSubmitPlan,
) -> Int {
  self.present_pixel_count
}

///|
pub fn NativeFrameSubmitPlan::get_present_byte_count(
  self : NativeFrameSubmitPlan,
) -> Int {
  self.present_byte_count
}

///|
pub fn NativeFrameSubmitPlan::saves_full_present_pixels(
  self : NativeFrameSubmitPlan,
) -> Bool {
  self.strategy == @graphics.DirtyPresentStrategy::Partial
}

///|
pub fn NativeFrameSubmitResult::get_submit_plan(
  self : NativeFrameSubmitResult,
) -> NativeFrameSubmitPlan {
  self.submit_plan
}

///|
pub fn NativeFrameSubmitResult::get_present_strategy(
  self : NativeFrameSubmitResult,
) -> @graphics.DirtyPresentStrategy {
  self.submit_plan.get_present_strategy()
}

///|
pub fn NativeFrameSubmitResult::get_presented_rect_count(
  self : NativeFrameSubmitResult,
) -> Int {
  self.presented_rect_count
}

///|
pub fn NativeFrameSubmitResult::get_state(
  self : NativeFrameSubmitResult,
) -> @graphics.DirtySubmitState {
  self.submit_plan.get_state()
}

///|
pub fn NativeFrameSubmitResult::has_dirty(
  self : NativeFrameSubmitResult,
) -> Bool {
  self.submit_plan.has_dirty()
}

///|
pub fn NativeFrameSubmitResult::needs_present(
  self : NativeFrameSubmitResult,
) -> Bool {
  self.submit_plan.needs_present()
}

///|
pub fn NativeFrameSubmitResult::was_clipped_away(
  self : NativeFrameSubmitResult,
) -> Bool {
  self.submit_plan.was_clipped_away()
}

///|
pub fn NativeFrameSubmitResult::get_present_pixel_count(
  self : NativeFrameSubmitResult,
) -> Int {
  self.submit_plan.get_present_pixel_count()
}

///|
pub fn NativeFrameSubmitResult::get_present_byte_count(
  self : NativeFrameSubmitResult,
) -> Int {
  self.submit_plan.get_present_byte_count()
}

///|
pub fn NativeFrameSubmitResult::saves_full_present_pixels(
  self : NativeFrameSubmitResult,
) -> Bool {
  self.submit_plan.saves_full_present_pixels()
}

///|
pub fn NativeFrameSubmitResult::did_present(
  self : NativeFrameSubmitResult,
) -> Bool {
  self.presented_rect_count > 0
}

///|
fn native_frame_submit_plan(
  strategy : @graphics.DirtyPresentStrategy,
  state : @graphics.DirtySubmitState,
  present_pixel_count : Int,
  present_byte_count : Int,
) -> NativeFrameSubmitPlan {
  { strategy, state, present_pixel_count, present_byte_count }
}

///|
fn native_frame_submit_plan_from_dirty(
  strategy : @graphics.DirtyPresentStrategy,
  plan : @graphics.DirtySubmitPlan,
) -> NativeFrameSubmitPlan {
  native_frame_submit_plan(
    strategy,
    plan.get_state(),
    plan.get_present_pixel_count(),
    plan.get_present_byte_count(),
  )
}

///|
fn native_frame_submit_result(
  submit_plan : NativeFrameSubmitPlan,
  presented_rect_count : Int,
) -> NativeFrameSubmitResult {
  { submit_plan, presented_rect_count }
}

///|
/// Create a new surface for the given window
pub fn Surface::new(window : Window) -> Surface {
  { window, width: window.width(), height: window.height() }
}

///|
/// Get surface width
pub fn Surface::width(self : Surface) -> Int {
  self.width
}

///|
/// Get surface height
pub fn Surface::height(self : Surface) -> Int {
  self.height
}

///|
/// Get surface width using the common graphics surface naming convention.
pub fn Surface::get_width(self : Surface) -> Int {
  self.width
}

///|
/// Get surface height using the common graphics surface naming convention.
pub fn Surface::get_height(self : Surface) -> Int {
  self.height
}

///|
/// Resize the surface to match window size
pub fn Surface::resize(self : Surface) -> Unit {
  self.width = self.window.width()
  self.height = self.window.height()
}

///|
/// Present RGBA pixels to the surface
pub fn Surface::present(self : Surface, pixels : FixedArray[Byte]) -> Unit {
  self.window.present(pixels, self.width, self.height)
}

///|
/// Present RGBA pixels to the surface with validation and optional row padding.
pub fn Surface::present_pixels(
  self : Surface,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  guard width > 0 && height > 0 else {
    return Err(@graphics.PresentError::InvalidDimensions(width, height))
  }
  guard width == self.width && height == self.height else {
    return Err(
      @graphics.PresentError::SizeMismatch(
        self.width,
        self.height,
        width,
        height,
      ),
    )
  }
  present_rect_to_handle(
    self.window.handle(),
    self.width,
    self.height,
    0,
    0,
    width,
    height,
    row_bytes,
    pixels,
  )
}

///|
/// Present a tightly packed or padded RGBA rectangle to the surface.
pub fn Surface::present_pixels_rect(
  self : Surface,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  present_rect_to_handle(
    self.window.handle(),
    self.width,
    self.height,
    x,
    y,
    width,
    height,
    row_bytes,
    pixels,
  )
}

///|
pub impl @graphics.Surface for Surface with fn get_width(self) {
  self.get_width()
}

///|
pub impl @graphics.Surface for Surface with fn get_height(self) {
  self.get_height()
}

///|
pub impl @graphics.Surface for Surface with fn present_pixels(
  self,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels(width, height, row_bytes, pixels)
}

///|
pub impl @graphics.Surface for Surface with fn present_pixels_rect(
  self,
  x,
  y,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels_rect(x, y, width, height, row_bytes, pixels)
}

///|
/// Create a surface around a native window handle and an explicit pixel size.
pub fn NativeSurface::new(
  handle : UInt64,
  width : Int,
  height : Int,
) -> NativeSurface {
  { handle, width, height, pre_present_hook: None }
}

///|
pub fn NativeSurface::from_frame(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> NativeSurface {
  NativeSurface::new(handle, frame.get_width(), frame.get_height())
}

///|
pub fn NativeSurface::get_width(self : NativeSurface) -> Int {
  self.width
}

///|
pub fn NativeSurface::get_height(self : NativeSurface) -> Int {
  self.height
}

///|
pub fn NativeSurface::handle(self : NativeSurface) -> UInt64 {
  self.handle
}

///|
pub fn NativeSurface::resize(
  self : NativeSurface,
  width : Int,
  height : Int,
) -> Unit {
  self.width = width
  self.height = height
}

///|
/// Install a hook called immediately before a validated native present.
pub fn NativeSurface::with_pre_present_hook(
  self : NativeSurface,
  hook : () -> Unit,
) -> NativeSurface {
  self.pre_present_hook = Some(hook)
  self
}

///|
pub fn NativeSurface::clear_pre_present_hook(
  self : NativeSurface,
) -> NativeSurface {
  self.pre_present_hook = None
  self
}

///|
fn NativeSurface::notify_pre_present(self : NativeSurface) -> Unit {
  match self.pre_present_hook {
    Some(hook) => hook()
    None => ()
  }
}

///|
pub fn NativeSurface::present(
  self : NativeSurface,
  pixels : FixedArray[Byte],
) -> Unit {
  self.notify_pre_present()
  display_pixels(self.handle, pixels, self.width, self.height)
}

///|
pub fn NativeSurface::present_pixels(
  self : NativeSurface,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  guard width > 0 && height > 0 else {
    return Err(@graphics.PresentError::InvalidDimensions(width, height))
  }
  guard width == self.width && height == self.height else {
    return Err(
      @graphics.PresentError::SizeMismatch(
        self.width,
        self.height,
        width,
        height,
      ),
    )
  }
  present_rect_to_handle(
    self.handle,
    self.width,
    self.height,
    0,
    0,
    width,
    height,
    row_bytes,
    pixels,
    pre_present_hook=self.pre_present_hook,
  )
}

///|
pub fn NativeSurface::present_pixels_rect(
  self : NativeSurface,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
) -> Result[Unit, @graphics.PresentError] {
  present_rect_to_handle(
    self.handle,
    self.width,
    self.height,
    x,
    y,
    width,
    height,
    row_bytes,
    pixels,
    pre_present_hook=self.pre_present_hook,
  )
}

///|
pub fn NativeSurface::present_frame_dirty(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  frame.present_dirty_to(self)
}

///|
pub fn NativeSurface::submit_frame_dirty(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> Result[@graphics.DirtySubmitResult, @graphics.PresentError] {
  frame.submit_dirty_to(self)
}

///|
pub fn NativeSurface::dirty_frame_submit_plan(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> @graphics.DirtySubmitPlan {
  frame.dirty_submit_plan(self)
}

///|
pub fn NativeSurface::dirty_frame_present_strategy(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> @graphics.DirtyPresentStrategy {
  self
  .dirty_frame_submit_plan(frame)
  .get_present_strategy(self.get_width(), self.get_height())
}

///|
pub fn NativeSurface::dirty_frame_submit_by_strategy_plan(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> NativeFrameSubmitPlan {
  let dirty_plan = self.dirty_frame_submit_plan(frame)
  let strategy = dirty_plan.get_present_strategy(
    self.get_width(),
    self.get_height(),
  )
  match strategy {
    @graphics.DirtyPresentStrategy::Full => {
      let present_pixels = self.get_width().max(0) * self.get_height().max(0)
      native_frame_submit_plan(
        strategy,
        @graphics.DirtySubmitState::Present,
        present_pixels,
        present_pixels * 4,
      )
    }
    _ => native_frame_submit_plan_from_dirty(strategy, dirty_plan)
  }
}

///|
pub fn NativeSurface::submit_frame_by_strategy(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> Result[NativeFrameSubmitResult, @graphics.PresentError] {
  let submit_plan = self.dirty_frame_submit_by_strategy_plan(frame)
  match submit_plan.get_present_strategy() {
    @graphics.DirtyPresentStrategy::Skip =>
      if frame.has_dirty() {
        match self.submit_frame_dirty(frame) {
          Ok(result) =>
            Ok(
              native_frame_submit_result(
                submit_plan,
                result.get_presented_rect_count(),
              ),
            )
          Err(error) => Err(error)
        }
      } else {
        Ok(native_frame_submit_result(submit_plan, 0))
      }
    @graphics.DirtyPresentStrategy::Partial =>
      match self.submit_frame_dirty(frame) {
        Ok(result) =>
          Ok(
            native_frame_submit_result(
              submit_plan,
              result.get_presented_rect_count(),
            ),
          )
        Err(error) => Err(error)
      }
    @graphics.DirtyPresentStrategy::Full =>
      match self.present_frame_all(frame) {
        Ok(presented) => Ok(native_frame_submit_result(submit_plan, presented))
        Err(error) => Err(error)
      }
  }
}

///|
pub fn NativeSurface::present_frame_all(
  self : NativeSurface,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  frame.present_all_to(self)
}

///|
pub fn present_render_frame_dirty(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  NativeSurface::from_frame(handle, frame).present_frame_dirty(frame)
}

///|
pub fn submit_render_frame_dirty(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> Result[@graphics.DirtySubmitResult, @graphics.PresentError] {
  NativeSurface::from_frame(handle, frame).submit_frame_dirty(frame)
}

///|
pub fn dirty_render_frame_submit_plan(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> @graphics.DirtySubmitPlan {
  NativeSurface::from_frame(handle, frame).dirty_frame_submit_plan(frame)
}

///|
pub fn dirty_render_frame_present_strategy(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> @graphics.DirtyPresentStrategy {
  NativeSurface::from_frame(handle, frame).dirty_frame_present_strategy(frame)
}

///|
pub fn dirty_render_frame_submit_by_strategy_plan(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> NativeFrameSubmitPlan {
  NativeSurface::from_frame(handle, frame).dirty_frame_submit_by_strategy_plan(
    frame,
  )
}

///|
pub fn submit_render_frame_by_strategy(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> Result[NativeFrameSubmitResult, @graphics.PresentError] {
  NativeSurface::from_frame(handle, frame).submit_frame_by_strategy(frame)
}

///|
pub fn present_render_frame_all(
  handle : UInt64,
  frame : @graphics.RenderFrame,
) -> Result[Int, @graphics.PresentError] {
  NativeSurface::from_frame(handle, frame).present_frame_all(frame)
}

///|
pub impl @graphics.Surface for NativeSurface with fn get_width(self) {
  self.get_width()
}

///|
pub impl @graphics.Surface for NativeSurface with fn get_height(self) {
  self.get_height()
}

///|
pub impl @graphics.Surface for NativeSurface with fn present_pixels(
  self,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels(width, height, row_bytes, pixels)
}

///|
pub impl @graphics.Surface for NativeSurface with fn present_pixels_rect(
  self,
  x,
  y,
  width,
  height,
  row_bytes,
  pixels,
) {
  self.present_pixels_rect(x, y, width, height, row_bytes, pixels)
}

///|
fn present_rect_to_handle(
  handle : UInt64,
  surface_width : Int,
  surface_height : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  row_bytes : Int,
  pixels : FixedArray[Byte],
  pre_present_hook? : (() -> Unit)? = None,
) -> Result[Unit, @graphics.PresentError] {
  match
    @graphics.validate_present_rect(
      surface_width, surface_height, x, y, width, height, row_bytes, pixels,
    ) {
    Err(error) => Err(error)
    Ok(info) => {
      notify_pre_present(pre_present_hook)
      if row_bytes == info.required_row_bytes() {
        display_pixels_rect(handle, pixels, x, y, width, height)
      } else {
        display_pixels_rect(
          handle,
          copy_tightly_packed_rows(
            height,
            row_bytes,
            info.required_row_bytes(),
            pixels,
          ),
          x,
          y,
          width,
          height,
        )
      }
      Ok(())
    }
  }
}

///|
fn notify_pre_present(hook : (() -> Unit)?) -> Unit {
  match hook {
    Some(callback) => callback()
    None => ()
  }
}

///|
fn copy_tightly_packed_rows(
  height : Int,
  row_bytes : Int,
  packed_row_bytes : Int,
  pixels : FixedArray[Byte],
) -> FixedArray[Byte] {
  let packed : FixedArray[Byte] = FixedArray::make(
    packed_row_bytes * height,
    0b0,
  )
  for y in 0..<height {
    let src_row = y * row_bytes
    let dst_row = y * packed_row_bytes
    for x in 0..<packed_row_bytes {
      packed[dst_row + x] = pixels[src_row + x]
    }
  }
  packed
}
