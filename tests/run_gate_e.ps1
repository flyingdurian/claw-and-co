param(
    [Parameter(Mandatory=$true)][string]$GodotExe
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
New-Item -ItemType Directory -Force (Join-Path $root 'logs') | Out-Null
& $GodotExe --headless --path $root --import --quit 2>&1 | Tee-Object -FilePath 'logs/gate_e_import.log'
if ($LASTEXITCODE -ne 0) { throw "Godot import failed: $LASTEXITCODE" }
& $GodotExe --headless --path $root --script res://scripts/tests/RunGateETests.gd 2>&1 | Tee-Object -FilePath 'logs/gate_e_headless.log'
if ($LASTEXITCODE -ne 0) { throw "Gate E headless test failed: $LASTEXITCODE" }
