#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="$PWD/ci/bin/godot"
OUT=ci/output/m01v31
mkdir -p "$OUT"/screenshots "$OUT"/movie "$OUT"/logs
python3 ci/inspect_m01_v31_masks.py > "$OUT/logs/mask_inspection.log" 2>&1
"$GODOT" --headless --path . --import --quit > "$OUT/logs/import.log" 2>&1
"$GODOT" --headless --path . --script res://scripts/tests/RunM01V31IntegrationTests.gd > "$OUT/logs/rig_tests.log" 2>&1
grep 'M01_V31_TEST_ASSERTIONS=' "$OUT/logs/rig_tests.log"
if grep -E 'SCRIPT ERROR:|Parse Error:|^ERROR:' "$OUT/logs/import.log" "$OUT/logs/rig_tests.log"; then exit 1; fi
LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe timeout 150s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --rendering-method gl_compatibility --resolution 1280x720 --audio-driver Dummy --script res://ci/CaptureM01V31.gd > "$OUT/logs/frames.log" 2>&1
LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe timeout 200s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --rendering-method gl_compatibility --resolution 1280x720 --audio-driver Dummy --fixed-fps 24 --write-movie "$OUT/movie/godot_raw.avi" --quit-after 288 res://scenes/r5/M01V31Proof.tscn > "$OUT/logs/movie.log" 2>&1
ffmpeg -hide_banner -loglevel error -y -i "$OUT/movie/godot_raw.avi" -an -c:v libx264 -preset fast -crf 22 -pix_fmt yuv420p -movflags +faststart "$OUT/movie/M01_v31_engine_12s.mp4"
rm -f "$OUT/movie/godot_raw.avi"
python3 - <<'PY'
from pathlib import Path
from PIL import Image
paths=list(Path('ci/output/m01v31/screenshots').glob('*.png'))
assert len(paths)==13, len(paths)
for p in paths:
 with Image.open(p) as im: assert im.size==(1280,720),p
assert Path('ci/output/m01v31/movie/M01_v31_engine_12s.mp4').stat().st_size>35000
print('V31_GODOT_PROOF=13 genuine engine images + 12s engine movie')
PY
