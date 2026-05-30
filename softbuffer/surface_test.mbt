///|
test "NativeSurface exposes size and handle" {
  let surface = NativeSurface::new(42, 3, 2)
  assert_eq(surface.get_width(), 3)
  assert_eq(surface.get_height(), 2)
  assert_eq(surface.handle(), 42)
  surface.resize(4, 5)
  assert_eq(surface.get_width(), 4)
  assert_eq(surface.get_height(), 5)
}

///|
test "NativeSurface validates present parameters" {
  let surface = NativeSurface::new(42, 2, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  assert_true(
    surface.present_pixels(0, 2, 8, pixels) ==
    Err(@graphics.PresentError::InvalidDimensions(0, 2)),
  )
  assert_true(
    surface.present_pixels(1, 2, 4, pixels) ==
    Err(@graphics.PresentError::SizeMismatch(2, 2, 1, 2)),
  )
  assert_true(
    surface.present_pixels_rect(2, 1, 1, 1, 4, pixels) ==
    Err(@graphics.PresentError::RectOutOfBounds(2, 1, 1, 1, 2, 2)),
  )
  assert_true(
    surface.present_pixels(2, 2, 4, pixels) ==
    Err(@graphics.PresentError::InvalidRowBytes(4, 8)),
  )
  let short_pixels : FixedArray[Byte] = FixedArray::make(15, 0)
  assert_true(
    surface.present_pixels(2, 2, 8, short_pixels) ==
    Err(@graphics.PresentError::PixelBufferTooSmall(15, 16)),
  )
}

///|
test "NativeSurface dispatches through graphics Surface trait" {
  let surface = NativeSurface::new(42, 2, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)
  let result = @graphics.present_pixels(surface, 2, 2, 4, pixels)
  assert_true(result == Err(@graphics.PresentError::InvalidRowBytes(4, 8)))
  let rect_result = @graphics.present_pixels_rect(
    surface, 1, 1, 1, 1, 4, pixels,
  )
  assert_true(rect_result == Ok(()))
}

///|
test "NativeSurface accepts padded row bytes through shared validation" {
  let surface = NativeSurface::new(42, 1, 2)
  let pixels : FixedArray[Byte] = FixedArray::make(12, 0)
  let result = surface.present_pixels(1, 2, 8, pixels)
  assert_true(result == Ok(()))
}

///|
test "NativeSurface calls pre-present hook only after validation" {
  let count = Ref(0)
  let surface = NativeSurface::new(42, 2, 2).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })
  let pixels : FixedArray[Byte] = FixedArray::make(16, 0)

  assert_true(
    surface.present_pixels(2, 2, 4, pixels) ==
    Err(@graphics.PresentError::InvalidRowBytes(4, 8)),
  )
  assert_eq(count.val, 0)

  assert_true(surface.present_pixels(2, 2, 8, pixels) == Ok(()))
  assert_eq(count.val, 1)

  assert_true(surface.present_pixels_rect(1, 1, 1, 1, 4, pixels) == Ok(()))
  assert_eq(count.val, 2)

  let padded : FixedArray[Byte] = FixedArray::make(12, 0)
  assert_true(surface.present_pixels_rect(0, 0, 1, 2, 8, padded) == Ok(()))
  assert_eq(count.val, 3)

  let without_hook = surface.clear_pre_present_hook()
  assert_true(without_hook.present_pixels(2, 2, 8, pixels) == Ok(()))
  assert_eq(count.val, 3)
}

///|
test "NativeSurface builds from RenderFrame dimensions" {
  let frame = @graphics.RenderFrame::new(3, 2)
  let surface = NativeSurface::from_frame(42, frame)
  assert_eq(surface.handle(), 42)
  assert_eq(surface.get_width(), 3)
  assert_eq(surface.get_height(), 2)
}

///|
test "NativeSurface presents dirty and full RenderFrame paths" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(2, 1)
  layer.clear(@graphics.Color::white())
  layer.get_canvas().draw_pixel(1, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))

  let surface = NativeSurface::from_frame(42, frame)
  assert_true(surface.present_frame_dirty(frame) == Ok(1))
  assert_true(!frame.has_dirty())
  assert_true(surface.present_frame_dirty(frame) == Ok(0))
  assert_true(surface.present_frame_all(frame) == Ok(1))
  assert_true(!frame.has_dirty())
}

