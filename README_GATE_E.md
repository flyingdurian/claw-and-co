# CLAW & CO. — Gate E Original Illustrated Presentation

Godot 4.7.2 · pure GDScript · 1280 × 720 · deterministic 60Hz simulation.

**Open `project.godot` and run `scenes/Main.tscn`.** The original Gates A–D code under `scripts/core/` and `scripts/managers/` is unchanged. This package adds scenes, original PNG illustrations, presentation adapters and Gate E smoke tests. No avatar, third-person camera, placeholder block sprites or revised transaction code were introduced.

See [Gate E delivery/verification report](docs/GATE_E_DELIVERY.md) for the architecture, controls, known limitations, testing status and PowerShell commands. The actual Godot 4.7.2 import and UI smoke test remain **unverified** in this authoring environment; run `tests/run_gate_e.ps1` locally.

The user-supplied A–D acceptance (514 assertions, reproducible Stage 1 SHA-256) remains the authoritative prior checkpoint. Gate E does not claim that a Python dependency check substitutes for a Godot scene run.
