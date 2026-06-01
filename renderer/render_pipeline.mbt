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
      RenderCommand::DrawBmpBytesKeyed(_, image_data, x, y, paint) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) => canvas.draw_pixmap(pixmap, x, y, paint)
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawPngBytesKeyed(_, image_data, x, y, paint) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) => canvas.draw_pixmap(pixmap, x, y, paint)
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawRgbaBytesKeyed(
        _,
        image_data,
        image_width,
        image_height,
        x,
        y,
        paint
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) => canvas.draw_pixmap(pixmap, x, y, paint)
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawSampledBmpBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_sampled_pixmap(
              pixmap, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawSampledPngBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_sampled_pixmap(
              pixmap, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawSampledRgbaBytesKeyed(
        _,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_sampled_pixmap(
              pixmap, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawQualityBmpBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_quality_pixmap(
              pixmap, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawQualityBmpBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_quality_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawQualityPngBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_quality_pixmap(
              pixmap, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawQualityPngBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_quality_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawQualityRgbaBytesKeyed(
        _,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_quality_pixmap(
              pixmap, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawQualityRgbaBytesRectKeyed(
        _,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_quality_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedSampledBmpBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_transformed_sampled_pixmap(
              pixmap, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedSampledBmpBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_transformed_sampled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedSampledPngBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_transformed_sampled_pixmap(
              pixmap, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedSampledPngBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_transformed_sampled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedQualityPngBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_transformed_quality_pixmap(
              pixmap, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedQualityPngBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_transformed_quality_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, quality,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedSampledRgbaBytesKeyed(
        _,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_transformed_sampled_pixmap(
              pixmap, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTransformedSampledRgbaBytesRectKeyed(
        _,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_transformed_sampled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawSampledBmpBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_sampled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawSampledPngBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_sampled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawSampledRgbaBytesRectKeyed(
        _,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_sampled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawBmpBytesRectKeyed(_, image_data, src_rect, x, y, paint) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) => canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawPngBytesRectKeyed(_, image_data, src_rect, x, y, paint) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) => canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawRgbaBytesRectKeyed(
        _,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        paint
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) => canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTiledBmpBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_tiled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTiledPngBytesRectKeyed(
        _,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_tiled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawTiledRgbaBytesRectKeyed(
        _,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_tiled_pixmap_rect(
              pixmap, src_rect, x, y, width, height, paint,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawNinePatchBmpBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_bmp_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_nine_patch_pixmap(
              pixmap, x, y, width, height, insets, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawNinePatchPngBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) => {
        match @graphics.Pixmap::from_png_bytes(image_data) {
          Ok(pixmap) =>
            canvas.draw_nine_patch_pixmap(
              pixmap, x, y, width, height, insets, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
        image_count += 1
      }
      RenderCommand::DrawNinePatchRgbaBytesKeyed(
        _,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) => {
        match
          @graphics.Pixmap::from_rgba_bytes(
            image_width, image_height, image_data,
          ) {
          Ok(pixmap) =>
            canvas.draw_nine_patch_pixmap(
              pixmap, x, y, width, height, insets, paint, sampling,
            )
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
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
      RenderCommand::DrawFontBytesFallbackAtlasKeyed(
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
          Err(_) => abort("failed to parse pipeline fallback atlas font bytes")
        }
        text_count += 1
      }
      RenderCommand::DrawLoadedFontKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font command requires a font loader")
      RenderCommand::DrawLoadedFontFallbackKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font fallback command requires a font loader")
      RenderCommand::DrawLoadedFontFallbackAtlasKeyed(_, _, _, _, _, _, _) =>
        abort(
          "pipeline loaded font fallback atlas command requires a font loader",
        )
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
      RenderCommand::DrawBmpBytesKeyed(resource_key, image_data, x, y, paint) =>
        match
          renderer.draw_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawPngBytesKeyed(resource_key, image_data, x, y, paint) =>
        match
          renderer.draw_png_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, resources, resource_key,
            paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawSampledBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawSampledPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawSampledRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, resources,
            resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawQualityBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawQualityBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawQualityPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawQualityPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawQualityRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, resources,
            resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawQualityRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawTransformedSampledBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawTransformedSampledBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawTransformedSampledPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTransformedSampledPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTransformedQualityPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_transformed_quality_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTransformedQualityPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_transformed_quality_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTransformedSampledRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, resources,
            resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawTransformedSampledRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawSampledBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawSampledPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawSampledRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, resources, resource_key,
            paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawTiledBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) =>
        match
          renderer.draw_tiled_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawTiledPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) =>
        match
          renderer.draw_tiled_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTiledRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) =>
        match
          renderer.draw_tiled_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawNinePatchBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) =>
        match
          renderer.draw_nine_patch_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, insets, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawNinePatchPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) =>
        match
          renderer.draw_nine_patch_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, insets, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawNinePatchRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) =>
        match
          renderer.draw_nine_patch_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, insets, resources,
            resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
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
      RenderCommand::DrawFontBytesFallbackAtlasKeyed(
        sources,
        glyph_key_prefix,
        text,
        x,
        y,
        config,
        paint
      ) => {
        match
          renderer.draw_font_bytes_fallback_line_atlas_with_renderer_resources(
            sources, text, x, y, config, resources, glyph_key_prefix, paint,
          ) {
          Ok(result) => {
            font_parse_count += result.get_parsed_font_count()
            font_cache_hit_count += result.get_font_cache_hit_count()
            glyph_cache_hit_count += result.get_cache_hit_count()
            glyph_mask_render_count += result.get_rasterized_glyph_count()
            atlas_cache_hit_count += result.get_atlas_hit_count()
            atlas_insert_count += result.get_atlas_inserted_count()
            if result.did_clear_atlas() {
              atlas_clear_count += 1
            }
            keyed_atlas_text_count += result.get_drawn_span_count()
          }
          Err(error) => return Err(error)
        }
        keyed_font_count += sources.length()
        text_count += 1
      }
      RenderCommand::DrawLoadedFontKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font command requires a font loader")
      RenderCommand::DrawLoadedFontFallbackKeyed(_, _, _, _, _, _, _) =>
        abort("pipeline loaded font fallback command requires a font loader")
      RenderCommand::DrawLoadedFontFallbackAtlasKeyed(_, _, _, _, _, _, _) =>
        abort(
          "pipeline loaded font fallback atlas command requires a font loader",
        )
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
      RenderCommand::DrawBmpBytesKeyed(resource_key, image_data, x, y, paint) =>
        match
          renderer.draw_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawPngBytesKeyed(resource_key, image_data, x, y, paint) =>
        match
          renderer.draw_png_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, resources, resource_key,
            paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawSampledBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawSampledPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawSampledRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, resources,
            resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawQualityBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawQualityBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawQualityPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawQualityPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawQualityRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, resources,
            resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawQualityRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_quality_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawSampledBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawSampledPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawSampledRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_sampled_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        paint
      ) =>
        match
          renderer.draw_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, resources, resource_key,
            paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawTiledBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) =>
        match
          renderer.draw_tiled_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawTiledPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) =>
        match
          renderer.draw_tiled_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTiledRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint
      ) =>
        match
          renderer.draw_tiled_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawNinePatchBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) =>
        match
          renderer.draw_nine_patch_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, insets, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawNinePatchPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) =>
        match
          renderer.draw_nine_patch_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, insets, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawNinePatchRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        insets,
        paint,
        sampling
      ) =>
        match
          renderer.draw_nine_patch_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, insets, resources,
            resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
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
      RenderCommand::DrawFontBytesFallbackAtlasKeyed(
        sources,
        glyph_key_prefix,
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
        let result = renderer.draw_text_fallback_line_atlas_with_renderer_resources(
          faces, text, x, y, config, resources, glyph_key_prefix, paint,
        )
        font_parse_count += command_font_parse_count
        font_cache_hit_count += command_font_cache_hit_count
        glyph_cache_hit_count += result.get_cache_hit_count()
        glyph_mask_render_count += result.get_rasterized_glyph_count()
        atlas_cache_hit_count += result.get_atlas_hit_count()
        atlas_insert_count += result.get_atlas_inserted_count()
        if result.did_clear_atlas() {
          atlas_clear_count += 1
        }
        keyed_font_count += sources.length()
        keyed_atlas_text_count += result.get_drawn_span_count()
        text_count += 1
      }
      RenderCommand::DrawTransformedSampledBmpBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawTransformedSampledBmpBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_bmp_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline BMP bytes")
        }
      RenderCommand::DrawTransformedSampledPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTransformedSampledPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTransformedSampledRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, width, height, resources,
            resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawTransformedSampledRgbaBytesRectKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        sampling
      ) =>
        match
          renderer.draw_transformed_sampled_rgba_bytes_rect_cached_with_renderer_resources(
            image_data, image_width, image_height, src_rect, x, y, width, height,
            resources, resource_key, paint, sampling,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline RGBA bytes")
        }
      RenderCommand::DrawTransformedQualityPngBytesKeyed(
        resource_key,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_transformed_quality_png_bytes_cached_with_renderer_resources(
            image_data, x, y, width, height, resources, resource_key, paint, quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
        }
      RenderCommand::DrawTransformedQualityPngBytesRectKeyed(
        resource_key,
        image_data,
        src_rect,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) =>
        match
          renderer.draw_transformed_quality_png_bytes_rect_cached_with_renderer_resources(
            image_data, src_rect, x, y, width, height, resources, resource_key, paint,
            quality,
          ) {
          Ok(result) => {
            if result.did_hit_cache() {
              image_cache_hit_count += 1
            } else {
              image_cache_insert_count += 1
            }
            keyed_image_count += 1
            image_count += 1
          }
          Err(_) => abort("failed to decode pipeline PNG bytes")
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
      RenderCommand::DrawLoadedFontFallbackKeyed(
        font_keys,
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
        for font_key in font_keys {
          match resources.get_or_load_font_face_result(font_key, loader) {
            Ok(load_result) => {
              faces.push(load_result.get_face())
              if load_result.did_parse() {
                command_font_parse_count += 1
              } else {
                command_font_cache_hit_count += 1
              }
            }
            Err(error) => return Err(error)
          }
        }
        let result = renderer.draw_text_fallback_line_cached_with_renderer_resources(
          faces, text, x, y, config, resources, text_key_prefix, paint,
        )
        font_parse_count += command_font_parse_count
        font_cache_hit_count += command_font_cache_hit_count
        text_mask_render_count += result.get_rendered_mask_count()
        text_cache_hit_count += result.get_cache_hit_count()
        keyed_font_count += font_keys.length()
        keyed_text_count += result.get_drawn_span_count()
        text_count += 1
      }
      RenderCommand::DrawLoadedFontFallbackAtlasKeyed(
        font_keys,
        glyph_key_prefix,
        text,
        x,
        y,
        config,
        paint
      ) => {
        let faces : Array[@text.FontFace] = []
        let mut command_font_parse_count = 0
        let mut command_font_cache_hit_count = 0
        for font_key in font_keys {
          match resources.get_or_load_font_face_result(font_key, loader) {
            Ok(load_result) => {
              faces.push(load_result.get_face())
              if load_result.did_parse() {
                command_font_parse_count += 1
              } else {
                command_font_cache_hit_count += 1
              }
            }
            Err(error) => return Err(error)
          }
        }
        let result = renderer.draw_text_fallback_line_atlas_with_renderer_resources(
          faces, text, x, y, config, resources, glyph_key_prefix, paint,
        )
        font_parse_count += command_font_parse_count
        font_cache_hit_count += command_font_cache_hit_count
        glyph_cache_hit_count += result.get_cache_hit_count()
        glyph_mask_render_count += result.get_rasterized_glyph_count()
        atlas_cache_hit_count += result.get_atlas_hit_count()
        atlas_insert_count += result.get_atlas_inserted_count()
        if result.did_clear_atlas() {
          atlas_clear_count += 1
        }
        keyed_font_count += font_keys.length()
        keyed_atlas_text_count += result.get_drawn_span_count()
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
fn render_pipeline_make_bmp_bytes_image_dependency(
  command_index : Int,
  resource_key : String,
  image_data : Bytes,
) -> RenderPipelineImageDependency {
  match @graphics.Pixmap::from_bmp_bytes(image_data) {
    Ok(pixmap) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        pixmap.get_width(),
        pixmap.get_height(),
      )
    Err(_) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        0,
        0,
      )
  }
}

///|
fn render_pipeline_make_png_bytes_image_dependency(
  command_index : Int,
  resource_key : String,
  image_data : Bytes,
) -> RenderPipelineImageDependency {
  match @graphics.Pixmap::from_png_bytes(image_data) {
    Ok(pixmap) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        pixmap.get_width(),
        pixmap.get_height(),
      )
    Err(_) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        0,
        0,
      )
  }
}

///|
fn render_pipeline_make_rgba_bytes_image_dependency(
  command_index : Int,
  resource_key : String,
  image_data : Bytes,
  image_width : Int,
  image_height : Int,
) -> RenderPipelineImageDependency {
  match
    @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
    Ok(pixmap) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        pixmap.get_width(),
        pixmap.get_height(),
      )
    Err(_) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        0,
        0,
      )
  }
}

///|
fn render_pipeline_make_bmp_bytes_rect_image_dependency(
  command_index : Int,
  resource_key : String,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
) -> RenderPipelineImageDependency {
  match @graphics.Pixmap::from_bmp_bytes(image_data) {
    Ok(pixmap) =>
      render_pipeline_make_rect_image_dependency(
        command_index,
        Some(resource_key),
        pixmap,
        src_rect,
      )
    Err(_) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        0,
        0,
      )
  }
}