///|
test "NativeSurface exposes RenderFrame dirty submit plans" {
  let frame = @graphics.RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  frame.get_canvas().draw_pixel(0, 0, @graphics.Color::red())

  let middle = @graphics.Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, @graphics.Color::green())
  let right = @graphics.Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(middle))
  ignore(frame.get_layer_tree().add_layer(right))

  let surface = NativeSurface::from_frame(42, frame)
  let submit_plan = surface.dirty_frame_submit_plan(frame)
  assert_true(submit_plan.get_state() == @graphics.DirtySubmitState::Present)
  assert_true(submit_plan.has_dirty())
  assert_true(submit_plan.needs_present())
  assert_true(submit_plan.uses_bounds_fallback())
  assert_eq(submit_plan.get_present_rect_count(), 1)
  assert_eq(submit_plan.get_present_pixel_count(), 7)
  assert_eq(submit_plan.get_present_byte_count(), 28)
  assert_true(submit_plan.saves_full_present_pixels(8, 1))
  assert_true(!submit_plan.saves_full_present_pixels(7, 1))
  assert_true(
    submit_plan.get_present_strategy(8, 1) ==
    @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(
    submit_plan.get_present_strategy(7, 1) ==
    @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(
    submit_plan.get_present_plan().get_rects()[0] ==
    @graphics.PixelRect::new(x=0, y=0, width=7, height=1),
  )
  assert_true(frame.has_dirty())

  let constructed_plan = dirty_render_frame_submit_plan(42, frame)
  assert_true(
    constructed_plan.get_present_plan().get_rects()[0] ==
    submit_plan.get_present_plan().get_rects()[0],
  )
  assert_true(
    surface.dirty_frame_present_strategy(frame) ==
    @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(
    NativeSurface::new(42, 7, 1).dirty_frame_present_strategy(frame) ==
    @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(
    dirty_render_frame_present_strategy(42, frame) ==
    @graphics.DirtyPresentStrategy::Partial,
  )
}

///|
test "NativeSurface exposes RenderFrame dirty present batches" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  frame.get_canvas().draw_pixel(0, 0, @graphics.Color::red())

  let middle = @graphics.Layer::new(1, 1).set_position(3, 0)
  middle.get_canvas().draw_pixel(0, 0, @graphics.Color::green())
  let right = @graphics.Layer::new(1, 1).set_position(6, 0)
  right.get_canvas().draw_pixel(0, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(middle))
  ignore(frame.get_layer_tree().add_layer(right))

  let surface = NativeSurface::from_frame(42, frame).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })
  match surface.dirty_frame_present_batch(frame) {
    Ok(batch) => {
      assert_eq(batch.get_rect_count(), 1)
      assert_eq(batch.get_present_pixel_count(), 7)
      assert_eq(batch.get_present_byte_count(), 28)
      let payloads = batch.get_payloads()
      assert_true(
        payloads[0].get_rect() ==
        @graphics.PixelRect::new(x=0, y=0, width=7, height=1),
      )
      let pixels = payloads[0].get_pixels()
      assert_eq(pixels.length(), 28)
      assert_eq(pixels[0], @graphics.Color::red().r)
      assert_eq(pixels[12], @graphics.Color::green().r)
      assert_eq(pixels[24], @graphics.Color::blue().r)
    }
    Err(_) => abort("expected native dirty present batch")
  }
  assert_eq(count.val, 0)
  assert_eq(
    frame.get_canvas().get_pixmap().get_pixel(3, 0),
    @graphics.Color::transparent(),
  )
  assert_true(frame.has_dirty())

  assert_true(surface.present_frame_dirty(frame) == Ok(1))
  assert_eq(count.val, 1)
  assert_true(!frame.has_dirty())
}

///|
test "NativeSurface dirty present batch preserves clipped-away dirty" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.mark_dirty_rect(@graphics.PixelRect::new(x=3, y=0, width=1, height=1))
  let surface = NativeSurface::new(42, 2, 1).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })

  match surface.dirty_frame_present_batch(frame) {
    Ok(batch) => {
      assert_true(batch.is_empty())
      assert_eq(batch.get_rect_count(), 0)
      assert_eq(batch.get_present_pixel_count(), 0)
      assert_eq(batch.get_present_byte_count(), 0)
    }
    Err(_) => abort("expected clipped-away dirty present batch")
  }
  assert_eq(count.val, 0)
  assert_true(frame.has_dirty())
}

///|
test "NativeSurface dirty submit plan preserves clipped-away dirty without presenting" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.mark_dirty_rect(@graphics.PixelRect::new(x=3, y=0, width=1, height=1))
  let surface = NativeSurface::new(42, 2, 1).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })

  let submit_plan = surface.dirty_frame_submit_plan(frame)
  assert_true(
    submit_plan.get_state() == @graphics.DirtySubmitState::DirtyClippedAway,
  )
  assert_true(submit_plan.has_dirty())
  assert_true(!submit_plan.needs_present())
  assert_eq(submit_plan.get_present_rect_count(), 0)
  assert_eq(submit_plan.get_present_pixel_count(), 0)
  assert_eq(submit_plan.get_present_byte_count(), 0)
  assert_true(!submit_plan.saves_full_present_pixels(2, 1))
  assert_true(
    submit_plan.get_present_strategy(2, 1) ==
    @graphics.DirtyPresentStrategy::Skip,
  )
  assert_true(
    submit_plan.get_present_plan().get_mode() ==
    @graphics.DirtyPresentPlanMode::Empty,
  )
  assert_true(
    surface.dirty_frame_present_strategy(frame) ==
    @graphics.DirtyPresentStrategy::Skip,
  )
  assert_eq(count.val, 0)
  assert_true(frame.has_dirty())
}

///|
test "NativeSurface submits dirty frames with scheduler result" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, @graphics.Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))
  let surface = NativeSurface::from_frame(42, frame).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })

  match surface.submit_frame_dirty(frame) {
    Ok(result) => {
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_true(result.has_dirty())
      assert_true(result.needs_present())
      assert_true(result.did_present())
      assert_true(!result.was_clipped_away())
      assert_eq(result.get_present_pixel_count(), 1)
      assert_eq(result.get_present_byte_count(), 4)
      assert_true(result.saves_full_present_pixels(2, 1))
      assert_true(
        result.get_present_strategy(2, 1) ==
        @graphics.DirtyPresentStrategy::Partial,
      )
    }
    Err(_) => abort("expected dirty submit result")
  }
  assert_eq(count.val, 1)
  assert_true(!frame.has_dirty())
  assert_true(
    surface.dirty_frame_present_strategy(frame) ==
    @graphics.DirtyPresentStrategy::Skip,
  )

  match surface.submit_frame_dirty(frame) {
    Ok(result) => {
      assert_true(result.get_state() == @graphics.DirtySubmitState::Clean)
      assert_eq(result.get_presented_rect_count(), 0)
      assert_true(!result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(!result.did_present())
      assert_eq(result.get_present_pixel_count(), 0)
      assert_eq(result.get_present_byte_count(), 0)
      assert_true(!result.saves_full_present_pixels(2, 1))
      assert_true(
        result.get_present_strategy(2, 1) ==
        @graphics.DirtyPresentStrategy::Skip,
      )
    }
    Err(_) => abort("expected clean submit result")
  }
  assert_eq(count.val, 1)
}

