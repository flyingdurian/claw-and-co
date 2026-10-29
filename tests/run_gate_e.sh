#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${GODOT_BIN:-godot}"
mkdir -p "$ROOT/logs"
"$BIN" --headless --path "$ROOT" --import --quit 2>&1 | tee "$ROOT/logs/gate_e_import.log"
"$BIN" --headless --path "$ROOT" --script res://scripts/tests/RunGateETests.gd 2>&1 | tee "$ROOT/logs/gate_e_headless.log"
