# CLAW & CO. — R5.1-M4 R10: Owner-Marked Rail Clipping, Alignment and Straightness

**Reviewed:** 2026-10-29, Vancouver. **Source:** owner's annotated `09_closeup_finger_joints.png` (red problem circles, green target line pairs).  
**Verified final CI:** [Godot mechanical run #41002580106](https://github.com/flyingdurian/claw-and-co/actions/runs/41002580106).  
**Status:** engineering proof passed, **owner visual acceptance pending**. Draft PR #1 remains unmerged.

## Owner-reported failures in R9
1. Left guide mounting "block" clipped through the cabinet front/side frame.
2. Apparent right "block" crowded the trolley/middle rather than the outer right guide.
3. Left fixed rail appeared bent/warped, contrary to believable gantry construction.

## Diagnosis
The central piece bearing the hanging cable is the **moving trolley/winch** and necessarily travels laterally. It cannot be permanently fixed to the right guide. The actual fixed right-side bearing track was too far inward, and the left mounting hardware began very near the glass-frame margin.

Previous fixed rail UV coordinates sheared the original high-fidelity illustration diagonally. The replacement maps one unsheared chrome material strip onto a constant-width straight guide.

## R10 camera-space geometry (unchanged original M01 1024x1536 source coordinates)

| Mount | R9 | R10 |
|---|---|---|
| Left rear | (440,380) | **(440,409)** |
| Left front | (280,422) | **(313,430)** |
| Right rear | (688,380) | **(711,410)** |
| Right front | (512,422) | **(584,431)** |

- Both guide vectors front → rear are `(127,-21)`: parallel, straight and no bending.
- Constant 28-pixel rail full width, rather than old widening/narrowing 30→38px and diagonal UV shear.
- Fixed supporting cradle and mounts use the same underlying geometry. Moving bridge endpoints interpolate both guide axes at the same authored depth. Roller/bogie contacts remain 0.75px-tolerant.
- Original source M01 alpha at both **front** mount centers is transparent, and near left support moved rightwards to clear the visible frame. The far-right mount is behind the original opaque roof/fascia as a rear attachment, which is intentional occlusion.
- Enlarged lateral trolley limit from 548 to 580 in cabinet-local pixels, with conservative ~80px projected claw half-width clearance against approximate front-panel right boundary 665px. Center trolley remains movable, not welded to fixed guides.

## Test evidence
The final R10 run **passed 1,376 / 1,376 mechanical assertions** with no failed assertion, and generated 12 real 1280x720 Godot screenshots plus a 12-second engine movie.

New strict checks cover:
- unsheared rectangular rail UVs, same front/back rail width, mutually parallel straight rail vectors;
- left/front clearance and outward right/front positioning, >260 source-pixel physical guide separation;
- fixed mounting and 12-second deterministic joint states;
- both moving roller-to-guide engagement errors;
- gravity-upright cable/winch and continuous connector;
- full right-trolley command `set_pose(0.92,0.78,0,0)` reaching near x=580 without bounding-center overlap of the right glass;
- 12th Godot screenshot explicitly showing the trolley visiting right-side green-markup vicinity rather than permanently relocating it.

## Visual assessment
R10 genuine Godot capture removes the visibly exposed left-rail protrusion of R9, places right-side guide bearing farther outward, and produces a straighter metal track. The additional right-travel capture demonstrates the moving central winch can approach the right side without becoming a second fixed rail.

**Not yet certified:** entire true sprite alpha bounds at every physical claw pose; exact structural bolt/roof force mechanics; third-prong grasp geometry; dynamic plush stock, reward, maintenance, payout chute; whole Front Aisle composition; owner final acceptance. 1376 assertions is not commercial visual-quality proof.

## Scope
Only `scripts/presentation/r5/M01MechanicalRig.gd`, `scripts/tests/RunR51MechanicalTests.gd`, and the R5.1-M dedicated screenshot/CI scripts changed in this checkpoint. **No original Gate A–D simulation, ledger, customer or transaction implementation changed.**

## Next
Present real R9-vs-R10 close-up, rightward travel capture and video to owner; request owner feedback specifically on clipping, guide straightness, outward rail and moving trolley balance. Once accepted, proceed to prize stock/contact/chute without another generic rail redesign.
