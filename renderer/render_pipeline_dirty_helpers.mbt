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
      render_pixmap_estimated_dirty_rect(pixmap, x, y)
    RenderCommand::DrawPixmapKeyed(_, pixmap, x, y, _) =>
      render_pixmap_estimated_dirty_rect(pixmap, x, y)
    RenderCommand::DrawBmpBytesKeyed(_, image_data, x, y, _) =>
      render_decoded_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        x,
        y,
      )
    RenderCommand::DrawPngBytesKeyed(_, image_data, x, y, _) =>
      render_decoded_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        x,
        y,
      )
    RenderCommand::DrawRgbaBytesKeyed(
      _,
      image_data,
      image_width,
      image_height,
      x,
      y,
      _
    ) =>
      render_decoded_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        x,
        y,
      )
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
      render_decoded_scaled_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_transformed_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
    RenderCommand::DrawBmpBytesRectKeyed(_, image_data, src_rect, x, y, _) =>
      render_decoded_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        src_rect,
        x,
        y,
      )
    RenderCommand::DrawPngBytesRectKeyed(_, image_data, src_rect, x, y, _) =>
      render_decoded_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        src_rect,
        x,
        y,
      )
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
      render_decoded_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        src_rect,
        x,
        y,
      )
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
      render_decoded_tiled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_tiled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_tiled_pixmap_rect_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        src_rect,
        x,
        y,
        width,
        height,
      )
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
      render_decoded_nine_patch_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_bmp_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_nine_patch_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_png_bytes(image_data),
        x,
        y,
        width,
        height,
      )
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
      render_decoded_nine_patch_pixmap_estimated_dirty_rect(
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data),
        x,
        y,
        width,
        height,
      )
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
fn render_decoded_pixmap_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  x : Int,
  y : Int,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) => render_pixmap_estimated_dirty_rect(pixmap, x, y)
    Err(_) => None
  }
}

///|
fn render_decoded_scaled_pixmap_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) =>
      render_scaled_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
    Err(_) => None
  }
}

///|
fn render_decoded_transformed_pixmap_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) =>
      render_transformed_pixmap_estimated_dirty_rect(
        pixmap, x, y, width, height,
      )
    Err(_) => None
  }
}

///|
fn render_decoded_transformed_pixmap_rect_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) =>
      render_transformed_pixmap_rect_estimated_dirty_rect(
        pixmap, src_rect, x, y, width, height,
      )
    Err(_) => None
  }
}

///|
fn render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) =>
      render_scaled_pixmap_rect_estimated_dirty_rect(
        pixmap, src_rect, x, y, width, height,
      )
    Err(_) => None
  }
}

///|
fn render_decoded_pixmap_rect_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) =>
      render_pixmap_rect_estimated_dirty_rect(pixmap, src_rect, x, y)
    Err(_) => None
  }
}

///|
fn render_decoded_tiled_pixmap_rect_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) =>
      render_tiled_pixmap_rect_estimated_dirty_rect(
        pixmap, src_rect, x, y, width, height,
      )
    Err(_) => None
  }
}

///|
fn render_decoded_nine_patch_pixmap_estimated_dirty_rect(
  decoded : Result[@graphics.Pixmap, @graphics.PixmapDecodeError],
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  match decoded {
    Ok(pixmap) =>
      render_nine_patch_pixmap_estimated_dirty_rect(pixmap, x, y, width, height)
    Err(_) => None
  }
}

///|
fn render_pixmap_estimated_dirty_rect(
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
) -> @graphics.PixelRect? {
  non_empty_pixel_rect(
    @graphics.PixelRect::new(
      x~,
      y~,
      width=pixmap.get_width(),
      height=pixmap.get_height(),
    ),
  )
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
