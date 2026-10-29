#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ENGINE="${GODOT_BIN:-godot}"
if ! command -v "$ENGINE" >/dev/null 2>&1; then
  echo "NOT RUN: Godot executable not available. Install Godot 4.7.2 and set GODOT_BIN=/path/to/godot" >&2
  exit 127
fi
"$ENGINE" --version
"$ENGINE" --headless --path . --import --quit
"$ENGINE" --headless --path . --script res://scripts/tests/RunTests.gd 2>&1 | tee logs/godot_headless.log
