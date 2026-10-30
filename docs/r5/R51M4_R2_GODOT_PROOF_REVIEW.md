# CLAW & CO. — R5.1-M4 R2 Godot proof review

Date: 2026-10-29 Vancouver
Commit tested: `bdf115badb2ac30bd6f9e704dfe5ff1136e3abf0`
[Actual Godot Actions run](https://github.com/flyingdurian/claw-and-co/actions/runs/40950496578)

## Result
- Godot 4.7.2 Mechanical Proof: **1101/1101 assertions passed**, 0 test assertion failures.
- Nine genuine 1280×720 engine frames + 12-second movie produced.
- Original Stage 1 deterministic simulation, core, managers and Main scene remain unchanged.
- R5.1-M4: **functional mounting-geometry proof ACCEPTED provisionally**; **owner visual acceptance NOT achieved**.

## Implemented versus previous M4
- Fixed static roof rails switched from squeezed full sprites to explicit two-guide **UV-textured Polygon2D meshes** using original high-detail chrome asset regions, not placeholder solid-color shapes.
- Guide mesh vertices are anchored at the four roof mounting coordinates; near/far thickness differs to communicate shallow 3/4 perspective.
- Four separate roof bracket hardware sprites are region-cropped from the original Astra artwork; increased physical extent and kept stationary.
- Moving bridge rollers use the exact same roof points for their interpolation, with two independently verified engagement markers.
- Rig invariant tests validate rail UV/texture, four roof mount hardware nodes, four corner points, end position, bridge engagement, shared cable/connector anchors and 720-tick determinism.
- First R2 CI run failed 81 assertions because stale instrumentation measured the Polygon2D's node origin (0,0) instead of the rail mesh midpoint. Updated diagnostic to measure four polygon corners; ensuing 1101/1101 passed without removing rail or mount correctness checks.

## Actual visual inspection
Compared prior R5.1-M4 closeup to current:
- Textured strips and bracket shapes provide more metallic continuity than previous squeezed sprites. The bridge position remains inside the front display and the cable appears continuous in proof poses.
- **Still a visual blocker**: the new fixed rails and attachment hardware are small and visually lost against the original cabinet roof fascia, particularly at 1280×720. The joint between the brackets and the cabinet's actual structural roof is not emphatic enough; the player could still perceive a suspended mechanism.
- The projection is a 2D image-space approximation; the camera's side-window occlusion and cross-bridge perspective require further approval.
- The third finger articulation is provisional; no live prize interaction or front lip collision *silhouette* certification.
- No claim of commercial-level mechanical visuals. A numerical CI success is NOT an artistic acceptance.

## Next production recommendation
1. Don't ask Astra for repeated perfect pixel registration. Crop **distinct bolt/roof plates** from existing high-quality source and render these as narrow foreground contact-layer art over only the cabinet's underside lip, with structural support behind. Avoid duplicating the entire fascia and avoid moving parts in this mask.
2. Calibrate bracket size and position at actual in-game cabinet scale, not 1024×1536 alone. Check all four contacts and near/far bridge endpoints through the real Godot movie.
3. If the existing donor bolts cannot be legibly placed without seams, ask for ONLY standalone roof mounting bracket material art (not a full registered rail assembly).
4. After fixed mounts visually read as physically attached, test dynamic independent plush/prize clip zones and chute delivery, without changing accepted simulation.
5. Keep PR #1 draft until owner visually approves actual engine captures.

## Evidence scope
The screenshot evidence in run is real Godot captured with software OpenGL Compatibility renderer; native GPU Forward+ not yet validated. The screenshots do not establish physical forces or working gameplay outcomes.
