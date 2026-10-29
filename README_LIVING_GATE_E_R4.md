# Claw & Co. — Gate E R4: Living-World Systems

This is a **development checkpoint, not a visually complete release**. R4 works toward the owner's Oct 28 animated-arcade requirements, but the final illustrated per-character sprite rigs are missing, so fluid character animation is not yet delivered. R3 cutout fallback is retained solely so existing scenes do not reference nonexistent files.

## Core improvements

- The exact approved reference image is saved at `docs/references/approved_living_arcade_full_aisle.png`, alongside the prior composite.
- Perspective routing: `scripts/presentation/PerspectiveCrowdRoutes.gd`.
- Rear/near character occlusion: `scenes/ArcadeAisle.tscn`, `scripts/presentation/LiveCrowdDirector.gd`.
- Actor animation parts and expressions contract: `scripts/presentation/ArticulatedCustomerRig.gd`. Source art production must populate `art/performers/actor_01` through `actor_10` before art acceptance.
- Event-limited speech bubbles: `scripts/presentation/CustomerView.gd`, `ArcadeAisle.gd`.
- Machine win, miss, fault, staff reset and changeover timelines: `MachinePerformanceTimeline.gd` and `MachineView.gd`.
- Inventory-driven `figure_star` art in `art/prizes/`, plus dynamic SKU image lookup.
- Simulation core and existing managers remain byte-identical to R3.

## Tests

`tests/run_r4_systems.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"`

This command runs Godot import, A-D tests, Gate E tests, living-world tests, depth tests and machine performance tests, followed by a deliberately strict final sprite-art contract test. **Until all 10 animated character rigs exist, the script is supposed to exit with an art-acceptance failure.** This prevents passing off cutout bobbing as production animation.

No Godot 4.7.2 executable was available in the creation environment. The packaged `logs/r4_static_audit.log` contains only static verification; it is not a Godot execution report.

## Visual acceptance work still required

See `docs/LIVING_WORLD_R4_ACCEPTANCE.md` and `docs/R4_DELIVERY_NOTES.md` for the required layered assets, interaction cases, camera depth, footage, and actual in-engine fidelity comparison. The existing blurred backdrop must also be replaced by art that does not contain static patrons.
