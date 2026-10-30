# CLAW & CO. — R5.1-M4 R7/R8 Cabinet Roof Perspective Review

Date: 2026-10-29 (Vancouver). Branch `r5/phase1-visual-foundation`.
Final tested SHA: `bb11968f0aa9f82dbba8244324be078b06e3640a`.
[Actual Godot 4.7.2 proof](https://github.com/flyingdurian/claw-and-co/actions/runs/40987249660).

## VERIFIED ENGINE RESULTS
- Godot R5.1 mechanical assertions: **1287 / 1287 passed; 0 failed**.
- Actual 11 in-engine 1280x720 screenshots, including dedicated far/near bridge endpoints, and 12-second animation from Godot.
- Original accepted Stage 1 simulation/manager/core/transaction code not changed.
- Drawn evidence inspected by developer before making decision.

## Structural findings that changed the architecture
- The original M01 body is **not flat across screen Y**: the source alpha shows that the fixed roof fascia descends from left to right in the three-quarter art perspective. Previous rear-right guide anchor (562,371), for example, lay behind near-opaque roof artwork; added chrome slab was mostly invisible behind it.
- The earlier linear bridge assumed horizontal left/right endpoints even while the inner roof silhouette is pitched.
- The idle hoist cable began below the connector, and a minimum-length clamp hid the disconnect. This caused two CI failures when R8 shortened the Z travel for safe chamber clearance.
- R7: added one UV-textured continuous under-roof soffit (authentic original chrome source rather than a flat placeholder) and 2 extra Godot roof close-ups. R7 test 1125/1125 passed, but the new soffit was partly hidden by opaque cabinet roof.
- R8: recalibrated roof anchors into genuinely transparent source-chamber region:
  - left rear = (370,390), right rear = (565,410)
  - left front = (305,425), right front = (635,443)
  - guide and soffit panel use pitched cabinet perspective instead of horizontal bar.
  - bridge rotation comes from actual left-right wheel attachment vector at every depth; both rollers derive from the same fixed paths.
  - trolley counter-rotates to keep cable/claw world-upright.
  - corrected idle cable start inside winch: local y=41 instead of 52 and retained full safe stroke, rather than lowering test requirement arbitrarily.

## Assertions validated
- Both bridge contact markers remain on their rail axes to <0.75 screen unit.
- Calibrated pitched bridge maintains a physical angle and suspended hoist remains world upright at all sampled 720-tick positions.
- Four fixed mounting anchors and actual textured guide geometry remain immobile.
- Cable end-to-connector and connector-to-hub overlap are checked in all sampled poses.
- Claw stays within previously established chamber envelope; lowered claw remains clear of front panel according to mount bounds (NOT yet full sprite silhouette collision).
- Scene dependency and production art material loads all pass.

## Visual review
R8 side-by-side engine close-up compared with R7: the gantry now follows the cabinet's slanted underside and physically tracks on four newly calibrated source coordinates; actual bridge angle is more coherent with the structural trim. Godot far/near screenshots show bridge movement along guides and a joined cable.
**However the roof mechanism still has too much shallow/fragmented chrome hardware in the close-up, and no variable plush prize contact or real gameplay has been validated. It is a much more credible geometry proof, not full commercial-quality visual approval.**
Owner should inspect actual R8 screenshots/movie for roof geometry; keep PR draft.

## Recommended next safe phase
1. Obtain owner opinion on R8 actual roof close-ups only, not on full Stage 1.
2. If geometry accepted as baseline, address bearing edge transparency and silhouette complexity through targeted atlas touch-up (not blind regeneration).
3. Test interactive prize stock placement and hard claw silhouette clearance separately while preserving accepted simulation.
4. Never claim R5.1 complete or merge PR #1 before owner visual signoff.
