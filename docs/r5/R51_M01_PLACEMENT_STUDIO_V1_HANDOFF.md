# CLAW & CO. — M01 Gantry Placement Studio v1 (owner calibration)

Date: 2026-10-29 (Vancouver). Status: **Owner-facing offline visual calibration tool created; owner alignment pending**.

## Decision
Following owner's rejection of the improperly assembled 12-part Astra gantry, use an owner-friendly visual placement tool **rather than another guessed manual alignment pass**. There is no requirement for Godot, Python, subscriptions, or image-generation allowances to position parts.

## Delivered artifact (in project conversation, NOT yet committed as binary into Git)
`ClawCo_M01_Gantry_Placement_Studio_v1.zip` (self-contained browser editor) with:
- `M01_Gantry_Placement_Studio.html` — **single offline HTML file containing the real approved cabinet image, recovered chamber, all 12 separated industrial gantry PNG islands and all 6 separated claw sprites** as embedded original image data.
- `START_HERE.txt`, `CALIBRATION_FORMAT.md`, `CALIBRATION_SCHEMA.json`, `SOURCE_ATLAS_MANIFEST.json`.

## Owner workflow
1. Extract ZIP, double-click single HTML file in Chrome/Edge.
2. Step 1: visual left and right roof assembly placement.
3. Step 2: moving bridge and trolley.
4. Step 3: rest/retraction height and lower position.
5. Step 4: front/back/left/right preview and one 12-second demo.
6. Click **Save my layout** to export `ClawCo_M01_Working_Gantry_Calibration.json`. Attach JSON in project chat for integration.

## Controls
- Direct click-drag, individual part toggles only in optional Advanced mode, 1/10-pixel nudge, X/Y fields, scale/rotation sliders, zoom/pan, undo/redo, reset.
- Show/hide chamber and original foreground cabinet to inspect occluded attachments.
- Source-coordinate transform saves are independent of desktop display size and zoom.
- Screenshot export, JSON import/roundtrip.
- Dynamic suspended cable drawn between hoist and connector and six-part claw pivots previewed, **not physical validation**.

## Engineering contract
JSON schema `claw-co.m01-calibration/v1`, with per-part x/y/s/a in original M01 source pixels (1024×1536); `claw` root; `travel_limits`; `preview_travel`.
After owner sends JSON, map the accepted transforms onto the isolated M01 Godot mechanical rig, **do not silently change core Stage 1 simulation**. Ensure bridge-to-fixed-rail contact, winch/cable/connector continuity, true graphical silhouette clearance at all axes, retraction pose, and third-prong motion in **real Godot 4.7.2 captures**. Offline browser preview alone is never release acceptance.
Former R10/new prototype remains a fallback; draft PR #1 stays unmerged.

## Verification
- Source HTML/JS syntax checked with Node.js and an isolated JavaScript/DOM smoke harness executed selection, drag/nudge, preview-pose and undo without an exception.
- All 20 source images embedded and cross-checked against the exact Library-derived source files.
- Container Chromium navigation to file:// and localhost was blocked by environment administration. Therefore full graphical-browser smoke-test and cross-browser UI acceptance **have not** been claimed. Owner to open the single file in ordinary Chrome/Edge; fix any genuine usability issue promptly.
- Tool is intentionally not a game editor and does not prove mechanical physics.
