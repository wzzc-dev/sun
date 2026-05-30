///|
test "RenderFrame presents layer tree dirty pixels to a surface" {
  let frame = RenderFrame::new(4, 1)
  let surface = MemorySurface::new(4, 1)

  let background = Layer::new(4, 1)
  background.clear(Color::white())

  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::red())

  let tree = frame.get_layer_tree()
  ignore(tree.add_layer(background))
  assert_eq(tree.add_layer(top), 1)

  assert_true(frame.present_dirty_to(surface) == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(1, 0), Color::red())
  assert_true(frame.get_canvas().get_dirty_region().is_empty())
  assert_true(frame.get_layer_tree().dirty_bounds() == None)
}

///|
test "RenderFrame retains layer tree mutations and redraws moved layers" {
  let frame = RenderFrame::new(4, 1)
  let surface = MemorySurface::new(4, 1)
  let background = Layer::new(4, 1)
  background.clear(Color::white())

  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = frame.get_layer_tree()
  ignore(tree.add_layer(background))
  assert_eq(tree.add_layer(top), 1)
  assert_true(frame.present_dirty_to(surface) == Ok(1))

  assert_true(frame.get_layer_tree().set_layer_position(1, 2, 0))
  assert_true(frame.present_dirty_to(surface) == Ok(1))
  assert_eq(surface.get_present_count(), 2)
  assert_eq(surface.get_pixel(1, 0), Color::white())
  assert_eq(surface.get_pixel(2, 0), Color::blue())
}

///|
test "RenderFrame dirty rect limit controls partial present fallback" {
  let frame = RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  let surface = MemorySurface::new(8, 1)

  let left = Layer::new(1, 1)
  left.get_canvas().draw_pixel(0, 0, Color::red())
  let middle = Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, Color::green())
  let right = Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = frame.get_layer_tree()
  ignore(tree.add_layer(left))
  ignore(tree.add_layer(middle))
  ignore(tree.add_layer(right))

  assert_eq(frame.get_dirty_rect_limit(), 2)
  assert_true(frame.present_dirty_to(surface) == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(3, 0), Color::green())
  assert_eq(surface.get_pixel(6, 0), Color::blue())
}

///|
test "RenderFrame::dirty_present_plan uses frame dirty rect limit" {
  let frame = RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  frame.get_canvas().draw_pixel(0, 0, Color::red())

  let middle = Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, Color::green())
  let right = Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, Color::blue())

  let tree = frame.get_layer_tree()
  ignore(tree.add_layer(middle))
  ignore(tree.add_layer(right))

  let plan = frame.dirty_present_plan(MemorySurface::new(8, 1))
  assert_true(plan.get_mode() == DirtyPresentPlanMode::Bounds)
  assert_eq(plan.get_rect_count(), 1)
  assert_true(
    plan.get_rects()[0] == PixelRect::new(x=0, y=0, width=7, height=1),
  )
  assert_true(frame.has_dirty())
}

