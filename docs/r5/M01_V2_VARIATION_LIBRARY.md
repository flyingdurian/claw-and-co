# CLAW & CO. — M01 V2 Complete Sequence Library

**Status:** reviewable, owner approval pending. Branch `r5/m01-v2-complete-variation-library`. Parent: owner-approved PR #5 merged to main.

## Authoritative contract
All results stay predetermined by MachineManager and the stage session manifest. Read-only M01VariationPilot selects one of five deterministic, paired win/miss animation families by stage ID, session ID, attempt index and visual seed. W1–W3/M1–M3 from V1 remain, with four new V2 resolution families. First 180/240 ticks (0–179 inclusive) are exactly outcome-neutral per pair. V2 deliberately uses a new versioned selector identity; pre-existing fixture seeds are recalculated, but no gameplay outcome is rerolled.

## New W4 and W5
- **W4 Near-slip recovery:** at resolution the carried plush dips and elongates under peak tension, then returns to the original secure grip. Damped pose at exit.
- **W5 Off-center pull:** start with an off-centre shared first-lift; pull diagonally with decreasing sway and return to stable alignment.
- **M4 Partial clamp/tug:** visual tension compresses prize during an incomplete grip; release begins at tick 202; controlled fall returns to authored floor proxy within attempt.
- **M5 Late slip:** common off-centre first-lift, then near-delivery carried transit; release begins at tick 225. Frozen claw-relative release origin ensures the falling proxy cannot chase a moving trolley. Fully settled at `(405,775)` by tick 237, before tick 240.

## Deformation and extreme poses
Secondary plush x-narrowing, y-stretch, compression, bounded rotation, damped oscillation and landing squash are presentation-only. Tests sample all 240 ticks for all ten outcomes, assert rig XYZ 0..1, plush squash/elasticity/rotation/offset bounds, zero snapshot mutations and early visual equality. No approved V3.1 hierarchy or calibration changes.

## Verification
`RunM01VariationPilotTests.gd` remains V1 compatibility proof, `RunM01V2VariationTests.gd` checks ten outcomes including M5 landing before 240, and the real M01 scene capture produces 42 original 1280x720 Godot frames plus four ten-sequence contact sheets.

## Deferred V3
E1–E3 premature/aborted actions and C1–C3 chute/payout beats remain unimplemented. No new real chute delay or staff-reset rules are authorized here.
