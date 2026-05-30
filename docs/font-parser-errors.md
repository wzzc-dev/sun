# Font Parser Error Contract

`text.parse_font_result` is the checked TTF parser entry point. It returns
`Result[Font, FontParseError]` and should be preferred by examples, tools, and
GUI code that load untrusted or user-provided font bytes.

The legacy `text.parse_font` entry point remains for compatibility. It delegates
to `parse_font_result` and aborts on parse failure, so new code should avoid it
unless the font bytes are known-good fixtures.

## Stability Policy

`FontParseError` is public because callers need to distinguish malformed input
from successful parsing without relying on string messages. The broad categories
are intended to stay stable:

- Header and directory errors: `UnexpectedEndOfData`, `InvalidFontHeader`,
  `MissingTable`, `TableOutOfBounds`, `TableTooShort`.
- Core TTF table shape errors: `UnsupportedIndexToLocFormat`,
  `MissingHorizontalMetrics`, `UnsortedLocaOffsets`.
- Glyph outline shape errors: `UnsortedGlyphContourEndpoints`,
  `GlyphFlagRepeatOverflow`.
- Unicode cmap shape errors: `UnsupportedCmapVersion`,
  `InvalidCmapSegmentCount`, `InvalidCmapSegmentRange`,
  `InvalidCmapGroupRange`.

The exact first error reported for a severely malformed font can still change as
the parser validates more structure earlier. Tests should assert exact variants
for targeted malformed fixtures, but application code should usually handle
categories rather than depending on a precise validation order.

## Variant Payloads

- `UnexpectedEndOfData(offset, needed, actual)` means the sfnt directory needed
  `needed` bytes starting at `offset`, but the input length was `actual`.
- `InvalidFontHeader(value)` means the sfnt version was not a supported TTF
  version.
- `MissingTable(tag)` means a required table such as `head`, `hhea`, `hmtx`,
  `cmap`, `maxp`, `loca`, or `glyf` was absent.
- `TableOutOfBounds(tag, offset, length, data_length)` means the table record or
  subtable range points outside the font bytes.
- `TableTooShort(tag, actual, minimum)` means a table or subtable was present but
  shorter than the fields needed by the supported parser path.
- `UnsupportedIndexToLocFormat(value)` means `head.indexToLocFormat` was neither
  short loca (`0`) nor long loca (`1`).
- `MissingHorizontalMetrics` means `hhea.numberOfHMetrics` is not sufficient for
  supported horizontal metrics parsing.
- `UnsortedLocaOffsets` means `loca` offsets are not monotonic.
- `UnsortedGlyphContourEndpoints` means simple glyph contour endpoints are not
  strictly increasing.
- `GlyphFlagRepeatOverflow` means repeated glyph flags describe more points than
  the glyph contour endpoints allow.
- `UnsupportedCmapVersion(value)` means the `cmap` table version is not `0`.
- `InvalidCmapSegmentCount(value)` means a format 4 `segCountX2` value is not an
  even segment count encoding.
- `InvalidCmapSegmentRange(start, end)` means a format 4 segment range is
  inverted.
- `InvalidCmapGroupRange(start, end)` means a format 12 group is inverted or
  outside Unicode scalar range.
- Supported format 12 groups can map supplementary-plane codepoints such as
  emoji or CJK extension characters into `FontFace::char_to_glyph` and
  `TextLayout` glyph runs.
- `InvalidTable(tag, reason)` is a compatibility catch-all for future or
  migration-only validation. Prefer adding a structured variant for new parser
  behavior that callers or tests need to handle explicitly.

## Validation Expectations

When changing parser behavior:

- Add a narrow fixture in `text/parser_test.mbt` for every new structured error.
- Run `moon test text`, `moon info`, and `scripts/check_ci.sh` before handoff.
- Review `text/pkg.generated.mbti` whenever variants are added, renamed, or
  removed.
- Keep `parse_font` behavior compatible unless the public API is deliberately
  changed and documented.
