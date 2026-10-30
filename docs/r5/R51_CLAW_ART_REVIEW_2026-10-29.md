# CLAW & CO — R5.1 M01 Three-Prong Claw Asset Review

Review date: 2026-10-29. **Appearance reference: ACCEPTED FOR DEVELOPMENT. Animated rig: NOT ACCEPTED.**

## Inspected exact Library asset
`Premium open three-prong chrome claw.png`, original 1024 × 1536 RGBA, authentic alpha background (81.35% zero-alpha pixels). Foreground content around x=89..934, y=90..1042 (alpha>10). Single flattened front-facing claw assembly with central chrome motor hub, left and right curved fingers and a visible foreshortened center/rear finger. Rich chrome reflections match the raspberry-pink M01 visual identity. Soft shadow/glow is partially baked into translucent pixels and needs edge cleanup before runtime use.

## Concrete cabinet registration experiment (NOT a Godot screenshot)
- Parent canvas: original `M01 Raspberry Claw Cabinet Body.png` 1024×1536.
- Provisional corrected inner chamber: recovered candidate in previous R5.1 review, **not owner-approved**.
- For diagnostic only, resize entire source claw uniformly to **34%**; position full scaled source canvas at **(327,313)** in parent-cabinet canvas.
- Computed nontrivial source-alpha object bbox maps approximately to cabinet coordinates x=357..645, y=344..667.
- Layer order in preview: chamber -> claw -> original body/front frame.
- The scaled claw is visibly plausible in chamber at open/rest. It is NOT certified for physical clearance at all heights, stock depths, or gameplay resolution.

## Engineering diagnostic: mechanical decomposition
Programmatic separation into hub, left finger, right finger and foreshortened rear finger was attempted using deterministic alpha masks.
- Reassembling unchanged pieces reproduced the *source alpha* in the neutral resting pose.
- Applying finger rotations exposed missing hinge material, orphan metallic slivers and inconsistent overlap.
- **Result: automatic mask extraction is unsuitable as the final production animation rig.** Keep only as feasibility evidence.
- A genuinely articulated assembly needs original clean component art or carefully retouched seam reconstruction, not a pretense that a flattened cut-out is fully animatable.

## Approved next asset request
Generate one clean **exploded mechanical component atlas** from the exact supplied claw image. Components must be independently isolated (transparent background) and maintain one perspective/light direction:
1. central chrome motor hub/casing with visible pivot mounts;
2. left proximal link (upper arm);
3. left curved gripping finger (distal segment);
4. right proximal link;
5. right curved gripping finger;
6. foreshortened rear/center prong with hinge and contact tip;
7. separate suspension shaft / head connection (if physically necessary).
A component atlas is NOT a pre-registered cabinet canvas. Do not demand AI output exact cabinet coordinates; compute alignment and pivots in Godot with a reference overlay after generating the atlas. No labels, captions, fake background, diffuse shadows, included cabinet/chamber or extra poses. The mechanism must not make parts appear to intersect when assembled in 3/4 cabinet view.

## Production acceptance gates
1. Transparent alpha and component separation verified pixel-wise.
2. No disconnected decorative fragments or baked dark translucent rectangle/halo.
3. Component sizes/pivot locations match at assembly; no visible seam in open/closed states.
4. Closed pose must truly bring all three contact tips inward, not just rotate full composite/cutout.
5. Hub and prong travel occurs within chamber, in front of variable prize inventory and behind the glass/frame. Add mechanical shaft/gantry motion from authoritative attempt state, not RNG.
6. Godot 4.7.2 isolated proof: neutral open, closed grasp, descending, lifting, translating toward chute; retain original static claw as appearance comparison only.
7. Owner sees genuine 1280x720 engine screenshots/video before visual acceptance.

## Scope protection
No edits to `scripts/core/`, `scripts/managers/` or `scenes/Main.tscn` for this art review. Preserve prior base simulation and all approved design locks.
