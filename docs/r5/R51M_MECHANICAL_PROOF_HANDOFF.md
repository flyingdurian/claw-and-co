# Claw & Co. — R5.1-M Mechanical Assembly Proof
Status: **Engine verification pending; NO owner visual acceptance**

## Implementation artifact
A complete R5.1-M mechanical-rig delta ZIP was generated in the ChatGPT development workspace and attached in the project conversation. The artifact includes independently extracted Astra gantry/claw sprites, unchanged M01 source body, provisionally registered interior, corrected depth rails, scenes, tests, capture scripts and CI job.

### Locally authored project files
- `scenes/r5/M01MechanicalRig.tscn`, `scenes/r5/R51MechanicalProof.tscn`
- `scripts/presentation/r5/M01MechanicalRig.gd`, `scripts/presentation/r5/R51MechanicalProof.gd`
- `scripts/tests/RunR51MechanicalTests.gd`
- `ci/CaptureR51Mechanical.gd`, `ci/run_r51m.sh`, `ci/build_mechanical_assets.py`
- `.github/workflows/r51-mechanical-proof.yml`
- `art/r5/mechanics/gantry/*`, `art/r5/mechanics/claw/*`, `art/r5/m01_body.png`, `art/r5/m01_interior_recovered.png`, `art/r5/front_aisle_architecture.png`, `art/r5/m01_fixed_depth_rails.png`

## Geometry implementation
Cabinet-local 1024×1536 coordinates. Two existing textured rails are projection-warped as *fixed overhead depth guides*, with a moving cross-bridge position between left/right rail endpoints. Independent trolley lateral movement is nested under the bridge. A separately rendered cable uses dynamic length while its winch housing remains undistorted. The original six claw components are instantiated as sprites under explicit hub/left-shoulder/left-elbow/right-shoulder/right-elbow/rear-pivot transform nodes.

## Test trajectory
The scene has a deterministic authored 720-tick demonstration: ready -> seek XY -> descend -> close -> hoist -> transit toward payout -> open -> return. No new gameplay RNG, stock/credit changes or prize outcomes. This is a *mechanism motion proof*, not the accepted playable M01 or validated collision mechanics.

## Honest acceptance limitations
- The art package has been statically validated locally, but Godot 4.7.2 engine import, mechanical tests, screenshots and movie have **not yet run** for this checkpoint.
- The connected GitHub writer does not accept local file paths for the 17 PNG assets. Therefore this documentation commit deliberately does NOT claim the mechanical scene is already published or CI validated. The complete binary/code delta must be applied to this branch before the new workflow can execute.
- Third finger upper linkage, exact physical contact/force, far/near rail projection, winch-claw cable seam, and cabinet extreme clearance must be inspected in real Godot captures. Do not certify by passing static tests alone.
- Strict original R5.1 visual gate and owner signoff remain blockers.
- Original gameplay core and managers are unchanged by this checkpoint.

## Next action
Apply the accompanying R5.1-M delta ZIP at repository root on this branch, commit, and push. The `R5.1-M Mechanical Godot Proof` workflow then executes import, deterministic pose tests, nine authentic 1280x720 screenshots, and a 12-second engine movie. Review all rendered evidence and iterate on exact seams/perspective before anything is merged.