///|
test "NativeSurface submits frames by present strategy" {
  let partial_count = Ref(0)
  let partial_frame = @graphics.RenderFrame::new(4, 1)
  partial_frame.mark_dirty_rect(
    @graphics.PixelRect::new(x=1, y=0, width=1, height=1),
  )
  let partial_surface = NativeSurface::from_frame(42, partial_frame).with_pre_present_hook(fn() {
      partial_count.val = partial_count.val + 1
    },
  )

  let partial_plan = partial_surface.dirty_frame_submit_by_strategy_plan(
    partial_frame,
  )
  assert_true(
    partial_plan.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(partial_plan.get_state() == @graphics.DirtySubmitState::Present)
  assert_true(partial_plan.has_dirty())
  assert_true(partial_plan.needs_present())
  assert_true(!partial_plan.was_clipped_away())
  assert_true(!partial_plan.uses_bounds_fallback())
  assert_true(
    partial_plan.get_dirty_bounds() ==
    Some(@graphics.PixelRect::new(x=1, y=0, width=1, height=1)),
  )
  assert_eq(partial_plan.get_present_rect_count(), 1)
  assert_eq(partial_plan.get_present_pixel_count(), 1)
  assert_eq(partial_plan.get_present_byte_count(), 4)
  assert_true(partial_plan.saves_full_present_pixels())
  assert_eq(partial_count.val, 0)
  assert_true(partial_frame.has_dirty())

  match partial_surface.submit_frame_by_strategy(partial_frame) {
    Ok(result) => {
      assert_true(
        result.get_submit_plan().get_present_strategy() ==
        partial_plan.get_present_strategy(),
      )
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Partial,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.has_dirty())
      assert_true(result.needs_present())
      assert_true(!result.was_clipped_away())
      assert_true(!result.uses_bounds_fallback())
      assert_true(
        result.get_dirty_bounds() ==
        Some(@graphics.PixelRect::new(x=1, y=0, width=1, height=1)),
      )
      assert_true(result.did_present())
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 1)
      assert_eq(result.get_present_byte_count(), 4)
      assert_true(result.saves_full_present_pixels())
    }
    Err(_) => abort("expected partial strategy submit result")
  }
  assert_eq(partial_count.val, 1)
  assert_true(!partial_frame.has_dirty())

  let full_count = Ref(0)
  let full_frame = @graphics.RenderFrame::new(2, 1)
  full_frame.mark_all_dirty()
  let full_surface = NativeSurface::from_frame(42, full_frame).with_pre_present_hook(fn() {
      full_count.val = full_count.val + 1
    },
  )

  let full_plan = full_surface.dirty_frame_submit_by_strategy_plan(full_frame)
  assert_true(
    full_plan.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(full_plan.get_state() == @graphics.DirtySubmitState::Present)
  assert_true(full_plan.has_dirty())
  assert_true(full_plan.needs_present())
  assert_true(!full_plan.was_clipped_away())
  assert_true(!full_plan.uses_bounds_fallback())
  assert_true(
    full_plan.get_dirty_bounds() ==
    Some(@graphics.PixelRect::new(x=0, y=0, width=2, height=1)),
  )
  assert_eq(full_plan.get_present_rect_count(), 1)
  assert_eq(full_plan.get_present_pixel_count(), 2)
  assert_eq(full_plan.get_present_byte_count(), 8)
  assert_true(!full_plan.saves_full_present_pixels())
  assert_eq(full_count.val, 0)
  assert_true(full_frame.has_dirty())

  match full_surface.submit_frame_by_strategy(full_frame) {
    Ok(result) => {
      assert_true(
        result.get_submit_plan().get_present_strategy() ==
        full_plan.get_present_strategy(),
      )
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.has_dirty())
      assert_true(result.needs_present())
      assert_true(!result.was_clipped_away())
      assert_true(!result.uses_bounds_fallback())
      assert_true(
        result.get_dirty_bounds() ==
        Some(@graphics.PixelRect::new(x=0, y=0, width=2, height=1)),
      )
      assert_true(result.did_present())
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 2)
      assert_eq(result.get_present_byte_count(), 8)
      assert_true(!result.saves_full_present_pixels())
    }
    Err(_) => abort("expected full strategy submit result")
  }
  assert_eq(full_count.val, 1)
  assert_true(!full_frame.has_dirty())

  let bounds_count = Ref(0)
  let bounds_frame = @graphics.RenderFrame::new(8, 1).set_dirty_rect_limit(2)
  bounds_frame.mark_dirty_rect(
    @graphics.PixelRect::new(x=0, y=0, width=1, height=1),
  )
  bounds_frame.mark_dirty_rect(
    @graphics.PixelRect::new(x=3, y=0, width=1, height=1),
  )
  bounds_frame.mark_dirty_rect(
    @graphics.PixelRect::new(x=6, y=0, width=1, height=1),
  )
  let bounds_surface = NativeSurface::from_frame(42, bounds_frame).with_pre_present_hook(fn() {
      bounds_count.val = bounds_count.val + 1
    },
  )

  let bounds_plan = bounds_surface.dirty_frame_submit_by_strategy_plan(
    bounds_frame,
  )
  assert_true(
    bounds_plan.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(bounds_plan.get_state() == @graphics.DirtySubmitState::Present)
  assert_true(bounds_plan.has_dirty())
  assert_true(bounds_plan.needs_present())
  assert_true(!bounds_plan.was_clipped_away())
  assert_true(bounds_plan.uses_bounds_fallback())
  assert_true(
    bounds_plan.get_dirty_bounds() ==
    Some(@graphics.PixelRect::new(x=0, y=0, width=7, height=1)),
  )
  assert_eq(bounds_plan.get_present_rect_count(), 1)
  assert_eq(bounds_plan.get_present_pixel_count(), 7)
  assert_eq(bounds_plan.get_present_byte_count(), 28)
  assert_true(bounds_plan.saves_full_present_pixels())
  assert_eq(bounds_count.val, 0)
  assert_true(bounds_frame.has_dirty())

  match bounds_surface.submit_frame_by_strategy(bounds_frame) {
    Ok(result) => {
      assert_true(
        result.get_submit_plan().uses_bounds_fallback() ==
        bounds_plan.uses_bounds_fallback(),
      )
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Partial,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.has_dirty())
      assert_true(result.needs_present())
      assert_true(!result.was_clipped_away())
      assert_true(result.uses_bounds_fallback())
      assert_true(
        result.get_dirty_bounds() ==
        Some(@graphics.PixelRect::new(x=0, y=0, width=7, height=1)),
      )
      assert_true(result.did_present())
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 7)
      assert_eq(result.get_present_byte_count(), 28)
      assert_true(result.saves_full_present_pixels())
    }
    Err(_) => abort("expected bounds fallback strategy submit result")
  }
  assert_eq(bounds_count.val, 1)
  assert_true(!bounds_frame.has_dirty())

  let clean_count = Ref(0)
  let clean_frame = @graphics.RenderFrame::new(2, 1)
  let clean_surface = NativeSurface::from_frame(42, clean_frame).with_pre_present_hook(fn() {
      clean_count.val = clean_count.val + 1
    },
  )
  let clean_plan = clean_surface.dirty_frame_submit_by_strategy_plan(
    clean_frame,
  )
  assert_true(
    clean_plan.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
  )
  assert_true(clean_plan.get_state() == @graphics.DirtySubmitState::Clean)
  assert_true(!clean_plan.has_dirty())
  assert_true(!clean_plan.needs_present())
  assert_true(!clean_plan.was_clipped_away())
  assert_true(!clean_plan.uses_bounds_fallback())
  assert_true(clean_plan.get_dirty_bounds() == None)
  assert_eq(clean_plan.get_present_rect_count(), 0)
  assert_eq(clean_plan.get_present_pixel_count(), 0)
  assert_eq(clean_plan.get_present_byte_count(), 0)
  assert_true(!clean_plan.saves_full_present_pixels())
  assert_eq(clean_count.val, 0)
  match clean_surface.submit_frame_by_strategy(clean_frame) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Clean)
      assert_true(!result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(!result.was_clipped_away())
      assert_true(!result.uses_bounds_fallback())
      assert_true(result.get_dirty_bounds() == None)
      assert_true(!result.did_present())
      assert_eq(result.get_present_rect_count(), 0)
      assert_eq(result.get_presented_rect_count(), 0)
      assert_eq(result.get_present_pixel_count(), 0)
      assert_eq(result.get_present_byte_count(), 0)
      assert_true(!result.saves_full_present_pixels())
    }
    Err(_) => abort("expected clean strategy submit result")
  }
  assert_eq(clean_count.val, 0)
  assert_true(!clean_frame.has_dirty())
}

