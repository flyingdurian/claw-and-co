# CLAW & CO. — ART-02 Faithful Repaint and Hidden-Surface Reconstruction Requests

**Status:** production art requests; NOT evidence of existing artwork. Approved source is `art/performers/actor_01/identity_master_candidate.png`, SHA-256 `dfc1312937313976179bf5cb830f088e79134eb9018fce09a468ed1b943e81e3`. This source must accompany *every* art-generation call. The rejected 128px SVG mascot must not be used as a style source.

## ART-02-A. Head and hair (first approval group)

Create independent high-resolution lossless transparent painted PNG layers for the **same original girl** from the attached exact source. Maintain her 3/4 face, precise head shape, two distinct glossy pink-brown eyes, lip shape, blush, eyebrows, brown layered fringe, rear hair cap, full high ponytail, and three-dimensional pink hair bow. No montage, no labels, no panels, no dashboard, no new character design.

Export separately: `head_base.png` (with hidden back skull and neck genuinely painted), `hair_rear.png` (underhair completed), `ponytail.png` (fully continuous hidden root and underside), `hair_front.png` (bangs and wisps with hidden overlaps), `pink_bow.png` (underside/tie painted) and `face_neutral.png` (precisely registered underlying face details). Generate these as **editable separate components**, not merely rectangular cuts of an existing flattened illustration. Each must be accompanied by the original-source-coordinate pivot, canvas location and full-resolution neutral-assembly proof. Require independent, coherent overlap coverage when head tilts and ponytail swings. Do not generate limbs or animations in this batch.

**Gate A:** visually inspect full-resolution reconstructed neutral head against the exact master. Reject any eye, nose, mouth, hair-part, bow or texture drift; do not proceed if seams or hidden scalp gaps remain.

## ART-02-B. Hoodie, skirt, backpack and rabbit accessories (after Group A acceptance)

Faithfully reconstruct the same pink rabbit-emblem hoodie including its rabbit print, realistic fabric folds, cuff edges, drawstrings, pocket, hood interior, pleated dark skirt, pink bag, stitching and buckles, backpack straps, and rabbit charm. Each separately painted layer must continue into its hidden shoulder, neck and waist regions under occluding art. Keep source material, lighting, perspective and real cloth weight. Required exports: `hood_back.png`, `hoodie_torso.png`, `hood_drawstrings.png`, `skirt.png`, `backpack.png`, `backpack_strap_l.png`, `backpack_strap_r.png`, `rabbit_charm.png`. Provide a source-coordinate exact neutral composite and sleeve overlap tests before expanding.

## ART-02-C. Arms and fully painted elbow/hand overlaps

Preserve exactly the approved sleeves, fabric highlights and hands. Reconstruct both upper-arm sleeve caps hidden under the torso, continuous folded cloth at elbow bend, wrist cuffs extending underneath painted hand silhouettes, and anatomical hands from the approved angle. Required exports: paired `upper_arm_l/r.png`, `forearm_l/r.png`, `hand_l/r.png`. For each, include a normal alignment pose plus elbow bends at 0°, 50°, 100°, 140° and one reaching pose. Disallow a circular joint bead, hard discontinuity, exposed blank gap, flat fill patch or inconsistent skin/cloth texture.

## ART-02-D. Thighs, knee joints, striped socks and sneakers

Retain the exact approved leg lengths, knee contours, white-pink striped sock pattern, and glossy pink bunny sneakers with individual laces/soles. Hidden thighs beneath the skirt, shins behind socks and ankle/shoe collars must be fully painted at identical color/lighting. Required exports: `thigh_l/r.png`, `shin_l/r.png`, `sock_l/r.png`, `sneaker_l/r.png`. Compare neutral plus knee bends at 0°, 30°, 60°, 90° and extreme stride. No missing under-skirt geometry or disjointed shoe contact.

## ART-02-E. Expression continuity (only after neutral head)

Create `face_focus.png`, `face_joy.png`, `face_sad.png`, `face_angry.png`, `face_anticipation.png`, `face_speaking.png`, `face_determined.png` as expressive **registered features on the same face geometry**. Do not regenerate seven unrelated full heads; keep sclera and iris shape, glints, blush, facial plane and mouth alignment consistent.

## Required registration package for each group

- Original, separate transparent RGBA PNGs at native painterly detail, no full-body downsampling.
- `neutral_bbox`, `neutral_position`, `pivot_local`, `parent_joint`, `z_order` for each exported sprite, in the native 1024×1536 reference coordinate system.
- The source's original SHA-256 in the export manifest.
- Documentation of painted areas that were hidden in the original, with before/after 1:1 joint crops.
- A neutral assembly from the **individual** layers, verified against the authoritative full body (not a pasted copy of the original over the result).
- No move to MOT-01, no Actors 02–10, and no owner ART-02 acceptance claim from automated tests alone.

**Critical:** An image-generation tool's one-sheet illustration, even an appealing labeled exploded diagram, is *not* a registered layer package. Reject any fake PASS text, code status, GitHub metadata or Godot screenshots inside generated concept images. ART-02 acceptance requires actual component PNG files and real Godot exports.
