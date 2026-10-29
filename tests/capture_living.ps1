param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
& $GodotExe --path . --script res://scripts/tests/CaptureLivingSequences.gd
if ($LASTEXITCODE -ne 0) { throw 'Real engine capture failed' }