///|
test "RenderFrame::dirty_present_batch materializes frame dirty without submitting" {
  let frame = RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  frame.get_canvas().draw_pixel(0, 0, Color::red())

  let middle = Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, Color::green())
  let right = Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, Color::blue())
  ignore(frame.get_layer_tree().add_layer(middle))
  ignore(frame.get_layer_tree().add_layer(right))

  let surface = MemorySurface::new(8, 1)
  match frame.dirty_present_batch(surface) {
    Ok(batch) => {
      assert_eq(batch.get_rect_count(), 1)
      assert_eq(batch.get_present_pixel_count(), 7)
      assert_eq(batch.get_present_byte_count(), 28)
      let payloads = batch.get_payloads()
      assert_true(
        payloads[0].get_rect() == PixelRect::new(x=0, y=0, width=7, height=1),
      )
      let pixels = payloads[0].get_pixels()
      assert_eq(pixels.length(), 28)
      assert_eq(pixels[0], Color::red().r)
      assert_eq(pixels[12], Color::green().r)
      assert_eq(pixels[24], Color::blue().r)
    }
    Err(_) => abort("expected render frame dirty present batch")
  }

  assert_eq(surface.get_present_count(), 0)
  assert_eq(
    frame.get_canvas().get_pixmap().get_pixel(3, 0),
    Color::transparent(),
  )
  assert_true(frame.has_dirty())
  assert_true(frame.present_dirty_to(surface) == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::dirty_submit_plan snapshots dirty bounds and present plan" {
  let frame = RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  frame.get_canvas().draw_pixel(0, 0, Color::red())

  let middle = Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, Color::green())
  let right = Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, Color::blue())
  ignore(frame.get_layer_tree().add_layer(middle))
  ignore(frame.get_layer_tree().add_layer(right))

  let submit_plan = frame.dirty_submit_plan(MemorySurface::new(8, 1))
  assert_true(submit_plan.get_state() == DirtySubmitState::Present)
  assert_true(submit_plan.has_dirty())
  assert_true(submit_plan.needs_present())
  assert_true(submit_plan.uses_bounds_fallback())
  assert_eq(submit_plan.get_present_rect_count(), 1)
  assert_eq(submit_plan.get_present_pixel_count(), 7)
  assert_eq(submit_plan.get_present_byte_count(), 28)
  assert_true(submit_plan.saves_full_present_pixels(8, 1))
  assert_true(!submit_plan.saves_full_present_pixels(7, 1))
  assert_true(
    submit_plan.get_present_strategy(8, 1) == DirtyPresentStrategy::Partial,
  )
  assert_true(
    submit_plan.get_present_strategy(7, 1) == DirtyPresentStrategy::Full,
  )
  assert_true(
    submit_plan.get_dirty_bounds() ==
    Some(PixelRect::new(x=0, y=0, width=7, height=1)),
  )
  assert_true(
    submit_plan.get_present_plan().get_rects()[0] ==
    PixelRect::new(x=0, y=0, width=7, height=1),
  )
  assert_true(frame.has_dirty())
}

///|
test "RenderFrame::dirty_submit_plan keeps clipped-away dirty visible to scheduler" {
  let frame = RenderFrame::new(4, 1)
  frame.mark_dirty_rect(PixelRect::new(x=3, y=0, width=1, height=1))

  let submit_plan = frame.dirty_submit_plan(MemorySurface::new(2, 1))
  assert_true(submit_plan.get_state() == DirtySubmitState::DirtyClippedAway)
  assert_true(submit_plan.has_dirty())
  assert_true(!submit_plan.needs_present())
  assert_eq(submit_plan.get_present_rect_count(), 0)
  assert_eq(submit_plan.get_present_pixel_count(), 0)
  assert_eq(submit_plan.get_present_byte_count(), 0)
  assert_true(!submit_plan.saves_full_present_pixels(2, 1))
  assert_true(
    submit_plan.get_present_strategy(2, 1) == DirtyPresentStrategy::Skip,
  )
  assert_true(
    submit_plan.get_dirty_bounds() ==
    Some(PixelRect::new(x=3, y=0, width=1, height=1)),
  )
  assert_true(
    submit_plan.get_present_plan().get_mode() == DirtyPresentPlanMode::Empty,
  )
  assert_true(frame.has_dirty())
}

