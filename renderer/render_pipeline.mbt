///|
/// Replayable CPU render command.
pub enum RenderCommand {
  Clear(@graphics.Color)
  FillRect(Double, Double, Double, Double, @graphics.Paint)
  StrokeRect(Double, Double, Double, Double, @graphics.Paint)
  FillPath(@graphics.Path, @graphics.Paint)
  StrokePath(@graphics.Path, @graphics.Paint)
  DrawPixmap(@graphics.Pixmap, Int, Int, @graphics.Paint)
  DrawPixmapRect(
    @graphics.Pixmap,
    @graphics.PixelRect,
    Int,
    Int,
    @graphics.Paint
  )
  DrawTextFace(
    @text.FontFace,
    String,
    Double,
    Double,
    @text.LayoutConfig,
    @graphics.Paint
  )
} derive(Debug)

///|
/// Ordered list of CPU render commands.
pub struct RenderPipeline {
  commands : Array[RenderCommand]
} derive(Debug)

///|
/// Telemetry returned after replaying a render pipeline.
pub struct RenderPipelineReplayResult {
  command_count : Int
  clear_count : Int
  fill_count : Int
  stroke_count : Int
  image_count : Int
  text_count : Int
} derive(Eq, Debug)

///|
/// Conservative CPU-side analysis of a render pipeline before replay.
pub struct RenderPipelineAnalysis {
  command_count : Int
  clear_count : Int
  fill_count : Int
  stroke_count : Int
  image_count : Int
  text_count : Int
  dirty_region : @graphics.DirtyRegion
} derive(Debug)

///|
/// Conservative diff between two retained render pipelines.
pub struct RenderPipelineDiffResult {
  previous_command_count : Int
  next_command_count : Int
  retained_command_count : Int
  changed_command_count : Int
  inserted_command_count : Int
  removed_command_count : Int
  dirty_region : @graphics.DirtyRegion
} derive(Debug)

///|
/// Coarse command category used by CPU batch scheduling.
pub(all) enum RenderPipelineBatchKind {
  Clear
  Fill
  Stroke
  Image
  Text
} derive(Eq, Debug)

///|
/// One contiguous run of commands with the same scheduling category.
pub struct RenderPipelineBatch {
  kind : RenderPipelineBatchKind
  start_index : Int
  command_count : Int
  dirty_region : @graphics.DirtyRegion
} derive(Debug)

///|
/// Scheduler-facing grouping of a render pipeline into contiguous CPU batches.
pub struct RenderPipelineBatchPlan {
  command_count : Int
  batches : Array[RenderPipelineBatch]
  dirty_region : @graphics.DirtyRegion
} derive(Debug)

///|
/// Create an empty render pipeline.
pub fn RenderPipeline::new() -> RenderPipeline {
  { commands: [] }
}

///|
/// Return the number of queued commands.
pub fn RenderPipeline::len(self : RenderPipeline) -> Int {
  self.commands.length()
}

///|
/// Return whether this pipeline has no queued commands.
pub fn RenderPipeline::is_empty(self : RenderPipeline) -> Bool {
  self.len() is 0
}

///|
/// Return the queued commands.
pub fn RenderPipeline::get_commands(
  self : RenderPipeline,
) -> Array[RenderCommand] {
  self.commands
}

///|
/// Drop all queued commands.
pub fn RenderPipeline::clear_commands(self : RenderPipeline) -> Unit {
  self.commands.clear()
}

///|
/// Append an already constructed command.
pub fn RenderPipeline::push(
  self : RenderPipeline,
  command : RenderCommand,
) -> RenderPipeline {
  self.commands.push(command)
  self
}

///|
/// Queue a canvas clear command.
pub fn RenderPipeline::clear_canvas(
  self : RenderPipeline,
  color : @graphics.Color,
) -> RenderPipeline {
  self.push(RenderCommand::Clear(color))
}

///|
/// Queue a filled rectangle command.
pub fn RenderPipeline::fill_rect(
  self : RenderPipeline,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::FillRect(x, y, width, height, paint))
}

///|
/// Queue a stroked rectangle command.
pub fn RenderPipeline::stroke_rect(
  self : RenderPipeline,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::StrokeRect(x, y, width, height, paint))
}

