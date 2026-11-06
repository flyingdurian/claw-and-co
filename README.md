# Claw & Co. — Neon Shift

A first-person arcade service game built in **Godot 4.7.2**. Run a neon prize floor, charge cards, help guests, reset a stuck claw, replenish prizes, wrap gifts and manage trade-ups through one persistent service cart.

This branch introduces a complete playable presentation around the existing authoritative Stage 1 simulation. It uses the original cabinet and gantry, the approved Actor 01 identity, recovered walking artwork, and additional illustrated equipment and guest poses.

## Play

Open `project.godot` in Godot **4.7.2** and press **F6** on `scenes/neon_shift/NeonShift.tscn`, or **F5** to launch the main game. Packaged Windows and Linux releases need no editor; keep the executable and its `.pck` together.

1. Open the Prep Bench and charge a card.
2. Load it onto the cart, select a guest, and sell the card.
3. Start their game; serve other requests while the machine plays.
4. Help Lucky UFO with the staff key. Prepare a cassette and restock Mochi Club.
5. Complete gift wrapping and prize trades at the bench.

Earn two stars to unlock the next shift. Opening Shift lasts 120 seconds, Evening Rush 101 seconds, and Last Train 84 seconds. These are three pacing variants of the existing authored stage, with the same eight visits and deterministic machine outcomes. Scores and sound preference save locally.

| Control | Action |
|---|---|
| Mouse | Select guests, stations and cabinets |
| Drag | Charger to cart; card to guest; cassette to Mochi Club; item back to bench |
| Tab | Floor / Prep Bench |
| E or Enter | Serve selected guest |
| 1–4 | Select cabinet |
| Space or Escape | Pause / resume |
| H | Guide; pauses the clock |
| M | Toggle sound |
| F11 | Fullscreen / window |

## Implementation and verification

- Pure GDScript, fixed 60 Hz simulation, 1280×720 scalable canvas.
- Compatibility renderer is the default for this 2D presentation.
- Every transaction passes through the existing `SimulationRoot.command()` gateway.
- Existing core/managers, canonical Stage 1 data and accepted gantry sources are unchanged.
- The previous scene is retained at `scenes/Main.tscn`.
- [Build notes, test commands and known limits](docs/neon_shift/BUILD_NOTES.md)
- [Artwork provenance and production briefs](docs/neon_shift/ARTWORK.md)
- [Original foundation documentation](docs/FOUNDATION_README.md)

```bash
python3 ci/fetch_godot.py
bash ci/run_suites.sh
bash ci/run_neon_shift.sh  # requires Xvfb and Pillow on Linux
```

This is a playable development build for review. It does not claim final animation or release certification. M02–M04 currently share the illustrated cabinet family, and M03 still needs its dedicated Barber Cut visual mechanism. Character motion uses a limited frame library and is not yet a complete bespoke animation set.
