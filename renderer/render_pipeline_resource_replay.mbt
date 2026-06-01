///|
priv struct RenderPipelineImageCacheReplayCounters {
  mut keyed_image_count : Int
  mut image_cache_hit_count : Int
  mut image_cache_insert_count : Int
}

///|
fn RenderPipelineImageCacheReplayCounters::new() -> RenderPipelineImageCacheReplayCounters {
  {
    keyed_image_count: 0,
    image_cache_hit_count: 0,
    image_cache_insert_count: 0,
  }
}

///|
fn RenderPipelineImageCacheReplayCounters::record_cached_image(
  self : RenderPipelineImageCacheReplayCounters,
  did_hit_cache : Bool,
) -> Unit {
  if did_hit_cache {
    self.image_cache_hit_count += 1
  } else {
    self.image_cache_insert_count += 1
  }
  self.keyed_image_count += 1
}

///|
fn record_bmp_image_replay_result(
  counters : RenderPipelineImageCacheReplayCounters,
  result : Result[CachedBmpPixmapDrawResult, @graphics.PixmapDecodeError],
) -> Unit {
  match result {
    Ok(result) => counters.record_cached_image(result.did_hit_cache())
    Err(_) => abort("failed to decode pipeline BMP bytes")
  }
}

///|
fn record_png_image_replay_result(
  counters : RenderPipelineImageCacheReplayCounters,
  result : Result[CachedPngPixmapDrawResult, @graphics.PixmapDecodeError],
) -> Unit {
  match result {
    Ok(result) => counters.record_cached_image(result.did_hit_cache())
    Err(_) => abort("failed to decode pipeline PNG bytes")
  }
}

///|
fn record_rgba_image_replay_result(
  counters : RenderPipelineImageCacheReplayCounters,
  result : Result[CachedRgbaPixmapDrawResult, @graphics.PixmapDecodeError],
) -> Unit {
  match result {
    Ok(result) => counters.record_cached_image(result.did_hit_cache())
    Err(_) => abort("failed to decode pipeline RGBA bytes")
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
  let image_cache_counters = RenderPipelineImageCacheReplayCounters::new()
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
        image_cache_counters.record_cached_image(result.did_hit_cache())
        image_count += 1
      }
      RenderCommand::DrawBmpBytesKeyed(resource_key, image_data, x, y, paint) => {
        record_bmp_image_replay_result(
          image_cache_counters,
          renderer.draw_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ),
        )
        image_count += 1
      }
      RenderCommand::DrawPngBytesKeyed(resource_key, image_data, x, y, paint) => {
        record_png_image_replay_result(
          image_cache_counters,
          renderer.draw_png_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ),
        )
        image_count += 1
      }
      RenderCommand::DrawRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        paint
      ) => {
        record_rgba_image_replay_result(
          image_cache_counters,
          renderer.draw_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, resources, resource_key,
            paint,
          ),
        )
        image_count += 1
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
        image_cache_counters.record_cached_image(result.did_hit_cache())
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
    keyed_image_count: image_cache_counters.keyed_image_count,
    image_cache_hit_count: image_cache_counters.image_cache_hit_count,
    image_cache_insert_count: image_cache_counters.image_cache_insert_count,
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
  let image_cache_counters = RenderPipelineImageCacheReplayCounters::new()
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
        image_cache_counters.record_cached_image(result.did_hit_cache())
        image_count += 1
      }
      RenderCommand::DrawBmpBytesKeyed(resource_key, image_data, x, y, paint) => {
        record_bmp_image_replay_result(
          image_cache_counters,
          renderer.draw_bmp_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ),
        )
        image_count += 1
      }
      RenderCommand::DrawPngBytesKeyed(resource_key, image_data, x, y, paint) => {
        record_png_image_replay_result(
          image_cache_counters,
          renderer.draw_png_bytes_cached_with_renderer_resources(
            image_data, x, y, resources, resource_key, paint,
          ),
        )
        image_count += 1
      }
      RenderCommand::DrawRgbaBytesKeyed(
        resource_key,
        image_data,
        image_width,
        image_height,
        x,
        y,
        paint
      ) => {
        record_rgba_image_replay_result(
          image_cache_counters,
          renderer.draw_rgba_bytes_cached_with_renderer_resources(
            image_data, image_width, image_height, x, y, resources, resource_key,
            paint,
          ),
        )
        image_count += 1
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
        image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
            image_cache_counters.record_cached_image(result.did_hit_cache())
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
    keyed_image_count: image_cache_counters.keyed_image_count,
    image_cache_hit_count: image_cache_counters.image_cache_hit_count,
    image_cache_insert_count: image_cache_counters.image_cache_insert_count,
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