///|
test "NativeSurface strategy submit consumes clipped-away dirty without presenting" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.mark_dirty_rect(@graphics.PixelRect::new(x=3, y=0, width=1, height=1))
  let surface = NativeSurface::new(42, 2, 1).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })

  let submit_plan = surface.dirty_frame_submit_by_strategy_plan(frame)
  assert_true(
    submit_plan.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
  )
  assert_true(
    submit_plan.get_state() == @graphics.DirtySubmitState::DirtyClippedAway,
  )
  assert_true(submit_plan.has_dirty())
  assert_true(!submit_plan.needs_present())
  assert_true(submit_plan.was_clipped_away())
  assert_true(!submit_plan.uses_bounds_fallback())
  assert_true(
    submit_plan.get_dirty_bounds() ==
    Some(@graphics.PixelRect::new(x=3, y=0, width=1, height=1)),
  )
  assert_eq(submit_plan.get_present_rect_count(), 0)
  assert_eq(submit_plan.get_present_pixel_count(), 0)
  assert_eq(submit_plan.get_present_byte_count(), 0)
  assert_true(!submit_plan.saves_full_present_pixels())
  assert_eq(count.val, 0)
  assert_true(frame.has_dirty())

  match surface.submit_frame_by_strategy(frame) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
      )
      assert_true(
        result.get_state() == @graphics.DirtySubmitState::DirtyClippedAway,
      )
      assert_true(result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(result.was_clipped_away())
      assert_true(!result.uses_bounds_fallback())
      assert_true(
        result.get_dirty_bounds() ==
        Some(@graphics.PixelRect::new(x=3, y=0, width=1, height=1)),
      )
      assert_true(!result.did_present())
      assert_eq(result.get_present_rect_count(), 0)
      assert_eq(result.get_presented_rect_count(), 0)
      assert_eq(result.get_present_pixel_count(), 0)
      assert_eq(result.get_present_byte_count(), 0)
      assert_true(!result.saves_full_present_pixels())
    }
    Err(_) => abort("expected clipped-away strategy submit result")
  }
  assert_eq(count.val, 0)
  assert_true(!frame.has_dirty())
}

