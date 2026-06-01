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
