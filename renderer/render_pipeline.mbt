///|
/// Replayable CPU render command.
pub enum RenderCommand {
  Clear(@graphics.Color)
  FillRect(Double, Double, Double, Double, @graphics.Paint)
  StrokeRect(Double, Double, Double, Double, @graphics.Paint)
  FillPath(@graphics.Path, @graphics.Paint)
  StrokePath(@graphics.Path, @graphics.Paint)
  DrawPixmap(@graphics.Pixmap, Int, Int, @graphics.Paint)
  DrawPixmapKeyed(String, @graphics.Pixmap, Int, Int, @graphics.Paint)
  DrawPixmapRect(
    @graphics.Pixmap,
    @graphics.PixelRect,
    Int,
    Int,
    @graphics.Paint
  )
  DrawPixmapRectKeyed(
    String,
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
  DrawTextFaceKeyed(
    String,
    @text.FontFace,
    String,
    Double,
    Double,
    @text.LayoutConfig,
    @graphics.Paint
  )
  DrawFontBytesKeyed(
    String,
    Bytes,
    String,
    String,
    Double,
    Double,
    @text.LayoutConfig,
    @graphics.Paint
  )
  DrawFontBytesAtlasKeyed(
    String,
    Bytes,
    String,
    String,
    Double,
    Double,
    @text.LayoutConfig,
    @graphics.Paint
  )
  DrawFontBytesFallbackKeyed(
    Array[FontBytesFallbackSource],
    String,
    String,
    Double,
    Double,
    @text.LayoutConfig,
    @graphics.Paint
  )
  DrawLoadedFontKeyed(
    String,
    String,
    String,
    Double,
    Double,
    @text.LayoutConfig,
    @graphics.Paint
  )
  DrawLoadedFontAtlasKeyed(
    String,
    String,
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
/// Telemetry returned after replaying a pipeline through RendererResources.
pub struct RenderPipelineResourceReplayResult {
  replay_result : RenderPipelineReplayResult
  keyed_font_count : Int
  font_cache_hit_count : Int
  font_parse_count : Int
  keyed_image_count : Int
  image_cache_hit_count : Int
  image_cache_insert_count : Int
  keyed_text_count : Int
  text_cache_hit_count : Int
  text_mask_render_count : Int
  keyed_atlas_text_count : Int
  glyph_cache_hit_count : Int
  glyph_mask_render_count : Int
  atlas_cache_hit_count : Int
  atlas_insert_count : Int
  atlas_clear_count : Int
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
/// One image resource use discovered before replaying a render pipeline.
pub struct RenderPipelineImageDependency {
  command_index : Int
  resource_key : String?
  source_width : Int
  source_height : Int
  source_pixel_count : Int
} derive(Debug)

///|
/// One parsed-font text resource use discovered before replaying a pipeline.
pub struct RenderPipelineTextDependency {
  command_index : Int
  resource_key : String?
  text_byte_count : Int
  run_count : Int
  glyph_count : Int
  layout_width : Double
  layout_height : Double
} derive(Debug)

///|
/// One keyed font resource use discovered before replaying a pipeline.
pub struct RenderPipelineFontDependency {
  command_index : Int
  font_key : String
  font_byte_count : Int
} derive(Debug)

///|
/// Resource dependencies that can be pre-resolved from existing commands.
pub struct RenderPipelineResourcePlan {
  command_count : Int
  font_dependencies : Array[RenderPipelineFontDependency]
  image_dependencies : Array[RenderPipelineImageDependency]
  text_dependencies : Array[RenderPipelineTextDependency]
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
/// Queue a keyed pixmap draw command for stable resource identity.
pub fn RenderPipeline::draw_pixmap_keyed(
  self : RenderPipeline,
  resource_key : String,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::DrawPixmapKeyed(resource_key, pixmap, x, y, paint))
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
/// Queue a keyed source-rectangle pixmap command for stable resource identity.
pub fn RenderPipeline::draw_pixmap_rect_keyed(
  self : RenderPipeline,
  resource_key : String,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(
    RenderCommand::DrawPixmapRectKeyed(
      resource_key, pixmap, src_rect, x, y, paint,
    ),
  )
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
/// Queue a keyed parsed-font text command for stable resource identity.
pub fn RenderPipeline::draw_text_face_keyed(
  self : RenderPipeline,
  resource_key : String,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(
    RenderCommand::DrawTextFaceKeyed(
      resource_key, face, text, x, y, config, paint,
    ),
  )
}

///|
/// Queue a keyed font-byte text command for RendererResources-backed replay.
pub fn RenderPipeline::draw_font_bytes_keyed(
  self : RenderPipeline,
  font_key : String,
  font_data : Bytes,
  text_key : String,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(
    RenderCommand::DrawFontBytesKeyed(
      font_key, font_data, text_key, text, x, y, config, paint,
    ),
  )
}

///|
/// Queue a keyed font-byte atlas text command for RendererResources replay.
pub fn RenderPipeline::draw_font_bytes_atlas_keyed(
  self : RenderPipeline,
  font_key : String,
  font_data : Bytes,
  glyph_key_prefix : String,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(
    RenderCommand::DrawFontBytesAtlasKeyed(
      font_key, font_data, glyph_key_prefix, text, x, y, config, paint,
    ),
  )
}

///|
/// Queue a keyed font-byte fallback text command for RendererResources replay.
pub fn RenderPipeline::draw_font_bytes_fallback_keyed(
  self : RenderPipeline,
  sources : Array[FontBytesFallbackSource],
  text_key_prefix : String,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(
    RenderCommand::DrawFontBytesFallbackKeyed(
      sources, text_key_prefix, text, x, y, config, paint,
    ),
  )
}

///|
/// Queue a keyed loader-backed text command for font-loader replay.
pub fn RenderPipeline::draw_loaded_font_keyed(
  self : RenderPipeline,
  font_key : String,
  text_key : String,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(
    RenderCommand::DrawLoadedFontKeyed(
      font_key, text_key, text, x, y, config, paint,
    ),
  )
}

///|
/// Queue a keyed loader-backed atlas text command for font-loader replay.
pub fn RenderPipeline::draw_loaded_font_atlas_keyed(
  self : RenderPipeline,
  font_key : String,
  glyph_key_prefix : String,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(
    RenderCommand::DrawLoadedFontAtlasKeyed(
      font_key, glyph_key_prefix, text, x, y, config, paint,
    ),
  )
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
/// Return the base command replay telemetry.
pub fn RenderPipelineResourceReplayResult::get_replay_result(
  self : RenderPipelineResourceReplayResult,
) -> RenderPipelineReplayResult {
  self.replay_result
}

///|
/// Return the number of commands replayed.
pub fn RenderPipelineResourceReplayResult::get_command_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.replay_result.get_command_count()
}

///|
/// Return the number of clear commands replayed.
pub fn RenderPipelineResourceReplayResult::get_clear_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.replay_result.get_clear_count()
}

///|
/// Return the number of fill commands replayed.
pub fn RenderPipelineResourceReplayResult::get_fill_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.replay_result.get_fill_count()
}

///|
/// Return the number of stroke commands replayed.
pub fn RenderPipelineResourceReplayResult::get_stroke_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.replay_result.get_stroke_count()
}

///|
/// Return the number of image commands replayed.
pub fn RenderPipelineResourceReplayResult::get_image_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.replay_result.get_image_count()
}

///|
/// Return the number of text commands replayed.
pub fn RenderPipelineResourceReplayResult::get_text_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.replay_result.get_text_count()
}

///|
/// Return the number of keyed font commands replayed through the font cache.
pub fn RenderPipelineResourceReplayResult::get_keyed_font_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.keyed_font_count
}

