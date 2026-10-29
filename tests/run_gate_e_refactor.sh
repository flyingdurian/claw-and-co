#!/usr/bin/env bash
set -euo pipefail
GODOT="${1:-godot}"
cd "$(dirname "$0")/.."
mkdir -p logs
"$GODOT" --headless --path . --import --quit 2>&1 | tee logs/gate_e_refactor_import.log
"$GODOT" --headless --path . --script res://scripts/tests/RunTests.gd 2>&1 | tee logs/gate_e_refactor_core.log
"$GODOT" --headless --path . --script res://scripts/tests/RunGateETests.gd 2>&1 | tee logs/gate_e_refactor_legacy_ui.log
"$GODOT" --headless --path . --script res://scripts/tests/RunGateERefactorTests.gd 2>&1 | tee logs/gate_e_refactor_interactions.log