///|
/// Queue a filled path command.
pub fn RenderPipeline::fill_path(
  self : RenderPipeline,
  path : @graphics.Path,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::FillPath(path, paint))
}

///|
/// Queue a stroked path command.
pub fn RenderPipeline::stroke_path(
  self : RenderPipeline,
  path : @graphics.Path,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::StrokePath(path, paint))
}

///|
/// Queue a pixmap draw command.
pub fn RenderPipeline::draw_pixmap(
  self : RenderPipeline,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::DrawPixmap(pixmap, x, y, paint))
}

///|
/// Queue a source-rectangle pixmap draw command.
pub fn RenderPipeline::draw_pixmap_rect(
  self : RenderPipeline,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, paint))
}

///|
/// Queue a text draw command using an already parsed font face.
pub fn RenderPipeline::draw_text_face(
  self : RenderPipeline,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::DrawTextFace(face, text, x, y, config, paint))
}

///|
/// Return the number of commands replayed.
pub fn RenderPipelineReplayResult::get_command_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.command_count
}

///|
/// Return the number of clear commands replayed.
pub fn RenderPipelineReplayResult::get_clear_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.clear_count
}

///|
/// Return the number of fill commands replayed.
pub fn RenderPipelineReplayResult::get_fill_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.fill_count
}

///|
/// Return the number of stroke commands replayed.
pub fn RenderPipelineReplayResult::get_stroke_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.stroke_count
}

///|
/// Return the number of image commands replayed.
pub fn RenderPipelineReplayResult::get_image_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.image_count
}

///|
/// Return the number of text commands replayed.
pub fn RenderPipelineReplayResult::get_text_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.text_count
}

///|
/// Return the number of commands analyzed.
pub fn RenderPipelineAnalysis::get_command_count(
  self : RenderPipelineAnalysis,
) -> Int {
  self.command_count
}

///|
/// Return the number of clear commands analyzed.
pub fn RenderPipelineAnalysis::get_clear_count(
  self : RenderPipelineAnalysis,
) -> Int {
  self.clear_count
}

///|
/// Return the number of fill commands analyzed.
pub fn RenderPipelineAnalysis::get_fill_count(
  self : RenderPipelineAnalysis,
) -> Int {
  self.fill_count
}

///|
/// Return the number of stroke commands analyzed.
pub fn RenderPipelineAnalysis::get_stroke_count(
  self : RenderPipelineAnalysis,
) -> Int {
  self.stroke_count
}

///|
/// Return the number of image commands analyzed.
pub fn RenderPipelineAnalysis::get_image_count(
  self : RenderPipelineAnalysis,
) -> Int {
  self.image_count
}

///|
/// Return the number of text commands analyzed.
pub fn RenderPipelineAnalysis::get_text_count(
  self : RenderPipelineAnalysis,
) -> Int {
  self.text_count
}

///|
/// Return the conservative dirty region estimated for this pipeline.
pub fn RenderPipelineAnalysis::get_dirty_region(
  self : RenderPipelineAnalysis,
) -> @graphics.DirtyRegion {
  self.dirty_region
}

///|
/// Return whether analysis found any pixel area that may need presenting.
pub fn RenderPipelineAnalysis::has_dirty(self : RenderPipelineAnalysis) -> Bool {
  !self.dirty_region.is_empty()
}

///|
/// Return the number of conservative dirty rectangles estimated.
pub fn RenderPipelineAnalysis::get_dirty_rect_count(
  self : RenderPipelineAnalysis,
) -> Int {
  self.dirty_region.get_rect_count()
}

///|
/// Return the conservative dirty bounds estimated for this pipeline.
pub fn RenderPipelineAnalysis::get_dirty_bounds(
  self : RenderPipelineAnalysis,
) -> @graphics.PixelRect? {
  self.dirty_region.bounds()
}

///|
/// Build a present plan from the estimated dirty region.
pub fn RenderPipelineAnalysis::get_present_plan(
  self : RenderPipelineAnalysis,
  width : Int,
  height : Int,
  max_rects : Int,
) -> @graphics.DirtyPresentPlan {
  self.dirty_region.present_plan(
    @graphics.PixelRect::new(x=0, y=0, width~, height~),
    max_rects,
  )
}