///|
test "RenderFrame::submit_dirty_to reports scheduler result" {
  let frame = RenderFrame::new(2, 1)
  let layer = Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  let result = frame.submit_dirty_to(MemorySurface::new(2, 1))
  match result {
    Ok(submit_result) => {
      assert_true(submit_result.get_state() == DirtySubmitState::Present)
      assert_eq(submit_result.get_presented_rect_count(), 1)
      assert_true(submit_result.has_dirty())
      assert_true(submit_result.needs_present())
      assert_true(submit_result.did_present())
      assert_eq(submit_result.get_present_pixel_count(), 1)
      assert_eq(submit_result.get_present_byte_count(), 4)
      assert_true(submit_result.saves_full_present_pixels(2, 1))
      assert_true(
        submit_result.get_present_strategy(2, 1) ==
        DirtyPresentStrategy::Partial,
      )
      assert_true(!submit_result.was_clipped_away())
      assert_true(!submit_result.uses_bounds_fallback())
      assert_true(
        submit_result.get_dirty_bounds() ==
        Some(PixelRect::new(x=1, y=0, width=1, height=1)),
      )
    }
    Err(_) => abort("expected dirty submit result")
  }
  assert_true(!frame.has_dirty())

  let clean = frame.submit_dirty_to(MemorySurface::new(2, 1))
  match clean {
    Ok(submit_result) => {
      assert_true(submit_result.get_state() == DirtySubmitState::Clean)
      assert_eq(submit_result.get_presented_rect_count(), 0)
      assert_true(!submit_result.has_dirty())
      assert_true(!submit_result.needs_present())
      assert_true(!submit_result.did_present())
      assert_true(!submit_result.was_clipped_away())
      assert_eq(submit_result.get_present_pixel_count(), 0)
      assert_eq(submit_result.get_present_byte_count(), 0)
      assert_true(!submit_result.saves_full_present_pixels(2, 1))
      assert_true(
        submit_result.get_present_strategy(2, 1) == DirtyPresentStrategy::Skip,
      )
      assert_true(submit_result.get_dirty_bounds() == None)
    }
    Err(_) => abort("expected clean submit result")
  }
}

///|
test "RenderFrame::submit_dirty_to consumes surface-clipped dirty" {
  let frame = RenderFrame::new(4, 1)
  let layer = Layer::new(1, 1).set_position(3, 0)
  layer.get_canvas().draw_pixel(0, 0, Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))

  let result = frame.submit_dirty_to(MemorySurface::new(2, 1))
  match result {
    Ok(submit_result) => {
      assert_true(
        submit_result.get_state() == DirtySubmitState::DirtyClippedAway,
      )
      assert_eq(submit_result.get_presented_rect_count(), 0)
      assert_true(submit_result.has_dirty())
      assert_true(!submit_result.needs_present())
      assert_true(!submit_result.did_present())
      assert_eq(submit_result.get_present_pixel_count(), 0)
      assert_eq(submit_result.get_present_byte_count(), 0)
      assert_true(!submit_result.saves_full_present_pixels(2, 1))
      assert_true(
        submit_result.get_present_strategy(2, 1) == DirtyPresentStrategy::Skip,
      )
      assert_true(submit_result.was_clipped_away())
      assert_true(
        submit_result.get_dirty_bounds() ==
        Some(PixelRect::new(x=3, y=0, width=1, height=1)),
      )
    }
    Err(_) => abort("expected clipped-away submit result")
  }
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::submit_by_strategy_plan reports partial present cost" {
  let frame = RenderFrame::new(4, 1)
  frame.mark_dirty_rect(PixelRect::new(x=1, y=0, width=1, height=1))
  let surface = MemorySurface::new(4, 1)

  assert_true(frame.present_strategy(surface) == DirtyPresentStrategy::Partial)
  let plan = frame.submit_by_strategy_plan(surface)
  assert_true(plan.get_present_strategy() == DirtyPresentStrategy::Partial)
  assert_true(plan.get_state() == DirtySubmitState::Present)
  assert_true(plan.has_dirty())
  assert_true(plan.needs_present())
  assert_true(!plan.was_clipped_away())
  assert_true(!plan.uses_bounds_fallback())
  assert_eq(plan.get_present_rect_count(), 1)
  assert_eq(plan.get_present_pixel_count(), 1)
  assert_eq(plan.get_present_byte_count(), 4)
  assert_true(plan.saves_full_present_pixels())
  assert_true(
    plan.get_dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )
  assert_true(
    plan.get_dirty_submit_plan().get_present_strategy(4, 1) ==
    DirtyPresentStrategy::Partial,
  )
  assert_true(frame.has_dirty())
  assert_eq(surface.get_present_count(), 0)
}

