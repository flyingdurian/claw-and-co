# Claw & Co. — R5.1 Visual Foundation (isolated checkpoint)
Status: IN DEVELOPMENT — NO VISUAL ACCEPTANCE CLAIM.

## Verified CI-0 baseline
- Godot 4.7.2 runtime import and 6 existing test suites passed at commit `0786722`.
- Genuine 1280×720 screenshots and a 10-second engine recording were uploaded to GitHub Actions run 40827608338.
- Separate R4 modular character art acceptance is BLOCKED (0/10 rigs); **this is not a CI success claim**.
- Baseline render has workshop equipment leaking onto the arcade background; baked prizes and patrons; mismatched, duplicated live sprites; and badly overlapping controls.
- Software OpenGL Compatibility rendering is useful for composition QA; do not equate it with native Windows Forward+ fidelity.

## R5.1 scope ONLY
Reconstruct the empty illustrated arcade architecture and ONE M01 3-prong cabinet. Build independent production textures, avoid chopping artwork out of the approved composite, and preserve the gameplay simulation. Customer rigs, other machines, workshop, and cart redesign remain outside this phase.

The M01 must be a coherent original physical cabinet, not a bitmap cut-out pretending to be interactive. Required independently authored layers:
1. `arcade_environment.png`: camera-matched original room plate, NO baked machines, people, HUD, cart or request bubbles.
2. `m01_body.png`: opaque cabinet chassis with a transparent display cavity and no baked prizes/customers.
3. `m01_interior.png`: unobstructed illuminated play chamber.
4. `m01_mechanism.png`: separate carriage/claw (future animation pivot).
5. `m01_glass.png`: isolated alpha reflection and refraction, not a solid rectangle over prizes.
6. `m01_marquee.png`: cohesive premium sign, with no unrelated UI.
7. Optional light mask and decorative layers as appropriate.

The isolated review scene must keep a real 1280×720 Godot camera framing. All layer origins and anchor pivots must be documented and readable at gameplay resolution. No repeated source slices, no ColorRect/Polygon2D placeholder panels, no painted inventory or patrons, no overlaid old cabinets, no fallback to the rejected R4 background.

## Objective acceptance evidence
A separate engine capture shall include: full 1280×720 stage, M01 full-body crop, glass/interior close-up, and an alternate cabinet state (empty/refilled). Use a genuine Godot screenshot, not a Python composite, for acceptance. Produce a side-by-side with the two approved benchmarks and list remaining differences. Visual approval requires an owner review, not an automated green check.

## Hard protections
- No edits to `scripts/core/` or `scripts/managers/` during R5.1.
- No edits to `scenes/Main.tscn` until the isolated visual proof is approved.
- No external asset source may silently overwrite the two original approved benchmark images.
- Missing asset files are a **BLOCKER**, not a placeholder to be substituted.
- QA artifacts must indicate the exact Git SHA, renderer and capture method.

## Current next work
Original layered M01/environment illustration must be produced and integrated into a clean isolated scene; run actual capture and repeat until visual review is satisfactory. Do not mark R5.1 complete based on file counts or static checks.
