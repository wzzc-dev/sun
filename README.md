# wzzc-dev - MoonBit Graphics & Text Rendering

A collection of MoonBit libraries for 2D graphics rendering, text processing, and display.

## Project Structure

```
wzzc-dev/
├── moon.mod                    # Root module
├── moon.work                   # Workspace configuration
│
├── graphics/                   # 2D graphics rendering
│   ├── moon.mod
│   ├── color.mbt              # RGBA color
│   ├── path.mbt               # Vector path
│   ├── paint.mbt              # Paint configuration
│   ├── pixmap.mbt             # Pixel buffer
│   ├── layer.mbt              # Off-screen layer cache
│   ├── layer_tree.mbt         # Z-ordered cached layer composition
│   ├── render_frame.mbt       # Frame canvas + layer tree submit unit
│   ├── rasterizer.mbt         # Scanline rasterizer
│   ├── canvas.mbt             # Drawing canvas
│   └── deprecated.mbt         # Deprecated compatibility APIs
│
├── text/                       # Text processing
│   ├── moon.mod
│   ├── reader.mbt             # Binary reader
│   ├── tables.mbt             # TTF tables
│   ├── parser.mbt             # TTF parser
│   ├── font.mbt               # Font data
│   ├── glyph.mbt              # Glyph representation
│   ├── shaper.mbt             # Text shaping
│   ├── line.mbt               # Text line
│   ├── paragraph.mbt          # Paragraph
│   ├── layout.mbt             # Layout engine
│   ├── rasterizer.mbt         # Glyph rasterizer
│   ├── renderer.mbt           # Font renderer
│   └── file_io.mbt            # File I/O (uses moonbitlang/x/fs)
│
├── renderer/                   # Graphics + text integration
│   ├── moon.mod
│   ├── renderer.mbt           # Renderer core and text mask composition
│   └── renderer_test.mbt
│
├── softbuffer/                 # Pixel display
│   ├── moon.mod
│   ├── ffi.mbt                # FFI bindings
│   ├── window.mbt             # Window management
│   ├── surface.mbt            # graphics.Surface native present targets
│   ├── event_loop.mbt         # Event loop
│   └── native_renderer.c      # Win32 GDI implementation
│
└── examples/
    ├── headless_render/       # MemorySurface off-screen render smoke test
    │   ├── moon.mod
    │   ├── moon.pkg
    │   └── main.mbt
    ├── hello_world/            # RenderFrame + LayerTree window demo
    │   ├── moon.mod
    │   ├── moon.pkg
    │   └── main.mbt
    ├── font_demo/              # Font rendering demo
    │   ├── moon.mod
    │   ├── moon.pkg
    │   └── main.mbt
    └── triangle_window/        # Triangle rendering demo
        ├── moon.mod
        ├── moon.pkg
        └── main.mbt
```

## Libraries

### graphics
2D graphics rendering library.

**Features:**
- Color, Path, Paint, Pixmap, Canvas, Layer, LayerTree, RenderFrame
- Scanline triangle/polygon fill
- Bresenham line drawing
- Bezier curve rendering
- `Canvas` line/polyline/polygon/arc/pie/rect/circle/ellipse and uniform/per-corner rounded-rect helpers for reusable GUI dividers, borders, progress rings, badges, ovals, panels, tabs, buttons, charts, simple icons, and input backgrounds
- `Canvas::draw_placeholder_text` for debug text boxes; real text drawing lives in `renderer`
- Canvas save/restore state stack, transform-aware rect/path drawing, transform helpers, and intersecting clip scopes for nested GUI drawing
- `Surface` trait, `MemorySurface`, and full/rect present helpers for `Canvas` and `Pixmap`
- Pixmap blitting, source-rect atlas drawing, tiled Pixmap fills, explicit nearest/bilinear sampling modes, and straight-alpha composition for image and layer caching
- Nine-patch Pixmap scaling for reusable GUI panel/background image composition
- `PixelRect` / `DirtyRegion` tracking with merge, explicit dirty-present/dirty-submit plans, scheduler states, and `Canvas` bounded dirty-present helpers
- `Layer` off-screen caches with resize, overlap preservation, and dirty-region composition back into a target `Canvas`
- `LayerTree` z-order composition with dirty rectangle propagation, layer resize/remove/replace/reorder lifecycle, property-change invalidation, dirty-present planning, and partial present submission
- `RenderFrame` as a frame-sized canvas and layer-tree submit unit with resize lifecycle, dirty queries/marking, dirty-submit planning/results, result-level scheduler, did-present, present-cost, and Skip/Partial/Full present strategy queries, and dirty/full present helpers for future event-loop integration

### text
Text processing library (font parsing, shaping, layout).

