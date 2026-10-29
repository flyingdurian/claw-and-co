# CLAW & CO. — M4 Roof Fixture: Stop Generative Registration Retries

**Date:** 2026-10-29 (Vancouver)
**Decision:** DO NOT commission another generic Astra attempt to satisfy precise fixed roof geometry. Pivot to engineering-controlled rail construction with the existing premium hardware art as texture sources.

## Actual latest artwork inspected
- Exact user Library image: `Chrome ceiling rails with brackets.png` 1024 × 1536 RGBA.
- Fully transparent pixels: approximately 95.1%. The two main alpha-connected component bounding regions at threshold alpha>20: `(146,307)-(438,513)` and `(565,312)-(879,515)` (image-space coordinates).
- The visible artwork consists of **two disconnected short rail/bracket units**, not full continuous roof-depth guide rails.
- Material, fasteners, lighting and bracket construction are aesthetically usable, but source rails do NOT follow the engineer's existing left/right depth axes and are wider apart/lower than the calibrated two-rail path.
- Original Astra model correctly reported registration failure. Pixel dimensions/alpha alone do not establish alignment.

## Alignment contract (existing prototype anchors; visually survey again if needed)
Existing `M01MechanicalRig.gd` at M4:
- `LEFT_REAR=(383,371)`, `LEFT_FRONT=(300,415)`
- `RIGHT_REAR=(562,371)`, `RIGHT_FRONT=(645,414)`
- Bridge left and right endpoints derive from linear interpolation along these same fixed rail centerlines at a shared normalized `depth`.
- The rail art is registered to these endpoints; hardware appearance must not dictate *different* movement paths. Candidate anchors still need checking against physical structure and full claw envelope.

## Revised production approach

1. Treat generated rail/bracket art as **material donor/source**, not a coordinate-authoritative fixture.
2. Create independently cropped, premultiplied-alpha-correct roof bracket sprites. Use original high-fidelity polished metal bolts/plates, not flat placeholder rectangles.
3. Build each fixed track as a **texture-mapped strip or segmented mesh**, explicitly anchored between physically plausible cabinet roof mount locations; preserve proper width and perspective interpolation. Bilinear/deformation math is allowed for the geometry, but avoid crude squashing of an entire assembled fixture.
4. The moving bridge's wheel attachment targets must derive from the same underlying guide curves and remain tangent/contacting at all tested depths. No independent arbitrary rail vs bridge screen positions.
5. Render roof trim occlusion appropriately: fixed bolts appear inserted into structural roof; no beam hovering beneath fascia or punching through glass.
6. Revisit near/far guide perspective as a deliberate design task, then certify only through **actual Godot** 1280×720 shots and video. Tests must measure both numeric engagement error and visual appearance.
7. If a source component proves unusable, ask Astra for an isolated straight chrome beam MATERIAL TILE or a bracket texture, with no request for exact registration. Do not regenerate the full M01 cabinet or complete roof fixture.

## Engineering acceptance

- Four visibly roof-bolted stationary mounts.
- Two continuous and credible front-to-back guides.
- Moving bridge rollers engage both guides throughout Y travel.
- Trolley X travel, Z hoist and claw remain in the chamber.
- No disappearing into rear/body, no detached cable, no visual collision with front control lip.
- Authoritative deterministic game simulation frozen.
- All tests plus actual Godot visual inspection/owner approval; numeric pass alone does not imply fidelity.

**R5.1-M4 status:** fixed roof hardware still blocked on rig-registered asset construction. Existing draft PR remains unmerged.
