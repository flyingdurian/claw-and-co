# R4 living arcade: development handoff

**Source checkpoint, not completed visual-acceptance release.**

## Important: What the owner rejected

The user-supplied eight-second R3 MP4 showed isolated screenshot cutouts translated or warped. Even though R3 had 280 pose PNG files, those files did not supply independently animated feet/legs/arms/expressions. The result is **not** a fluid animated character. Do not report it as such.

## R4 changes

- Tick-indexed authored far/middle/near crowd paths and 3x+ size change through perspective, independently rendered behind and in front of cabinets.
- Stage request cards are now gated on a real waiting-for-service step or M02's actual `RESET_REQUIRED` state, not every character in the scene.
- Four per-SKU stock images now include Stage 1 premium `figure_star` (which R3 lacked); sprite files can be replaced per new SKU without modifying ledger code.
- Four autonomous machine motion timelines read Stage 1 attempts and the exact authoritative manager state. Attempts never change from their authored outcome to satisfy a visual cue.
- `ArticulatedCustomerRig.gd` loads **only complete artist-painted modular parts**; it does not generate vector mannequins. R3 cutout fallback remains while art is missing.
- Explicit rig art test blocks passing acceptance without original sprite rigs.
- Both exact owner reference images are in `docs/references/` for a scene-by-scene comparison; those are visual inspiration/composition references, not literal licensed asset sheets for a shipped game.

## Blocking gaps

1. No complete consistent 2D character rigs are supplied. Actor body frames are still R3's unacceptable screenshot cutouts.
2. Some layer art, especially `art/living/arcade_depth_bg.png`, is a softened composite rather than a clean empty deep arcade corridor. This is **not** final, and baked static people must not survive the final background.
3. No Godot 4.7.2 engine is available in this container; runtime and screenshot parity remain unchecked.
4. Missing sprite rigs must pass both import and motion review, not just file-presence checks.

## Run on Windows

```powershell
.\tests\run_r4_systems.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

The final art-contract suite intentionally returns a nonzero status until genuine layered character images exist.