///|
/// Return the number of commands in the previous display list.
pub fn RenderPipelineDiffResult::get_previous_command_count(
  self : RenderPipelineDiffResult,
) -> Int {
  self.previous_command_count
}

///|
/// Return the number of commands in the next display list.
pub fn RenderPipelineDiffResult::get_next_command_count(
  self : RenderPipelineDiffResult,
) -> Int {
  self.next_command_count
}

///|
/// Return the number of commands retained without dirtying their bounds.
pub fn RenderPipelineDiffResult::get_retained_command_count(
  self : RenderPipelineDiffResult,
) -> Int {
  self.retained_command_count
}

///|
/// Return the number of paired commands whose value changed.
pub fn RenderPipelineDiffResult::get_changed_command_count(
  self : RenderPipelineDiffResult,
) -> Int {
  self.changed_command_count
}

///|
/// Return the number of commands inserted in the next display list.
pub fn RenderPipelineDiffResult::get_inserted_command_count(
  self : RenderPipelineDiffResult,
) -> Int {
  self.inserted_command_count
}

///|
/// Return the number of commands removed from the previous display list.
pub fn RenderPipelineDiffResult::get_removed_command_count(
  self : RenderPipelineDiffResult,
) -> Int {
  self.removed_command_count
}

///|
/// Return whether the retained display list changed structurally or by value.
pub fn RenderPipelineDiffResult::has_changes(
  self : RenderPipelineDiffResult,
) -> Bool {
  self.changed_command_count > 0 ||
  self.inserted_command_count > 0 ||
  self.removed_command_count > 0
}

///|
/// Return the conservative dirty region caused by this display-list diff.
pub fn RenderPipelineDiffResult::get_dirty_region(
  self : RenderPipelineDiffResult,
) -> @graphics.DirtyRegion {
  self.dirty_region
}

///|
/// Return whether this display-list diff has dirty pixels to submit.
pub fn RenderPipelineDiffResult::has_dirty(
  self : RenderPipelineDiffResult,
) -> Bool {
  !self.dirty_region.is_empty()
}

///|
/// Return the number of conservative dirty rectangles in this diff.
pub fn RenderPipelineDiffResult::get_dirty_rect_count(
  self : RenderPipelineDiffResult,
) -> Int {
  self.dirty_region.get_rect_count()
}

///|
/// Return the conservative dirty bounds for this display-list diff.
pub fn RenderPipelineDiffResult::get_dirty_bounds(
  self : RenderPipelineDiffResult,
) -> @graphics.PixelRect? {
  self.dirty_region.bounds()
}

///|
/// Build a present plan from this diff's estimated dirty region.
pub fn RenderPipelineDiffResult::get_present_plan(
  self : RenderPipelineDiffResult,
  width : Int,
  height : Int,
  max_rects : Int,
) -> @graphics.DirtyPresentPlan {
  self.dirty_region.present_plan(
    @graphics.PixelRect::new(x=0, y=0, width~, height~),
    max_rects,
  )
}

///|
/// Return this batch's scheduling category.
pub fn RenderPipelineBatch::get_kind(
  self : RenderPipelineBatch,
) -> RenderPipelineBatchKind {
  self.kind
}

///|
/// Return the first command index covered by this batch.
pub fn RenderPipelineBatch::get_start_index(self : RenderPipelineBatch) -> Int {
  self.start_index
}

///|
/// Return the number of commands covered by this batch.
pub fn RenderPipelineBatch::get_command_count(
  self : RenderPipelineBatch,
) -> Int {
  self.command_count
}

///|
/// Return the conservative dirty region for this batch.
pub fn RenderPipelineBatch::get_dirty_region(
  self : RenderPipelineBatch,
) -> @graphics.DirtyRegion {
  self.dirty_region
}

///|
/// Return whether this batch may dirty pixels.
pub fn RenderPipelineBatch::has_dirty(self : RenderPipelineBatch) -> Bool {
  !self.dirty_region.is_empty()
}

