#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

moon check

# The renderer packages have executable unit tests. GUI backends are compiled
# build-only because some native test runners cannot execute framework-linked
# or platform-specific window packages on every host.
moon test graphics
moon test text
moon test renderer
moon test softbuffer
moon test .local_repos/window/core
moon test .local_repos/window/dpi
moon run examples/headless_render
moon build examples/triangle_window --target native
moon build examples/hello_world --target native
moon build examples/font_demo --target native
moon test --build-only
