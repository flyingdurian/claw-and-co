# CLAW & CO. — R5.1 M01 Gantry Redesign — Astra Step 1 Review

**Date:** 2026-10-29 Vancouver. **Decision:** preserve the new architecture/art direction, reject the flattened file for production registration. Existing PR remains draft.

## Actual source inspected
- `Precision overhead claw gantry.png` (ChatGPT Library): **1024×1536 RGBA**, real alpha; substantial visible hardware bounding box at threshold alpha >10: **(53,144)..(978,640)**.
- `M01 Raspberry Claw Cabinet Body.png` (authoritative): **1024×1536 RGBA**, transparent chamber behind a strongly illustrated roof fascia.

## Observations from diagnostic pixel composites
- Original unchanged coordinate registration: most of the heavy assembly overlaps/disappears behind opaque M01 roof/marquee; Astra's failure report is justified.
- As an optical-fit experiment only, resizing the nontransparent art to 72%, 60%, and 54% and compositing beneath the unmodified body shows a plausible overall mounting scale in the **~55–65% band** for this exact crop. This is NOT a production fit, dynamic clearance or accepted rig.
- The new architecture is substantially better than the legacy R5.1-M4 chrome fragment approach: believable industrial beam thickness, bolted roof mount plates, transverse bridge/trolley design, cable routing.
- The source bakes **a long cable and connector into the same flattened image**. This is incompatible with a truly retracted/resting hoist. Re-scaling the entire image cannot solve both roof fit and retracted lower-prong clearance.
- The central trolley's reduction of ~30–40% relative to the Gemini architecture benchmark has **not been independently verified**; there is insufficient same-scale reference registration to claim it.
- Three-prong claw was intentionally not present in this image. Therefore full tip clearance cannot be measured from Step 1.

## Next art production decision
**DO NOT regenerate another exact registered full composite.** Prior Astra registration attempts repeatedly failed, while exact geometry can be authored in Godot. Proceed to a **Step 2 independently isolated component atlas** using the NEW Step 1 source as the visual/material authority. This does not approve its dimensions or exact mounting.

The required independent sprites:
1. front-left/back-left and front-right/back-right cabinet-bolted roof brackets, or a pair of reusable fixed mounting plates;
2. two fixed front/back roof guide rail sections with straight bearing surfaces and reusable end stops;
3. moving transverse cross-bridge beam with attachment bogies contacting both fixed guides;
4. truly compact X-axis trolley/carriage (visually **30–40% smaller** than bulky Gemini example, relative to beam width; require genuinely detached part);
5. independent winch/drum or hoist motor;
6. short flexible cable chain (only feeding trolley, can be segmented);
7. thin suspension cable on its own with variable-length segment or a short repeatable cable texture, not a permanently long cable fused with motor/connector;
8. isolated suspension connector to existing approved six-part claw hub.
Do not generate a duplicate fully assembled gantry or replace M01 cabinet.

## Godot assembly acceptance
- Exact fixed roof mounting positions derived from authoritative cabinet geometry, not source atlas frame.
- Parallel straight fixed depth rails and rigid moving transverse bridge, bridge-end rollers maintain visible rail contact at near/far positions.
- Cable pays out/retracts dynamically; at top limit claw tips hang just below carriage and do not intersect roof or glass. At bottom limit finger tips meet inventory-dependent prize top without crossing support floor.
- Check minimum/maximum claw opening, all four extreme XY positions, maximum stock pile height, empty inventory and output chute sweep.
- Position via a camera-calibrated chamber coordinate system and world-upright Z suspension; no full-asset squash/warp or cloned scenery.
- Review actual Godot 1280×720 frames/video, including fully retracted claw and fully descended claw with separate stock sprites.
- The prior M4 mechanical prototype is preserved as fallback until new rig passes; no edits to core Stage 1 authoritative simulation/ledger/managers.
