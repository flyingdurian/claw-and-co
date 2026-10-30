# CLAW & CO. — R5.1-M4 R9 Owner-Annotated Right Rail Correction

**Date:** 2026-10-29, Vancouver; working branch `r5/phase1-visual-foundation`.
**Verified source:** Owner-provided M01 screenshot `image(20261030-034018).png` with four green reference lines and two red negative reference lines.

## Requested geometry
Owner approved R8's cleaner ceiling structure but requested that the *inward-shifted right guide*, marked red, instead follow the same outward-projecting angle/direction as the green-marked left guide. Green line strokes are approximate visual guides, not an authoritative line-engineering blueprint.

## Coordinate calibration, not a new image-generation task
The actual annotated owner screenshot was matched to original `M01 Raspberry Claw Cabinet Body.png` using 786 inlier feature correspondences and a projective mapping approximately scale 0.8797 + translation (13.1,-4.9). Green annotation stroke endpoints were measured, and each upper/lower pair was averaged into a physical rail centerline in the **existing unchanged 1024x1536 cabinet canvas**.

Provisional engineering contact points used by R9:

| Mount | Previous R8 | R9 / green-guide-derived |
|---|---|---|
| LEFT_REAR | (370,390) | (440,380) |
| LEFT_FRONT | (305,425) | (280,422) |
| RIGHT_REAR | (565,410) | (688,380) |
| RIGHT_FRONT | (635,443) | (512,422) |

The previous right rail sloped down-right (rear x565→front x635), while the owner's green guides run from lower-left to upper-right (front x512→rear x688). The right rail now has the same visual depth direction as the left. User markups are approximations and still require the owner's visual assessment.

## Implementation
- Edited only `scripts/presentation/r5/M01MechanicalRig.gd` and the isolated rig regression `scripts/tests/RunR51MechanicalTests.gd`.
- Fixed mount and UV-textured rail geometries, roof soffit and fixed crossmembers are constructed from one shared anchor configuration; bridge endpoint contacts are calculated from these same two paths.
- Because both re-surveyed guides meet the same rear and near Y elevations, the transverse moving bridge is level again instead of artificially pitched downward to the right.
- Trolley continues to counter-rotate any mechanical bridge pitch and hangs under gravity, cable and claw remain connected.
- The tests now assert that both rails retreat *outward/up-right*, reject the old red inward path, verify right rail rear >670/near <530, ensure both guides share same depth slope, confirm all moving rollers remain on the tracks at 720-tick sampled positions, and retain the prior Z/cable/roof transform invariants.
- No new generated art or flat placeholder geometry. Existing premium source textures reused.
- **No changes to accepted Stage 1 core, managers, credits, inventory, customer logic or workshop gameplay.**

## Actual Godot proof
[Run #40999550707](https://github.com/flyingdurian/claw-and-co/actions/runs/40999550707) on commit `5093f2a64e61e12fe1c9b63312c3163b00cb5f36`.
- Godot 4.7.2 isolated mechanical test **1290/1290 passed**, 0 assertion failures.
- Generated 11 actual 1280x720 Godot screenshots, including zoomed frame and far/near bridge contact, and 12-second actual engine movie.
- Actual same-camera R8 versus R9 closeup was inspected. R9 visibly replaces the inward/crossing right rail with an outward diagonal guide; moving bridge support travels correspondingly.
- At source-camera scale, the rail/bridge structure remains visually intricate; moving grab is still a **pose proof, not a mechanically validated pickup**. Third prong linkage, inventory-driven prizes, force contact, prize drop path, and full arcade fidelity are not proven.

## Decision
**Approve as a geometrically consistent engineering candidate and an actual Godot visual-review build.** Owner visual approval is required before treating the new rail layout as the accepted R5.1-M4 roof layout.
Keep PR #1 draft and protect frozen game simulation. If owner flags a specific collision or mounting problem, update this one anchor fixture and rerun the same tests. No Astra request needed.