///|
fn render_pipeline_make_png_bytes_rect_image_dependency(
  command_index : Int,
  resource_key : String,
  image_data : Bytes,
  src_rect : @graphics.PixelRect,
) -> RenderPipelineImageDependency {
  match @graphics.Pixmap::from_png_bytes(image_data) {
    Ok(pixmap) =>
      render_pipeline_make_rect_image_dependency(
        command_index,
        Some(resource_key),
        pixmap,
        src_rect,
      )
    Err(_) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        0,
        0,
      )
  }
}

///|
fn render_pipeline_make_rgba_bytes_rect_image_dependency(
  command_index : Int,
  resource_key : String,
  image_data : Bytes,
  image_width : Int,
  image_height : Int,
  src_rect : @graphics.PixelRect,
) -> RenderPipelineImageDependency {
  match
    @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
    Ok(pixmap) =>
      render_pipeline_make_rect_image_dependency(
        command_index,
        Some(resource_key),
        pixmap,
        src_rect,
      )
    Err(_) =>
      render_pipeline_make_image_dependency(
        command_index,
        Some(resource_key),
        0,
        0,
      )
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
    | RenderCommand::DrawBmpBytesKeyed(_, _, _, _, _)
    | RenderCommand::DrawPngBytesKeyed(_, _, _, _, _)
    | RenderCommand::DrawRgbaBytesKeyed(_, _, _, _, _, _, _)
    | RenderCommand::DrawSampledBmpBytesKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawSampledPngBytesKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawSampledRgbaBytesKeyed(_, _, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawQualityBmpBytesKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawQualityBmpBytesRectKeyed(_, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawQualityPngBytesKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawQualityPngBytesRectKeyed(_, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawQualityRgbaBytesKeyed(_, _, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawQualityRgbaBytesRectKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
    | RenderCommand::DrawTransformedSampledBmpBytesKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawTransformedSampledBmpBytesRectKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
    | RenderCommand::DrawTransformedSampledPngBytesKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawTransformedSampledPngBytesRectKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
    | RenderCommand::DrawTransformedQualityPngBytesKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawTransformedQualityPngBytesRectKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
    | RenderCommand::DrawTransformedSampledRgbaBytesKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
    | RenderCommand::DrawTransformedSampledRgbaBytesRectKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
    | RenderCommand::DrawSampledBmpBytesRectKeyed(_, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawSampledPngBytesRectKeyed(_, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawSampledRgbaBytesRectKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
    | RenderCommand::DrawBmpBytesRectKeyed(_, _, _, _, _, _)
    | RenderCommand::DrawPngBytesRectKeyed(_, _, _, _, _, _)
    | RenderCommand::DrawRgbaBytesRectKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawTiledBmpBytesRectKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawTiledPngBytesRectKeyed(_, _, _, _, _, _, _, _)
    | RenderCommand::DrawTiledRgbaBytesRectKeyed(_, _, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawNinePatchBmpBytesKeyed(_, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawNinePatchPngBytesKeyed(_, _, _, _, _, _, _, _, _)
    | RenderCommand::DrawNinePatchRgbaBytesKeyed(
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    )
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
    RenderCommand::DrawFontBytesFallbackAtlasKeyed(_, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawLoadedFontKeyed(_, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawLoadedFontFallbackKeyed(_, _, _, _, _, _, _) =>
      RenderPipelineBatchKind::Text
    RenderCommand::DrawLoadedFontFallbackAtlasKeyed(_, _, _, _, _, _, _) =>
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
    RenderCommand::DrawBmpBytesKeyed(_, image_data, x, y, _) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          non_empty_pixel_rect(
            @graphics.PixelRect::new(
              x~,
              y~,
              width=pixmap.get_width(),
              height=pixmap.get_height(),
            ),
          )
        Err(_) => None
      }
    RenderCommand::DrawPngBytesKeyed(_, image_data, x, y, _) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          non_empty_pixel_rect(
            @graphics.PixelRect::new(
              x~,
              y~,
              width=pixmap.get_width(),
              height=pixmap.get_height(),
            ),
          )
        Err(_) => None
      }
    RenderCommand::DrawRgbaBytesKeyed(
      _,
      image_data,
      image_width,
      image_height,
      x,
      y,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          non_empty_pixel_rect(
            @graphics.PixelRect::new(
              x~,
              y~,
              width=pixmap.get_width(),
              height=pixmap.get_height(),
            ),
          )
        Err(_) => None
      }
    RenderCommand::DrawSampledBmpBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
        Err(_) => None
      }
    RenderCommand::DrawSampledPngBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
        Err(_) => None
      }
    RenderCommand::DrawSampledRgbaBytesKeyed(
      _,
      image_data,
      image_width,
      image_height,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
        Err(_) => None
      }
    RenderCommand::DrawQualityBmpBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
        Err(_) => None
      }
    RenderCommand::DrawQualityBmpBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawQualityPngBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
        Err(_) => None
      }
    RenderCommand::DrawQualityPngBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawQualityRgbaBytesKeyed(
      _,
      image_data,
      image_width,
      image_height,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
        Err(_) => None
      }
    RenderCommand::DrawQualityRgbaBytesRectKeyed(
      _,
      image_data,
      image_width,
      image_height,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedSampledBmpBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_estimated_dirty_rect(
            pixmap, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedSampledBmpBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedSampledPngBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_estimated_dirty_rect(
            pixmap, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedSampledPngBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedQualityPngBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_estimated_dirty_rect(
            pixmap, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedQualityPngBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedSampledRgbaBytesKeyed(
      _,
      image_data,
      image_width,
      image_height,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_estimated_dirty_rect(
            pixmap, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTransformedSampledRgbaBytesRectKeyed(
      _,
      image_data,
      image_width,
      image_height,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_transformed_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawSampledBmpBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawSampledPngBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawSampledRgbaBytesRectKeyed(
      _,
      image_data,
      image_width,
      image_height,
      src_rect,
      x,
      y,
      width,
      height,
      _,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_scaled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawBmpBytesRectKeyed(_, image_data, src_rect, x, y, _) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_pixmap_rect_estimated_dirty_rect(pixmap, src_rect, x, y)
        Err(_) => None
      }
    RenderCommand::DrawPngBytesRectKeyed(_, image_data, src_rect, x, y, _) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_pixmap_rect_estimated_dirty_rect(pixmap, src_rect, x, y)
        Err(_) => None
      }
    RenderCommand::DrawRgbaBytesRectKeyed(
      _,
      image_data,
      image_width,
      image_height,
      src_rect,
      x,
      y,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_pixmap_rect_estimated_dirty_rect(pixmap, src_rect, x, y)
        Err(_) => None
      }
    RenderCommand::DrawTiledBmpBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_tiled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTiledPngBytesRectKeyed(
      _,
      image_data,
      src_rect,
      x,
      y,
      width,
      height,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_tiled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawTiledRgbaBytesRectKeyed(
      _,
      image_data,
      image_width,
      image_height,
      src_rect,
      x,
      y,
      width,
      height,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_tiled_pixmap_rect_estimated_dirty_rect(
            pixmap, src_rect, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawNinePatchBmpBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) =>
          render_nine_patch_pixmap_estimated_dirty_rect(
            pixmap, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawNinePatchPngBytesKeyed(
      _,
      image_data,
      x,
      y,
      width,
      height,
      _,
      _,
      _
    ) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) =>
          render_nine_patch_pixmap_estimated_dirty_rect(
            pixmap, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawNinePatchRgbaBytesKeyed(
      _,
      image_data,
      image_width,
      image_height,
      x,
      y,
      width,
      height,
      _,
      _,
      _
    ) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) =>
          render_nine_patch_pixmap_estimated_dirty_rect(
            pixmap, x, y, width, height,
          )
        Err(_) => None
      }
    RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, _) =>
      render_pixmap_rect_estimated_dirty_rect(pixmap, src_rect, x, y)
    RenderCommand::DrawPixmapRectKeyed(_, pixmap, src_rect, x, y, _) =>
      render_pixmap_rect_estimated_dirty_rect(pixmap, src_rect, x, y)
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
    RenderCommand::DrawFontBytesFallbackAtlasKeyed(_, _, text, x, y, config, _) => {
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
    RenderCommand::DrawLoadedFontFallbackKeyed(_, _, text, x, y, config, _) => {
      guard text.length() > 0 else { return None }
      pixel_rect_from_double_bounds(
        x,
        y,
        x + render_pipeline_fallback_text_width(text, config),
        y + config.line_height.max(config.font_size),
      )
    }
    RenderCommand::DrawLoadedFontFallbackAtlasKeyed(_, _, text, x, y, config, _) => {
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
fn render_scaled_pixmap_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  guard width > 0 && height > 0 else { return None }
  guard pixmap.get_width() > 0 && pixmap.get_height() > 0 else { return None }
  non_empty_pixel_rect(@graphics.PixelRect::new(x~, y~, width~, height~))
}

///|
fn render_transformed_pixmap_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> @graphics.PixelRect? {
  guard width > 0.0 && height > 0.0 else { return None }
  guard pixmap.get_width() > 0 && pixmap.get_height() > 0 else { return None }
  pixel_rect_from_double_bounds(x, y, x + width, y + height)
}

///|
fn render_transformed_pixmap_rect_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> @graphics.PixelRect? {
  guard width > 0.0 && height > 0.0 else { return None }
  let src_bounds = @graphics.PixelRect::new(
    x=0,
    y=0,
    width=pixmap.get_width(),
    height=pixmap.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) =>
      if clipped_src.is_empty() {
        None
      } else {
        pixel_rect_from_double_bounds(x, y, x + width, y + height)
      }
    None => None
  }
}

///|
fn render_scaled_pixmap_rect_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  guard width > 0 && height > 0 else { return None }
  let src_bounds = @graphics.PixelRect::new(
    x=0,
    y=0,
    width=pixmap.get_width(),
    height=pixmap.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) =>
      if clipped_src.is_empty() {
        None
      } else {
        non_empty_pixel_rect(@graphics.PixelRect::new(x~, y~, width~, height~))
      }
    None => None
  }
}

///|
fn render_nine_patch_pixmap_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  guard width > 0 && height > 0 else { return None }
  guard pixmap.get_width() > 0 && pixmap.get_height() > 0 else { return None }
  non_empty_pixel_rect(@graphics.PixelRect::new(x~, y~, width~, height~))
}

///|
fn render_tiled_pixmap_rect_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  guard width > 0 && height > 0 else { return None }
  let src_bounds = @graphics.PixelRect::new(
    x=0,
    y=0,
    width=pixmap.get_width(),
    height=pixmap.get_height(),
  )
  match src_rect.clip_to(src_bounds) {
    Some(clipped_src) =>
      if clipped_src.is_empty() {
        None
      } else {
        non_empty_pixel_rect(@graphics.PixelRect::new(x~, y~, width~, height~))
      }
    None => None
  }
}

///|
fn render_pixmap_rect_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
) -> @graphics.PixelRect? {
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
      RenderCommand::DrawBmpBytesKeyed(a_key, _, ax, ay, a_paint),
      RenderCommand::DrawBmpBytesKeyed(b_key, _, bx, by, b_paint),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawPngBytesKeyed(a_key, _, ax, ay, a_paint),
      RenderCommand::DrawPngBytesKeyed(b_key, _, bx, by, b_paint),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawRgbaBytesKeyed(
        a_key,
        _,
        a_width,
        a_height,
        ax,
        ay,
        a_paint
      ),
      RenderCommand::DrawRgbaBytesKeyed(
        b_key,
        _,
        b_width,
        b_height,
        bx,
        by,
        b_paint
      ),
    ) =>
      a_key == b_key &&
      a_width == b_width &&
      a_height == b_height &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawSampledBmpBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawSampledBmpBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawSampledPngBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawSampledPngBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawSampledRgbaBytesKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawSampledRgbaBytesKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawQualityBmpBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawQualityBmpBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawQualityBmpBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawQualityBmpBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawQualityPngBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawQualityPngBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawQualityPngBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawQualityPngBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawQualityRgbaBytesKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawQualityRgbaBytesKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawQualityRgbaBytesRectKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawQualityRgbaBytesRectKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawTransformedSampledBmpBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawTransformedSampledBmpBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawTransformedSampledBmpBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawTransformedSampledBmpBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawTransformedSampledPngBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawTransformedSampledPngBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawTransformedSampledPngBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawTransformedSampledPngBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawTransformedQualityPngBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawTransformedQualityPngBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawTransformedQualityPngBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_quality
      ),
      RenderCommand::DrawTransformedQualityPngBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_quality
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_quality == b_quality
    (
      RenderCommand::DrawTransformedSampledRgbaBytesKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawTransformedSampledRgbaBytesKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawTransformedSampledRgbaBytesRectKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawTransformedSampledRgbaBytesRectKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawSampledBmpBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawSampledBmpBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawSampledPngBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawSampledPngBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawSampledRgbaBytesRectKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawSampledRgbaBytesRectKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawBmpBytesRectKeyed(a_key, _, a_src, ax, ay, a_paint),
      RenderCommand::DrawBmpBytesRectKeyed(b_key, _, b_src, bx, by, b_paint),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawPngBytesRectKeyed(a_key, _, a_src, ax, ay, a_paint),
      RenderCommand::DrawPngBytesRectKeyed(b_key, _, b_src, bx, by, b_paint),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawRgbaBytesRectKeyed(
        a_key,
        _,
        a_width,
        a_height,
        a_src,
        ax,
        ay,
        a_paint
      ),
      RenderCommand::DrawRgbaBytesRectKeyed(
        b_key,
        _,
        b_width,
        b_height,
        b_src,
        bx,
        by,
        b_paint
      ),
    ) =>
      a_key == b_key &&
      a_width == b_width &&
      a_height == b_height &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawTiledBmpBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint
      ),
      RenderCommand::DrawTiledBmpBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawTiledPngBytesRectKeyed(
        a_key,
        _,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint
      ),
      RenderCommand::DrawTiledPngBytesRectKeyed(
        b_key,
        _,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint
      ),
    ) =>
      a_key == b_key &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawTiledRgbaBytesRectKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        a_src,
        ax,
        ay,
        aw,
        ah,
        a_paint
      ),
      RenderCommand::DrawTiledRgbaBytesRectKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        b_src,
        bx,
        by,
        bw,
        bh,
        b_paint
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      a_src == b_src &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawNinePatchBmpBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_insets,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawNinePatchBmpBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_insets,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      a_insets == b_insets &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawNinePatchPngBytesKeyed(
        a_key,
        _,
        ax,
        ay,
        aw,
        ah,
        a_insets,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawNinePatchPngBytesKeyed(
        b_key,
        _,
        bx,
        by,
        bw,
        bh,
        b_insets,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      a_insets == b_insets &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
    (
      RenderCommand::DrawNinePatchRgbaBytesKeyed(
        a_key,
        _,
        a_image_width,
        a_image_height,
        ax,
        ay,
        aw,
        ah,
        a_insets,
        a_paint,
        a_sampling
      ),
      RenderCommand::DrawNinePatchRgbaBytesKeyed(
        b_key,
        _,
        b_image_width,
        b_image_height,
        bx,
        by,
        bw,
        bh,
        b_insets,
        b_paint,
        b_sampling
      ),
    ) =>
      a_key == b_key &&
      a_image_width == b_image_width &&
      a_image_height == b_image_height &&
      ax == bx &&
      ay == by &&
      aw == bw &&
      ah == bh &&
      a_insets == b_insets &&
      render_paint_is_same(a_paint, b_paint) &&
      a_sampling == b_sampling
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
      RenderCommand::DrawFontBytesFallbackAtlasKeyed(
        a_sources,
        a_glyph_key_prefix,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawFontBytesFallbackAtlasKeyed(
        b_sources,
        b_glyph_key_prefix,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      render_font_bytes_fallback_sources_are_same(a_sources, b_sources) &&
      a_glyph_key_prefix == b_glyph_key_prefix &&
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
      RenderCommand::DrawLoadedFontFallbackKeyed(
        a_font_keys,
        a_text_key_prefix,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawLoadedFontFallbackKeyed(
        b_font_keys,
        b_text_key_prefix,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      string_arrays_are_same(a_font_keys, b_font_keys) &&
      a_text_key_prefix == b_text_key_prefix &&
      a_text == b_text &&
      ax == bx &&
      ay == by &&
      render_layout_config_is_same(a_config, b_config) &&
      render_paint_is_same(a_paint, b_paint)
    (
      RenderCommand::DrawLoadedFontFallbackAtlasKeyed(
        a_font_keys,
        a_glyph_key_prefix,
        a_text,
        ax,
        ay,
        a_config,
        a_paint
      ),
      RenderCommand::DrawLoadedFontFallbackAtlasKeyed(
        b_font_keys,
        b_glyph_key_prefix,
        b_text,
        bx,
        by,
        b_config,
        b_paint
      ),
    ) =>
      string_arrays_are_same(a_font_keys, b_font_keys) &&
      a_glyph_key_prefix == b_glyph_key_prefix &&
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
fn string_arrays_are_same(a : Array[String], b : Array[String]) -> Bool {
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
