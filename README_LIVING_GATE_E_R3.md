# CLAW & CO. — Gate E R3: Living Arcade

## What this package contains

Godot 4.7.2, pure GDScript, first-person point-and-click 1280×720 2D game presentation, preserving the accepted Stage 1 core. Additional custom-built animated live sprite actors, 280 pre-rendered animation frames, independent scheduled ambient shoppers, state-linked arcade customers, independent dynamic machine stock, active mechanisms, and detailed tactile cart icons.

### Open in Godot

Import `project.godot`, set `Main.tscn` as the main scene (already configured), run at 1280×720. No playable walking avatar. Areas switch instantly and do not pause production. Four machine cabinets are click targets. Customers show their requests as UI bubbles layered over their animated bodies. The workshop includes card charging, cassette preparation, wrapping and trade-up.

### Runtime validation (Windows)

```
.\tests\run_living_world.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

Capture genuine graphics (not headless):

```
.\tests\capture_living.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

On Linux/macOS you can run `bash tests/run_living_world.sh /path/to/godot`.

### Scope limits

All added animation is cosmetic and derives from the 60Hz simulation tick. The 12 ambient extras are visual-only, while the eight actual Stage 1 visit actors become service customers only at their authored arrivals. **Please do not treat the included offline MP4 as a Godot runtime screenshot.** Actual engine imports/tests and final visual parity are unverified until the scripts above succeed. See `docs/LIVING_VISUAL_FIDELITY.md`.
