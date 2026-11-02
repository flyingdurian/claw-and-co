# CLAW & CO. — ART-02 Group A source-conditioned painting handoff

**Classification:** ACTIONABLE ART REQUEST ONLY — NOT PAINTED ART, NOT ENGINE EVIDENCE, NOT OWNER APPROVAL.  
**Source branch on preparation:** `r4/actor01-art02-reconstruction`; original source checkpoint `301f7b073d5c1f7dc2d21592550d693e9b1846c6`.  
**Approved source:** `art/performers/actor_01/identity_master_candidate.png`.  
**Required source SHA-256:** `dfc1312937313976179bf5cb830f088e79134eb9018fce09a468ed1b943e81e3`.  
**Original format:** 1024 × 1536 RGBA PNG, 2,005,493 bytes; exception approved. Never modify these bytes.  
**Output directory:** `art/performers/actor_01/art02_layers/`.

## Mandatory source conditioning — read before any generation

Load the **actual approved native image pixels** from the private GitHub repository or from an exact-byte copy verified against the digest above, not from a screenshot, an AI interpretation of the filename, a publicity board, or the old 128 × 128 SVG performer. An art tool that cannot ingest the exact source cannot fulfill this job. Do **not** improvise a replacement identity. Every reconstruction call must use this same source image as an image reference, with identical light direction, 3/4 perspective, brush texture, color grading, face geometry, and hair/bow structure.

Use supervised digital painting, multilayer native authoring, or image-assisted editing that delivers **six truly independent RGBA sprite files**; six unrelated new generations or a single exploded sheet do not count. Extract visible pixels only where appropriate, but genuinely repaint occluded anatomy/overlaps in the same finish. A silhouette crop without hidden surfaces fails. Do not create production SVG substitutes. Use tightly cropped full-resolution sprites and store precise neutral top-left offsets in original canvas coordinates; keep native pixel scale with no zoom or resizing. Preserve antialiased premultiplied-edge appearance without dark, white, or transparent-RGB fringe.

## First artist instruction — reusable source-conditioned prefix

> You are reconstructing the approved CLAW & CO. Actor 01 girl from the attached **exact** 1024 × 1536 RGBA master. This is image decomposition and faithful hidden-surface reconstruction, NOT character concept generation. Preserve every recognizable face, brown hair strand, pink bow highlight, painterly material, three-quarter viewing angle, direction of light, and proportions. Output only the requested independent cutout PNG with genuine clean transparent alpha, *including painted portions occluded in the original*. Keep the neutral placement pixel-registered to the master. No labels, panels, added props, extra characters, character redesign, new facial expression, 3D mesh, or vector approximation. If exact-source alignment cannot be maintained, report the mismatch and do not present the file as approved.

### Six independent production exports — exact manifest contract

| Export | Parent joint | z_order | Artist task and hidden-anatomy requirement |
| --- | --- | ---: | --- |
| `head_base.png` | `HeadPivot` | 8 | Recover the *same* head/face skin planes and ear contours with painted full rear skull, scalp and neck that continue beneath the hair/hood. Maintain original silhouette where visible. Do not permanently flatten eyes/bangs onto the skin plane; those belong to other exports. |
| `hair_rear.png` | `HeadPivot` | 3 | Rebuild the brown rear hair cap, all layers behind the face/head, hidden roots underneath the ponytail and occluded side/underside strands. Maintain the original glints and tapered painterly edges. |
| `ponytail.png` | `PonytailPivot` | 2 | Isolate the approved high brown ponytail with all strands and texture; **paint a continuous attached root and hidden underside**, not a cropped shape that detaches when rotated. Keep the exact neutral location and existing hair silhouette. |
| `hair_front.png` | `HeadPivot` | 16 | Recover the original layered brown fringe and side wisps, preserve exact visible contour/shine, repaint hidden strand tips beneath overlying locks and bow. Do not cover or redraw the approved eyes. |
| `pink_bow.png` | `BowPivot` | 17 | Isolate exactly the approved dimensional pink hair bow with folds/highlights and painted rear loop, knot underside and attachment hidden beneath hair. No generic replacement ribbon. |
| `face_neutral.png` | `HeadPivot` | 13 | Register the exact source neutral facial features separately over the head skin: both glossy original eyes/iris highlights, brows, lids, mouth, nose and blush as visible. Preserve spatial relationship and transparency; **do not invent a new expression or repaint an unrelated face**. |