///|
/// Return the number of dirty rects estimated for this batch.
pub fn RenderPipelineBatch::get_dirty_rect_count(
  self : RenderPipelineBatch,
) -> Int {
  self.dirty_region.get_rect_count()
}

///|
/// Return the conservative dirty bounds for this batch.
pub fn RenderPipelineBatch::get_dirty_bounds(
  self : RenderPipelineBatch,
) -> @graphics.PixelRect? {
  self.dirty_region.bounds()
}

///|
/// Build a present plan from this batch's estimated dirty region.
pub fn RenderPipelineBatch::get_present_plan(
  self : RenderPipelineBatch,
  width : Int,
  height : Int,
  max_rects : Int,
) -> @graphics.DirtyPresentPlan {
  self.dirty_region.present_plan(
    @graphics.PixelRect::new(x=0, y=0, width~, height~),
    max_rects,
  )
}

///|
/// Return the number of commands covered by this plan.
pub fn RenderPipelineBatchPlan::get_command_count(
  self : RenderPipelineBatchPlan,
) -> Int {
  self.command_count
}

///|
/// Return the number of contiguous command batches.
pub fn RenderPipelineBatchPlan::get_batch_count(
  self : RenderPipelineBatchPlan,
) -> Int {
  self.batches.length()
}

///|
/// Return the scheduler-facing contiguous command batches.
pub fn RenderPipelineBatchPlan::get_batches(
  self : RenderPipelineBatchPlan,
) -> Array[RenderPipelineBatch] {
  self.batches
}

///|
/// Return the conservative dirty region for all batches.
pub fn RenderPipelineBatchPlan::get_dirty_region(
  self : RenderPipelineBatchPlan,
) -> @graphics.DirtyRegion {
  self.dirty_region
}

///|
/// Return whether any batch may dirty pixels.
pub fn RenderPipelineBatchPlan::has_dirty(
  self : RenderPipelineBatchPlan,
) -> Bool {
  !self.dirty_region.is_empty()
}

///|
/// Return the conservative dirty bounds for all batches.
pub fn RenderPipelineBatchPlan::get_dirty_bounds(
  self : RenderPipelineBatchPlan,
) -> @graphics.PixelRect? {
  self.dirty_region.bounds()
}

///|
/// Build a present plan from the batch plan's estimated dirty region.
pub fn RenderPipelineBatchPlan::get_present_plan(
  self : RenderPipelineBatchPlan,
  width : Int,
  height : Int,
  max_rects : Int,
) -> @graphics.DirtyPresentPlan {
  self.dirty_region.present_plan(
    @graphics.PixelRect::new(x=0, y=0, width~, height~),
    max_rects,
  )
}

///|
/// Replay all queued commands through this renderer.
pub fn Renderer::draw_pipeline(
  self : Renderer,
  pipeline : RenderPipeline,
) -> RenderPipelineReplayResult {
  pipeline.replay(self)
}

///|
/// Analyze a pipeline against this renderer's canvas dimensions.
pub fn Renderer::analyze_pipeline(
  self : Renderer,
  pipeline : RenderPipeline,
) -> RenderPipelineAnalysis {
  let pixmap = self.get_canvas().get_pixmap()
  pipeline.analyze(pixmap.get_width(), pixmap.get_height())
}

///|
/// Diff two retained pipelines against this renderer's canvas dimensions.
pub fn Renderer::diff_pipelines(
  self : Renderer,
  previous : RenderPipeline,
  next : RenderPipeline,
) -> RenderPipelineDiffResult {
  let pixmap = self.get_canvas().get_pixmap()
  RenderPipeline::diff(previous, next, pixmap.get_width(), pixmap.get_height())
}

///|
/// Build a scheduler-facing batch plan against this renderer's canvas size.
pub fn Renderer::plan_pipeline_batches(
  self : Renderer,
  pipeline : RenderPipeline,
) -> RenderPipelineBatchPlan {
  let pixmap = self.get_canvas().get_pixmap()
  pipeline.batch_plan(pixmap.get_width(), pixmap.get_height())
}