///|
test "RenderFrame::submit_by_strategy_to submits partial dirty rects" {
  let frame = RenderFrame::new(4, 1)
  frame.get_canvas().draw_pixel(1, 0, Color::red())
  let surface = MemorySurface::new(4, 1)

  match frame.submit_by_strategy_to(surface) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == DirtyPresentStrategy::Partial,
      )
      assert_true(
        result.get_submit_plan().get_present_strategy() ==
        DirtyPresentStrategy::Partial,
      )
      assert_true(result.get_state() == DirtySubmitState::Present)
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_true(result.has_dirty())
      assert_true(result.needs_present())
      assert_true(result.did_present())
      assert_true(!result.was_clipped_away())
      assert_eq(result.get_present_pixel_count(), 1)
      assert_eq(result.get_present_byte_count(), 4)
      assert_true(result.saves_full_present_pixels())
      assert_true(
        result.get_dirty_bounds() ==
        Some(PixelRect::new(x=1, y=0, width=1, height=1)),
      )
    }
    Err(_) => abort("expected partial strategy submit result")
  }
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(1, 0), Color::red())
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::submit_by_strategy_to promotes full-frame cost" {
  let frame = RenderFrame::new(2, 1)
  frame.mark_all_dirty()
  let surface = MemorySurface::new(2, 1)

  let plan = frame.submit_by_strategy_plan(surface)
  assert_true(plan.get_present_strategy() == DirtyPresentStrategy::Full)
  assert_true(plan.get_state() == DirtySubmitState::Present)
  assert_true(plan.has_dirty())
  assert_true(plan.needs_present())
  assert_eq(plan.get_present_rect_count(), 1)
  assert_eq(plan.get_present_pixel_count(), 2)
  assert_eq(plan.get_present_byte_count(), 8)
  assert_true(!plan.saves_full_present_pixels())
  assert_true(frame.has_dirty())
  assert_eq(surface.get_present_count(), 0)

  match frame.submit_by_strategy_to(surface) {
    Ok(result) => {
      assert_true(result.get_present_strategy() == DirtyPresentStrategy::Full)
      assert_true(result.get_state() == DirtySubmitState::Present)
      assert_true(result.did_present())
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 2)
      assert_eq(result.get_present_byte_count(), 8)
      assert_true(!result.saves_full_present_pixels())
    }
    Err(_) => abort("expected full strategy submit result")
  }
  assert_eq(surface.get_present_count(), 1)
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::submit_by_strategy_to consumes clipped-away dirty" {
  let frame = RenderFrame::new(4, 1)
  frame.mark_dirty_rect(PixelRect::new(x=3, y=0, width=1, height=1))
  let surface = MemorySurface::new(2, 1)

  let plan = frame.submit_by_strategy_plan(surface)
  assert_true(plan.get_present_strategy() == DirtyPresentStrategy::Skip)
  assert_true(plan.get_state() == DirtySubmitState::DirtyClippedAway)
  assert_true(plan.has_dirty())
  assert_true(!plan.needs_present())
  assert_true(plan.was_clipped_away())
  assert_eq(plan.get_present_rect_count(), 0)
  assert_eq(plan.get_present_pixel_count(), 0)
  assert_eq(plan.get_present_byte_count(), 0)
  assert_true(!plan.saves_full_present_pixels())
  assert_true(frame.has_dirty())
  assert_eq(surface.get_present_count(), 0)

  match frame.submit_by_strategy_to(surface) {
    Ok(result) => {
      assert_true(result.get_present_strategy() == DirtyPresentStrategy::Skip)
      assert_true(result.get_state() == DirtySubmitState::DirtyClippedAway)
      assert_true(result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(result.was_clipped_away())
      assert_true(!result.did_present())
      assert_eq(result.get_present_rect_count(), 0)
      assert_eq(result.get_presented_rect_count(), 0)
      assert_eq(result.get_present_pixel_count(), 0)
      assert_eq(result.get_present_byte_count(), 0)
      assert_true(!result.saves_full_present_pixels())
    }
    Err(_) => abort("expected clipped-away strategy submit result")
  }
  assert_eq(surface.get_present_count(), 0)
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::submit_by_strategy_to skips clean frames" {
  let frame = RenderFrame::new(2, 1)
  let surface = MemorySurface::new(2, 1)

  match frame.submit_by_strategy_to(surface) {
    Ok(result) => {
      assert_true(result.get_present_strategy() == DirtyPresentStrategy::Skip)
      assert_true(result.get_state() == DirtySubmitState::Clean)
      assert_true(!result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(!result.was_clipped_away())
      assert_true(!result.did_present())
      assert_eq(result.get_present_rect_count(), 0)
      assert_eq(result.get_presented_rect_count(), 0)
      assert_eq(result.get_present_pixel_count(), 0)
      assert_eq(result.get_present_byte_count(), 0)
      assert_true(!result.saves_full_present_pixels())
      assert_true(result.get_dirty_bounds() == None)
    }
    Err(_) => abort("expected clean strategy submit result")
  }
  assert_eq(surface.get_present_count(), 0)
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame dirty helpers cover canvas and layer tree dirtiness" {
  let frame = RenderFrame::new(4, 2)
  assert_true(!frame.has_dirty())
  assert_true(frame.dirty_bounds() == None)

  frame.mark_dirty_rect(PixelRect::new(x=1, y=0, width=1, height=1))
  assert_true(frame.has_dirty())
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )

  let layer = Layer::new(1, 1).set_position(3, 1)
  layer.get_canvas().draw_pixel(0, 0, Color::green())
  ignore(frame.get_layer_tree().add_layer(layer))
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=3, height=2)),
  )

  frame.clear_dirty_regions()
  frame.mark_all_dirty()
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=4, height=2)),
  )
}

