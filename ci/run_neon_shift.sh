#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$PWD/ci/bin/godot}"
mkdir -p ci/output/neon_shift
python3 ci/audit_neon_assets.py | tee ci/output/neon_shift/assets.log
"$GODOT" --headless --path . --script res://scripts/tests/RunNeonShiftTests.gd > ci/output/neon_shift/gameplay.log 2>&1
cat ci/output/neon_shift/gameplay.log
! grep -E 'SCRIPT ERROR:|^ERROR:|FAILED=[1-9]' ci/output/neon_shift/gameplay.log
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
for script in TestNeonInput CaptureNeonShift; do
  timeout 180s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --audio-driver Dummy --script "res://ci/$script.gd" > "ci/output/neon_shift/$script.log" 2>&1
  cat "ci/output/neon_shift/$script.log"
  ! grep -E 'SCRIPT ERROR:|^ERROR:|FAILED=[1-9]' "ci/output/neon_shift/$script.log"
done
timeout 30s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --audio-driver Dummy -- --neon-smoke > ci/output/neon_shift/startup.log 2>&1
cat ci/output/neon_shift/startup.log
grep 'EXPORTED_SMOKE_PASS' ci/output/neon_shift/startup.log
! grep -E 'SCRIPT ERROR:|^ERROR:' ci/output/neon_shift/startup.log