///|
/// Estimate the dirty region and command categories without replaying.
pub fn RenderPipeline::analyze(
  self : RenderPipeline,
  width : Int,
  height : Int,
) -> RenderPipelineAnalysis {
  let dirty_region = @graphics.DirtyRegion::new()
  let canvas_bounds = @graphics.PixelRect::new(x=0, y=0, width~, height~)
  let mut clear_count = 0
  let mut fill_count = 0
  let mut stroke_count = 0
  let mut image_count = 0
  let mut text_count = 0
  for command in self.commands {
    match command {
      RenderCommand::Clear(_) => clear_count += 1
      RenderCommand::FillRect(_, _, _, _, _) | RenderCommand::FillPath(_, _) =>
        fill_count += 1
      RenderCommand::StrokeRect(_, _, _, _, _)
      | RenderCommand::StrokePath(_, _) => stroke_count += 1
      RenderCommand::DrawPixmap(_, _, _, _)
      | RenderCommand::DrawPixmapRect(_, _, _, _, _) => image_count += 1
      RenderCommand::DrawTextFace(_, _, _, _, _, _) => text_count += 1
    }
    match render_command_estimated_dirty_rect(command, width, height) {
      Some(rect) => dirty_region.add_clipped_rect(rect, canvas_bounds)
      None => ()
    }
  }
  {
    command_count: self.commands.length(),
    clear_count,
    fill_count,
    stroke_count,
    image_count,
    text_count,
    dirty_region,
  }
}

///|
/// Build a present plan from the pipeline's estimated dirty region.
pub fn RenderPipeline::dirty_present_plan(
  self : RenderPipeline,
  width : Int,
  height : Int,
  max_rects : Int,
) -> @graphics.DirtyPresentPlan {
  self.analyze(width, height).get_present_plan(width, height, max_rects)
}

///|
/// Group contiguous commands by scheduling category and estimate batch dirties.
pub fn RenderPipeline::batch_plan(
  self : RenderPipeline,
  width : Int,
  height : Int,
) -> RenderPipelineBatchPlan {
  let batches = []
  let plan_dirty_region = @graphics.DirtyRegion::new()
  let canvas_bounds = @graphics.PixelRect::new(x=0, y=0, width~, height~)
  let mut has_current_batch = false
  let mut current_kind = RenderPipelineBatchKind::Clear
  let mut current_start = 0
  let mut current_count = 0
  let mut current_dirty_region = @graphics.DirtyRegion::new()
  for index in 0..<self.commands.length() {
    let command = self.commands[index]
    let kind = render_command_batch_kind(command)
    if has_current_batch && current_kind != kind {
      batches.push(
        render_pipeline_make_batch(
          current_kind, current_start, current_count, current_dirty_region,
        ),
      )
      current_start = index
      current_count = 0
      current_dirty_region = @graphics.DirtyRegion::new()
    } else if !has_current_batch {
      has_current_batch = true
      current_start = index
      current_count = 0
      current_dirty_region = @graphics.DirtyRegion::new()
    }
    current_kind = kind
    current_count += 1
    render_pipeline_add_command_dirty(
      current_dirty_region, canvas_bounds, command, width, height,
    )
    render_pipeline_add_command_dirty(
      plan_dirty_region, canvas_bounds, command, width, height,
    )
  }
  if has_current_batch {
    batches.push(
      render_pipeline_make_batch(
        current_kind, current_start, current_count, current_dirty_region,
      ),
    )
  }
  {
    command_count: self.commands.length(),
    batches,
    dirty_region: plan_dirty_region,
  }
}

