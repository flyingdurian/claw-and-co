#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$PWD/ci/bin/godot}"
mkdir -p ci/output/r51m/screenshots ci/output/r51m/movie ci/output/r51m/logs
"$GODOT" --headless --path . --import --quit > ci/output/r51m/logs/import.log 2>&1
"$GODOT" --headless --path . --script res://scripts/tests/RunR51MechanicalTests.gd > ci/output/r51m/logs/rig_tests.log 2>&1
if grep -E '(SCRIPT ERROR:|Parse Error:|^ERROR:)' ci/output/r51m/logs/rig_tests.log; then exit 1; fi
LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe timeout 150s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --rendering-method gl_compatibility --resolution 1280x720 --script res://ci/CaptureR51Mechanical.gd > ci/output/r51m/logs/frames.log 2>&1
LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe timeout 200s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --rendering-method gl_compatibility --resolution 1280x720 --fixed-fps 24 --write-movie ci/output/r51m/movie/godot_raw.avi --quit-after 288 res://scenes/r5/R51MechanicalProof.tscn > ci/output/r51m/logs/movie.log 2>&1
ffmpeg -hide_banner -loglevel error -y -i ci/output/r51m/movie/godot_raw.avi -an -c:v libx264 -preset fast -crf 22 -pix_fmt yuv420p -movflags +faststart ci/output/r51m/movie/M01_mechanism_12s.mp4
rm -f ci/output/r51m/movie/godot_raw.avi
python3 - <<'PY'
from pathlib import Path
from PIL import Image
screens=sorted(Path('ci/output/r51m/screenshots').glob('*.png'))
assert len(screens)==9, f'Need 9 real Godot screenshot keyframes, got {len(screens)}'
for path in screens:
 with Image.open(path) as im:assert im.size==(1280,720), path
assert Path('ci/output/r51m/movie/M01_mechanism_12s.mp4').stat().st_size>25000
print('R51M_CAPTURE_VERIFIED=9 frames + 12sec engine movie (NOT owner artistic acceptance)')
PY
