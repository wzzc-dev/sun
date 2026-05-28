///|
test "layout_paragraph with short text" {
  let font = FontData::new(b"fake_font_data")
  let config = LayoutConfig::new(
    max_width=800.0,
    font_size=16.0,
    line_height=24.0,
  )
  let paragraph = layout_paragraph("Hello World", font, config)
  let lines = paragraph.get_lines()
  // Short text should fit in one line
  assert_eq(lines.length(), 1)
}

///|
test "layout_paragraph with long text wraps" {
  let font = FontData::new(b"fake_font_data")
  let config = LayoutConfig::new(
    max_width=100.0,
    font_size=16.0,
    line_height=24.0,
  )
  let text = "This is a long text that should wrap"
  let paragraph = layout_paragraph(text, font, config)
  let lines = paragraph.get_lines()
  // With max_width=100 and char_width=9.6 (16*0.6), about 10 chars per line
  // 36 chars / 10 = ~4 lines
  assert_true(lines.length() > 1)
}

///|
test "LayoutMetrics" {
  let metrics = LayoutMetrics::new(width=100.0, height=50.0, baseline=16.0)
  assert_eq(metrics.width, 100.0)
  assert_eq(metrics.height, 50.0)
  assert_eq(metrics.baseline, 16.0)
}
