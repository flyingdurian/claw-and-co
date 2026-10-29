param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force -Path 'logs' | Out-Null
& $GodotExe --headless --path . --import --quit *>&1 | Tee-Object -FilePath 'logs/r4_import.log'
if ($LASTEXITCODE -ne 0) { throw 'R4 Godot import failed; inspect logs/r4_import.log' }
$tests = @(
    'res://scripts/tests/RunTests.gd',
    'res://scripts/tests/RunGateETests.gd',
    'res://scripts/tests/RunGateERefactorTests.gd',
    'res://scripts/tests/RunLivingWorldTests.gd',
    'res://scripts/tests/RunPerspectiveCrowdTests.gd',
    'res://scripts/tests/RunMachinePerformanceTests.gd'
)
foreach ($test in $tests) {
    $log = 'logs/' + ((Split-Path -Leaf $test) -replace '\.gd$', '.log')
    & $GodotExe --headless --path . --script $test *>&1 | Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) { throw "R4 runtime suite failed: $test" }
}
Write-Host 'R4 RUNTIME SYSTEM TESTS PASS. ART CONTRACT IS A SEPARATE REQUIRED CHECK.'
& $GodotExe --headless --path . --script res://scripts/tests/RunR4ArtAcceptance.gd *>&1 | Tee-Object -FilePath 'logs/RunR4ArtAcceptance.log'
if ($LASTEXITCODE -ne 0) { throw 'R4 animation-art contract BLOCKED. Export illustrated modular rigs before accepting Gate E.' }
Write-Host 'R4 ENGINE + ART CONTRACT PASS (FINAL VISUAL REVIEW STILL REQUIRED).'
