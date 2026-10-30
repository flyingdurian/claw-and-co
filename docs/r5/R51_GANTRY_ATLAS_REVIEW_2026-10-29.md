# Claw & Co. — R5.1 gantry hoist atlas review (actual asset)

Reviewed 2026-10-29. **Decision: accept as source art for rig construction; do not yet accept kinematics / Godot runtime.**

## Sources
- `Exploded Chrome Gantry Hoist Atlas.png` — exact ChatGPT Library file, 1536x1024 RGBA.
- Compared visually with `Six-Part Chrome Claw Disassembly Atlas.png` and `M01 Raspberry Claw Cabinet Body.png`.
- All source hardware artwork remains unchanged. This note is a diagnostic, NOT full development completion.

## Pixel-level evidence
- Source atlas 1536×1024 RGBA. 43.92% fully transparent pixels; additional low-alpha glow is present outside the object edges. Extraction must avoid baking the ambient pink halo into the runtime.
- Connected components with alpha >16 form **exactly seven substantial islands**. Independent alpha islands do **not** independently prove mechanical articulation or fit.
- Exact bounding boxes `[x0,y0,x1,y1)`:
  1. Fixed rail A `[43,13,1495,282)` (1452x269)
  2. Fixed rail B `[41,208,1506,466)` (1465x258)
  3. Cross bridge `[38,429,1502,701)` (1464x272)
  4. Carriage/trolley `[80,683,509,999)` (429x316)
  5. Hoist winch/drum `[552,700,1102,969)` (550x269)
  6. Suspension cable `[1151,693,1180,1002)` (29x309)
  7. Claw connector `[1302,710,1439,1002)` (137x292)

## Actual visual review
- Excellent consistent materials: pink chrome reflection, industrial bolts, wheeled brackets, machined edges.
- Three beams have broadly consistent length and hardware: the top two appear designed as fixed rails; middle as a moving crossbar. Their atlas presentation is nearly horizontal, not projected into the M01 cabinet's three-quarter depth.
- The trolley is a four-wheel mount, the winch is a complete drum/motor, the cable is a narrow separate strip, and the adapter is a discrete suspension connector.
- Long beams may not naturally fit front-to-back chamber guide axes without perspective correction / rerendering of a **specific rail**. Do not squash the whole gantry indiscriminately; test anchored deformation/placement at cabinet scale.
- Cable sprite is a short segment; hoist travel should change its length using repeat/segment geometry, NOT scale/stretch bolts/motor housings.
- The connector and six-part claw hub must be mounted to the same local coordinate frame, and the final 3rd claw finger still needs a validated articulation route.

## Pre-Godot diagnostic only (NOT runtime proof)
A proportional source composite of the bridge, carriage, winch, cable, original open-claw reference and existing recovered chamber fit beneath the original M01 cabinet body without repainting the shell.
No depth guide rails were accepted in that composite because their three-quarter projection is unresolved.
The nominal scale/place experiment **does not** establish moving-part clearance, cable continuity, retraction, working winch alignment, 2D depth projection or contact with prizes.

## Next development milestone — R5.1 Mechanical Proof
1. Extract the seven alpha-isolated pieces. Clean translucent edge halos.
2. Create `M01MechanicalRig.tscn` with fixed depth rails, moving XY bridge, trolley, winch, extendable cable, connector, and existing independently-pivoted 6-part claw sprites.
3. Establish a single chamber-local coordinate system for X lateral, Y chamber depth and Z vertical hoist; project into 2D from fixed camera. Depth movement must change screen position/occlusion correctly.
4. Prove **one complete authored attempt**: idle, position, descend, three-finger close, lift, move to payout chute, release, return; plus fail/lift-empty case. Animate deterministically from existing machine state/time, not outcome RNG.
5. Keep prize sprites in inventory-owned scene state, with consistent depth, gripping offset and output chute handoff. Do not use art to create prizes.
6. Test gantry stops at all extreme travel positions and reject visible intersections with cabinet frame/interior/floor; verify cable-to-hub connection at all heights.
7. Use actual Godot 4.7.2 screenshot and brief animation movie with GitHub CI. Offline images can be used only as diagnostics, not owner acceptance.
8. If a component fails mechanical/perspective proof, request one targeted corrected rail/connector from Astra, not a whole gantry regeneration.
9. Protect `scripts/core`, `scripts/managers`, `scenes/Main.tscn` and approved Stage 1 deterministic simulation.

## CI outcome / release
**Asset source: approved to prototype. Articulation and actual scene: pending.** The strict R5.1 visual gate remains blocked until source assets are staged and an actual Godot capture is inspected and owner-accepted. This PR must stay draft.
