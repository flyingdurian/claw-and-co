# CLAW & CO — R5.1-M4 R3 In-engine Roof Hardware Review

Date: 2026-10-29 (Vancouver).
Commit tested: `bfbca45c0d0e10742dd5b20c2192d51e2edf74f1`.
[Actual Godot proof run](https://github.com/flyingdurian/claw-and-co/actions/runs/40951082723)

## Verified
- Godot 4.7.2 mechanical test: **1105 / 1105 assertions passed** (0 failures).
- 9 actual 1280×720 screenshots and 12-second engine movie produced.
- No accepted Stage 1 simulation/core/managers/Main modification.
- Camera/stock proof isolated; no claim of gameplay-ready win/loss or prize mechanics.

## Code changes since first M4
- Fixed guide hardware no longer uses a horizontally squashed full source sprite.
- Each fixed guide is a cabinet-registered **UV-textured Polygon2D mesh** sampling real chromed rail illustration, with width varying toward near end. Four corner points match mounting track geometry and are used in tests.
- Four original hardware mounting columns are sourced from the illustrated atlas, and now each has a distinct textured **RoofAttachmentPlate** rendered in front of roof fascia, while its supporting column remains behind.
- The bridge still derives endpoints from the same two physical guide paths, and the gantry's moving assembly remains independent of the fixed hardware.

## Actual visual result
The rail-to-bridge connection is clearer, and small bolt plates at fascia line are now visible in 1280×720 close-up. However, **the overall fixed fixture still reads too thin/lightweight** in the screenshot; visually substantial roof brackets and believable rolling-bearing mating have not reached the approved art benchmark. Small chrome fragments can still look pasted on when inspected closely.

**Decision: mechanical geometry and engine pipeline pass; VISUAL ACCEPTANCE STILL PENDING/FAILED.**

## Next engineering step
- Build a substantially larger permanent fixed mounting cradle, with visible attachment plates and substantial bracket depth in the same M01 perspective; calibrate at target 1280×720 size.
- Preserve the approved M01 body and existing free-moving gantry and claw source art.
- Avoid creating new artist-full fixture where previous Astra exact-registration attempts failed. A **Godot mesh/material re-authoring** using actual original chrome atlas details is still preferred.
- Verify 4 roof fixed contacts and bridge roller contact at near/far positions using 4x close-up crops and real video.
- Once mounting reads physically installed, test variable plush stock/rig contact/chute handoff without touching authoritative Stage 1 simulation until integration explicitly approved.

## Source of truth
The user-approved R5.1 mechanical structure is *not* owner approved in rendering. Do not merge draft PR #1 based on 1105 passing numeric assertions.
