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
