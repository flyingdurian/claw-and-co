# CLAW & CO. — M01 Connected Gantry Studio V2

**Date:** 2026-10-30 (Vancouver). **Owner review: pending.**

## Reason V1 was rejected
The owner screenshot showed 12 disconnected flat sprite components, difficulty assembling them into the Astra precision gantry design, cabinet-wide foreground occlusion hiding components behind the central post, and erroneous Back↔Front motion applying to pieces that ought to be stationary or on different axes.

Code audit of V1 confirmed:
- source parts held independent arbitrary x/y/s/a transforms and freeform group selection;
- dynamicKeys/depth offsets were applied to bridge, moving trolley, winch, chain, connector, cable independently;
- a complete cabinet PNG was rendered **after** the mechanics, hiding them behind all opaque body/frame regions.

## Revised standalone owner-facing artifact
Delivered a new, self-contained HTML browser tool in the project chat:
`ClawCo_M01_Connected_Gantry_Studio_V2.zip`.

Contents: embedded 20 actual reference sprites (12 original gantry, 6 claw, cabinet, interior), 3-step guided editor, assembled machine geometry, axis previews, position/size controls, save/load v2 calibration, documentation and 2 browser screenshots.

### Constrained kinematics
1. **Two fixed depth guides** remain roof-attached at all poses.
2. **Moving cross-bridge** is located by interpolation between both guides using Y; no individual rails travel on Y.
3. **Trolley** rides along the moving cross-bridge using X; X does not relocate the bridge.
4. **Winch/cable/connector/six-part claw** follow trolley; variable Z lowers only cable/connector/claw.
5. Composition: cabinet background + operating gantry + selective roof-fascia occlusion; entire cabinet is NOT drawn as the last opaque layer. Optional ghosted frame assists assembly inspection.
6. Owner cannot casually break the mechanism by dragging 12 independent pieces. Position the entire roof assembly, tune rail spacing/trolley size/rest gap/max descent, inspect independently controlled XY/Z motion, and export owner-calibrated source-coordinate JSON.

### Proof performed, limitations
- Chromium graphical browser test via Playwright `set_content`: all **20/20** embedded source assets loaded, 0 page script errors.
- Strict independent-axis checks: X changes trolley but not bridge or rails; Y changes bridge+trolley but not fixed rail anchors; Z changes only cable/claw. All passed.
- JSON v2 save, restore from file and derived rail geometry roundtrip passed.
- UI screenshots and ZIP archive integrity checked locally.
- Sandbox blocked file:// navigation administratively, therefore standalone double-click experience in actual end-user Windows Chrome/Edge remains owner-usability pending.
- **Not a validated Godot rig, 3D depth solver, actual bearing contact, clearance, or gameplay integration.** Flat illustrated source components cannot be made into exact 3D machinery solely by scripting 2D position offsets.
- V1 JSON loose-sprite schema is deliberately rejected; do not silently migrate invalid mechanical placements.

## Expected owner handoff
Owner opens HTML and adjusts whole mechanism, using X/Y/Z previews. Download `ClawCo_M01_Connected_Gantry_Calibration_V2.json`, send it to ChatGPT. Then adapt the isolated production Godot scene using the constrained hierarchy and calibrations; inspect true 1280x720 in-engine pictures/video before owner acceptance.

Original accepted Gate A–D deterministic simulation and transactional inventory remain frozen. Draft PR #1 remains unmerged pending physical/visual verification.
