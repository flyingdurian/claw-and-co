# Claw & Co. — Gate E implementation record

## Scope

**Original illustrated 2D presentation integrated with the accepted A–D source**. The nine original files in `scripts/core/` and `scripts/managers/` are preserved byte-for-byte from `claw_and_co_godot472_gates_A_D_source.zip`. The stage manifest and 514-assertion baseline are **not** modified or rerun.

**Do not classify Gate E runtime accepted solely from this delivery.** Godot was not installed in the authoring environment. Python scene/texture/source-reference validation passed, but the Godot import, scene-instantiation, and interaction smoke test still require execution in Godot 4.7.2.

## Implemented scenes

- `scenes/Main.tscn`: single persistent Control; owns SimulationDriver, PresentationBridge, both area views, HUD and cart. This is configured as `run/main_scene`.
- `scenes/ArcadeAisle.tscn`: first-person customer-facing aisle, four illustrated interactive cabinets and chibi request bubbles, Staff Key and restock controls, service desk.
- `scenes/BackstageWorkshop.tscn`: illustrated card-charging station, cassette-unboxing bay, gift-wrap bench and prize trade-up counter, plus K05 cart pickup.
- `scenes/ServiceCartUI.tscn`: four supply pockets, two prize pockets, one bulk cradle, persistent across area switches and populated from ledger snapshots.
- `scenes/TopBarHUD.tscn`: stage title, remaining minutes/seconds, cash balance (minor units / 100), score, star threshold meter.
- `scenes/machines/M01_Machine.tscn` through `M04_Machine.tscn`: four distinct original illustrated cabinet scenes and fixed-tick CanvasItem effects.
- `scenes/customers/CustomerView.tscn`: original chibi artwork plus actionable speech bubble and short win/miss/help reactions.

All illustrations in `art/` are original PNG assets rendered from locally generated vector artwork, not copied from reference arcade games. Empty cart pockets are **actual empty slots**, not temporary gray-box stand-ins.

## Integration boundary and safe commands

`PresentationBridge.gd` wraps the *existing* `SimulationDriver.submit` and never changes `SimulationRoot`, InventoryLedger or stage contents. All interactive commands go through `PresentationBridge.request_action`, which supplies distinct command IDs. `request_quote` invokes the authoritative `quote_card_purchase`; purchase confirmation alone issues `purchase_card` and core revalidates availability. No presentation script edits balances or prize ownership.

Both area scenes remain alive. `switch_tab` sends the pure `switch_area` simulation command and changes only scene visibility; it does not pause, recreate, or advance a separate clock. The adapter publishes snapshots in the physics loop after the SimulationDriver (priorities -20 and 20), and forwards simulation/machine/workshop events. Sprite movement is derived from integer `tick`, attempt timings and machine states; no random effects or wall-clock-based game logic.

Workshop/arcade interactions deliberately support manual play: use the Workshop to charge cards, serve purchases by tapping customers or using the Desk, and tap a machine to open available service commands. A customer card quote is shown in a confirmation dialog before sale. The Stage 1 **authored replay** is only test data and is not forcibly auto-executed in normal interactive play.

## Verification evidence

- `logs/gate_e_static_validation.log`: real local static test PASS, including 10 scene files, 8 presentation scripts, 24 PNG textures, 31 external scene references, expected node paths, unique machine illustrations, and verified freeze of all nine core/manager code files.
- `scripts/tests/RunGateETests.gd`: **unexecuted** scene interaction smoke runner. It checks boot, four cabinets, 4/2/1 cart, HUD, scene switching without tick mutation, workshop charging, customer sale quote and confirmation, admission credit debit and lack of duplicate revenue, machine visual state and original asset imports.
- `tests/run_gate_e.ps1`, `tests/run_gate_e.sh`: commands to import project and run the Godot headless UI smoke test, recording `logs/gate_e_import.log` and `logs/gate_e_headless.log` in the user's environment.
- `previews/*_layout_preview.png`: composited 1280x720 art layout previews. **Not runtime screenshots**; do not treat them as UI acceptance captures.

## Windows Godot 4.7.2 execution

Extract this ZIP to a directory and open a PowerShell terminal inside it. The script creates `logs/` if necessary, avoiding Tee-Object's path-not-found error.

```powershell
.\tests\run_gate_e.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

Or run manually:

```powershell
New-Item -ItemType Directory -Force .\logs | Out-Null
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --import --quit 2>&1 | Tee-Object .\logs\gate_e_import.log
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/RunGateETests.gd 2>&1 | Tee-Object .\logs\gate_e_headless.log
```

For visual review, open `project.godot` and run the default main scene. Check sprite composition, tap hit targets, order card legibility, Staff Key timing, M03 miss effects, idle frame rate, and tab switching. Gate E visual acceptance is a separate decision after the Godot runtime tests.