///|
test "RenderFrame::present_all_to marks and presents the whole frame" {
  let frame = RenderFrame::new(2, 1)
  let layer = Layer::new(2, 1)
  layer.clear(Color::white())
  layer.get_canvas().draw_pixel(1, 0, Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))
  assert_true(frame.present_dirty_to(MemorySurface::new(2, 1)) == Ok(1))
  assert_true(!frame.has_dirty())

  let surface = MemorySurface::new(2, 1)
  let result = frame.present_all_to(surface)
  assert_true(result == Ok(1))
  assert_eq(surface.get_present_count(), 1)
  assert_eq(surface.get_pixel(0, 0), Color::white())
  assert_eq(surface.get_pixel(1, 0), Color::blue())
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::present_all_to preserves dirty state after surface error" {
  let frame = RenderFrame::new(2, 1)
  let layer = Layer::new(2, 1)
  layer.get_canvas().draw_pixel(0, 0, Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))
  assert_true(frame.present_dirty_to(MemorySurface::new(2, 1)) == Ok(1))

  match frame.present_all_to(RenderFrameFailingSurface::new(2, 1)) {
    Err(PresentError::InvalidDimensions(0, 0)) => ()
    _ => abort("expected surface failure")
  }
  assert_true(frame.has_dirty())
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=2, height=1)),
  )
}

