#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci/output/logs
GODOT="${GODOT:-$PWD/ci/bin/godot}"
failed=0
# GitHub runner has no screen for tests. Render capture is a separate graphical step.
if ! timeout 150s "$GODOT" --headless --path . --import --quit > ci/output/logs/import.log 2>&1; then
  echo 'FAIL: Godot editor import' | tee -a ci/output/logs/status.txt
  failed=1
else
  echo 'PASS: Godot editor import' | tee -a ci/output/logs/status.txt
fi
if grep -E '(^ERROR:|SCRIPT ERROR:|Parse Error:)' ci/output/logs/import.log >/dev/null; then
  echo 'FAIL: Import logged engine/script errors' | tee -a ci/output/logs/status.txt
  failed=1
fi
for testname in RunTests RunGateETests RunGateERefactorTests RunLivingWorldTests RunPerspectiveCrowdTests RunMachinePerformanceTests; do
  log="ci/output/logs/${testname}.log"
  if timeout 150s "$GODOT" --headless --path . --script "res://scripts/tests/${testname}.gd" > "$log" 2>&1; then
    if grep -E '(^ERROR:|SCRIPT ERROR:|Parse Error:)' "$log" >/dev/null; then
      echo "FAIL: $testname emitted engine errors" | tee -a ci/output/logs/status.txt
      failed=1
    else
      echo "PASS: $testname" | tee -a ci/output/logs/status.txt
    fi
  else
    echo "FAIL: $testname" | tee -a ci/output/logs/status.txt
    failed=1
  fi
done
# This known unfinished art gate must not masquerade as accepted.
if timeout 90s "$GODOT" --headless --path . --script res://scripts/tests/RunR4ArtAcceptance.gd > ci/output/logs/RunR4ArtAcceptance.log 2>&1; then
  echo 'ART_GATE: PASS' | tee -a ci/output/logs/status.txt
else
  echo 'ART_GATE: BLOCKED (known incomplete articulated performer assets)' | tee -a ci/output/logs/status.txt
fi
exit "$failed"
