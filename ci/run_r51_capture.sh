#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci/output/r51 ci/output/logs
python3 ci/r51_review.py | tee ci/output/logs/r51_asset_gate.log
GODOT="${GODOT:-$PWD/ci/bin/godot}"
xvfb-run -a -s '-screen 0 1280x720x24' timeout 120s "$GODOT" --path . --rendering-method gl_compatibility --resolution 1280x720 --script res://ci/CaptureR51.gd > ci/output/logs/r51_capture.log 2>&1
python3 - <<'PY'
from pathlib import Path
from PIL import Image
shots=sorted(Path('ci/output/r51').glob('*.png'))
assert len(shots)==3, f'R51 expected 3 genuine Godot frames, found {len(shots)}'
for shot in shots:
 with Image.open(shot) as im: assert im.size==(1280,720)
print('R51_GODOT_CAPTURE: VERIFIED (owner artistic approval pending)')
PY