///|
/// Diff two retained display lists and estimate the dirty region to redraw.
pub fn RenderPipeline::diff(
  previous : RenderPipeline,
  next : RenderPipeline,
  width : Int,
  height : Int,
) -> RenderPipelineDiffResult {
  let dirty_region = @graphics.DirtyRegion::new()
  let canvas_bounds = @graphics.PixelRect::new(x=0, y=0, width~, height~)
  let previous_len = previous.commands.length()
  let next_len = next.commands.length()
  let common_len = previous_len.min(next_len)
  let mut retained_count = 0
  let mut changed_count = 0
  for index in 0..<common_len {
    let old_command = previous.commands[index]
    let new_command = next.commands[index]
    if render_commands_are_same(old_command, new_command) {
      retained_count += 1
    } else {
      changed_count += 1
      render_pipeline_add_command_dirty(
        dirty_region, canvas_bounds, old_command, width, height,
      )
      render_pipeline_add_command_dirty(
        dirty_region, canvas_bounds, new_command, width, height,
      )
    }
  }
  for index in common_len..<previous_len {
    render_pipeline_add_command_dirty(
      dirty_region,
      canvas_bounds,
      previous.commands[index],
      width,
      height,
    )
  }
  for index in common_len..<next_len {
    render_pipeline_add_command_dirty(
      dirty_region,
      canvas_bounds,
      next.commands[index],
      width,
      height,
    )
  }
  {
    previous_command_count: previous_len,
    next_command_count: next_len,
    retained_command_count: retained_count,
    changed_command_count: changed_count,
    inserted_command_count: if next_len > previous_len {
      next_len - previous_len
    } else {
      0
    },
    removed_command_count: if previous_len > next_len {
      previous_len - next_len
    } else {
      0
    },
    dirty_region,
  }
}