**Exact provisional joint anchors, native source coordinates (x,y, top-left origin):** `HeadPivot=(557,491)`, `PonytailPivot=(355,142)`, `BowPivot=(397,144)`. These are provisional source-manifest positions, not approved final pivot placements. Calibrate using the actual master and individual sprite anatomy; record deviations and reasons.

**Draw/registration order:** sort by actual manifest z_order, not filename, so ponytail (2), hair rear (3), head (8), neutral face (13), front hair (16), bow (17). Confirm that all six independently export and correctly cover the neutral source. Do not change these manifest z-orders to hide bad decomposition; discuss any necessary correction explicitly before changing the contract.

## Registration packet — fill only from actual exports

For **each** exported component, provide:
- `filename`, RGBA pixel dimensions, exact output SHA-256, original-master SHA-256, painting/edit tool and provenance;
- `neutral_bbox=[x0,y0,x1,y1]` in native source coordinates, measured from the actual nontransparent sprite footprint;
- `neutral_position=[x0,y0]` (source-space top-left of the tightly cropped sprite, **not** the parent-joint coordinate);
- `pivot_local=[pivot_source_x-x0,pivot_source_y-y0]`, recalculated using the **calibrated** parent anchor appropriate to that part;
- existing `parent_joint` and `z_order` unchanged unless an explicit reviewed correction is required;
- a short note and a closeup of which formerly hidden area was truly reconstructed.

No invented bbox, transform, hash, or success flag. Do not fill the JSON fields before the pixels exist.

## Group A proof package

1. Six separately downloadable, original RGBA PNGs (not a flattened contact sheet).
2. Full-resolution transparent contact preview for orientation; **clearly label it PREVIEW**.
3. Native-pixel, side-by-side **source head vs. six-layer neutral composite**; the composite must be generated only from the six component files, never covered with original source pixels.
4. Scalp/neck, ponytail-root/underside, fringe/eye and bow-knot seam closeups at 1:1.
5. Head tilt and ponytail swing tests revealing the painted hidden overlaps; indicate test angles and label offline comps **OFFLINE, NOT GODOT**. If a Godot capture is provided, record actual Godot version, project commit, scene, resolution and capture method.
6. A factual discrepancy register for eyes, proportions, silhouettes, material texture, occlusions, alpha fringe, attachments, and misalignments. No confidence score or automated alpha metric can substitute for the owner's visual comparison.

## Strict stop and status semantics

At the latest audited source head (commit `301f7b0`), GitHub Actions `41481245231` verified the original SHA-256 and reported `ART02_MISSING_RECONSTRUCTED_LAYERS=35`. The workflow *intentionally* passes while art is missing. `tools/validate_actor01_art02.py` requires **all 35** layers to be present to create its full neutral composite; until then, report full-art validation as `ART_PENDING`. For a six-layer interim proof, use a separate, explicitly labeled **Group A only** offline comparison and alpha/registration inspection — never claim the full validator passed.

Stop after Group A and obtain the owner's explicit visual review before Groups B–E. Do not touch the master bytes, M01 V3.1, simulation, the articulated rig, PR #7/#8 merges, MOT-01/ENV-01/INT-01/SCALE-01, or future expressions. Current output of this handoff document is **DOCUMENTATION IMPLEMENTED / PAINTED ART NOT EXPORTED / OWNER VISUAL APPROVAL PENDING**.