///|
test "NativeSurface exposes dry-run frame schedule actions" {
  let partial_count = Ref(0)
  let partial_frame = @graphics.RenderFrame::new(4, 1)
  partial_frame.mark_dirty_rect(
    @graphics.PixelRect::new(x=1, y=0, width=1, height=1),
  )
  let partial_surface = NativeSurface::from_frame(42, partial_frame).with_pre_present_hook(fn() {
      partial_count.val = partial_count.val + 1
    },
  )
  let partial_schedule = partial_surface.frame_schedule(partial_frame)
  assert_true(
    partial_schedule.get_action() == NativeFrameScheduleAction::Present,
  )
  assert_true(partial_schedule.should_submit())
  assert_true(partial_schedule.needs_present())
  assert_true(partial_schedule.has_dirty())
  assert_true(!partial_schedule.was_clipped_away())
  assert_true(!partial_schedule.uses_bounds_fallback())
  assert_true(
    partial_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(
    partial_schedule.get_state() == @graphics.DirtySubmitState::Present,
  )
  assert_true(
    partial_schedule.get_dirty_bounds() ==
    Some(@graphics.PixelRect::new(x=1, y=0, width=1, height=1)),
  )
  assert_eq(partial_schedule.get_present_rect_count(), 1)
  assert_eq(partial_schedule.get_present_pixel_count(), 1)
  assert_eq(partial_schedule.get_present_byte_count(), 4)
  assert_true(partial_schedule.saves_full_present_pixels())
  assert_eq(partial_count.val, 0)
  assert_true(partial_frame.has_dirty())

  let clipped_frame = @graphics.RenderFrame::new(4, 1)
  clipped_frame.mark_dirty_rect(
    @graphics.PixelRect::new(x=3, y=0, width=1, height=1),
  )
  let clipped_surface = NativeSurface::new(42, 2, 1).with_pre_present_hook(fn() {
    partial_count.val = partial_count.val + 1
  })
  let clipped_schedule = clipped_surface.frame_schedule(clipped_frame)
  assert_true(
    clipped_schedule.get_action() ==
    NativeFrameScheduleAction::SubmitWithoutPresent,
  )
  assert_true(clipped_schedule.should_submit())
  assert_true(!clipped_schedule.needs_present())
  assert_true(clipped_schedule.has_dirty())
  assert_true(clipped_schedule.was_clipped_away())
  assert_true(
    clipped_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Skip,
  )
  assert_true(
    clipped_schedule.get_state() == @graphics.DirtySubmitState::DirtyClippedAway,
  )
  assert_eq(clipped_schedule.get_present_rect_count(), 0)
  assert_eq(clipped_schedule.get_present_pixel_count(), 0)
  assert_eq(clipped_schedule.get_present_byte_count(), 0)
  assert_true(!clipped_schedule.saves_full_present_pixels())
  assert_eq(partial_count.val, 0)
  assert_true(clipped_frame.has_dirty())

  let clean_frame = @graphics.RenderFrame::new(2, 1)
  let clean_schedule = NativeSurface::from_frame(42, clean_frame).frame_schedule(
    clean_frame,
  )
  assert_true(clean_schedule.get_action() == NativeFrameScheduleAction::Skip)
  assert_true(!clean_schedule.should_submit())
  assert_true(!clean_schedule.needs_present())
  assert_true(!clean_schedule.has_dirty())
  assert_true(clean_schedule.get_dirty_bounds() == None)
  assert_true(
    clean_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Skip,
  )
  assert_true(clean_schedule.get_state() == @graphics.DirtySubmitState::Clean)
}

///|
test "NativeSurface exposes clean redraw schedule as full cached present" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(2, 1)
  layer.clear(@graphics.Color::white())
  layer.get_canvas().draw_pixel(1, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))
  assert_true(
    frame.present_dirty_to(@graphics.MemorySurface::new(2, 1)) == Ok(1),
  )
  assert_true(!frame.has_dirty())

  let surface = NativeSurface::from_frame(42, frame).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })
  let regular_schedule = surface.frame_schedule(frame)
  assert_true(regular_schedule.get_action() == NativeFrameScheduleAction::Skip)
  assert_true(!regular_schedule.needs_present())
  assert_true(
    regular_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Skip,
  )

  let redraw_schedule = surface.frame_redraw_schedule(frame)
  assert_true(
    redraw_schedule.get_action() == NativeFrameScheduleAction::Present,
  )
  assert_true(redraw_schedule.should_submit())
  assert_true(redraw_schedule.needs_present())
  assert_true(!redraw_schedule.has_dirty())
  assert_true(
    redraw_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(redraw_schedule.get_state() == @graphics.DirtySubmitState::Clean)
  assert_true(redraw_schedule.get_dirty_bounds() == None)
  assert_eq(redraw_schedule.get_present_rect_count(), 1)
  assert_eq(redraw_schedule.get_present_pixel_count(), 2)
  assert_eq(redraw_schedule.get_present_byte_count(), 8)
  assert_true(!redraw_schedule.saves_full_present_pixels())
  assert_eq(count.val, 0)
  assert_true(!frame.has_dirty())
}

