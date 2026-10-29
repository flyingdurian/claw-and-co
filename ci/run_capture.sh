#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci/output/screenshots ci/output/movie ci/output/logs
GODOT="${GODOT:-$PWD/ci/bin/godot}"
# Use llvmpipe for repeatability. This Compatibility-renderer capture is NOT a
# substitute for final native Forward+ lighting acceptance on the owner's GPU.
echo 'renderer=gl_compatibility; driver=llvmpipe; display=Xvfb; visual parity not certified' > ci/output/renderer.txt
if ! timeout 180s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --rendering-method gl_compatibility --resolution 1280x720 --script res://ci/CaptureReview.gd > ci/output/logs/actual_screenshots.log 2>&1; then
  echo 'CAPTURE ERROR: in-engine screenshot process failed'
  exit 1
fi
if [ "$(find ci/output/screenshots -maxdepth 1 -name '*.png' | wc -l)" -ne 5 ]; then
  echo 'CAPTURE ERROR: expected 5 actual Godot screenshots'
  exit 1
fi
# Movie recording is a separate REAL Godot run of Main.tscn, not a composed mockup.
if ! timeout 300s xvfb-run -a -s '-screen 0 1280x720x24' "$GODOT" --path . --rendering-method gl_compatibility --resolution 1280x720 --fixed-fps 24 --write-movie ci/output/movie/raw_godot.avi --quit-after 240 > ci/output/logs/actual_movie.log 2>&1; then
  echo 'CAPTURE ERROR: Godot movie recording failed'
  exit 1
fi
if [ ! -s ci/output/movie/raw_godot.avi ]; then
  echo 'CAPTURE ERROR: movie missing'
  exit 1
fi
ffmpeg -hide_banner -loglevel error -y -i ci/output/movie/raw_godot.avi -an -c:v libx264 -preset fast -crf 22 -pix_fmt yuv420p -movflags +faststart ci/output/movie/arcade_10s.mp4 || exit 1
rm -f ci/output/movie/raw_godot.avi
python3 ci/verify_captures.py || exit 1
python3 ci/compare_benchmarks.py || exit 1
