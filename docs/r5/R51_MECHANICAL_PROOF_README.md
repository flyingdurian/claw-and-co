# CLAW & CO. — R5.1-M Mechanical Proof (not yet engine-certified)

## Delivery
This ZIP is an isolated overlay for the existing private GitHub project, branch `r5/phase1-visual-foundation`. It **does not modify** the Stage 1 simulation or original `scenes/Main.tscn`.

### Windows publish (once)
1. Ensure the `claw-and-co` repository is cloned locally and the branch `r5/phase1-visual-foundation` is checked out. `git pull` the branch first.
2. Extract the accompanying `ClawCo_R51M_Mechanical_Rig_Delta.zip` directly into that repository root, keeping directory structure intact.
3. From PowerShell in the cloned repository root, execute `./Publish-R51M.ps1`. If PowerShell prevents running scripts, see the manual command below; do not change your global execution policy to run an unverified script.

Manual alternative (after extracting ZIP at repository root):

```powershell
git add art/r5 scenes/r5/M01MechanicalRig.tscn scenes/r5/R51MechanicalProof.tscn scripts/presentation/r5/M01MechanicalRig.gd scripts/presentation/r5/R51MechanicalProof.gd scripts/tests/RunR51MechanicalTests.gd ci/CaptureR51Mechanical.gd ci/run_r51m.sh ci/build_mechanical_assets.py .github/workflows/r51-mechanical-proof.yml docs/r5/R51_MECHANICAL_PROOF_README.md
git commit -m 'R5.1-M: articulated gantry/claw mechanical proof'
git push origin r5/phase1-visual-foundation
```

The new GitHub workflow `Claw & Co. | R5.1-M Mechanical Godot Proof` imports scenes and runs deterministic mechanical tests, generates nine actual 1280×720 engine screenshots and records a 12-second Godot animation.

## Scope
- Source artwork: independent 7 gantry sprites + 6 claw sprites, projected fixed rails, M01 body, provisional chamber interior and clean architecture.
- Mechanical 3-axis proof: moving overhead bridge (Y depth), trolley (X lateral), winch/cable (Z vertical), independent left/right/rear claw pivots.
- Authored 720-tick mechanical cycle: ready, seek, lower, close, hoist, move over payout, release, return.
- No new sales, inventory, prizes or authoritative gameplay outcomes. This is a **visual mechanical test**, not a playable machine completion.

## Explicit acceptance blockers
- Engine tests in the ZIP are provided but have **not been run in this container**.
- Rear finger lacks an original independent proximal linkage, remaining mechanical risk.
- Correct 3/4 fixed-rail depth projection, no cable gap, claw clearance at all extremes and contact behavior require real Godot video inspection.
- Premature proof can show arm motion without genuine stock collision, payout handoff or customer play; those remain for later R5.3.
- Godot Compatibility captured in GitHub is not equivalent to native Windows Forward+ glow quality.
- No owner visual approval; original strict R5.1 full art gate still awaits glass/lighting and full aisle review.

## Original simulation protection
`art/r5`, `scripts/presentation/r5`, `scripts/tests/RunR51MechanicalTests.gd` and `ci` only; no changes to `scripts/core`, `scripts/managers`, or Main scene.