///|
test "NativeSurface exposes policy-driven frame schedules" {
  let clean_frame = @graphics.RenderFrame::new(2, 1)
  let clean_surface = NativeSurface::from_frame(42, clean_frame)
  let dirty_only_schedule = clean_surface.frame_schedule_by_policy(
    clean_frame,
    NativeFrameSubmitPolicy::DirtyOnly,
  )
  assert_true(
    dirty_only_schedule.get_action() == NativeFrameScheduleAction::Skip,
  )
  assert_true(
    dirty_only_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Skip,
  )
  assert_true(
    dirty_only_schedule.get_state() == @graphics.DirtySubmitState::Clean,
  )
  assert_true(!dirty_only_schedule.needs_present())

  let cached_schedule = clean_surface.frame_schedule_by_policy(
    clean_frame,
    NativeFrameSubmitPolicy::CachedRedraw,
  )
  assert_true(
    cached_schedule.get_action() == NativeFrameScheduleAction::Present,
  )
  assert_true(
    cached_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(cached_schedule.get_state() == @graphics.DirtySubmitState::Clean)
  assert_true(cached_schedule.needs_present())
  assert_true(!cached_schedule.has_dirty())
  assert_eq(cached_schedule.get_present_pixel_count(), 2)
  assert_eq(cached_schedule.get_present_byte_count(), 8)

  let dirty_frame = @graphics.RenderFrame::new(4, 1)
  dirty_frame.get_canvas().draw_pixel(1, 0, @graphics.Color::red())
  let dirty_surface = NativeSurface::from_frame(42, dirty_frame)
  let cached_dirty_schedule = dirty_surface.frame_schedule_by_policy(
    dirty_frame,
    NativeFrameSubmitPolicy::CachedRedraw,
  )
  assert_true(
    cached_dirty_schedule.get_action() == NativeFrameScheduleAction::Present,
  )
  assert_true(
    cached_dirty_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(
    cached_dirty_schedule.get_state() == @graphics.DirtySubmitState::Present,
  )
  assert_true(cached_dirty_schedule.has_dirty())
  assert_eq(cached_dirty_schedule.get_present_pixel_count(), 1)
  assert_eq(cached_dirty_schedule.get_present_byte_count(), 4)

  let full_dirty_schedule = dirty_surface.frame_schedule_by_policy(
    dirty_frame,
    NativeFrameSubmitPolicy::FullRedraw,
  )
  assert_true(
    full_dirty_schedule.get_action() == NativeFrameScheduleAction::Present,
  )
  assert_true(
    full_dirty_schedule.get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(
    full_dirty_schedule.get_state() == @graphics.DirtySubmitState::Present,
  )
  assert_true(full_dirty_schedule.has_dirty())
  assert_true(full_dirty_schedule.needs_present())
  assert_eq(full_dirty_schedule.get_present_rect_count(), 1)
  assert_eq(full_dirty_schedule.get_present_pixel_count(), 4)
  assert_eq(full_dirty_schedule.get_present_byte_count(), 16)
  assert_true(!full_dirty_schedule.saves_full_present_pixels())
  assert_true(dirty_frame.has_dirty())
}

///|
test "NativeSurface submits precomputed frame schedules" {
  let count = Ref(0)
  let partial_frame = @graphics.RenderFrame::new(4, 1)
  partial_frame.get_canvas().draw_pixel(1, 0, @graphics.Color::red())
  let partial_surface = NativeSurface::from_frame(42, partial_frame).with_pre_present_hook(fn() {
      count.val = count.val + 1
    },
  )
  let partial_schedule = partial_surface.frame_schedule(partial_frame)
  match partial_surface.submit_frame_schedule(partial_frame, partial_schedule) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Partial,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.did_present())
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 1)
      assert_eq(result.get_present_byte_count(), 4)
      assert_true(result.saves_full_present_pixels())
    }
    Err(_) => abort("expected scheduled partial submit result")
  }
  assert_eq(count.val, 1)
  assert_true(!partial_frame.has_dirty())

  let clipped_frame = @graphics.RenderFrame::new(4, 1)
  clipped_frame.mark_dirty_rect(
    @graphics.PixelRect::new(x=3, y=0, width=1, height=1),
  )
  let clipped_surface = NativeSurface::new(42, 2, 1).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })
  let clipped_schedule = clipped_surface.frame_schedule(clipped_frame)
  match clipped_surface.submit_frame_schedule(clipped_frame, clipped_schedule) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
      )
      assert_true(
        result.get_state() == @graphics.DirtySubmitState::DirtyClippedAway,
      )
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
    Err(_) => abort("expected scheduled clipped submit result")
  }
  assert_eq(count.val, 1)
  assert_true(!clipped_frame.has_dirty())

  let clean_frame = @graphics.RenderFrame::new(2, 1)
  let clean_surface = NativeSurface::from_frame(42, clean_frame).with_pre_present_hook(fn() {
      count.val = count.val + 1
    },
  )
  let clean_schedule = clean_surface.frame_schedule(clean_frame)
  match clean_surface.submit_frame_schedule(clean_frame, clean_schedule) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Clean)
      assert_true(!result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(!result.did_present())
      assert_eq(result.get_presented_rect_count(), 0)
      assert_eq(result.get_present_pixel_count(), 0)
      assert_eq(result.get_present_byte_count(), 0)
    }
    Err(_) => abort("expected scheduled clean submit result")
  }
  assert_eq(count.val, 1)
  assert_true(!clean_frame.has_dirty())
}

///|
test "NativeSurface submits clean redraw as cached full present" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(2, 1)
  layer.clear(@graphics.Color::white())
  layer.get_canvas().draw_pixel(1, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))
  assert_true(
    frame.present_dirty_to(@graphics.MemorySurface::new(2, 1)) == Ok(1),
  )
  assert_true(!frame.has_dirty())

  let surface = NativeSurface::from_frame(42, frame).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })
  match surface.submit_frame_redraw(frame) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Clean)
      assert_true(!result.has_dirty())
      assert_true(result.needs_present())
      assert_true(result.did_present())
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 2)
      assert_eq(result.get_present_byte_count(), 8)
      assert_true(!result.saves_full_present_pixels())
    }
    Err(_) => abort("expected redraw submit result")
  }
  assert_eq(count.val, 1)
  assert_true(!frame.has_dirty())
}

///|
test "NativeSurface submits frame by explicit policy" {
  let count = Ref(0)
  let dirty_frame = @graphics.RenderFrame::new(4, 1)
  dirty_frame.get_canvas().draw_pixel(1, 0, @graphics.Color::red())
  let dirty_surface = NativeSurface::from_frame(42, dirty_frame).with_pre_present_hook(fn() {
      count.val = count.val + 1
    },
  )

  match
    dirty_surface.submit_frame_by_policy(
      dirty_frame,
      NativeFrameSubmitPolicy::FullRedraw,
    ) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.has_dirty())
      assert_true(result.did_present())
      assert_eq(result.get_present_rect_count(), 1)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 4)
      assert_eq(result.get_present_byte_count(), 16)
    }
    Err(_) => abort("expected policy submit result")
  }
  assert_eq(count.val, 1)
  assert_true(!dirty_frame.has_dirty())

  let clean_frame = @graphics.RenderFrame::new(2, 1)
  let clean_surface = NativeSurface::from_frame(42, clean_frame).with_pre_present_hook(fn() {
      count.val = count.val + 1
    },
  )
  match
    clean_surface.submit_frame_by_policy(
      clean_frame,
      NativeFrameSubmitPolicy::DirtyOnly,
    ) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Clean)
      assert_true(!result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(!result.did_present())
      assert_eq(result.get_presented_rect_count(), 0)
    }
    Err(_) => abort("expected dirty-only policy submit result")
  }
  assert_eq(count.val, 1)
}

