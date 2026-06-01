///|
priv enum RenderPipelineImageBytes {
  Bmp(Bytes)
  Png(Bytes)
  Rgba(Bytes, Int, Int)
}

///|
fn RenderPipelineImageBytes::decode(
  self : RenderPipelineImageBytes,
) -> Result[@graphics.Pixmap, @graphics.PixmapDecodeError] {
  match self {
    RenderPipelineImageBytes::Bmp(image_data) =>
      @graphics.Pixmap::from_bmp_bytes(image_data)
    RenderPipelineImageBytes::Png(image_data) =>
      @graphics.Pixmap::from_png_bytes(image_data)
    RenderPipelineImageBytes::Rgba(image_data, image_width, image_height) =>
      @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data)
  }
}

///|
fn RenderPipelineImageBytes::decode_or_abort(
  self : RenderPipelineImageBytes,
) -> @graphics.Pixmap {
  match self {
    RenderPipelineImageBytes::Bmp(image_data) =>
      match @graphics.Pixmap::from_bmp_bytes(image_data) {
        Ok(pixmap) => pixmap
        Err(_) => abort("failed to decode pipeline BMP bytes")
      }
    RenderPipelineImageBytes::Png(image_data) =>
      match @graphics.Pixmap::from_png_bytes(image_data) {
        Ok(pixmap) => pixmap
        Err(_) => abort("failed to decode pipeline PNG bytes")
      }
    RenderPipelineImageBytes::Rgba(image_data, image_width, image_height) =>
      match
        @graphics.Pixmap::from_rgba_bytes(image_width, image_height, image_data) {
        Ok(pixmap) => pixmap
        Err(_) => abort("failed to decode pipeline RGBA bytes")
      }
  }
}

///|
fn render_pipeline_make_image_bytes_dependency(
  command_index : Int,
  resource_key : String,
  image : RenderPipelineImageBytes,
) -> RenderPipelineImageDependency {
  render_pipeline_make_decoded_image_dependency(
    command_index,
    resource_key,
    image.decode(),
  )
}

///|
fn render_pipeline_make_image_bytes_rect_dependency(
  command_index : Int,
  resource_key : String,
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
) -> RenderPipelineImageDependency {
  render_pipeline_make_decoded_rect_image_dependency(
    command_index,
    resource_key,
    image.decode(),
    src_rect,
  )
}

///|
fn render_pipeline_draw_image_bytes(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> Unit {
  canvas.draw_pixmap(image.decode_or_abort(), x, y, paint)
}

///|
fn render_pipeline_draw_image_bytes_rect(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> Unit {
  canvas.draw_pixmap_rect(image.decode_or_abort(), src_rect, x, y, paint)
}

///|
fn render_pipeline_draw_sampled_image_bytes(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Unit {
  canvas.draw_sampled_pixmap(
    image.decode_or_abort(),
    x,
    y,
    width,
    height,
    paint,
    sampling,
  )
}

///|
fn render_pipeline_draw_sampled_image_bytes_rect(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Unit {
  canvas.draw_sampled_pixmap_rect(
    image.decode_or_abort(),
    src_rect,
    x,
    y,
    width,
    height,
    paint,
    sampling,
  )
}

///|
fn render_pipeline_draw_quality_image_bytes(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Unit {
  canvas.draw_quality_pixmap(
    image.decode_or_abort(),
    x,
    y,
    width,
    height,
    paint,
    quality,
  )
}

///|
fn render_pipeline_draw_quality_image_bytes_rect(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Unit {
  canvas.draw_quality_pixmap_rect(
    image.decode_or_abort(),
    src_rect,
    x,
    y,
    width,
    height,
    paint,
    quality,
  )
}

///|
fn render_pipeline_draw_transformed_sampled_image_bytes(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Unit {
  canvas.draw_transformed_sampled_pixmap(
    image.decode_or_abort(),
    x,
    y,
    width,
    height,
    paint,
    sampling,
  )
}

///|
fn render_pipeline_draw_transformed_sampled_image_bytes_rect(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Unit {
  canvas.draw_transformed_sampled_pixmap_rect(
    image.decode_or_abort(),
    src_rect,
    x,
    y,
    width,
    height,
    paint,
    sampling,
  )
}

///|
fn render_pipeline_draw_transformed_quality_image_bytes(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Unit {
  canvas.draw_transformed_quality_pixmap(
    image.decode_or_abort(),
    x,
    y,
    width,
    height,
    paint,
    quality,
  )
}

///|
fn render_pipeline_draw_transformed_quality_image_bytes_rect(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
  quality : @graphics.ImageQuality,
) -> Unit {
  canvas.draw_transformed_quality_pixmap_rect(
    image.decode_or_abort(),
    src_rect,
    x,
    y,
    width,
    height,
    paint,
    quality,
  )
}

///|
fn render_pipeline_draw_tiled_image_bytes_rect(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  paint : @graphics.Paint,
) -> Unit {
  canvas.draw_tiled_pixmap_rect(
    image.decode_or_abort(),
    src_rect,
    x,
    y,
    width,
    height,
    paint,
  )
}

///|
fn render_pipeline_draw_nine_patch_image_bytes(
  canvas : @graphics.Canvas,
  image : RenderPipelineImageBytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  insets : @graphics.NinePatchInsets,
  paint : @graphics.Paint,
  sampling : @graphics.ImageSampling,
) -> Unit {
  canvas.draw_nine_patch_pixmap(
    image.decode_or_abort(),
    x,
    y,
    width,
    height,
    insets,
    paint,
    sampling,
  )
}

///|
fn render_image_bytes_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  x : Int,
  y : Int,
) -> @graphics.PixelRect? {
  render_decoded_pixmap_estimated_dirty_rect(image.decode(), x, y)
}

///|
fn render_image_bytes_rect_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
) -> @graphics.PixelRect? {
  render_decoded_pixmap_rect_estimated_dirty_rect(
    image.decode(),
    src_rect,
    x,
    y,
  )
}

///|
fn render_scaled_image_bytes_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  render_decoded_scaled_pixmap_estimated_dirty_rect(
    image.decode(),
    x,
    y,
    width,
    height,
  )
}

///|
fn render_scaled_image_bytes_rect_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  render_decoded_scaled_pixmap_rect_estimated_dirty_rect(
    image.decode(),
    src_rect,
    x,
    y,
    width,
    height,
  )
}

///|
fn render_transformed_image_bytes_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> @graphics.PixelRect? {
  render_decoded_transformed_pixmap_estimated_dirty_rect(
    image.decode(),
    x,
    y,
    width,
    height,
  )
}

///|
fn render_transformed_image_bytes_rect_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> @graphics.PixelRect? {
  render_decoded_transformed_pixmap_rect_estimated_dirty_rect(
    image.decode(),
    src_rect,
    x,
    y,
    width,
    height,
  )
}

///|
fn render_tiled_image_bytes_rect_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  render_decoded_tiled_pixmap_rect_estimated_dirty_rect(
    image.decode(),
    src_rect,
    x,
    y,
    width,
    height,
  )
}

///|
fn render_nine_patch_image_bytes_estimated_dirty_rect(
  image : RenderPipelineImageBytes,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> @graphics.PixelRect? {
  render_decoded_nine_patch_pixmap_estimated_dirty_rect(
    image.decode(),
    x,
    y,
    width,
    height,
  )
}