**Features:**
- TTF font loading and parsing
- `parse_font_result` for checked TTF structural validation while retaining the legacy `parse_font` compatibility entry point
- Documented `FontParseError` categories for callers that load untrusted font bytes
- `FontFace`, `GlyphRun`, and `TextLayout` facades for renderer and GUI-facing text APIs
- Left, center, right, and basic non-final-line justify alignment through the `TextLayout` facade
- Explicit newline and empty-line preservation in `TextLayout`, text masks, and renderer text drawing
- Configurable letter spacing and word spacing through `LayoutConfig`
- Trailing-space measurement and wrapping semantics suitable for editor-style text blocks
- Simplified LTR/RTL shaping order with inspectable `ShapedText` glyphs and positions
- Text layout and basic Unicode line-break classes for digits, combining marks, Hangul clusters, joiners, emoji modifiers, and CJK ranges
- Glyph rasterization with anti-aliasing
- Kerning support

### renderer
Renderer integration layer that composes `graphics.Canvas` with `text` coverage masks.

**Features:**
- `Renderer::draw_text` for `Font -> layout -> glyph raster -> Canvas` drawing
- `Renderer::draw_text_face` for checked `FontFace -> TextLayout -> Canvas` drawing
- `Renderer::draw_coverage_mask` for testing and low-level mask composition
- End-to-end regression from parsed TTF bytes to rendered `Pixmap` pixels
- Keeps `graphics` independent from font parsing and text layout

### softbuffer
Pixel display library.

**Features:**
- Window creation (Win32 API)
- Pixel buffer presentation through `graphics.Surface`
- `NativeSurface` adapter for external native window handles
- `RenderFrame -> NativeSurface` dirty/full present helpers plus strategy-aware submit/query/plan results with state, cost, and full-present savings telemetry for window integration
- Optional `NativeSurface` pre-present hook for window lifecycle notifications before validated native presents
- Native full-frame and rectangle present entry points for dirty redraw plumbing
- Event loop

### examples
Small build-checked programs that exercise the public packages together.

**Features:**
- `headless_render` renders a GUI-style frame through `RenderFrame`, `LayerTree`, and `MemorySurface`, then self-checks state-aware dirty submit output without creating a window
- `hello_world` uses `graphics.RenderFrame`, `LayerTree`, and `softbuffer` strategy-aware frame-submit helpers as a minimal window submit path with resize/redraw lifecycle reuse
- `font_demo` renders real TTF text through the `renderer` package
- `triangle_window` keeps a simple native pixel-output smoke test

## Building & Running

### Prerequisites

- **MoonBit** - https://www.moonbitlang.com/
- **Visual Studio Build Tools** - For native compilation on Windows

### Using VS Developer Command Prompt (Recommended)

The easiest way to build and run on Windows is using the VS Developer Command Prompt:

```powershell
# 1. Open VS Developer PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64

# 2. Then run directly
moon run examples/font_demo --target native
```

Or create a batch file `run.bat`:

```batch
@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
moon run examples/font_demo --target native
```

### Manual Environment Setup (PowerShell)

If you prefer to set environment variables manually:

```powershell
$env:PATH = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x64;$env:PATH"
$env:INCLUDE = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.51.36231\include;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\ucrt;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\shared;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\um"
$env:LIB = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.51.36231\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"

moon run examples/font_demo --target native
```

### Commands

```bash
# Check all packages
moon check

# Run the local validation gate
scripts/check_ci.sh

# Run renderer package tests directly
moon test graphics
moon test text
moon test renderer
moon test softbuffer

# Build example
moon build examples/font_demo --target native

# Run headless rendering smoke test
moon run examples/headless_render

# Run RenderFrame window demo
moon run examples/hello_world --target native

# Run font demo
moon run examples/font_demo --target native

# Run triangle demo
moon run examples/triangle_window --target native
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Application                            │
│               (examples/font_demo)                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   graphics    │   │     text      │   │  softbuffer   │
│  (渲染图形)    │   │  (解析字体)    │   │  (显示到屏幕)  │
└───────┬───────┘   └───────┬───────┘   └───────────────┘
        │                   │
        └─────────┬─────────┘
                  ▼
          ┌───────────────┐
          │   renderer    │
          │ (组合渲染管线) │
          └───────────────┘
```

## Project Direction

The long-term goal is to grow this repository into a MoonBit-native,
CPU-first, testable, cross-platform lightweight 2D rendering stack for text,
vector graphics, pixel output, and GUI foundations. See [ROADMAP.md](ROADMAP.md)
for milestones and acceptance criteria, and [docs/testing.md](docs/testing.md)
for the local validation gate. The checked font parser error contract is tracked
in [docs/font-parser-errors.md](docs/font-parser-errors.md), and text API facade
boundaries are tracked in [docs/text-api-boundaries.md](docs/text-api-boundaries.md).

## License

Apache-2.0