///|
/// Replay all queued commands through a renderer.
pub fn RenderPipeline::replay(
  self : RenderPipeline,
  renderer : Renderer,
) -> RenderPipelineReplayResult {
  let canvas = renderer.get_canvas()
  let mut clear_count = 0
  let mut fill_count = 0
  let mut stroke_count = 0
  let mut image_count = 0
  let mut text_count = 0
  for command in self.commands {
    match command {
      RenderCommand::Clear(color) => {
        canvas.clear(color)
        clear_count += 1
      }
      RenderCommand::FillRect(x, y, width, height, paint) => {
        canvas.fill_rect(x, y, width, height, paint)
        fill_count += 1
      }
      RenderCommand::StrokeRect(x, y, width, height, paint) => {
        canvas.stroke_rect(x, y, width, height, paint)
        stroke_count += 1
      }
      RenderCommand::FillPath(path, paint) => {
        canvas.fill_path(path, paint)
        fill_count += 1
      }
      RenderCommand::StrokePath(path, paint) => {
        canvas.stroke_path(path, paint)
        stroke_count += 1
      }
      RenderCommand::DrawPixmap(pixmap, x, y, paint) => {
        canvas.draw_pixmap(pixmap, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, paint) => {
        canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawTextFace(face, text, x, y, config, paint) => {
        renderer.draw_text_face(face, text, x, y, config, paint)
        text_count += 1
      }
    }
  }
  {
    command_count: self.commands.length(),
    clear_count,
    fill_count,
    stroke_count,
    image_count,
    text_count,
  }
}

///|
fn render_pipeline_add_command_dirty(
  dirty_region : @graphics.DirtyRegion,
  canvas_bounds : @graphics.PixelRect,
  command : RenderCommand,
  width : Int,
  height : Int,
) -> Unit {
  match render_command_estimated_dirty_rect(command, width, height) {
    Some(rect) => dirty_region.add_clipped_rect(rect, canvas_bounds)
    None => ()
  }
}

///|
fn render_pipeline_make_batch(
  kind : RenderPipelineBatchKind,
  start_index : Int,
  command_count : Int,
  dirty_region : @graphics.DirtyRegion,
) -> RenderPipelineBatch {
  { kind, start_index, command_count, dirty_region }
}

///|
fn render_command_batch_kind(
  command : RenderCommand,
) -> RenderPipelineBatchKind {
  match command {
    RenderCommand::Clear(_) => RenderPipelineBatchKind::Clear
    RenderCommand::FillRect(_, _, _, _, _) | RenderCommand::FillPath(_, _) =>
      RenderPipelineBatchKind::Fill
    RenderCommand::StrokeRect(_, _, _, _, _)
    | RenderCommand::StrokePath(_, _) => RenderPipelineBatchKind::Stroke
    RenderCommand::DrawPixmap(_, _, _, _)
    | RenderCommand::DrawPixmapRect(_, _, _, _, _) =>
      RenderPipelineBatchKind::Image
    RenderCommand::DrawTextFace(_, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
  }
}

///|
fn render_command_estimated_dirty_rect(
  command : RenderCommand,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  match command {
    RenderCommand::Clear(_) =>
      non_empty_pixel_rect(@graphics.PixelRect::new(x=0, y=0, width~, height~))
    RenderCommand::FillRect(x, y, rect_width, rect_height, _) =>
      pixel_rect_from_double_bounds(x, y, x + rect_width, y + rect_height)
    RenderCommand::StrokeRect(x, y, rect_width, rect_height, paint) => {
      let expand = paint.stroke_width.max(0.0) / 2.0
      pixel_rect_from_double_bounds(
        x - expand,
        y - expand,
        x + rect_width + expand,
        y + rect_height + expand,
      )
    }
    RenderCommand::FillPath(path, _) =>
      render_path_estimated_dirty_rect(path, 0.0)
    RenderCommand::StrokePath(path, paint) =>
      render_path_estimated_dirty_rect(path, paint.stroke_width.max(0.0) / 2.0)
    RenderCommand::DrawPixmap(pixmap, x, y, _) =>
      non_empty_pixel_rect(
        @graphics.PixelRect::new(
          x~,
          y~,
          width=pixmap.get_width(),
          height=pixmap.get_height(),
        ),
      )
    RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, _) => {
      let src_bounds = @graphics.PixelRect::new(
        x=0,
        y=0,
        width=pixmap.get_width(),
        height=pixmap.get_height(),
      )
      match src_rect.clip_to(src_bounds) {
        Some(clipped_src) =>
          non_empty_pixel_rect(
            @graphics.PixelRect::new(
              x=x + clipped_src.x - src_rect.x,
              y=y + clipped_src.y - src_rect.y,
              width=clipped_src.width,
              height=clipped_src.height,
            ),
          )
        None => None
      }
    }
    RenderCommand::DrawTextFace(face, text, x, y, config, _) => {
      guard text.length() > 0 else { return None }
      let layout = @text.TextLayout::layout(face, text, config)
      pixel_rect_from_double_bounds(
        x,
        y,
        x + layout.get_width(),
        y + layout.get_height(),
      )
    }
  }
}

///|
fn render_commands_are_same(a : RenderCommand, b : RenderCommand) -> Bool {
  match (a, b) {
    (RenderCommand::Clear(a_color), RenderCommand::Clear(b_color)) =>
      a_color == b_color
    (
      RenderCommand::FillRect(ax, ay, aw, ah, a_paint),
      RenderCommand::FillRect(bx, by, bw, bh, b_paint),
    ) =>
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::StrokeRect(ax, ay, aw, ah, a_paint),
      RenderCommand::StrokeRect(bx, by, bw, bh, b_paint),
    ) =>
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::FillPath(a_path, a_paint),
      RenderCommand::FillPath(b_path, b_paint),
    ) =>
      render_paths_are_same(a_path, b_path) &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::StrokePath(a_path, a_paint),
      RenderCommand::StrokePath(b_path, b_paint),
    ) =>
      render_paths_are_same(a_path, b_path) &&
      render_paint_is_same(a_paint, b_paint)
    // Pixmap and text commands depend on mutable/external resources. Treat
    // them as changed until resource-key preflight can prove identity.
    (
      RenderCommand::DrawPixmap(_, _, _, _),
      RenderCommand::DrawPixmap(_, _, _, _),
    ) => false
    (
      RenderCommand::DrawPixmapRect(_, _, _, _, _),
      RenderCommand::DrawPixmapRect(_, _, _, _, _),
    ) => false
    (
      RenderCommand::DrawTextFace(_, _, _, _, _, _),
      RenderCommand::DrawTextFace(_, _, _, _, _, _),
    ) => false
    _ => false
  }
}

///|
fn render_paths_are_same(a : @graphics.Path, b : @graphics.Path) -> Bool {
  let a_segments = a.get_segments()
  let b_segments = b.get_segments()
  guard a_segments.length() == b_segments.length() else { return false }
  for index in 0..<a_segments.length() {
    if a_segments[index] != b_segments[index] {
      return false
    }
  }
  true
}

