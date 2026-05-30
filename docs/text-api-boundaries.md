# Text API Boundaries

The `text` package currently exposes both low-level parser structures and a
higher-level facade for GUI and renderer code. New rendering code should prefer
the facade types below.

## Stable Facade

- `FontData` is a raw font-byte container. It can preserve a future font-index
  choice for TTC/OTC support, but it should not be treated as a parsed face.
- `FontFace` is a checked parsed font face. Construct it with
  `FontFace::from_bytes`, `FontFace::from_data`, or `FontData::parse` so parse
  failures stay in `Result` instead of aborting.
- `FontFaceCache` is a small keyed cache for checked parsed faces. GUI and
  resource-loading code can use `get_or_parse` to avoid reparsing the same font
  bytes while preserving checked `FontParseError` results for cache misses.
- `GlyphMaskCache` is a small keyed cache for individual glyph `CoverageMask`
  values. Renderer and future atlas code can use `get_or_rasterize_glyph` when
  a stable font/glyph/scale/subpixel key is already known.
- `GlyphMaskAtlas` is a text-local row-packed atlas for copied glyph masks. It
  records caller-provided glyph keys and mask placement without depending on
  `graphics.PixelRect`, keeping the renderer atlas path optional and layered on
  top of text coverage masks. Resource code can inspect capacity, used pixels,
  free pixels, occupancy ratio, and `can_fit` before deciding whether to reuse,
  clear, or rotate an atlas.
- `TextMaskCache` is a small keyed cache for rendered `CoverageMask` values.
  GUI and renderer code can use `get_or_render_face` for repeated labels or
  text runs, while `get` and `insert` copy mask pixels to keep cached entries
  isolated from caller mutation.
- `TextLayout` is the layout result intended for renderer and GUI code. It owns
  layout metrics and an array of `GlyphRun` values.
- `GlyphRun` is one positioned run of glyphs with width and baseline. It is the
  handoff shape between text layout and glyph rasterization.
- Explicit `\n`, `\r`, and `\r\n` breaks are preserved as layout lines.
  Consecutive breaks create zero-glyph runs so editors and GUI text blocks can
  keep empty-line height and baseline information.
- `LayoutConfig.alignment` applies to `TextLayout` and `render_text_mask_face`.
  `Left`, `Center`, and `Right` shift each line inside `max_width`; `Justify`
  expands interior spaces on non-final wrapped lines while leaving leading or
  trailing spaces, explicit line breaks, and the final line unchanged.
- `LayoutConfig.letter_spacing` adds extra advance between glyphs in a shaped
  text token. `LayoutConfig.word_spacing` adds extra advance to preserved ASCII
  space tokens. Both values participate in measurement, wrapping, text masks,
  and renderer text drawing.
- Trailing ASCII spaces are preserved in layout width and glyph runs, but a
  space token by itself does not start a wrapped line; the following visible
  text is wrapped instead.

The renderer package should accept `FontFace`/`TextLayout` level concepts first.
Legacy functions that accept `Font` or `LayoutResult` may remain for tests and
compatibility while callers migrate.

## Low-Level Structures

`Font`, `FontHead`, `FontHhea`, `LongHorMetric`, `GlyphData`, `GlyphContour`,
`GlyphPoint`, `KernPair`, `LayoutLine`, `LayoutResult`, and `PositionedGlyph`
are still public today because the early codebase exposed parser internals
directly. Treat them as implementation-adjacent until the public API is reviewed
and narrowed. New application-facing APIs should avoid requiring callers to
construct these types by hand.

## Migration Rules

- Prefer `FontFace::from_bytes(data)` over `parse_font(data)` for untrusted or
  user-provided fonts.
- Prefer `FontFaceCache::get_or_parse(key, data)` when a GUI or renderer owns a
  stable font-resource key and may request the same face repeatedly.
- Prefer `GlyphMaskCache::get_or_rasterize_glyph(key, glyph, ...)` when renderer
  code already owns a stable glyph-resource key and wants per-glyph reuse.
- Prefer `GlyphMaskAtlas::can_fit(mask)` and `GlyphMaskAtlas::insert(key, mask)`
  when a renderer or GUI resource layer wants deterministic glyph placement and
  enough lifecycle telemetry to make package-specific eviction, texture upload,
  or dirty atlas policy decisions.
- Prefer `TextMaskCache::get_or_render_face(key, face, text, ...)` when a GUI
  owns a stable text-resource key and may draw the same mask repeatedly.
- Prefer `TextLayout::layout(face, text, config)` or `layout_text_face` over
  calling `layout_text` directly from application code.
- Prefer `render_text_mask_face` and `Renderer::draw_text_face` when connecting
  text to pixels.
- Add layout-level and renderer-level regressions when changing alignment,
  baseline, wrapping, or glyph positioning semantics.
- Keep exact parser error tests in `text/parser_test.mbt`; keep facade and
  renderer integration tests near `FontFace`/`TextLayout` users.

This boundary lets the parser, shaper, fallback strategy, glyph cache, and atlas
packing evolve without forcing GUI code to depend on table-level TTF details.
