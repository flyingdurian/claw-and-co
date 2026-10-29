# Claw & Co. — Living Arcade R3

## Scope and authority

This revision is a presentation architecture, not a new game. The existing Stage 1 JSON, `SimulationRoot` command gateway, `SimulationClock`, `CustomerManager`, `MachineManager`, `WorkshopManager`, `InventoryLedger`, and `CartManager` are preserved byte-for-byte from Gate E R2. No random state, extra admissions, or hidden staff actions were added. The authoritative clock continues at 60Hz while switching areas.

## Living customers / patrons

* `LiveCrowdDirector.gd` instantiates **8 unique visit actors plus 12 visual-only background patrons**. Scheduled future customers wander and chat as ordinary shoppers *before* their authored arrival tick, then become eligible to request service; no extra inventory or fake customer transactions are created. All patrons have individual deterministic route schedules.
* `LiveActor.gd` uses 10 manually extracted character textures, 280 2D deformation pose frames, footstep bobs, different hand/prize/reaction poses, facial indication, moving shadow and patience meter. Animations and waypoints are derived from integer simulation ticks.
* Behavior modes: WALK/ARRIVE/LEAVE, BROWSE, CHAT, WATCH, QUEUE, ANTICIPATE, REQUEST, PLAY, CONCENTRATE, FRUSTRATED, SAD/MISS, TRY_AGAIN, WIN, CHEER/CELEBRATE, COLLECT/HOLD_PRIZE, REST.
* Staff reset causes an impatient M02 animation, subsequent reset anticipation and return to focused play. Exact M02 reset = 90 ticks, controlled by the previously tested machine simulation.
* A Barber miss triggers a visible disappointed reaction, nearby spectator surprise, and either departure or another request. No phantom prizes are created.
* Winners can visibly hold only prizes whose ledger owner actually is `customer:<customer_id>`. Nearby visual spectators cheer when a cabinet reports an output or collection event.
* All cosmetic routes use immutable author-defined numeric sequences with no `randf`, `randi`, time-based stochastic RNG or simulation commands.
* CustomerView scene is now a click/request panel. Its former static character portrait is hidden; its moving customer has a dedicated actor in the crowd layer.

## Living machines and exact stock

* Cabinets have genuine `Sprite2D` body, glass, neon, mechanism, and dynamic stock nodes. All four exhibit powered idle motion.
* Each cabinet reads the actual `cassette:<cassette_id>` inventory entries from the **authoritative inventory ledger**. When stock is transferred out on a win, that sprite disappears from the shelf; an `OUTPUT_HELD` prize animates at the chute.
* M01: move, descend, grip, lift, spark. M02: carriage, approach, box reaction, 90-tick reset hop. M03: motorized scissor travel, snip flash. M04: pulsing display and rotating prize.
* Source art still consists of 2D cropped illustrated PNGs, not full multi-angle hand-animated character productions. Motion is more substantial than translating a static portrait, but it is not yet a commercial-quality, hand-drawn animation sheet.

## Fidelity and blocking tests

* `tests/run_living_world.ps1 -GodotExe <path>`: imports then executes four separate headless suites (Gates A-D, E original, E R2 and R3 crowd), recording actual engine logs.
* `tests/capture_living.ps1 -GodotExe <path>`: launches graphical Godot 4.7.2 and captures five real 1280x720 snapshots at different authored simulation states.
* `/mnt/data/claw_living_offline_motion_1280x720.mp4`: an **offline artwork and movement mockup**, **NOT** a Godot runtime capture, and not proof of in-engine parity.
* The supplied user import log covers only Godot editor startup; it ends during 'Reopening scenes...' and does not report game test execution.
* This container lacks the Godot executable and cannot reach its download endpoint. Consequently **Godot engine runtime/import/interaction tests and side-by-side in-engine comparison are pending**. Do not mark 100% runtime acceptance from static tests or the offline preview.

## Acceptance gaps

Hand-authored expressive animation sheets, character path occlusion, machine cabinet depth masking, and true in-engine lighting/glow parity remain subject to actual Godot gameplay review. The lower original arcade backplate was explicitly replaced with an architectural-only reconstructed depth layer using source pixels solely above y=177 (where no crowd is painted). Cabinet bodies were retouched to mask baked foreground customer fragments and character art appears only through separately animated sprites. Edge artifacts, matte quality, and true engine visual parity are **not yet confirmed**. Additional paint-over and Godot iterative captures may still be required.
