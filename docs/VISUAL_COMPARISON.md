# Gate E Visual Comparison — Evidence Boundary

## Benchmark and current result

- Reference: owner-supplied composite, left-hand arcade panel, proportionally remapped to 1280×720.
- Current comparison image: `previews/gate_e_refactor_offline_side_by_side.png`.
- Current output is a **software-composited offline art mock**, not a frame captured from the running Godot renderer.
- Above cart, source art exactly matches by construction (**RGB MAE 0.00/255**) because the same source pixels were sliced. This is *art provenance*, not proof of Godot scene parity.
- Within cart region, new discrete slot texture intentionally diverges (**RGB MAE 59.73/255**). The difference is mandated by the 11-slot tray redesign.

## Visual elements addressed

1. Original luminous photo-illustrated arcade and shop backgrounds used, not flat stand-in panels.
2. Four separate physical cabinet artwork sets: body, prize pile, mechanism, glass reflection, marquee.
3. Moving scene-graph sprites keyed by simulation ticks and per-cabinet PointLight2D.
4. WorldEnvironment glow configured; actual screen energy/rendering not measured.
5. New glossy 11-slot physical tray and Staff Key icon, one inventory instance per slot.

## Remaining to reach confirmed in-engine parity

- Capture real rendered 1280×720 screenshot after successful Godot 4.7.2 import.
- Inspect layering, background ghosting around moving cropped claws, reflections and overlapping customer cutouts.
- Verify font positioning/HUD overlays, color-space and bloom intensity in engine.
- Run `python tests/compare_visuals.py` on captured PNG to produce real engine side-by-side and structural similarity metrics.
- Improve isolated artwork masks where the flattened reference contains shadows/parts baked into the background.

**Result: In-engine parity is NOT YET CONFIRMED.** Source artwork is aligned; user-visible animation, asset imports, screenshot and 100% passing interaction tests require a running Godot environment.
