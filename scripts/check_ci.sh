#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

scripts/check_core_warnings.sh

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
moon run examples/render_bench

case "$(uname -s)" in
  Darwin)
    HOST_WINDOW_PACKAGE=".local_repos/window/macos"
    HOST_GUI_EXAMPLES=(".local_repos/window/examples/window")
    ;;
  Linux)
    HOST_WINDOW_PACKAGE=".local_repos/window/linux"
    HOST_GUI_EXAMPLES=(".local_repos/window/examples/window_linux")
    ;;
  MINGW*|MSYS*|CYGWIN*)
    HOST_WINDOW_PACKAGE=".local_repos/window/windows"
    HOST_GUI_EXAMPLES=(
      "examples/triangle_window"
      "examples/hello_world"
      "examples/font_demo"
      ".local_repos/window/examples/window_windows"
    )
    ;;
  *)
    HOST_WINDOW_PACKAGE=""
    HOST_GUI_EXAMPLES=()
    ;;
esac

for example in "${HOST_GUI_EXAMPLES[@]}"; do
  moon build "$example" --target native
done

# Build the packages that are meaningful on this host. The workspace also
# contains platform-specific native stubs for other OSes, which cannot compile
# against this host's C SDK.
moon test --build-only graphics text renderer softbuffer
moon test --build-only .local_repos/window/core .local_repos/window/dpi
if [[ -n "$HOST_WINDOW_PACKAGE" ]]; then
  moon test --build-only "$HOST_WINDOW_PACKAGE"
fi
