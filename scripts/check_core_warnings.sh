#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Keep the renderer core warning-free across supported backends. Window backend
# warnings are tracked separately because they live under .local_repos/window.
moon check --deny-warn --target all \
  graphics \
  text \
  renderer \
  examples/headless_render \
  examples/render_bench

moon check --deny-warn --target native softbuffer
