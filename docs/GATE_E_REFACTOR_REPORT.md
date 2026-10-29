# CLAW & CO. — Gate E Art Slicing and Tactile Cart R2

**Classification:** Source implementation delivered; **Godot 4.7.2 runtime verification outstanding**.

## Source benchmark

Authoritative image: `image(20261028-165956).png` (1536×1024). It is a **composite concept reference**, not independent proof that its depicted UI or terminal output actually ran in Godot. Only its game-design area, the left 1160 px, is used in this project. The right-side screenshot of source folders and passing tests is not imported or represented as execution evidence.

## Art slicing and scene construction

- `art/parity/arcade_backdrop.png` — approved artwork crop sized exactly 1280×720.
- `art/parity/workshop_backdrop.png` — approved workshop crop remapped for the game viewport.
- `art/parity/cabinet/M01..M04` — independent base-body, prize interior, gantry/mechanism, glass and marquee PNG layers for each machine.
- `art/parity/fx/light_cookie.png` — soft light-cookie used by actual Godot `PointLight2D` nodes.
- `ArcadeAisle.tscn` — parallax backdrop + four illustrated Sprite2D-cabinet instances + customers.
- `BackstageWorkshop.tscn` — illustrated multi-charger, gift station, cassette bay, and real station overlays.
- `Main.tscn` — WorldEnvironment glow, persistent simulation, HUD and cart CanvasLayer.
- No new `ColorRect` or `Polygon2D` placeholders exist in the delivered `.tscn` files.

**Limitation:** The approved reference is a *flattened* image. Cropped layers necessarily retain some previously baked lighting and machine/customer pixels. This first extraction has textured, interactive layers, but is not a fully reconstructed original set of background-free character/prop illustration assets. Independently animated objects can expose tiny background ghosts until manual paint-over assets are authored.

## Tactile cart contract (new Gate E override)

Older Gate A–D: 4 supply + 2 prize + 1 cassette = 7 slots.

New requested explicit layout: **4 single IC card slots + 2 single gift boxes + 2 single ribbons + 2 single prize slots + 1 cassette + permanently accessible key**. Eleven authoritative slots and one virtual tool are now defined. Old `supply_0` through `supply_3`, `prize_0/1`, and `bulk_0` identifiers survive for backward compatibility; new `gift_0/1` and `ribbon_0/1` are added.

- Item selection and click highlight are presentation state; they do not move a single item.
- Loading from Workshop creates one validated `pickup_cart` ledger transfer to a real empty compatible slot.
- Tapping a chosen card then its customer or cabinet opens the existing availability-confirmation popup. On confirmation a **single atomic sale** transfers that exact `cart:supply_n` card to `customer:CN` and updates credits and revenue once. A failed prevalidation leaves the card in its original tray.
- Tapping selected cassette then M01 invokes the already-authoritative restock job. No shadow stock.
- Tapping Staff Key then M02 invokes the existing 90-tick position reset. The key never lives in `InventoryLedger`.
- Tapping a selected gift box or ribbon then the Workshop gift bench transfers that exact item to workshop inventory. Tap again to begin the `gift_wrap` recipe. Selected prize delivery to the trade counter is also supported.
- The original no-cart-card sale route remains available for legacy command replay. This is a compatible route, not a separate business-revenue system.

Files deliberately altered in the protected core: `CartManager.gd` (slot definitions) and `SimulationRoot.gd` (optional source slot for card sale). The `stage_01.json` carrier stanza and its schema were extended; stage content SHA will change, so the earlier accepted final hash cannot be reused to certify this revision. All other protected core/manager source files should match the delivered Gate E baseline byte for byte (checked by static audit).

## Validation and evidence

| Check | State |
|---|---|
| JSON Schema valid, all asset paths exist, complete authored scene hierarchy | See `logs/gate_e_refactor_static.log` |
| Live Godot 4.7.2 parsing/import | **NOT RUN** — engine absent |
| Gate A–D core replay | **NOT RE-RUN** — owner previously accepted baseline, modified cart requires new run |
| Legacy Gate E smoke tests | **NOT RUN** — engine absent |
| New tactile cart / scene smoke tests | **NOT RUN** — engine absent |
| Actual in-engine 1280×720 screenshot | **NOT CAPTURED** — engine absent |
| Runtime side-by-side fidelity measurement | **NOT CERTIFIED** — needs actual screenshot |
| Offline preview | `previews/gate_e_refactor_offline_arcade.png`, explicitly **not** an engine capture |

## Windows execution and parity capture

From the extracted project directory:

```powershell
.\tests\run_gate_e_refactor.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

Once those tests pass, capture a true graphical frame (do **not** pass `--headless`):

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --path . --script res://scripts/tests/CaptureGateE.gd
```

Captures will be written to `previews/gate_e_runtime_arcade_1280x720.png` and `previews/gate_e_runtime_workshop_1280x720.png`. Run `python tests/compare_visuals.py` to produce an actual pixel comparison and side-by-side image. **Do not claim near-identical visual parity until those captures are reviewed.**
