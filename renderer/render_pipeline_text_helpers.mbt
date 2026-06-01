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