///|
test "RenderFrame::resize preserves overlapping pixels and marks new frame dirty" {
  let frame = RenderFrame::new(2, 1)
  frame.get_canvas().draw_pixel(0, 0, Color::red())
  frame.get_canvas().draw_pixel(1, 0, Color::blue())
  frame.clear_dirty_regions()

  ignore(frame.resize(3, 2))
  assert_eq(frame.get_width(), 3)
  assert_eq(frame.get_height(), 2)
  assert_eq(frame.get_canvas().get_pixmap().get_pixel(0, 0), Color::red())
  assert_eq(frame.get_canvas().get_pixmap().get_pixel(1, 0), Color::blue())
  assert_eq(
    frame.get_canvas().get_pixmap().get_pixel(2, 1),
    Color::transparent(),
  )
  assert_true(
    frame.get_canvas().get_dirty_region().bounds() ==
    Some(PixelRect::new(x=0, y=0, width=3, height=2)),
  )

  ignore(frame.resize(1, 1))
  assert_eq(frame.get_width(), 1)
  assert_eq(frame.get_height(), 1)
  assert_eq(frame.get_canvas().get_pixmap().get_pixel(0, 0), Color::red())
  assert_true(
    frame.get_canvas().get_dirty_region().bounds() ==
    Some(PixelRect::new(x=0, y=0, width=1, height=1)),
  )
}

///|
test "RenderFrame::resize retains layer tree and dirty present policy" {
  let frame = RenderFrame::new(2, 1).set_dirty_rect_limit(2)
  let layer = Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, Color::green())
  assert_eq(frame.get_layer_tree().add_layer(layer), 0)

  ignore(frame.resize(3, 2))
  assert_eq(frame.get_dirty_rect_limit(), 2)
  assert_eq(frame.get_layer_tree().get_layer_count(), 1)
  assert_true(
    frame.get_layer_tree().dirty_bounds() ==
    Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )
}

///|
test "RenderFrame::resize presents resized frame and retained dirty layers" {
  let frame = RenderFrame::new(1, 1)
  frame.get_canvas().draw_pixel(0, 0, Color::red())
  frame.clear_dirty_regions()

  let layer = Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))

  ignore(frame.resize(2, 1))
  let surface = MemorySurface::new(2, 1)
  let white = Pixmap::new(2, 1)
  white.clear(Color::white())
  assert_true(white.present_to(surface) == Ok(()))

  assert_true(frame.present_dirty_to(surface) == Ok(1))
  assert_eq(surface.get_present_count(), 2)
  assert_eq(surface.get_pixel(0, 0), Color::red())
  assert_eq(surface.get_pixel(1, 0), Color::blue())
  assert_true(frame.get_canvas().get_dirty_region().is_empty())
  assert_true(frame.get_layer_tree().dirty_bounds() == None)
}

///|
test "RenderFrame::resize_and_clear_layer resizes frame background layer" {
  let frame = RenderFrame::new(2, 1)
  let background = Layer::new(2, 1)
  background.clear(Color::white())
  let top = Layer::new(1, 1).set_position(1, 0)
  top.get_canvas().draw_pixel(0, 0, Color::red())

  let tree = frame.get_layer_tree()
  assert_eq(tree.add_layer(background), 0)
  assert_eq(tree.add_layer(top), 1)
  assert_true(frame.present_dirty_to(MemorySurface::new(2, 1)) == Ok(1))
  assert_true(!frame.has_dirty())

  assert_true(frame.resize_and_clear_layer(0, 3, 2, Color::blue()))
  assert_eq(frame.get_width(), 3)
  assert_eq(frame.get_height(), 2)
  match tree.get_layer(0) {
    Some(resized_background) => {
      assert_eq(resized_background.get_width(), 3)
      assert_eq(resized_background.get_height(), 2)
      assert_eq(resized_background.get_pixmap().get_pixel(0, 0), Color::blue())
      assert_eq(resized_background.get_pixmap().get_pixel(2, 1), Color::blue())
      assert_true(
        resized_background.dirty_bounds() ==
        Some(PixelRect::new(x=0, y=0, width=3, height=2)),
      )
    }
    None => abort("expected resized background layer")
  }
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=3, height=2)),
  )

  let surface = MemorySurface::new(3, 2)
  assert_true(frame.present_dirty_to(surface) == Ok(1))
  assert_eq(surface.get_pixel(0, 0), Color::blue())
  assert_eq(surface.get_pixel(1, 0), Color::red())
  assert_eq(surface.get_pixel(2, 1), Color::blue())
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::resize_and_clear_layer clears same-size layer" {
  let frame = RenderFrame::new(2, 1)
  let background = Layer::new(2, 1)
  background.clear(Color::white())
  assert_eq(frame.get_layer_tree().add_layer(background), 0)
  assert_true(frame.present_dirty_to(MemorySurface::new(2, 1)) == Ok(1))
  assert_true(!frame.has_dirty())

  assert_true(frame.resize_and_clear_layer(0, 2, 1, Color::green()))
  assert_eq(frame.get_width(), 2)
  assert_eq(frame.get_height(), 1)
  match frame.get_layer_tree().get_layer(0) {
    Some(layer) => {
      assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::green())
      assert_eq(layer.get_pixmap().get_pixel(1, 0), Color::green())
      assert_true(
        layer.dirty_bounds() ==
        Some(PixelRect::new(x=0, y=0, width=2, height=1)),
      )
    }
    None => abort("expected background layer")
  }
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=2, height=1)),
  )
}