///|
test "NativeSurface submit requests preserve policy and schedule decisions" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.get_canvas().draw_pixel(1, 0, @graphics.Color::red())
  let surface = NativeSurface::from_frame(42, frame).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })

  let request = surface.frame_submit_request_by_policy(
    frame,
    NativeFrameSubmitPolicy::FullRedraw,
  )
  assert_true(request.get_policy() == NativeFrameSubmitPolicy::FullRedraw)
  assert_true(request.get_action() == NativeFrameScheduleAction::Present)
  assert_true(request.should_submit())
  assert_true(request.needs_present())
  assert_true(request.has_dirty())
  assert_true(!request.was_clipped_away())
  assert_true(!request.uses_bounds_fallback())
  assert_true(
    request.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(request.get_state() == @graphics.DirtySubmitState::Present)
  assert_true(
    request.get_dirty_bounds() ==
    Some(@graphics.PixelRect::new(x=1, y=0, width=1, height=1)),
  )
  assert_true(
    request.to_render_frame_submit_request().get_policy() ==
    @graphics.RenderFrameSubmitPolicy::FullRedraw,
  )
  assert_true(
    request.get_schedule().get_submit_plan().get_present_strategy() ==
    @graphics.DirtyPresentStrategy::Full,
  )
  assert_eq(request.get_present_rect_count(), 1)
  assert_eq(request.get_present_pixel_count(), 4)
  assert_eq(request.get_present_byte_count(), 16)
  assert_true(!request.saves_full_present_pixels())
  assert_eq(count.val, 0)
  assert_true(frame.has_dirty())

  match surface.submit_frame_request(frame, request) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.did_present())
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 4)
      assert_eq(result.get_present_byte_count(), 16)
    }
    Err(_) => abort("expected native submit request result")
  }
  assert_eq(count.val, 1)
  assert_true(!frame.has_dirty())

  let clean_frame = @graphics.RenderFrame::new(2, 1)
  let clean_surface = NativeSurface::from_frame(42, clean_frame).with_pre_present_hook(fn() {
      count.val = count.val + 1
    },
  )
  let clean_schedule = clean_surface.frame_schedule_by_policy(
    clean_frame,
    NativeFrameSubmitPolicy::DirtyOnly,
  )
  let clean_request = NativeFrameSubmitRequest::new(
    NativeFrameSubmitPolicy::DirtyOnly,
    clean_schedule,
  )
  assert_true(clean_request.get_policy() == NativeFrameSubmitPolicy::DirtyOnly)
  assert_true(clean_request.get_action() == NativeFrameScheduleAction::Skip)
  assert_true(!clean_request.should_submit())
  assert_true(!clean_request.needs_present())
  assert_true(!clean_request.has_dirty())
  assert_true(clean_request.get_dirty_bounds() == None)
  match clean_surface.submit_frame_request(clean_frame, clean_request) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Skip,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Clean)
      assert_true(!result.did_present())
      assert_eq(result.get_presented_rect_count(), 0)
    }
    Err(_) => abort("expected clean native submit request result")
  }
  assert_eq(count.val, 1)
}

///|
test "NativeSurface dirty submit skips clipped-away presents" {
  let count = Ref(0)
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.mark_dirty_rect(@graphics.PixelRect::new(x=3, y=0, width=1, height=1))
  let surface = NativeSurface::new(42, 2, 1).with_pre_present_hook(fn() {
    count.val = count.val + 1
  })

  match surface.submit_frame_dirty(frame) {
    Ok(result) => {
      assert_true(
        result.get_state() == @graphics.DirtySubmitState::DirtyClippedAway,
      )
      assert_eq(result.get_presented_rect_count(), 0)
      assert_true(result.has_dirty())
      assert_true(!result.needs_present())
      assert_true(!result.did_present())
      assert_eq(result.get_present_pixel_count(), 0)
      assert_eq(result.get_present_byte_count(), 0)
      assert_true(!result.saves_full_present_pixels(2, 1))
      assert_true(
        result.get_present_strategy(2, 1) ==
        @graphics.DirtyPresentStrategy::Skip,
      )
      assert_true(result.was_clipped_away())
    }
    Err(_) => abort("expected clipped-away submit result")
  }
  assert_eq(count.val, 0)
  assert_true(!frame.has_dirty())
}

///|
test "render frame strategy submit helper constructs NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, @graphics.Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  let plan = dirty_render_frame_submit_by_strategy_plan(42, frame)
  assert_true(
    plan.get_present_strategy() == @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(plan.get_state() == @graphics.DirtySubmitState::Present)
  assert_eq(plan.get_present_pixel_count(), 1)
  assert_eq(plan.get_present_byte_count(), 4)
  assert_true(plan.saves_full_present_pixels())
  assert_true(frame.has_dirty())

  match submit_render_frame_by_strategy(42, frame) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Partial,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.did_present())
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 1)
      assert_eq(result.get_present_byte_count(), 4)
      assert_true(result.saves_full_present_pixels())
    }
    Err(_) => abort("expected constructed strategy submit result")
  }
  assert_true(!frame.has_dirty())
}

