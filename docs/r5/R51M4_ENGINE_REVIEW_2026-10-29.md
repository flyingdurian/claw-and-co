# CLAW & CO. — R5.1-M4 Engine Review

**Date:** 2026-10-29 (Vancouver)
**Development branch:** `r5/phase1-visual-foundation`
**GitHub Actions proof:** [40944930998](https://github.com/flyingdurian/claw-and-co/actions/runs/40944930998)
**Commit tested:** `1ebf9f3a425f21599c3c52b7bf23be9194d393ac`
**Decision:** KINEMATIC PROTOTYPE ACCEPTED FOR CONTINUED WORK; VISUAL ART ACCEPTANCE **FAILED/PENDING REPLACEMENT FIXTURE**.

## Evidence actually inspected
- Godot 4.7.2 `R51M_TEST_ASSERTIONS=1092 PASSED=1092 FAILED=0`.
- 9 genuine engine 1280×720 screenshots at scripted keyframes including closeup.
- 12-second actual engine movie.
- `frames.log` ALSA audio driver warning/error falls back to dummy driver; not a GDScript parser error and did not stop capture.
- OpenGL Compatibility with llvmpipe software renderer; the native GPU/Forward+ look remains unverified.

## M4 technical changes implemented
1. Four cabinet-relative mounting markers surveyed provisionally from source PNG:
   `LEFT_REAR=(383,371)`, `RIGHT_REAR=(562,371)`, `LEFT_FRONT=(300,415)`, `RIGHT_FRONT=(645,414)`.
2. Fixed rails attach to cabinet-root `FixedDepthRails`, not moving `DepthBridge`; four separate bracket sprite crops exist under `FixedRoofMounts`.
3. Moving bridge endpoints are computed as interpolation along both fixed rail endpoints using the same normalized depth; two child `Marker2D` nodes represent bridge roller engagement.
4. Trolley left-right travel and claw's cable suspension remain independently articulated.
5. Additional checks: four mounts unchanged by all demo ticks; roller markers remain on rails, bridge interpolates from both rails; existing cable, clamp, fingerprint determinism tests retained.

## What the visual captures STILL show
Despite strict numerical rail/roller proximity passing, the ceiling rail artwork still reads as **thin, horizontally compressed hardware** rather than a believable structural overhead bridge mechanically bolted to M01. The bolt/bracket image crops are very small; the projected fixed rail appears to hover below the source cabinet roof. The four current coordinates are **working candidates, NOT physically certified mount locations**. The illustrated cabinet's perspective and the horizontally authored source rail texture resist adequate correction by scale/rotation alone.

**This is a real visual acceptance blocker.** Never use 1092/1092 assertions as a proxy for owner-quality rendering.

## Approved architectural next action
Ask Astra for **one revised STATIC roof-mounted X/Y guide fixture** only. Because the guide rails/brackets never move relative to M01, they may be one clean layered asset, while the moving bridge/trolley/winch/claw must remain independent. Reference actual `M01 Raspberry Claw Cabinet Body.png` and `Exploded Chrome Gantry Hoist Atlas.png`, plus the failing closeup.
- Faithfully match cabinet underside / visible mounting bays.
- Two parallel front/back rail guides with four clearly bolted mounts; strong physical rail thickness and longitudinal perspective.
- Clear engaged-wheel surface for the already-existing moving cross-bridge; keep the bridge and claw out of this static asset.
- No paid regeneration of the cabinet, claw or other machine parts.
- Transparent artwork, clean edges; deliver separate layer so Godot may test fit. If exact pixel registration fails, say so; use code-determined placement/warp.
- No prize inventory / people / entire scene or UI.
- Preserve rich original chrome-and-raspberry material style, not placeholder metal rectangles.

## Next mechanical test after static art
1. Correct mount registration with the original cabinet source: upper hardware visibly touches roof, brackets don't hang in the chamber.
2. Integrate corrected static guide/roof asset on this branch.
3. Relocate and, if necessary, recalibrate shared rail/bridge interpolation to actual art support points. Continue testing 0/0.5/1 depth and extreme lateral positions. Include full claw silhouette clipping check.
4. Run real Godot screenshot/movie. Owner approval of visual mount geometry required.
5. Only after fixed mounting is convincing, proceed to prize clearance, variable stock sprites and chute handoff.

## Freeze
No changes to authoritative `scripts/core/`, `scripts/managers/`, Stage 1 card accounting, inventory, queues, or deterministic simulation. No merge of draft PR #1 until validated.
