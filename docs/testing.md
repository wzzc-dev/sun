# Testing

Use the project validation gate from the repository root:

```bash
scripts/check_ci.sh
```

For public API or rendering changes, use this final local checklist:

```bash
moon fmt
moon info
git diff -- '*pkg.generated.mbti'
scripts/check_ci.sh
```

Review the generated `.mbti` diff before handoff. A changed `.mbti` means the
package's visible API changed; call that out in the summary. An unchanged
`.mbti` usually means the change is implementation-only, which is the preferred
shape for safe refactors.

The gate runs `moon check`, executable tests for the renderer and present
packages (`graphics`, `text`, `renderer`, and `softbuffer`), executable tests
for framework-free window packages (`core` and `dpi`), native build checks for
the window examples, and `moon test --build-only` for the full workspace.

The `renderer` package includes the integration regressions that cross package
boundaries, including parsed TTF bytes through text layout, glyph rasterization,
coverage-mask composition, and final `Pixmap` pixels.

For headless pixel fixtures, `graphics.Pixmap::to_rgba_bytes` and
`graphics.Pixmap::to_rgba_rect_bytes` provide isolated raw RGBA bytes in
row-major order, while `graphics.Pixmap::to_ppm_bytes` and
`graphics.Pixmap::to_ppm_rect_bytes` provide deterministic binary PPM(P6)
export paths without adding filesystem or image codec dependencies to the
graphics core. `MemorySurface::to_pixmap`, `MemorySurface::to_pixmap_rect`,
`MemorySurface::to_rgba_bytes`, `MemorySurface::to_rgba_rect_bytes`,
`MemorySurface::to_ppm_bytes`, and `MemorySurface::to_ppm_rect_bytes` expose
the same output paths directly from the reference surface, so examples and
tests do not need to hand-copy surface pixels. For compact regression checks
and benchmark telemetry, `Pixmap::checksum`, `Pixmap::checksum_rect`,
`MemorySurface::checksum`, and `MemorySurface::checksum_rect` use the same
deterministic raw RGBA byte checksum without treating it as a cryptographic
hash. `MemorySurface::reset_present_telemetry` clears present records and
aggregate counters while preserving pixels, which keeps multi-frame headless
tests from allocating a new reference surface only to restart telemetry.
`PresentRectPayload::get_source_byte_count` and
`PresentBatch::get_source_byte_count` expose the source-stride byte budget used
by packed dirty-present dry-runs, matching `MemoryPresentRecord` terminology.
The `headless_render` example checks the exported header, byte length, and
first rendered RGB pixel as an executable smoke test for off-screen output.

The `softbuffer` package implements the `graphics.Surface` present contract for
native windows. Its tests cover validation and trait dispatch without requiring
a live platform window; the example build checks make sure Canvas/Pixmap pixels
can still flow through `NativeSurface` to the native presentation backend.

Glyph rasterization snapshots use ASCII coverage dumps in `text` white-box
tests. `.` means empty coverage, `:`, `*`, and `#` represent increasing
coverage bands. This keeps mask regressions readable while the renderer remains
CPU-first and deterministic.

When changing pixel output, prefer adding a narrow regression at the layer that
owns the behavior:

- `graphics`: exact `Pixmap` pixels for blending, path, stroke, clip, image blit,
  and surface present behavior.
- `text`: glyph outline parsing, layout metrics, and coverage-mask snapshots.
- `renderer`: cross-package regressions from parsed font bytes to final `Pixmap`
  pixels, including printable ASCII fixture coverage through the public
  `FontFace -> Renderer` path.
- `softbuffer`: validation, trait dispatch, and build-only native present checks
  without requiring a live platform window.

Full `moon test` currently executes AppKit-linked native tests through
`tcc -run` on macOS. That runner path does not accept framework arguments such
as `-framework AppKit`, so it can fail with:

```text
tcc: error: file 'AppKit' not found
```

That failure is a native test-runner limitation rather than a renderer or
window build failure. Keep GUI/backend packages covered by build-only tests
until framework-linked native execution works reliably across supported hosts.
