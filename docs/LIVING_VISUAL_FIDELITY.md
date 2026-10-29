# Gate E R3 — Visual Fidelity / Acceptance Record

**Reference:** owner's uploaded Gate E illustrated concept screenshot. **Provisional comparison:** `previews/living_reference_vs_offline.png` and `previews/living_offline_motion_1280x720.mp4`.

## Observations

* Positive: independent on-screen actor cutouts with 280 authentic 2D warped animation poses, authored patrols, customer action states, multiple cabinet-specific mechanism animations, a discrete physical tray cart and ledger-driven swappable prizes. Source cabinets use original illustrated PNGs, retouched to remove baked customers.
* Not yet matching: original benchmark has richer densely packed award interiors, larger animated character artwork, better occlusion, fuller body poses, integrated spotlights and more sophisticated animation transitions. The offline video shows the concept motion but does not establish any real Godot lighting, speed, click hitboxes or screenshot fidelity.
* Corrective design: all Stage 1 inventory prizes shown inside a cabinet are derived from authoritative cassette ownership; empty/depleted machines cannot keep a falsely stocked pile as eye candy. Sparse stock may therefore look less visually dense than the approved reference, and needs professionally painted non-prize cabinet dressing or multiple authored prizes per cassette to reach the reference.
* Input user's import log is editor boot only, with no completed game frame or renderer output. No engine binary exists in this environment, and GitHub downloads cannot resolve here.

## Acceptance

**Static source audit:** 763/763 checks passed. **In-engine screenshot:** unavailable. **Godot 4.7.2 headless acceptance:** not executed here. **Near-identical visual parity:** NOT CERTIFIED. This remains an open owner-review milestone, and should not be recorded as complete until an actual Godot capture and interaction regression logs are available.

## Required capture and regression

Use `tests/run_living_world.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"` to execute four runtime suites. Use `tests/capture_living.ps1` in a graphical session to create `previews/living_00_ambient.png`, `living_01_arrivals.png`, `living_02_play.png`, `living_03_reactions.png`, and `living_04_workshop.png`, all at 1280×720, and review side by side with owner's benchmark.
