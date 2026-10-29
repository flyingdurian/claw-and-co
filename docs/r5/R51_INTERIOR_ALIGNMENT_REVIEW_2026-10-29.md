# Claw & Co. R5.1 — M01 empty interior alignment review

Date: 2026-10-29. Status: **Provisional recovery candidate; NOT production / Godot accepted.**

## Source assets inspected from user's ChatGPT Library
- `M01 Raspberry Claw Cabinet Body.png` — source-authoritative cabinet; 1024x1536 RGBA; 37.8% pixels fully transparent.
- `Empty arcade prize chamber interior.png` — Astra interior attempt; 1024x1536 RGBA; 67.0% pixels fully transparent.
- Both have authentic transparent alpha and matching overall image size. Matching canvas is NOT sufficient to establish pixel registration.

## Verified failure
At native 1:1 composition with the interior underneath the untouched cabinet body, the interior prize-support floor falls below the transparent display opening. It is hidden under the opaque control-panel / chassis. Source interior upper rails also visibly duplicate the already-painted shell's top trim. **Astra correctly rejected the original as a registered production layer.**

## Recovery experiment
A deterministic, no-regeneration PIL vertical correction was applied to the interior only:

- `x' = x`
- `y' = 0.82 * y - 5` for interior-source coordinates, using bicubic interpolation, transparent fill.
- Canvas stays 1024x1536 RGBA.
- Original M01 body remains pixel-for-pixel unchanged.
- Result is composited UNDER the cabinet body and reveals the formerly hidden floor inside the window.

This improves visible fit in a diagnostic 1:1 composite, but the floor art is vertically compressed and must still be reviewed at gameplay scale and with prize sprites. Geometry and layer seams are **not** automatically production accepted by this mathematical warp.

## Required validation before acceptance
1. Compare original vs registered layer using actual transparent PNG and dark/light backgrounds.
2. Ensure no duplicated wall rails, shelf surfaces or seams at every chamber edge.
3. Place variable-sized plush sprite instances inside the chamber and prove they rest on the floor without clipping.
4. Place actual 3-prong claw at a safe Y range: verify no body/top trim collision or impossible travel.
5. Test output chute / collectible prize travel independently. A visible bottom floor does not establish functioning payout.
6. Run isolated Godot proof with 1280x720 screenshot; review visual alignment, scaling, cabinet contrast and gameplay clearance.
7. Owner decides whether salvage is accepted. If it fails, regenerate only the failing component or use paint/inpainting, not the full machine.

## Cost discipline
Do not spend Astra allowance on another complete interior unless registration cannot be solved losslessly/acceptably. Reserve generation for a separate, animated gantry/claw asset and later true actor animation layers. The correction is a **candidate**, not an override of the artist's failure assessment.

## Render order
Interior back/walls -> inventory-driven physical prize instances -> gantry mechanism -> body/frame -> front lip / glass reflections and effects (split front-floor lip into foreground occlusion if needed). This is a proposed render-architecture test, not gameplay implementation.

## Existing source protections
Do not change frozen `scripts/core/`, `scripts/managers/`, or `scenes/Main.tscn` while R5.1 is under artistic review.
