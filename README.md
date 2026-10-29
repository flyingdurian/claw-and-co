# CLAW & CO. — Gates A–D GDScript simulation source

**Target** Godot 4.7.2 stable, pure GDScript, Forward+, 1280x720, 60 physics ticks/sec, 7200-tick Stage 1.
**No scenes, sprites, placeholder blocks, avatar, character controller, or Gate E work are included.**

## Current verification status (read before using)

- **PASS**: Three Draft 2020-12 JSON Schema validations, cross-file inventory and reference preflight, negative schema tests, replay schedule preflight, and GDScript source contract check.
- **NOT EXECUTED**: Godot 4.7.2 parsing, import, runtime, and the 7200-tick GDScript headless suite. The authoring container has no Godot executable and cannot download it. See `logs/godot_headless_attempt.txt`. **Do not classify Gates B–D as runtime accepted until the Godot suite passes.**
- This package is an isolated, source-only project. No pre-existing Godot, GitHub or Higgsfield project was changed.

## Run the tests in a Godot 4.7.2 environment

From the extracted directory:

```bash
python3 -m pip install jsonschema
python3 tests/validate_fixtures.py
python3 tests/validate_replay_schedule.py
python3 tests/static_contract_check.py
python3 tests/test_schema_negative.py
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 ./tests/run_headless.sh
```

On Windows, use Godot.exe and run:

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64.exe" --headless --path . --import --quit
& "C:\path\to\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://scripts/tests/RunTests.gd
```

The GDScript headless runner checks the entire 120-second authored trace three times (two identical replays and one without area-switch commands), plus atomic-failure and cart-capacity cases. It emits `FINAL_SHA256`, `FINAL_SCORE`, revenue and exit code **0 only after all assertions pass**. `tests/run_headless.sh` writes `logs/godot_headless.log` when Godot is available.

## Folder map

- `schemas/*.schema.json`: Item, machine and stage Draft2020-12 JSON schemas
- `data/items.stage1.json`: 11 original item SKUs
- `data/machine_types.stage1.json`: 3-prong plush, 2-prong UFO, Barber Cut
- `data/stage_01.json`: Opening Rush, 4 cabinets, 3 waves, 8 visits, 5 sessions, 4 production jobs
- `data/commands.stage1.json`: deterministic player-input timeline (23 commands)
- `scripts/resources/ItemData.gd`, `MachineData.gd`, `StageManifest.gd`: optional Godot editor Resources; **JSON remains canonical**
- `scripts/core/SchemaLoader.gd`: runtime JSON parser, version checks, critical cross-references. Full JSON Schema validation is the external preflight tool.
- `scripts/core/SimulationClock.gd`: integer 60Hz timeline
- `scripts/core/SimulationRoot.gd`: sole command gateway, money/credit account and authoritative snapshot
- `scripts/core/InventoryLedger.gd`: item ledger, exclusive claims, atomic multi-item transfer
- `scripts/core/SimulationDriver.gd`: a scene-independent Node adapter for a future persistent main scene
- `scripts/managers/`: MachineManager, CustomerManager, WorkshopManager, CartManager
- `scripts/tests/RunTests.gd`: Godot headless executable tests
- `tests/*.py`: external fixture, adversarial schema, and static contract checks
- `logs/`: actual external test logs and honest Godot execution blocker

## Gate contracts

**A / Input:** Production and machine data loaded from fixed versioned JSON. Schemas validated externally and loaded via Godot JSON parser. An extra PB04 `prepare_cassette` job was added to Stage 1 to prove cassette unboxing before the M01 restock; original JSON fixtures and schemas were otherwise preserved.

**B / Engine:** The simulation is an integer-tick model. `SimulationDriver` advances once per physics callback; headless replay calls `SimulationRoot.advance()` explicitly. Every physical item is uniquely owned. A reservation is an exclusive token, never another owner. Transfers validate all owners before moving any item. Consumed materials remain as tombstones for audit. Card sale increments cash and revenue and customer credits once; admission consumes credits once and never creates revenue.

**C / Floor:** Arrival ticks and attempt outcomes come from the manifest; no random payout rolls. Machine admission verifies card balance, FIFO queue head, cabinet READY and exact prize available; a failed check cannot change credit or stock. Output remains occupied for the authored collection duration and blocks new play/loading. A miss releases prize claim and reduces patience without taking stock. M02 Staff Key takes exactly 90 ticks and sets `aligned_for_win`, immediately starting next authored attempt.

**D / Work:** Charging, unboxing, gift wrapping and trade-ups complete at absolute ticks regardless of area. Cart inventory has four supply pockets, two prize pockets and one bulk cassette cradle. `quote_card_purchase()` exposes current cabinet state and queue for UI presentation before a purchase; `purchase_card` revalidates the same facts at commit time.

## Deterministic Stage 1 command sequence

| Tick | Command | Expected state effect |
| ---: | --- | --- |
| 0 | PB01 charge | Blank starter card enters production |
| 200–201 | V01 sale and M01 admission | 500 revenue minor; 6 credits added; 3 spent |
| 600–601 | V02 top-up and M02 admission | 400 revenue minor; UFO plays first attempt |
| 930 | V03 trade-up | Two small plush consumed into one fixed P900 |
| 1200 | M02 Staff Key | 90 ticks, then immediate second attempt |
| 1800 | PB02 charge | Progresses offscreen |
| 1940 | V04 wrapping | 360-tick job and exact packaging ownership |
| 1980 | PB04 cassette preparation | K05 prepared by tick 2070 |
| 2110–2120 | Cart pickup and M01 restock | K05 in bulk cradle, then changeover |
| 2300–2301 | V05 sale and M03 admission | Barber scripted miss; claim released |
| 3100–3101 | V06 top-up and M04 admission | Premium plush session |
| 3600 | PB03 charge | Final starter card ready at tick 3780 |
| 3950 | V07 top-up | Card purchase without session |
| 4650–4651 | V08 starter purchase and M01 admission | Newly restocked P005 is played |
| 7200 | End of Stage 1 | Three stars expected; project revenue CAD 27.00 |

## Important implementation boundaries

- No placeholder UI or sprites were created; Gate E owns all illustrated presentation.
- A standalone point-and-click UI must call `quote_card_purchase` before `purchase_card` and display availability/queue data.
- Full JSON Schema support is provided by Python preflight, not an embedded GDScript JSON Schema interpreter.
- This fixture assumes one completed scripted session per requested admission; a future customer retry uses a new authored admission/session and another explicit credit debit, rather than silently replaying a failed terminal attempt.
- Do not substitute a successful Python validation for Godot 4.7.2 compilation and behavior tests.
