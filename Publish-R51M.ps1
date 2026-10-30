# Runs from the root of the cloned private flyingdurian/claw-and-co repository,
# AFTER the R5.1-M delta ZIP has been extracted into this folder.
$ErrorActionPreference = 'Stop'
$expected = 'r5/phase1-visual-foundation'
if (-not (Test-Path '.git')) { throw 'Run this from the cloned claw-and-co Git repository root.' }
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne $expected) {
    throw "Expected branch $expected, found $branch. Switch to the existing R5.1 branch first."
}
$preStaged = @(& git diff --cached --name-only)
if ($preStaged.Count -gt 0) { throw 'Unrelated staged changes detected. Commit or unstage them before publishing R5.1-M.' }
$required = @(
    'art/r5/mechanics/gantry/cross_bridge.png',
    'art/r5/mechanics/claw/motor_hub.png',
    'art/r5/m01_body.png',
    'scenes/r5/M01MechanicalRig.tscn',
    'scripts/presentation/r5/M01MechanicalRig.gd',
    '.github/workflows/r51-mechanical-proof.yml'
)
foreach ($f in $required) { if (-not (Test-Path $f)) { throw "Missing R5.1-M file: $f. Extract the ZIP into this folder first." } }
$protected = @(& git status --short -- scripts/core scripts/managers scenes/Main.tscn)
if ($protected.Count -gt 0) { throw 'Protected simulation files have local changes. Do not publish until reconciled.' }
& git add -- art/r5 scenes/r5/M01MechanicalRig.tscn scenes/r5/R51MechanicalProof.tscn scripts/presentation/r5/M01MechanicalRig.gd scripts/presentation/r5/R51MechanicalProof.gd scripts/tests/RunR51MechanicalTests.gd ci/CaptureR51Mechanical.gd ci/run_r51m.sh ci/build_mechanical_assets.py .github/workflows/r51-mechanical-proof.yml docs/r5/R51_MECHANICAL_PROOF_README.md
if ($LASTEXITCODE -ne 0) { throw 'Git staging failed.' }
$paths = @(& git diff --cached --name-only)
if ($paths | Where-Object { $_ -match '^(scripts/core/|scripts/managers/|scenes/Main\.tscn)' }) { throw 'Protected simulation path was staged.' }
if ($paths.Count -eq 0) { Write-Host 'R5.1-M files already staged/committed; nothing to publish.'; exit 0 }
& git commit -m 'R5.1-M: articulated gantry/claw proof with genuine Godot capture workflow'
if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
& git push origin $expected
if ($LASTEXITCODE -ne 0) { throw 'Git push failed. Check GitHub Desktop or Git credentials.' }
Write-Host 'R5.1-M pushed. GitHub Actions will execute the mechanical proof; visual acceptance remains pending.'