///|
test "RenderFrame::resize_and_clear_layers resizes multiple frame layers" {
  let frame = RenderFrame::new(2, 1)
  let background = Layer::new(2, 1)
  background.clear(Color::white())
  let overlay = Layer::new(2, 1)
  overlay.clear(Color::transparent())
  let tree = frame.get_layer_tree()
  assert_eq(tree.add_layer(background), 0)
  assert_eq(tree.add_layer(overlay), 1)
  assert_true(frame.present_dirty_to(MemorySurface::new(2, 1)) == Ok(1))
  assert_true(!frame.has_dirty())

  assert_true(
    frame.resize_and_clear_layers(3, 2, [
      RenderFrameLayerClearRequest::new(0, Color::blue()),
      RenderFrameLayerClearRequest::new(1, Color::green()),
    ]),
  )
  assert_eq(frame.get_width(), 3)
  assert_eq(frame.get_height(), 2)
  match tree.get_layer(0) {
    Some(layer) => {
      assert_eq(layer.get_width(), 3)
      assert_eq(layer.get_height(), 2)
      assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::blue())
      assert_eq(layer.get_pixmap().get_pixel(2, 1), Color::blue())
      assert_true(
        layer.dirty_bounds() ==
        Some(PixelRect::new(x=0, y=0, width=3, height=2)),
      )
    }
    None => abort("expected background layer")
  }
  match tree.get_layer(1) {
    Some(layer) => {
      assert_eq(layer.get_width(), 3)
      assert_eq(layer.get_height(), 2)
      assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::green())
      assert_eq(layer.get_pixmap().get_pixel(2, 1), Color::green())
      assert_true(
        layer.dirty_bounds() ==
        Some(PixelRect::new(x=0, y=0, width=3, height=2)),
      )
    }
    None => abort("expected overlay layer")
  }
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=0, y=0, width=3, height=2)),
  )

  let surface = MemorySurface::new(3, 2)
  assert_true(frame.present_dirty_to(surface) == Ok(1))
  assert_eq(surface.get_pixel(0, 0), Color::green())
  assert_eq(surface.get_pixel(2, 1), Color::green())
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::resize_and_clear_layers validates all layers before mutation" {
  let frame = RenderFrame::new(2, 1)
  let background = Layer::new(2, 1)
  background.clear(Color::white())
  assert_eq(frame.get_layer_tree().add_layer(background), 0)
  assert_true(frame.present_dirty_to(MemorySurface::new(2, 1)) == Ok(1))
  assert_true(!frame.has_dirty())

  assert_true(
    !frame.resize_and_clear_layers(3, 2, [
      RenderFrameLayerClearRequest::new(0, Color::blue()),
      RenderFrameLayerClearRequest::new(3, Color::red()),
    ]),
  )
  assert_eq(frame.get_width(), 2)
  assert_eq(frame.get_height(), 1)
  match frame.get_layer_tree().get_layer(0) {
    Some(layer) => {
      assert_eq(layer.get_width(), 2)
      assert_eq(layer.get_height(), 1)
      assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::white())
      assert_true(layer.dirty_bounds() == None)
    }
    None => abort("expected background layer")
  }
  assert_true(!frame.has_dirty())

  assert_true(!frame.resize_and_clear_layers(2, 1, []))
  assert_true(
    !frame.resize_and_clear_layers(0, 1, [
      RenderFrameLayerClearRequest::new(0, Color::blue()),
    ]),
  )
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame::resize_and_clear_layer rejects invalid lifecycle requests" {
  let frame = RenderFrame::new(2, 1)
  let background = Layer::new(2, 1)
  background.clear(Color::white())
  assert_eq(frame.get_layer_tree().add_layer(background), 0)
  assert_true(frame.present_dirty_to(MemorySurface::new(2, 1)) == Ok(1))
  assert_true(!frame.has_dirty())

  assert_true(!frame.resize_and_clear_layer(2, 3, 2, Color::blue()))
  assert_eq(frame.get_width(), 2)
  assert_eq(frame.get_height(), 1)
  match frame.get_layer_tree().get_layer(0) {
    Some(layer) => {
      assert_eq(layer.get_width(), 2)
      assert_eq(layer.get_height(), 1)
      assert_eq(layer.get_pixmap().get_pixel(0, 0), Color::white())
      assert_true(layer.dirty_bounds() == None)
    }
    None => abort("expected background layer")
  }
  assert_true(!frame.has_dirty())

  assert_true(!frame.resize_and_clear_layer(0, 0, 2, Color::blue()))
  assert_eq(frame.get_width(), 2)
  assert_eq(frame.get_height(), 1)
  assert_true(!frame.has_dirty())
}

