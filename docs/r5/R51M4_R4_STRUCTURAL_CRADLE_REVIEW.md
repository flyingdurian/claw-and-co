# CLAW & CO. — R5.1-M4 R4 structural cradle proof
**2026-10-29 — Vancouver.** Verified run [40970916971](https://github.com/flyingdurian/claw-and-co/actions/runs/40970916971); head commit `23f059ef5ad3233238716f7503d6509e0e333b14`.

## Actual engineering delivery
- `M01MechanicalRig.gd`: new fixed `FixedRoofCradle/RearLoadBeam` and `FixedRoofCradle/FrontLoadBeam`. Both use original source GANTRY chrome UV textures on fixed cabinet-mounted polygons; they connect the corresponding surveyed rear/front roof mounts rather than following bridge movement.
- Bridge `LeftRollerEngagement/LeftBearingBogie` and `RightRollerEngagement/RightBearingBogie`: independent illustrated roller bearing regions, each parented to the moving bridge's precise rail-contact anchor.
- Increased four fixed bolt/bracket mount proportions to improve visibility; retained existing four fixed contact plates.
- No new flat material/wireframe placeholders and no new generated images.
- Tests now check original chrome texture presence, crossmember geometry, immutable cradle transforms over authored 720-tick movement, and distinct moving bearing assets.
- All 1116/1116 Godot 4.7.2 mechanical assertions pass, 0 failed.
- Nine actual Godot 1280×720 screenshots and 12-second movie captured via CI.
- No change to simulation, customer, inventory, scoring, Workshop, Stage 1 manifest or production.

## Visual findings from actual R3/R4 comparison
- Mechanical roller support visibility is improved. The moving bridge and cable remain within the front chamber in inspected poses.
- Side-by-side screenshot close-up shows change is **small at game resolution**, with a crowded horizontal chrome zone; cabinet roof still reads partly as a collection of miniature applied hardware rather than a premium integrated ceiling gantry.
- Existing cabinet source painting includes structural ceiling chrome under the marquee, so adding full redundant chrome components creates risk of double/triple mechanical detail.
- Main fidelity blocker is now **layer composition/roof occlusion and integrated weight-bearing silhouette**, not numerical bridge interpolation. The existing source is too shallow to support many more ornamental sprites without clutter.
- Distinct bearing wheels are not a mechanical force or collision proof; numerical anchor contact alone is not an actual rolling contact simulation.
- Third prong and variable-stock pickup still provisional, outside this checkpoint.

## Release decision
**R4 engineering complete; owner visual acceptance NOT claimed.** Keep M4 open, PR #1 draft. No Astra retry necessary right now.

## R5 follow-through
1. Design a **single deliberate front fascia/roof occlusion layer** based on the approved cabinet body and physically useful mount/rail segments. Avoid stacking more fragmented bolted ornaments.
2. Calibrate rooftop support placement at the actual 1280x720 game camera, not only full source-asset resolution.
3. Render near/far/left/right extremes, verify no duplicate baked ceiling art and ensure both bearings are visibly seated.
4. Only after the owner accepts mounting quality proceed to live prize contact and chute handoff. No changes to accepted simulation during this isolated art proof.
