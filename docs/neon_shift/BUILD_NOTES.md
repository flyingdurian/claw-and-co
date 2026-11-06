# Neon Shift development build — 2026-11-06

## Result

The game now opens into an interactive arcade shift selector and runs a complete service loop with a floor, prep bench, seven-compartment cart, guest queue, cabinet interaction, result screen and persistent local records. Three shift settings compress arrival and deadline schedules without changing the underlying money, inventory or machine-outcome rules.

The new entry scene is `scenes/neon_shift/NeonShift.tscn`. The original scene remains available at `scenes/Main.tscn`. Main has not been merged or replaced; changes live on `reimagine/neon-shift`.

## Architectural boundary

`ShiftSession.gd` loads the canonical JSON bundle and scales timing fields in a private duplicate. It does not edit source data. Sales, admission, preparation, cart transfers, staff resets, refills, wrapping and trades call the existing command gateway. Item instances retain identity, and the original transaction invariants remain authoritative.

`NeonShift.gd` owns UI state, input routing, scene presentation and saved records. `NeonCabinet.gd` adapts the accepted cabinet presentation to each machine snapshot. `NeonVisitor.gd` maps authoritative visit states to registered artwork. Animation and feedback do not debit money, award prizes or complete services.

`user://neon_shift.cfg` stores best scores, unlocked shift and sound preference. A failed save displays a warning. Help and pause freeze the simulation, and interaction is mapped through canvas stretch at larger window sizes.

## Verified locally

- Original six Godot suites: PASS.
- Frozen-source static preflight: 26/26.
- Neon Shift gameplay: 340/340, covering all three shifts, inventory invariants, exact revenue, final refill delivery, trade ownership, negative preparation, closed-shift commands, zero-action result, UI actions and retry.
- Real mouse/keyboard/drag input: 21/21, including returned-card ownership, direct guest selection, staff-key drag and 1600×900 input mapping.
- Registered PNG hashes and bounded atlas regions audited; approved Actor 01 identity SHA is unchanged.
- Eight actual Godot viewport screenshots, plus a scripted complete playthrough rendered by Godot Movie Maker.

Each shift's successful test route serves all eight visitors, completes 13 service steps, earns 1,430 points / three stars, and books exactly 2,700 minor currency units ($27). The outcome is deterministic for a given command schedule; different schedules may produce different digests.

Headless tests deliberately skip audio playback. Audio is active in graphical execution and the gameplay recording. Rendering evidence uses Godot 4.7.2 Compatibility with Mesa llvmpipe on Linux, not the owner's Windows GPU.

## Build and record

```bash
ci/bin/godot --headless --path . --import --quit
ci/bin/godot --headless --path . --export-release 'Windows Desktop'
ci/bin/godot --headless --path . --export-release Linux
# Install the matching 4.7.2 export templates first.
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a ci/bin/godot --path . --audio-driver Dummy \
  --script res://ci/RecordNeonShift.gd --write-movie neon_shift.avi --fixed-fps 30 --disable-vsync
```

Windows is exported for x86-64; execution on Windows still needs owner testing. The Linux executable is separately smoke-tested. CI retains source audits, regression logs, actual input checks and eight rendered views.

## Deliberate limits

- One authored stage with three pacing variants, not three separate content campaigns.
- Three character designs represent eight named visits. Mika uses five recovered walk drawings; Ren and Yuki use four walk drawings each. Reactions switch illustrated poses. This is not the previously requested complete expressive skeletal animation library.
- M02–M04 share the M01 cabinet art family. M02 hides the rear claw prong; M03's underlying Barber Cut transactions work, but its display still uses the claw assembly. Side-panel M01 branding remains in the shared source artwork.
- The cart retains four supply slots, two prize slots and one bulk cradle. This short stage mainly uses cards and the refill cradle; direct prize delivery and wrapping follow the original simulation.
- Deadlines affect score. Guests do not abandon the queue when their bar empties, matching the existing manager behavior.
- No account services, analytics, monetization, accessibility certification, controller support, localization or store release process is included.
- The original R4 articulated-art acceptance gate remains blocked and is not relabeled as passed by this build.

## Next production priorities

1. Playtest timing and clarity with the owner on the actual Windows device.
2. Replace shared M03/M02 mechanisms with dedicated registered production art.
3. Extend characters into continuous acting sequences, preserve identity and foot registration, then test crowded aisles.
4. Author distinct stages and richer cart logistics using the same transaction layer.
