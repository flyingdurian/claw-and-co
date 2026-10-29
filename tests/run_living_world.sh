#!/usr/bin/env bash
set -euo pipefail
GODOT="${1:-godot}"
cd "$(dirname "$0")/.."
mkdir -p logs
"$GODOT" --headless --path . --import --quit 2>&1 | tee logs/living_import.log
for script in RunTests RunGateETests RunGateERefactorTests RunLivingWorldTests; do
  "$GODOT" --headless --path . --script "res://scripts/tests/${script}.gd" 2>&1 | tee "logs/${script}.log"
done
echo 'ALL FOUR GATE A-E / LIVING WORLD SUITES PASSED'