///|
/// Return the number of keyed image commands replayed through the image cache.
pub fn RenderPipelineResourceReplayResult::get_keyed_image_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.keyed_image_count
}

///|
/// Return the number of keyed text commands replayed through the text cache.
pub fn RenderPipelineResourceReplayResult::get_keyed_text_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.keyed_text_count
}

///|
/// Return the number of keyed atlas text commands replayed through glyph resources.
pub fn RenderPipelineResourceReplayResult::get_keyed_atlas_text_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.keyed_atlas_text_count
}

///|
/// Return the number of keyed commands replayed through resource caches.
pub fn RenderPipelineResourceReplayResult::get_keyed_resource_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.keyed_font_count +
  self.keyed_image_count +
  self.keyed_text_count +
  self.keyed_atlas_text_count
}

///|
/// Return the number of keyed font commands that reused a cached font face.
pub fn RenderPipelineResourceReplayResult::get_font_cache_hit_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.font_cache_hit_count
}

///|
/// Return the number of keyed font commands that parsed or loaded a new face.
pub fn RenderPipelineResourceReplayResult::get_font_parse_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.font_parse_count
}

///|
/// Return the number of keyed image commands that reused a cached pixmap.
pub fn RenderPipelineResourceReplayResult::get_image_cache_hit_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.image_cache_hit_count
}

///|
/// Return the number of keyed image commands that inserted a pixmap cache entry.
pub fn RenderPipelineResourceReplayResult::get_image_cache_insert_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.image_cache_insert_count
}

///|
/// Return the number of keyed text commands that reused a cached text mask.
pub fn RenderPipelineResourceReplayResult::get_text_cache_hit_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.text_cache_hit_count
}

///|
/// Return the number of keyed text commands that rendered a new text mask.
pub fn RenderPipelineResourceReplayResult::get_text_mask_render_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.text_mask_render_count
}

///|
/// Return the number of atlas text glyph masks reused from the glyph cache.
pub fn RenderPipelineResourceReplayResult::get_glyph_cache_hit_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.glyph_cache_hit_count
}

///|
/// Return the number of atlas text glyph masks rasterized into the glyph cache.
pub fn RenderPipelineResourceReplayResult::get_glyph_mask_render_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.glyph_mask_render_count
}

///|
/// Return the number of atlas glyph placements reused from the atlas.
pub fn RenderPipelineResourceReplayResult::get_atlas_cache_hit_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.atlas_cache_hit_count
}

///|
/// Return the number of atlas glyph placements inserted into the atlas.
pub fn RenderPipelineResourceReplayResult::get_atlas_insert_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.atlas_insert_count
}

///|
/// Return the number of atlas draws that cleared the atlas while replaying.
pub fn RenderPipelineResourceReplayResult::get_atlas_clear_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.atlas_clear_count
}

///|
/// Return the number of keyed resource commands that hit a cache.
pub fn RenderPipelineResourceReplayResult::get_resource_cache_hit_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.font_cache_hit_count +
  self.image_cache_hit_count +
  self.text_cache_hit_count +
  self.glyph_cache_hit_count +
  self.atlas_cache_hit_count
}

///|
/// Return the number of keyed resource commands that populated a cache.
pub fn RenderPipelineResourceReplayResult::get_resource_cache_miss_count(
  self : RenderPipelineResourceReplayResult,
) -> Int {
  self.font_parse_count +
  self.image_cache_insert_count +
  self.text_mask_render_count +
  self.glyph_mask_render_count +
  self.atlas_insert_count
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
/// Return the command index that owns this image dependency.
pub fn RenderPipelineImageDependency::get_command_index(
  self : RenderPipelineImageDependency,
) -> Int {
  self.command_index
}

///|
/// Return the stable resource key for this image dependency when provided.
pub fn RenderPipelineImageDependency::get_resource_key(
  self : RenderPipelineImageDependency,
) -> String? {
  self.resource_key
}

///|
/// Return whether this image dependency has a stable resource key.
pub fn RenderPipelineImageDependency::has_resource_key(
  self : RenderPipelineImageDependency,
) -> Bool {
  self.resource_key is Some(_)
}

///|
/// Return the clipped source width read from the image resource.
pub fn RenderPipelineImageDependency::get_source_width(
  self : RenderPipelineImageDependency,
) -> Int {
  self.source_width
}

///|
/// Return the clipped source height read from the image resource.
pub fn RenderPipelineImageDependency::get_source_height(
  self : RenderPipelineImageDependency,
) -> Int {
  self.source_height
}

///|
/// Return the clipped source pixel count read from the image resource.
pub fn RenderPipelineImageDependency::get_source_pixel_count(
  self : RenderPipelineImageDependency,
) -> Int {
  self.source_pixel_count
}

///|
/// Return the command index that owns this text dependency.
pub fn RenderPipelineTextDependency::get_command_index(
  self : RenderPipelineTextDependency,
) -> Int {
  self.command_index
}

///|
/// Return the stable resource key for this text dependency when provided.
pub fn RenderPipelineTextDependency::get_resource_key(
  self : RenderPipelineTextDependency,
) -> String? {
  self.resource_key
}

///|
/// Return whether this text dependency has a stable resource key.
pub fn RenderPipelineTextDependency::has_resource_key(
  self : RenderPipelineTextDependency,
) -> Bool {
  self.resource_key is Some(_)
}

///|
/// Return the number of bytes in the queued text string.
pub fn RenderPipelineTextDependency::get_text_byte_count(
  self : RenderPipelineTextDependency,
) -> Int {
  self.text_byte_count
}

///|
/// Return the number of layout runs precomputed for this text command.
pub fn RenderPipelineTextDependency::get_run_count(
  self : RenderPipelineTextDependency,
) -> Int {
  self.run_count
}

///|
/// Return the number of positioned glyphs precomputed for this text command.
pub fn RenderPipelineTextDependency::get_glyph_count(
  self : RenderPipelineTextDependency,
) -> Int {
  self.glyph_count
}

///|
/// Return the precomputed text layout width.
pub fn RenderPipelineTextDependency::get_layout_width(
  self : RenderPipelineTextDependency,
) -> Double {
  self.layout_width
}

///|
/// Return the precomputed text layout height.
pub fn RenderPipelineTextDependency::get_layout_height(
  self : RenderPipelineTextDependency,
) -> Double {
  self.layout_height
}

///|
/// Return the command index for this font dependency.
pub fn RenderPipelineFontDependency::get_command_index(
  self : RenderPipelineFontDependency,
) -> Int {
  self.command_index
}

///|
/// Return the stable font resource key for this dependency.
pub fn RenderPipelineFontDependency::get_font_key(
  self : RenderPipelineFontDependency,
) -> String {
  self.font_key
}

///|
/// Return the number of bytes in the queued font data.
pub fn RenderPipelineFontDependency::get_font_byte_count(
  self : RenderPipelineFontDependency,
) -> Int {
  self.font_byte_count
}

///|
/// Return the number of commands scanned for resources.
pub fn RenderPipelineResourcePlan::get_command_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  self.command_count
}

