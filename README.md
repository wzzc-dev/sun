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
│   ├── rasterizer.mbt         # Scanline rasterizer
│   ├── canvas.mbt             # Drawing canvas
│   └── renderer.mbt           # Text + graphics renderer
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
├── softbuffer/                 # Pixel display
│   ├── moon.mod
│   ├── ffi.mbt                # FFI bindings
│   ├── window.mbt             # Window management
│   ├── surface.mbt            # Pixel surface
│   ├── event_loop.mbt         # Event loop
│   └── native_renderer.c      # Win32 GDI implementation
│
└── examples/
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
- Color, Path, Paint, Pixmap, Canvas
- Scanline triangle/polygon fill
- Bresenham line drawing
- Bezier curve rendering

### text
Text processing library (font parsing, shaping, layout).

**Features:**
- TTF font loading and parsing
- Text shaping (simplified)
- Text layout and line breaking
- Glyph rasterization with anti-aliasing
- Kerning support

### softbuffer
Pixel display library.

**Features:**
- Window creation (Win32 API)
- Pixel buffer presentation
- Event loop

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

# Run tests
moon test

# Build example
moon build examples/font_demo --target native

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
└───────────────┘   └───────────────┘   └───────────────┘
```

## License

Apache-2.0
