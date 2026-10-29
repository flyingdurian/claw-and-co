param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force -Path 'logs' | Out-Null
& $GodotExe --headless --path . --import --quit *>&1 | Tee-Object -FilePath 'logs/gate_e_refactor_import.log'
if ($LASTEXITCODE -ne 0) { throw "Godot import failed with exit $LASTEXITCODE" }
& $GodotExe --headless --path . --script res://scripts/tests/RunTests.gd *>&1 | Tee-Object -FilePath 'logs/gate_e_refactor_core.log'
if ($LASTEXITCODE -ne 0) { throw "Gates A-D regression failed" }
& $GodotExe --headless --path . --script res://scripts/tests/RunGateETests.gd *>&1 | Tee-Object -FilePath 'logs/gate_e_refactor_legacy_ui.log'
if ($LASTEXITCODE -ne 0) { throw "Original Gate E regression failed" }
& $GodotExe --headless --path . --script res://scripts/tests/RunGateERefactorTests.gd *>&1 | Tee-Object -FilePath 'logs/gate_e_refactor_interactions.log'
if ($LASTEXITCODE -ne 0) { throw "Gate E refactor test failed" }
Write-Host 'ALL THREE SUITES PASSED'