///|
/// Return the number of discovered font-byte resource uses.
pub fn RenderPipelineResourcePlan::get_font_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  self.font_dependencies.length()
}

///|
/// Return the number of font-byte resource uses with stable keys.
pub fn RenderPipelineResourcePlan::get_keyed_font_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  self.font_dependencies.length()
}

///|
/// Return the number of discovered image resource uses.
pub fn RenderPipelineResourcePlan::get_image_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  self.image_dependencies.length()
}

///|
/// Return the number of image resource uses with stable keys.
pub fn RenderPipelineResourcePlan::get_keyed_image_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  let mut count = 0
  for dependency in self.image_dependencies {
    if dependency.has_resource_key() {
      count += 1
    }
  }
  count
}

///|
/// Return the number of discovered text resource uses.
pub fn RenderPipelineResourcePlan::get_text_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  self.text_dependencies.length()
}

///|
/// Return the number of text resource uses with stable keys.
pub fn RenderPipelineResourcePlan::get_keyed_text_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  let mut count = 0
  for dependency in self.text_dependencies {
    if dependency.has_resource_key() {
      count += 1
    }
  }
  count
}

///|
/// Return the number of discovered resource uses.
pub fn RenderPipelineResourcePlan::get_resource_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  self.get_font_count() + self.get_image_count() + self.get_text_count()
}

///|
/// Return the number of discovered resource uses with stable keys.
pub fn RenderPipelineResourcePlan::get_keyed_resource_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  self.get_keyed_font_count() +
  self.get_keyed_image_count() +
  self.get_keyed_text_count()
}

///|
/// Return whether the plan discovered at least one resource use.
pub fn RenderPipelineResourcePlan::has_resources(
  self : RenderPipelineResourcePlan,
) -> Bool {
  self.get_resource_count() > 0
}

///|
/// Return pre-resolved font-byte resource uses.
pub fn RenderPipelineResourcePlan::get_font_dependencies(
  self : RenderPipelineResourcePlan,
) -> Array[RenderPipelineFontDependency] {
  self.font_dependencies
}

///|
/// Return pre-resolved image resource uses.
pub fn RenderPipelineResourcePlan::get_image_dependencies(
  self : RenderPipelineResourcePlan,
) -> Array[RenderPipelineImageDependency] {
  self.image_dependencies
}

///|
/// Return pre-resolved text resource uses.
pub fn RenderPipelineResourcePlan::get_text_dependencies(
  self : RenderPipelineResourcePlan,
) -> Array[RenderPipelineTextDependency] {
  self.text_dependencies
}

///|
/// Return the total clipped source pixels read by image commands.
pub fn RenderPipelineResourcePlan::get_image_source_pixel_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  let mut count = 0
  for dependency in self.image_dependencies {
    count += dependency.source_pixel_count
  }
  count
}

///|
/// Return the total queued font byte count.
pub fn RenderPipelineResourcePlan::get_font_byte_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  let mut count = 0
  for dependency in self.font_dependencies {
    count += dependency.font_byte_count
  }
  count
}

///|
/// Return the total queued text byte count.
pub fn RenderPipelineResourcePlan::get_text_byte_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  let mut count = 0
  for dependency in self.text_dependencies {
    count += dependency.text_byte_count
  }
  count
}

///|
/// Return the total precomputed text layout run count.
pub fn RenderPipelineResourcePlan::get_text_run_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  let mut count = 0
  for dependency in self.text_dependencies {
    count += dependency.run_count
  }
  count
}

