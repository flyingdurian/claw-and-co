# R5.1 — M01 chamber alignment failure and recovery

**Status: REJECT Astra chamber image; do not integrate as production asset.**

## Actual source evidence (2026-10-29)

- `M01 Raspberry Claw Cabinet Body.png`: 1024×1536 RGBA; original transparent apertures front x268–653 y364–894, right x730–937 y374–896, small side x121–200 y368–435.
- `Empty arcade prize chamber interior.png`: 1024×1536 RGBA; substantive interior painting x~265–958 y344–1118.
- Same PNG dimensions and alpha are **not** evidence of correct registration. The generated floor extends at least 222 pixels below the chamber opening; body/control panel occludes it in an unchanged-coordinate composite. Additional generated edge rails do not perfectly match the original.
- Vertical transform experiments make the floor visible but squash/distort decals and geometry. **Do not use compressed variants as final artwork.**
- The failed image can be retained only as a style and construction reference.

## Corrected asset method

Stop asking an image generator for a separately positioned transparent chamber and hoping it matches. Instead:
1. Supply **the unmodified original cabinet body** as the immutable 1024×1536 editing template.
2. Supply a **pixel-accurate mask of the three actual transparent apertures**, derived from the original source alpha. White means draw new interior pixels; black means untouched external cabinet/background.
3. Ask Astra to **edit only the apertures within the full-canvas original image**, returning the entire unchanged-size cabinet composite, NOT a free-floating new chamber.
4. Floor terminates behind the existing lower display rim (approximately y894–896), above the control-panel top.
5. Preserve original marquee, walls, outside rails, perspective, joystick, NFC reader and prize chute exactly. Do not bake prizes, movable gantry, claw or glass specular overlay.
6. Once a full-canvas pixel-registered edit passes visual inspection, extract masked pixels into an RGBA interior layer in code. This guarantees transparent pixels outside the actual chamber without depending on generation alpha. It does **not** guarantee internal image perspective; inspect in a side-by-side/overlay with original body at 0,0.
7. Run isolated Godot visual proof only when the artwork passes the composite and mechanism clearance review.

### Important limits

The image generator may alter the original cabinet even when told not to. Programmatic extraction keeps only pixels inside the immutable original apertures, so exterior drift is not imported. Interior geometry can still be wrong; do not declare production success without the real overlay and source review.

The mask/guide and extraction helper were created from the original image in the review session and shared as a separate artifact. Production versions should be placed under `art/r5/` after verification.

## Protected systems

Do not alter authoritative `scripts/core/` or `scripts/managers/` source for this art correction. R5.1 remains owner-unaccepted.