///|
test "render frame schedule helper constructs NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, @graphics.Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  let schedule = render_frame_schedule(42, frame)
  assert_true(schedule.get_action() == NativeFrameScheduleAction::Present)
  assert_true(schedule.should_submit())
  assert_true(schedule.needs_present())
  assert_true(
    schedule.get_present_strategy() == @graphics.DirtyPresentStrategy::Partial,
  )
  assert_true(schedule.get_state() == @graphics.DirtySubmitState::Present)
  assert_eq(schedule.get_present_rect_count(), 1)
  assert_eq(schedule.get_present_pixel_count(), 1)
  assert_eq(schedule.get_present_byte_count(), 4)
  assert_true(schedule.saves_full_present_pixels())
  assert_true(frame.has_dirty())
}

///|
test "render frame redraw helper constructs NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(2, 1)
  layer.clear(@graphics.Color::white())
  layer.get_canvas().draw_pixel(1, 0, @graphics.Color::blue())
  ignore(frame.get_layer_tree().add_layer(layer))
  assert_true(
    frame.present_dirty_to(@graphics.MemorySurface::new(2, 1)) == Ok(1),
  )
  assert_true(!frame.has_dirty())

  let schedule = render_frame_redraw_schedule(42, frame)
  assert_true(schedule.get_action() == NativeFrameScheduleAction::Present)
  assert_true(schedule.should_submit())
  assert_true(schedule.needs_present())
  assert_true(!schedule.has_dirty())
  assert_true(
    schedule.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(schedule.get_state() == @graphics.DirtySubmitState::Clean)
  assert_eq(schedule.get_present_rect_count(), 1)
  assert_eq(schedule.get_present_pixel_count(), 2)
  assert_eq(schedule.get_present_byte_count(), 8)

  match submit_render_frame_redraw(42, frame) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Clean)
      assert_true(result.did_present())
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 2)
      assert_eq(result.get_present_byte_count(), 8)
    }
    Err(_) => abort("expected constructed redraw submit result")
  }
  assert_true(!frame.has_dirty())
}

///|
test "render frame policy helpers construct NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.get_canvas().draw_pixel(1, 0, @graphics.Color::red())

  let schedule = render_frame_schedule_by_policy(
    42,
    frame,
    NativeFrameSubmitPolicy::FullRedraw,
  )
  assert_true(schedule.get_action() == NativeFrameScheduleAction::Present)
  assert_true(
    schedule.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(schedule.get_state() == @graphics.DirtySubmitState::Present)
  assert_true(schedule.has_dirty())
  assert_eq(schedule.get_present_pixel_count(), 4)
  assert_eq(schedule.get_present_byte_count(), 16)

  match
    submit_render_frame_by_policy(
      42,
      frame,
      NativeFrameSubmitPolicy::FullRedraw,
    ) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.did_present())
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 4)
      assert_eq(result.get_present_byte_count(), 16)
    }
    Err(_) => abort("expected constructed policy submit result")
  }
  assert_true(!frame.has_dirty())
}

///|
test "render frame submit request helpers construct NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(4, 1)
  frame.get_canvas().draw_pixel(1, 0, @graphics.Color::red())

  let request = render_frame_submit_request_by_policy(
    42,
    frame,
    NativeFrameSubmitPolicy::FullRedraw,
  )
  assert_true(request.get_policy() == NativeFrameSubmitPolicy::FullRedraw)
  assert_true(request.get_action() == NativeFrameScheduleAction::Present)
  assert_true(
    request.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
  )
  assert_true(request.get_state() == @graphics.DirtySubmitState::Present)
  assert_true(request.has_dirty())
  assert_eq(request.get_present_pixel_count(), 4)
  assert_eq(request.get_present_byte_count(), 16)
  assert_true(frame.has_dirty())

  match submit_render_frame_request(42, frame, request) {
    Ok(result) => {
      assert_true(
        result.get_present_strategy() == @graphics.DirtyPresentStrategy::Full,
      )
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_true(result.did_present())
      assert_eq(result.get_presented_rect_count(), 1)
      assert_eq(result.get_present_pixel_count(), 4)
      assert_eq(result.get_present_byte_count(), 16)
    }
    Err(_) => abort("expected constructed submit request result")
  }
  assert_true(!frame.has_dirty())
}

///|
test "render frame dirty batch helper constructs NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, @graphics.Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  match dirty_render_frame_present_batch(42, frame) {
    Ok(batch) => {
      assert_eq(batch.get_rect_count(), 1)
      assert_eq(batch.get_present_pixel_count(), 1)
      assert_eq(batch.get_present_byte_count(), 4)
      let payloads = batch.get_payloads()
      assert_true(
        payloads[0].get_rect() ==
        @graphics.PixelRect::new(x=1, y=0, width=1, height=1),
      )
      let pixels = payloads[0].get_pixels()
      assert_eq(pixels.length(), 4)
      assert_eq(pixels[0], @graphics.Color::red().r)
    }
    Err(_) => abort("expected constructed dirty present batch")
  }
  assert_true(frame.has_dirty())
}

///|
test "render frame present helpers construct NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, @graphics.Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  assert_true(present_render_frame_dirty(42, frame) == Ok(1))
  assert_true(!frame.has_dirty())
  assert_true(present_render_frame_dirty(42, frame) == Ok(0))
  assert_true(present_render_frame_all(42, frame) == Ok(1))
}

///|
test "render frame submit helper constructs NativeSurface internally" {
  let frame = @graphics.RenderFrame::new(2, 1)
  let layer = @graphics.Layer::new(1, 1).set_position(1, 0)
  layer.get_canvas().draw_pixel(0, 0, @graphics.Color::red())
  ignore(frame.get_layer_tree().add_layer(layer))

  match submit_render_frame_dirty(42, frame) {
    Ok(result) => {
      assert_true(result.get_state() == @graphics.DirtySubmitState::Present)
      assert_eq(result.get_presented_rect_count(), 1)
      assert_true(result.did_present())
      assert_eq(result.get_present_pixel_count(), 1)
      assert_eq(result.get_present_byte_count(), 4)
    }
    Err(_) => abort("expected constructed dirty submit result")
  }
  assert_true(!frame.has_dirty())
}