///|
/// Return the total precomputed positioned glyph count.
pub fn RenderPipelineResourcePlan::get_text_glyph_count(
  self : RenderPipelineResourcePlan,
) -> Int {
  let mut count = 0
  for dependency in self.text_dependencies {
    count += dependency.glyph_count
  }
  count
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
/// Replay a pipeline, routing keyed image/text commands through resources.
pub fn Renderer::draw_pipeline_with_renderer_resources(
  self : Renderer,
  pipeline : RenderPipeline,
  resources : RendererResources,
) -> RenderPipelineResourceReplayResult {
  pipeline.replay_with_renderer_resources(self, resources)
}

///|
/// Replay a pipeline through resources, preserving font-byte parse errors.
pub fn Renderer::draw_pipeline_with_renderer_resources_result(
  self : Renderer,
  pipeline : RenderPipeline,
  resources : RendererResources,
) -> Result[RenderPipelineResourceReplayResult, @text.FontParseError] {
  pipeline.replay_with_renderer_resources_result(self, resources)
}

///|
/// Replay a pipeline through resources and a font loader.
pub fn[L : @text.FontLoader] Renderer::draw_pipeline_with_font_loader_resources(
  self : Renderer,
  pipeline : RenderPipeline,
  resources : RendererResources,
  loader : L,
) -> RenderPipelineResourceReplayResult {
  pipeline.replay_with_font_loader_resources(self, resources, loader)
}

///|
/// Replay a pipeline through resources and a font loader, preserving load errors.
pub fn[L : @text.FontLoader] Renderer::draw_pipeline_with_font_loader_resources_result(
  self : Renderer,
  pipeline : RenderPipeline,
  resources : RendererResources,
  loader : L,
) -> Result[RenderPipelineResourceReplayResult, @text.FontLoadError] {
  pipeline.replay_with_font_loader_resources_result(self, resources, loader)
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
/// Pre-resolve image and parsed-font text resource uses for a pipeline.
pub fn Renderer::plan_pipeline_resources(
  self : Renderer,
  pipeline : RenderPipeline,
) -> RenderPipelineResourcePlan {
  ignore(self)
  pipeline.resource_plan()
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
      | RenderCommand::DrawPixmapKeyed(_, _, _, _, _)
      | RenderCommand::DrawPixmapRect(_, _, _, _, _)
      | RenderCommand::DrawPixmapRectKeyed(_, _, _, _, _, _) => image_count += 1
      RenderCommand::DrawTextFace(_, _, _, _, _, _)
      | RenderCommand::DrawTextFaceKeyed(_, _, _, _, _, _, _)
      | RenderCommand::DrawFontBytesKeyed(_, _, _, _, _, _, _, _)
      | RenderCommand::DrawFontBytesAtlasKeyed(_, _, _, _, _, _, _, _)
      | RenderCommand::DrawFontBytesFallbackKeyed(_, _, _, _, _, _, _)
      | RenderCommand::DrawLoadedFontKeyed(_, _, _, _, _, _, _)
      | RenderCommand::DrawLoadedFontAtlasKeyed(_, _, _, _, _, _, _) =>
        text_count += 1
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
/// Pre-resolve image and parsed-font text resource uses before replay.
pub fn RenderPipeline::resource_plan(
  self : RenderPipeline,
) -> RenderPipelineResourcePlan {
  let font_dependencies = []
  let image_dependencies = []
  let text_dependencies = []
  for index in 0..<self.commands.length() {
    let command = self.commands[index]
    match command {
      RenderCommand::DrawPixmap(pixmap, _, _, _) =>
        image_dependencies.push(
          render_pipeline_make_image_dependency(
            index,
            None,
            pixmap.get_width(),
            pixmap.get_height(),
          ),
        )
      RenderCommand::DrawPixmapKeyed(resource_key, pixmap, _, _, _) =>
        image_dependencies.push(
          render_pipeline_make_image_dependency(
            index,
            Some(resource_key),
            pixmap.get_width(),
            pixmap.get_height(),
          ),
        )
      RenderCommand::DrawPixmapRect(pixmap, src_rect, _, _, _) =>
        image_dependencies.push(
          render_pipeline_make_rect_image_dependency(
            index,
            None,
            pixmap,
            src_rect,
          ),
        )
      RenderCommand::DrawPixmapRectKeyed(
        resource_key,
        pixmap,
        src_rect,
        _,
        _,
        _
      ) =>
        image_dependencies.push(
          render_pipeline_make_rect_image_dependency(
            index,
            Some(resource_key),
            pixmap,
            src_rect,
          ),
        )
      RenderCommand::DrawTextFace(face, text, _, _, config, _) =>
        text_dependencies.push(
          render_pipeline_make_text_dependency(index, None, face, text, config),
        )
      RenderCommand::DrawTextFaceKeyed(
        resource_key,
        face,
        text,
        _,
        _,
        config,
        _
      ) =>
        text_dependencies.push(
          render_pipeline_make_text_dependency(
            index,
            Some(resource_key),
            face,
            text,
            config,
          ),
        )
      RenderCommand::DrawFontBytesKeyed(
        font_key,
        font_data,
        text_key,
        text,
        _,
        _,
        config,
        _
      ) => {
        font_dependencies.push(
          render_pipeline_make_font_dependency(index, font_key, font_data),
        )
        text_dependencies.push(
          render_pipeline_make_font_bytes_text_dependency(
            index, text_key, font_data, text, config,
          ),
        )
      }
      RenderCommand::DrawFontBytesAtlasKeyed(
        font_key,
        font_data,
        glyph_key_prefix,
        text,
        _,
        _,
        config,
        _
      ) => {
        font_dependencies.push(
          render_pipeline_make_font_dependency(index, font_key, font_data),
        )
        text_dependencies.push(
          render_pipeline_make_font_bytes_text_dependency(
            index, glyph_key_prefix, font_data, text, config,
          ),
        )
      }
      RenderCommand::DrawFontBytesFallbackKeyed(
        sources,
        text_key_prefix,
        text,
        _,
        _,
        _,
        _
      ) => {
        for source in sources {
          font_dependencies.push(
            render_pipeline_make_font_dependency(
              index,
              source.get_font_key(),
              source.get_font_data(),
            ),
          )
        }
        text_dependencies.push(
          render_pipeline_make_unresolved_text_dependency(
            index,
            Some(text_key_prefix),
            text,
          ),
        )
      }
      RenderCommand::DrawLoadedFontKeyed(font_key, text_key, text, _, _, _, _) => {
        font_dependencies.push(
          render_pipeline_make_loaded_font_dependency(index, font_key),
        )
        text_dependencies.push(
          render_pipeline_make_unresolved_text_dependency(
            index,
            Some(text_key),
            text,
          ),
        )
      }
      RenderCommand::DrawLoadedFontAtlasKeyed(
        font_key,
        glyph_key_prefix,
        text,
        _,
        _,
        _,
        _
      ) => {
        font_dependencies.push(
          render_pipeline_make_loaded_font_dependency(index, font_key),
        )
        text_dependencies.push(
          render_pipeline_make_unresolved_text_dependency(
            index,
            Some(glyph_key_prefix),
            text,
          ),
        )
      }
      _ => ()
    }
  }
  {
    command_count: self.commands.length(),
    font_dependencies,
    image_dependencies,
    text_dependencies,
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
      RenderCommand::DrawPixmapKeyed(_, pixmap, x, y, paint) => {
        canvas.draw_pixmap(pixmap, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, paint) => {
        canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawPixmapRectKeyed(_, pixmap, src_rect, x, y, paint) => {
        canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawTextFace(face, text, x, y, config, paint) => {
        renderer.draw_text_face(face, text, x, y, config, paint)
        text_count += 1
      }
      RenderCommand::DrawTextFaceKeyed(_, face, text, x, y, config, paint) => {
        renderer.draw_text_face(face, text, x, y, config, paint)
        text_count += 1
      }
      RenderCommand::DrawFontBytesKeyed(
        _,
        font_data,
        _,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match @text.FontFace::from_bytes(font_data) {
          Ok(face) => renderer.draw_text_face(face, text, x, y, config, paint)
          Err(_) => abort("failed to parse pipeline font bytes")
        }
        text_count += 1
      }
      RenderCommand::DrawFontBytesAtlasKeyed(
        _,
        font_data,
        _,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match @text.FontFace::from_bytes(font_data) {
          Ok(face) => renderer.draw_text_face(face, text, x, y, config, paint)
          Err(_) => abort("failed to parse pipeline font bytes")
        }
        text_count += 1
      }
      RenderCommand::DrawFontBytesFallbackKeyed(
        sources,
        _,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match render_pipeline_parse_font_bytes_fallback_sources(sources) {
          Ok(faces) =>
            ignore(
              renderer.draw_text_fallback_line(faces, text, x, y, config, paint),
            )
          Err(_) => abort("failed to parse pipeline fallback font bytes")
        }
        text_count += 1
      }
      RenderCommand::DrawLoadedFontKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font command requires a font loader")
      RenderCommand::DrawLoadedFontAtlasKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font atlas command requires a font loader")
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
/// Replay all queued commands, using RendererResources for keyed resources.
pub fn RenderPipeline::replay_with_renderer_resources(
  self : RenderPipeline,
  renderer : Renderer,
  resources : RendererResources,
) -> RenderPipelineResourceReplayResult {
  match self.replay_with_renderer_resources_result(renderer, resources) {
    Ok(result) => result
    Err(_) => abort("failed to parse pipeline font bytes")
  }
}

///|
/// Replay all queued commands through resources, preserving font parse errors.
pub fn RenderPipeline::replay_with_renderer_resources_result(
  self : RenderPipeline,
  renderer : Renderer,
  resources : RendererResources,
) -> Result[RenderPipelineResourceReplayResult, @text.FontParseError] {
  let canvas = renderer.get_canvas()
  let mut clear_count = 0
  let mut fill_count = 0
  let mut stroke_count = 0
  let mut image_count = 0
  let mut text_count = 0
  let mut keyed_font_count = 0
  let mut font_cache_hit_count = 0
  let mut font_parse_count = 0
  let mut keyed_image_count = 0
  let mut image_cache_hit_count = 0
  let mut image_cache_insert_count = 0
  let mut keyed_text_count = 0
  let mut text_cache_hit_count = 0
  let mut text_mask_render_count = 0
  let mut keyed_atlas_text_count = 0
  let mut glyph_cache_hit_count = 0
  let mut glyph_mask_render_count = 0
  let mut atlas_cache_hit_count = 0
  let mut atlas_insert_count = 0
  let mut atlas_clear_count = 0
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
      RenderCommand::DrawPixmapKeyed(resource_key, pixmap, x, y, paint) => {
        let result = renderer.draw_pixmap_cached_with_renderer_resources(
          pixmap, x, y, resources, resource_key, paint,
        )
        if result.did_hit_cache() {
          image_cache_hit_count += 1
        } else {
          image_cache_insert_count += 1
        }
        keyed_image_count += 1
        image_count += 1
      }
      RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, paint) => {
        canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawPixmapRectKeyed(
        resource_key,
        pixmap,
        src_rect,
        x,
        y,
        paint
      ) => {
        let result = renderer.draw_pixmap_rect_cached_with_renderer_resources(
          pixmap, src_rect, x, y, resources, resource_key, paint,
        )
        if result.did_hit_cache() {
          image_cache_hit_count += 1
        } else {
          image_cache_insert_count += 1
        }
        keyed_image_count += 1
        image_count += 1
      }
      RenderCommand::DrawTextFace(face, text, x, y, config, paint) => {
        renderer.draw_text_face(face, text, x, y, config, paint)
        text_count += 1
      }
      RenderCommand::DrawTextFaceKeyed(
        resource_key,
        face,
        text,
        x,
        y,
        config,
        paint
      ) => {
        let result = renderer.draw_text_face_cached_with_renderer_resources(
          face, text, x, y, config, resources, resource_key, paint,
        )
        if result.did_hit_cache() {
          text_cache_hit_count += 1
        } else {
          text_mask_render_count += 1
        }
        keyed_text_count += 1
        text_count += 1
      }
      RenderCommand::DrawFontBytesKeyed(
        font_key,
        font_data,
        text_key,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_font_bytes_cached_with_renderer_resources(
            font_data, text, x, y, config, resources, font_key, text_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_font_cache() {
              font_cache_hit_count += 1
            } else {
              font_parse_count += 1
            }
            if result.did_hit_text_cache() {
              text_cache_hit_count += 1
            } else {
              text_mask_render_count += 1
            }
          }
          Err(error) => return Err(error)
        }
        keyed_font_count += 1
        keyed_text_count += 1
        text_count += 1
      }
      RenderCommand::DrawFontBytesAtlasKeyed(
        font_key,
        font_data,
        glyph_key_prefix,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_font_bytes_atlas_with_renderer_resources(
            font_data, text, x, y, config, resources, font_key, glyph_key_prefix,
            paint,
          ) {
          Ok(result) => {
            if result.did_hit_font_cache() {
              font_cache_hit_count += 1
            } else {
              font_parse_count += 1
            }
            glyph_cache_hit_count += result.get_cache_hit_count()
            glyph_mask_render_count += result.get_rasterized_glyph_count()
            atlas_cache_hit_count += result.get_atlas_hit_count()
            atlas_insert_count += result.get_atlas_inserted_count()
            if result.did_clear_atlas() {
              atlas_clear_count += 1
            }
          }
          Err(error) => return Err(error)
        }
        keyed_font_count += 1
        keyed_atlas_text_count += 1
        text_count += 1
      }
      RenderCommand::DrawFontBytesFallbackKeyed(
        sources,
        text_key_prefix,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_font_bytes_fallback_line_cached_with_renderer_resources(
            sources, text, x, y, config, resources, text_key_prefix, paint,
          ) {
          Ok(result) => {
            font_parse_count += result.get_parsed_font_count()
            font_cache_hit_count += result.get_font_cache_hit_count()
            text_mask_render_count += result.get_rendered_mask_count()
            text_cache_hit_count += result.get_text_cache_hit_count()
            keyed_text_count += result.get_drawn_span_count()
          }
          Err(error) => return Err(error)
        }
        keyed_font_count += sources.length()
        text_count += 1
      }
      RenderCommand::DrawLoadedFontKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font command requires a font loader")
      RenderCommand::DrawLoadedFontAtlasKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font atlas command requires a font loader")
    }
  }
  Ok({
    replay_result: {
      command_count: self.commands.length(),
      clear_count,
      fill_count,
      stroke_count,
      image_count,
      text_count,
    },
    keyed_font_count,
    font_cache_hit_count,
    font_parse_count,
    keyed_image_count,
    image_cache_hit_count,
    image_cache_insert_count,
    keyed_text_count,
    text_cache_hit_count,
    text_mask_render_count,
    keyed_atlas_text_count,
    glyph_cache_hit_count,
    glyph_mask_render_count,
    atlas_cache_hit_count,
    atlas_insert_count,
    atlas_clear_count,
  })
}

///|
/// Replay all queued commands, using RendererResources and a font loader.
pub fn[L : @text.FontLoader] RenderPipeline::replay_with_font_loader_resources(
  self : RenderPipeline,
  renderer : Renderer,
  resources : RendererResources,
  loader : L,
) -> RenderPipelineResourceReplayResult {
  match
    self.replay_with_font_loader_resources_result(renderer, resources, loader) {
    Ok(result) => result
    Err(_) => abort("failed to load pipeline font")
  }
}

///|
/// Replay all queued commands through resources and a font loader.
pub fn[L : @text.FontLoader] RenderPipeline::replay_with_font_loader_resources_result(
  self : RenderPipeline,
  renderer : Renderer,
  resources : RendererResources,
  loader : L,
) -> Result[RenderPipelineResourceReplayResult, @text.FontLoadError] {
  let canvas = renderer.get_canvas()
  let mut clear_count = 0
  let mut fill_count = 0
  let mut stroke_count = 0
  let mut image_count = 0
  let mut text_count = 0
  let mut keyed_font_count = 0
  let mut font_cache_hit_count = 0
  let mut font_parse_count = 0
  let mut keyed_image_count = 0
  let mut image_cache_hit_count = 0
  let mut image_cache_insert_count = 0
  let mut keyed_text_count = 0
  let mut text_cache_hit_count = 0
  let mut text_mask_render_count = 0
  let mut keyed_atlas_text_count = 0
  let mut glyph_cache_hit_count = 0
  let mut glyph_mask_render_count = 0
  let mut atlas_cache_hit_count = 0
  let mut atlas_insert_count = 0
  let mut atlas_clear_count = 0
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
      RenderCommand::DrawPixmapKeyed(resource_key, pixmap, x, y, paint) => {
        let result = renderer.draw_pixmap_cached_with_renderer_resources(
          pixmap, x, y, resources, resource_key, paint,
        )
        if result.did_hit_cache() {
          image_cache_hit_count += 1
        } else {
          image_cache_insert_count += 1
        }
        keyed_image_count += 1
        image_count += 1
      }
      RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, paint) => {
        canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawPixmapRectKeyed(
        resource_key,
        pixmap,
        src_rect,
        x,
        y,
        paint
      ) => {
        let result = renderer.draw_pixmap_rect_cached_with_renderer_resources(
          pixmap, src_rect, x, y, resources, resource_key, paint,
        )
        if result.did_hit_cache() {
          image_cache_hit_count += 1
        } else {
          image_cache_insert_count += 1
        }
        keyed_image_count += 1
        image_count += 1
      }
      RenderCommand::DrawTextFace(face, text, x, y, config, paint) => {
        renderer.draw_text_face(face, text, x, y, config, paint)
        text_count += 1
      }
      RenderCommand::DrawTextFaceKeyed(
        resource_key,
        face,
        text,
        x,
        y,
        config,
        paint
      ) => {
        let result = renderer.draw_text_face_cached_with_renderer_resources(
          face, text, x, y, config, resources, resource_key, paint,
        )
        if result.did_hit_cache() {
          text_cache_hit_count += 1
        } else {
          text_mask_render_count += 1
        }
        keyed_text_count += 1
        text_count += 1
      }
      RenderCommand::DrawFontBytesKeyed(
        font_key,
        font_data,
        text_key,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_font_bytes_cached_with_renderer_resources(
            font_data, text, x, y, config, resources, font_key, text_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_font_cache() {
              font_cache_hit_count += 1
            } else {
              font_parse_count += 1
            }
            if result.did_hit_text_cache() {
              text_cache_hit_count += 1
            } else {
              text_mask_render_count += 1
            }
          }
          Err(error) =>
            return Err(@text.FontLoadError::FontParseFailed(font_key, error))
        }
        keyed_font_count += 1
        keyed_text_count += 1
        text_count += 1
      }
      RenderCommand::DrawFontBytesAtlasKeyed(
        font_key,
        font_data,
        glyph_key_prefix,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_font_bytes_atlas_with_renderer_resources(
            font_data, text, x, y, config, resources, font_key, glyph_key_prefix,
            paint,
          ) {
          Ok(result) => {
            if result.did_hit_font_cache() {
              font_cache_hit_count += 1
            } else {
              font_parse_count += 1
            }
            glyph_cache_hit_count += result.get_cache_hit_count()
            glyph_mask_render_count += result.get_rasterized_glyph_count()
            atlas_cache_hit_count += result.get_atlas_hit_count()
            atlas_insert_count += result.get_atlas_inserted_count()
            if result.did_clear_atlas() {
              atlas_clear_count += 1
            }
          }
          Err(error) =>
            return Err(@text.FontLoadError::FontParseFailed(font_key, error))
        }
        keyed_font_count += 1
        keyed_atlas_text_count += 1
        text_count += 1
      }
      RenderCommand::DrawFontBytesFallbackKeyed(
        sources,
        text_key_prefix,
        text,
        x,
        y,
        config,
        paint
      ) => {
        let faces : Array[@text.FontFace] = []
        let mut command_font_parse_count = 0
        let mut command_font_cache_hit_count = 0
        for source in sources {
          match
            resources
            .get_font_face_cache()
            .get_or_parse_result(source.get_font_key(), source.get_font_data()) {
            Ok(parse_result) => {
              faces.push(parse_result.get_face())
              if parse_result.did_parse() {
                command_font_parse_count += 1
              } else {
                command_font_cache_hit_count += 1
              }
            }
            Err(error) =>
              return Err(
                @text.FontLoadError::FontParseFailed(
                  source.get_font_key(),
                  error,
                ),
              )
          }
        }
        let result = renderer.draw_text_fallback_line_cached_with_renderer_resources(
          faces, text, x, y, config, resources, text_key_prefix, paint,
        )
        font_parse_count += command_font_parse_count
        font_cache_hit_count += command_font_cache_hit_count
        text_mask_render_count += result.get_rendered_mask_count()
        text_cache_hit_count += result.get_cache_hit_count()
        keyed_font_count += sources.length()
        keyed_text_count += result.get_drawn_span_count()
        text_count += 1
      }
      RenderCommand::DrawLoadedFontKeyed(
        font_key,
        text_key,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_loaded_font_cached_with_renderer_resources(
            loader, text, x, y, config, resources, font_key, text_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_font_cache() {
              font_cache_hit_count += 1
            } else {
              font_parse_count += 1
            }
            if result.did_hit_text_cache() {
              text_cache_hit_count += 1
            } else {
              text_mask_render_count += 1
            }
          }
          Err(error) => return Err(error)
        }
        keyed_font_count += 1
        keyed_text_count += 1
        text_count += 1
      }
      RenderCommand::DrawLoadedFontAtlasKeyed(
        font_key,
        glyph_key_prefix,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_loaded_font_atlas_with_renderer_resources(
            loader, text, x, y, config, resources, font_key, glyph_key_prefix, paint,
          ) {
          Ok(result) => {
            if result.did_hit_font_cache() {
              font_cache_hit_count += 1
            } else {
              font_parse_count += 1
            }
            glyph_cache_hit_count += result.get_cache_hit_count()
            glyph_mask_render_count += result.get_rasterized_glyph_count()
            atlas_cache_hit_count += result.get_atlas_hit_count()
            atlas_insert_count += result.get_atlas_inserted_count()
            if result.did_clear_atlas() {
              atlas_clear_count += 1
            }
          }
          Err(error) => return Err(error)
        }
        keyed_font_count += 1
        keyed_atlas_text_count += 1
        text_count += 1
      }
    }
  }
  Ok({
    replay_result: {
      command_count: self.commands.length(),
      clear_count,
      fill_count,
      stroke_count,
      image_count,
      text_count,
    },
    keyed_font_count,
    font_cache_hit_count,
    font_parse_count,
    keyed_image_count,
    image_cache_hit_count,
    image_cache_insert_count,
    keyed_text_count,
    text_cache_hit_count,
    text_mask_render_count,
    keyed_atlas_text_count,
    glyph_cache_hit_count,
    glyph_mask_render_count,
    atlas_cache_hit_count,
    atlas_insert_count,
    atlas_clear_count,
  })
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
fn render_pipeline_make_image_dependency(
  command_index : Int,
  resource_key : String?,
  source_width : Int,
  source_height : Int,
) -> RenderPipelineImageDependency {
  {
    command_index,
    resource_key,
    source_width,
    source_height,
    source_pixel_count: source_width * source_height,
  }
}

///|
fn render_pipeline_make_rect_image_dependency(
  command_index : Int,
  resource_key : String?,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
) -> RenderPipelineImageDependency {
  let src_bounds = @graphics.PixelRect::new(
    x=0,
    y=0,
    width=pixmap.get_width(),
    height=pixmap.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped) =>
      render_pipeline_make_image_dependency(
        command_index,
        resource_key,
        clipped.width,
        clipped.height,
      )
    None =>
      render_pipeline_make_image_dependency(command_index, resource_key, 0, 0)
  }
}

///|
fn render_pipeline_make_font_dependency(
  command_index : Int,
  font_key : String,
  font_data : Bytes,
) -> RenderPipelineFontDependency {
  { command_index, font_key, font_byte_count: font_data.length() }
}

///|
fn render_pipeline_make_loaded_font_dependency(
  command_index : Int,
  font_key : String,
) -> RenderPipelineFontDependency {
  { command_index, font_key, font_byte_count: 0 }
}

///|
fn render_pipeline_make_text_dependency(
  command_index : Int,
  resource_key : String?,
  face : @text.FontFace,
  text : String,
  config : @text.LayoutConfig,
) -> RenderPipelineTextDependency {
  let mut run_count = 0
  let mut glyph_count = 0
  let mut layout_width = 0.0
  let mut layout_height = 0.0
  if text.length() > 0 {
    let layout = @text.TextLayout::layout(face, text, config)
    run_count = layout.run_count()
    layout_width = layout.get_width()
    layout_height = layout.get_height()
    for run in layout.get_runs() {
      glyph_count += run.glyph_count()
    }
  }
  {
    command_index,
    resource_key,
    text_byte_count: text.length(),
    run_count,
    glyph_count,
    layout_width,
    layout_height,
  }
}

///|
fn render_pipeline_make_font_bytes_text_dependency(
  command_index : Int,
  resource_key : String,
  font_data : Bytes,
  text : String,
  config : @text.LayoutConfig,
) -> RenderPipelineTextDependency {
  match @text.FontFace::from_bytes(font_data) {
    Ok(face) =>
      render_pipeline_make_text_dependency(
        command_index,
        Some(resource_key),
        face,
        text,
        config,
      )
    Err(_) =>
      render_pipeline_make_unresolved_text_dependency(
        command_index,
        Some(resource_key),
        text,
      )
  }
}

///|
fn render_pipeline_make_unresolved_text_dependency(
  command_index : Int,
  resource_key : String?,
  text : String,
) -> RenderPipelineTextDependency {
  {
    command_index,
    resource_key,
    text_byte_count: text.length(),
    run_count: 0,
    glyph_count: 0,
    layout_width: 0.0,
    layout_height: 0.0,
  }
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
    | RenderCommand::DrawPixmapKeyed(_, _, _, _, _)
    | RenderCommand::DrawPixmapRect(_, _, _, _, _)
    | RenderCommand::DrawPixmapRectKeyed(_, _, _, _, _, _) =>
      RenderPipelineBatchKind::Image
    RenderCommand::DrawTextFace(_, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawTextFaceKeyed(_, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawFontBytesKeyed(_, _, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawFontBytesAtlasKeyed(_, _, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawFontBytesFallbackKeyed(_, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawLoadedFontKeyed(_, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawLoadedFontAtlasKeyed(_, _, _, _, _, _, _) =>
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
    RenderCommand::DrawPixmapKeyed(_, pixmap, x, y, _) =>
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
    RenderCommand::DrawPixmapRectKeyed(_, pixmap, src_rect, x, y, _) => {
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
    RenderCommand::DrawTextFaceKeyed(_, face, text, x, y, config, _) => {
      guard text.length() > 0 else { return None }
      let layout = @text.TextLayout::layout(face, text, config)
      pixel_rect_from_double_bounds(
        x,
        y,
        x + layout.get_width(),
        y + layout.get_height(),
      )
    }
    RenderCommand::DrawFontBytesKeyed(_, font_data, _, text, x, y, config, _) => {
      guard text.length() > 0 else { return None }
      match @text.FontFace::from_bytes(font_data) {
        Ok(face) => {
          let layout = @text.TextLayout::layout(face, text, config)
          pixel_rect_from_double_bounds(
            x,
            y,
            x + layout.get_width(),
            y + layout.get_height(),
          )
        }
        Err(_) =>
          pixel_rect_from_double_bounds(
            x,
            y,
            x + render_pipeline_fallback_text_width(text, config),
            y + config.line_height.max(config.font_size),
          )
      }
    }
    RenderCommand::DrawFontBytesAtlasKeyed(
      _,
      font_data,
      _,
      text,
      x,
      y,
      config,
      _
    ) => {
      guard text.length() > 0 else { return None }
      match @text.FontFace::from_bytes(font_data) {
        Ok(face) => {
          let layout = @text.TextLayout::layout(face, text, config)
          pixel_rect_from_double_bounds(
            x,
            y,
            x + layout.get_width(),
            y + layout.get_height(),
          )
        }
        Err(_) =>
          pixel_rect_from_double_bounds(
            x,
            y,
            x + render_pipeline_fallback_text_width(text, config),
            y + config.line_height.max(config.font_size),
          )
      }
    }
    RenderCommand::DrawFontBytesFallbackKeyed(_, _, text, x, y, config, _) => {
      guard text.length() > 0 else { return None }
      pixel_rect_from_double_bounds(
        x,
        y,
        x + render_pipeline_fallback_text_width(text, config),
        y + config.line_height.max(config.font_size),
      )
    }
    RenderCommand::DrawLoadedFontKeyed(_, _, text, x, y, config, _) => {
      guard text.length() > 0 else { return None }
      pixel_rect_from_double_bounds(
        x,
        y,
        x + render_pipeline_fallback_text_width(text, config),
        y + config.line_height.max(config.font_size),
      )
    }
    RenderCommand::DrawLoadedFontAtlasKeyed(_, _, text, x, y, config, _) => {
      guard text.length() > 0 else { return None }
      pixel_rect_from_double_bounds(
        x,
        y,
        x + render_pipeline_fallback_text_width(text, config),
        y + config.line_height.max(config.font_size),
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
    // Unkeyed pixmap and text commands depend on mutable/external resources.
    // Treat them as changed unless a stable key can prove identity.
    (
      RenderCommand::DrawPixmap(_, _, _, _),
      RenderCommand::DrawPixmap(_, _, _, _),
    ) => false
    (
      RenderCommand::DrawPixmapKeyed(a_key, _, ax, ay, a_paint),
      RenderCommand::DrawPixmapKeyed(b_key, _, bx, by, b_paint),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawPixmapRect(_, _, _, _, _),
      RenderCommand::DrawPixmapRect(_, _, _, _, _),
    ) => false
    (
      RenderCommand::DrawPixmapRectKeyed(a_key, _, a_src, ax, ay, a_paint),
      RenderCommand::DrawPixmapRectKeyed(b_key, _, b_src, bx, by, b_paint),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawTextFace(_, _, _, _, _, _),
      RenderCommand::DrawTextFace(_, _, _, _, _, _),
    ) => false
    (
      RenderCommand::DrawTextFaceKeyed(
        a_key,
        _,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawTextFaceKeyed(
        b_key,
        _,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      a_key == b_key &&
      a_text == b_text &&
      ax == bx &&
      ay == by &&
      render_layout_config_is_same(a_config, b_config) &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawFontBytesKeyed(
        a_font_key,
        _,
        a_text_key,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawFontBytesKeyed(
        b_font_key,
        _,
        b_text_key,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      a_font_key == b_font_key &&
      a_text_key == b_text_key &&
      a_text == b_text &&
      ax == bx &&
      ay == by &&
      render_layout_config_is_same(a_config, b_config) &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawFontBytesAtlasKeyed(
        a_font_key,
        _,
        a_glyph_key_prefix,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawFontBytesAtlasKeyed(
        b_font_key,
        _,
        b_glyph_key_prefix,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      a_font_key == b_font_key &&
      a_glyph_key_prefix == b_glyph_key_prefix &&
      a_text == b_text &&
      ax == bx &&
      ay == by &&
      render_layout_config_is_same(a_config, b_config) &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawFontBytesFallbackKeyed(
        a_sources,
        a_text_key_prefix,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawFontBytesFallbackKeyed(
        b_sources,
        b_text_key_prefix,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      render_font_bytes_fallback_sources_are_same(a_sources, b_sources) &&
      a_text_key_prefix == b_text_key_prefix &&
      a_text == b_text &&
      ax == bx &&
      ay == by &&
      render_layout_config_is_same(a_config, b_config) &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawLoadedFontKeyed(
        a_font_key,
        a_text_key,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawLoadedFontKeyed(
        b_font_key,
        b_text_key,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      a_font_key == b_font_key &&
      a_text_key == b_text_key &&
      a_text == b_text &&
      ax == bx &&
      ay == by &&
      render_layout_config_is_same(a_config, b_config) &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawLoadedFontAtlasKeyed(
        a_font_key,
        a_glyph_key_prefix,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawLoadedFontAtlasKeyed(
        b_font_key,
        b_glyph_key_prefix,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      a_font_key == b_font_key &&
      a_glyph_key_prefix == b_glyph_key_prefix &&
      a_text == b_text &&
      ax == bx &&
      ay == by &&
      render_layout_config_is_same(a_config, b_config) &&
      render_paint_is_same(a_paint, b_paint)
    _ => false
  }
}

///|
fn render_pipeline_parse_font_bytes_fallback_sources(
  sources : Array[FontBytesFallbackSource],
) -> Result[Array[@text.FontFace], @text.FontParseError] {
  let faces : Array[@text.FontFace] = []
  for source in sources {
    match @text.FontFace::from_bytes(source.get_font_data()) {
      Ok(face) => faces.push(face)
      Err(error) => return Err(error)
    }
  }
  Ok(faces)
}

///|
fn render_pipeline_fallback_text_width(
  text : String,
  config : @text.LayoutConfig,
) -> Double {
  if config.max_width > 0.0 {
    config.max_width
  } else {
    text.length().to_double() * config.font_size.max(1.0)
  }
}

///|
fn render_font_bytes_fallback_sources_are_same(
  a : Array[FontBytesFallbackSource],
  b : Array[FontBytesFallbackSource],
) -> Bool {
  guard a.length() == b.length() else { return false }
  for index in 0..<a.length() {
    if a[index].get_font_key() != b[index].get_font_key() {
      return false
    }
  }
  true
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
fn render_layout_config_is_same(
  a : @text.LayoutConfig,
  b : @text.LayoutConfig,
) -> Bool {
  a.max_width == b.max_width &&
  a.font_size == b.font_size &&
  a.line_height == b.line_height &&
  a.alignment == b.alignment &&
  a.letter_spacing == b.letter_spacing &&
  a.word_spacing == b.word_spacing
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
