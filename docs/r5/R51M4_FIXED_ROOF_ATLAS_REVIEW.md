# CLAW & CO. R5.1-M4 — Fixed Roof Assembly Actual Art Review

**Date:** 2026-10-29 (Vancouver).
**Source inspected:** exact ChatGPT Library file `Fixed Chrome Roof Rail Assembly.png` (1536 × 1024 RGBA).
**Decision:** ACCEPT as visual/material reference; **REJECT as directly registered production fixture**. No original Stage 1 simulation modifications.

## Grounded source observations

- Source has authentic alpha; pixels with nonzero alpha ~31.94%. Main visible object spans much of the 1536 × 1024 image.
- Rich chrome, raspberry highlights, distinct roof mounting plates and bolted hardware are a convincing visual improvement over the previous tiny cropped guide rails.
- Source assembles rails and cross-bracing into one coherent static fixture, which is the right art *type*: a static roof frame should not itself animate.
- **But** its long rails are perspective-drawn on a much wider, taller canvas than the M01 roof opening. Its left descending guide and near-vertical right guide do not map to the already implemented cabinet-local two-rail envelope by simple uniform scaling.

## Actual fit diagnostics (offline composites, NOT engine captures)
Compared with authoritative `M01 Raspberry Claw Cabinet Body.png` 1024x1536:
1. Simple 700x290 placement at cabinet (240,275): mounts appear within roof, but front rail ends descend too far into the display.
2. 4-point perspective registration: destroys/obscures much of one guide and causes severe deformation.
3. Smaller 700x210..245 placements: align under fascia more naturally, but mounting hardware and visible fixed rails no longer match both ends of the current moving cross-bridge.
4. With the existing R5.1-M4 moving bridge placed at depth 0.08 and 0.92, **bridge endpoints are visibly off the illustrated guide tracks**. Passing current mathematical tests on the previous rails would not certify this new art. It would replicate the owner's chief failure: disconnected or unsupported travel hardware.

*The source screenshot composite used the existing authored M4 bridge geometry, not a verified live Godot animation. Real engine review remains required after physical registration.*

## Decision and budget

Do not replace accepted mechanical rig sprite with the new fixture directly. Do not pay for another generic exploded atlas or regenerate the cabinet, winch or claw. One geometry-constrained revision with a **cabinet-local anchor overlay** is warranted.

The same bridge/rail contract must be visible in the art. Existing candidate geometry:
`LEFT_REAR=(383,371)`, `LEFT_FRONT=(300,415)`,
`RIGHT_REAR=(562,371)`, `RIGHT_FRONT=(645,414)` (cabinet-local 1024x1536 coordinates).
These coordinates are a **test geometry**, not authoritative physical survey: if mounting would require impossible bolt positions, return to geometry design rather than forcing an illustration to obey bad anchors.

## Next Astra request

Use:
- `M01 Raspberry Claw Cabinet Body.png` as structural and view authority.
- `Fixed Chrome Roof Rail Assembly.png` as finish/material quality reference, **not source of positional geometry**.
- The newly provided `M01_roof_anchor_alignment_guide.jpg` as **geometric constraint**: cyan roof points and rail trajectories; orange transverse bars show two positions of the *moving* bridge, which must NOT be painted into the fixed layer.
- The detached-bridge diagnostic composite as negative test evidence.

Generate one truly independent **static, two-guide ceiling rail + four roof brackets layer**, on the SAME 1024x1536 cabinet-local canvas, with all exterior regions transparent. Rails need credible cross sections and mounting plates mechanically joined to roof. No bridge, trolley, hoist, cable, claw, prizes or UI baked in. If exact pixel registration is infeasible, report failure explicitly; never falsely claim it.

## Next technical step after new artwork

1. Verify RGBA and exact registration over the original cabinet at unchanged position and scale.
2. Verify moving bridge left/right roller tips contact the new fixed guides at *all* Y sample positions, with no clipping, false occlusion or free-floating ends.
3. Replace only fixed fixture rendering, preserving existing moving rig and frozen gameplay.
4. Run Godot 4.7.2 engine tests, 1280x720 screenshots, moving 12-second video, and strict visual review.
5. If the geometry-constrained Astra attempt fails, use the source as a material donor for individually texture-mapped rail/bracket components and re-author mounting with code; no repeated blind full-atlas generations.

**Status:** R5.1-M4 visual checkpoint remains BLOCKED. Original `main` gameplay and financial transaction foundations are protected.