///|
test "RenderFrame preserves dirty state after surface error" {
  let frame = RenderFrame::new(2, 1)
  let surface = RenderFrameFailingSurface::new(2, 1)
  let layer = Layer::new(2, 1)
  layer.get_canvas().draw_pixel(1, 0, Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  match frame.present_dirty_to(surface) {
    Err(PresentError::InvalidDimensions(0, 0)) => ()
    _ => abort("expected surface failure")
  }
  assert_true(frame.get_canvas().get_dirty_region().is_empty())
  assert_true(
    frame.get_layer_tree().dirty_bounds() ==
    Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )
  assert_true(
    frame.dirty_bounds() == Some(PixelRect::new(x=1, y=0, width=1, height=1)),
  )
}

///|
struct RenderFrameFailingSurface {
  width : Int
  height : Int
} derive(Debug)

///|
fn RenderFrameFailingSurface::new(
  width : Int,
  height : Int,
) -> RenderFrameFailingSurface {
  { width, height }
}

///|
impl Surface for RenderFrameFailingSurface with fn get_width(self) {
  self.width
}

///|
impl Surface for RenderFrameFailingSurface with fn get_height(self) {
  self.height
}

///|
impl Surface for RenderFrameFailingSurface with fn present_pixels(
  self,
  width,
  height,
  row_bytes,
  pixels,
) {
  ignore(self)
  ignore(width)
  ignore(height)
  ignore(row_bytes)
  ignore(pixels)
  Err(PresentError::InvalidDimensions(0, 0))
}

///|
impl Surface for RenderFrameFailingSurface with fn present_pixels_rect(
  self,
  x,
  y,
  width,
  height,
  row_bytes,
  pixels,
) {
  ignore(self)
  ignore(x)
  ignore(y)
  ignore(width)
  ignore(height)
  ignore(row_bytes)
  ignore(pixels)
  Err(PresentError::InvalidDimensions(0, 0))
}