///|
fn render_paint_is_same(a : @graphics.Paint, b : @graphics.Paint) -> Bool {
  a.color == b.color &&
  a.style == b.style &&
  a.blend_mode == b.blend_mode &&
  a.stroke_width == b.stroke_width &&
  a.stroke_cap == b.stroke_cap &&
  a.stroke_join == b.stroke_join &&
  a.miter_limit == b.miter_limit &&
  double_arrays_are_same(a.stroke_dash_pattern, b.stroke_dash_pattern) &&
  a.stroke_dash_offset == b.stroke_dash_offset &&
  a.fill_rule == b.fill_rule &&
  a.opacity == b.opacity
}

///|
fn double_arrays_are_same(a : Array[Double], b : Array[Double]) -> Bool {
  guard a.length() == b.length() else { return false }
  for index in 0..<a.length() {
    if a[index] != b[index] {
      return false
    }
  }
  true
}

///|
fn render_path_estimated_dirty_rect(
  path : @graphics.Path,
  expand : Double,
) -> @graphics.PixelRect? {
  let mut has_bounds = false
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = 0.0
  let mut max_y = 0.0
  for segment in path.get_segments() {
    match segment {
      @graphics.PathSegment::MoveTo(x, y) => {
        let (has, left, top, right, bottom) = extend_double_bounds(
          has_bounds, min_x, min_y, max_x, max_y, x, y,
        )
        has_bounds = has
        min_x = left
        min_y = top
        max_x = right
        max_y = bottom
      }
      @graphics.PathSegment::LineTo(x, y) => {
        let (has, left, top, right, bottom) = extend_double_bounds(
          has_bounds, min_x, min_y, max_x, max_y, x, y,
        )
        has_bounds = has
        min_x = left
        min_y = top
        max_x = right
        max_y = bottom
      }
      @graphics.PathSegment::QuadTo(cx, cy, x, y) => {
        let (
          has_control,
          control_left,
          control_top,
          control_right,
          control_bottom,
        ) = extend_double_bounds(has_bounds, min_x, min_y, max_x, max_y, cx, cy)
        let (has, left, top, right, bottom) = extend_double_bounds(
          has_control, control_left, control_top, control_right, control_bottom,
          x, y,
        )
        has_bounds = has
        min_x = left
        min_y = top
        max_x = right
        max_y = bottom
      }
      @graphics.PathSegment::CubicTo(cx1, cy1, cx2, cy2, x, y) => {
        let (has_first, first_left, first_top, first_right, first_bottom) = extend_double_bounds(
          has_bounds, min_x, min_y, max_x, max_y, cx1, cy1,
        )
        let (has_second, second_left, second_top, second_right, second_bottom) = extend_double_bounds(
          has_first, first_left, first_top, first_right, first_bottom, cx2, cy2,
        )
        let (has, left, top, right, bottom) = extend_double_bounds(
          has_second, second_left, second_top, second_right, second_bottom, x, y,
        )
        has_bounds = has
        min_x = left
        min_y = top
        max_x = right
        max_y = bottom
      }
      @graphics.PathSegment::Close => ()
    }
  }
  guard has_bounds else { return None }
  pixel_rect_from_double_bounds(
    min_x - expand,
    min_y - expand,
    max_x + expand,
    max_y + expand,
  )
}

///|
fn extend_double_bounds(
  has_bounds : Bool,
  min_x : Double,
  min_y : Double,
  max_x : Double,
  max_y : Double,
  x : Double,
  y : Double,
) -> (Bool, Double, Double, Double, Double) {
  if has_bounds {
    (true, min_x.min(x), min_y.min(y), max_x.max(x), max_y.max(y))
  } else {
    (true, x, y, x, y)
  }
}

///|
fn pixel_rect_from_double_bounds(
  left : Double,
  top : Double,
  right : Double,
  bottom : Double,
) -> @graphics.PixelRect? {
  guard right > left && bottom > top else { return None }
  let x0 = floor_to_int(left)
  let y0 = floor_to_int(top)
  let x1 = ceil_to_int(right)
  let y1 = ceil_to_int(bottom)
  non_empty_pixel_rect(
    @graphics.PixelRect::new(x=x0, y=y0, width=x1 - x0, height=y1 - y0),
  )
}

///|
fn non_empty_pixel_rect(rect : @graphics.PixelRect) -> @graphics.PixelRect? {
  if rect.is_empty() {
    None
  } else {
    Some(rect)
  }
}
