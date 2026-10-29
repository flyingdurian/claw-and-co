param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force -Path 'logs' | Out-Null
& $GodotExe --headless --path . --import --quit *>&1 | Tee-Object -FilePath 'logs/living_import.log'
if ($LASTEXITCODE -ne 0) { throw 'Godot 4.7.2 import failed' }
$tests = @(
    'res://scripts/tests/RunTests.gd',
    'res://scripts/tests/RunGateETests.gd',
    'res://scripts/tests/RunGateERefactorTests.gd',
    'res://scripts/tests/RunLivingWorldTests.gd'
)
foreach ($test in $tests) {
    $logfile = 'logs/' + ((Split-Path -Leaf $test) -replace '\.gd$', '.log')
    & $GodotExe --headless --path . --script $test *>&1 | Tee-Object -FilePath $logfile
    if ($LASTEXITCODE -ne 0) { throw "Failed: $test" }
}
Write-Host 'ALL FOUR GATE A-E / LIVING WORLD SUITES PASSED'
