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
        render_pipeline_draw_image_bytes(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          x,
          y,
          paint,
        )
        image_count += 1
      }
      RenderCommand::DrawPngBytesKeyed(_, image_data, x, y, paint) => {
        render_pipeline_draw_image_bytes(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          x,
          y,
          paint,
        )
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
        render_pipeline_draw_image_bytes(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          x,
          y,
          paint,
        )
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
        render_pipeline_draw_sampled_image_bytes(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_sampled_image_bytes(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_sampled_image_bytes(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_quality_image_bytes(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_quality_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_quality_image_bytes(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_quality_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_quality_image_bytes(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_quality_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_transformed_sampled_image_bytes(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_transformed_sampled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
        image_count += 1
      }
      RenderCommand::DrawTransformedQualityBmpBytesKeyed(
        _,
        image_data,
        x,
        y,
        width,
        height,
        paint,
        quality
      ) => {
        render_pipeline_draw_transformed_quality_image_bytes(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
        image_count += 1
      }
      RenderCommand::DrawTransformedQualityBmpBytesRectKeyed(
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
        render_pipeline_draw_transformed_quality_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_transformed_sampled_image_bytes(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_transformed_sampled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_transformed_quality_image_bytes(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_transformed_quality_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_transformed_sampled_image_bytes(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_transformed_sampled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
        image_count += 1
      }
      RenderCommand::DrawTransformedQualityRgbaBytesKeyed(
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
        render_pipeline_draw_transformed_quality_image_bytes(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
        image_count += 1
      }
      RenderCommand::DrawTransformedQualityRgbaBytesRectKeyed(
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
        render_pipeline_draw_transformed_quality_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          quality,
        )
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
        render_pipeline_draw_sampled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_sampled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
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
        render_pipeline_draw_sampled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
          sampling,
        )
        image_count += 1
      }
      RenderCommand::DrawBmpBytesRectKeyed(_, image_data, src_rect, x, y, paint) => {
        render_pipeline_draw_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          src_rect,
          x,
          y,
          paint,
        )
        image_count += 1
      }
      RenderCommand::DrawPngBytesRectKeyed(_, image_data, src_rect, x, y, paint) => {
        render_pipeline_draw_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          src_rect,
          x,
          y,
          paint,
        )
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
        render_pipeline_draw_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          src_rect,
          x,
          y,
          paint,
        )
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
        render_pipeline_draw_tiled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
        )
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
        render_pipeline_draw_tiled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
        )
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
        render_pipeline_draw_tiled_image_bytes_rect(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          src_rect,
          x,
          y,
          width,
          height,
          paint,
        )
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
        render_pipeline_draw_nine_patch_image_bytes(
          canvas,
          RenderPipelineImageBytes::Bmp(image_data),
          x,
          y,
          width,
          height,
          insets,
          paint,
          sampling,
        )
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
        render_pipeline_draw_nine_patch_image_bytes(
          canvas,
          RenderPipelineImageBytes::Png(image_data),
          x,
          y,
          width,
          height,
          insets,
          paint,
          sampling,
        )
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
        render_pipeline_draw_nine_patch_image_bytes(
          canvas,
          RenderPipelineImageBytes::Rgba(image_data, image_width, image_height),
          x,
          y,
          width,
          height,
          insets,
          paint,
          sampling,
        )
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
