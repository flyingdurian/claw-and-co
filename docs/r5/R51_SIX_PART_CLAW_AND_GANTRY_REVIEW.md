# CLAW & CO. — R5.1 Six-Part Claw Atlas & Gantry Architecture

Reviewed 2026-10-29 from ChatGPT Library exact asset `Six-Part Chrome Claw Disassembly Atlas.png`.
**Status: six-part source extraction verified; kinematic positions provisional; art not runtime accepted.**

## Source facts
- Source atlas 1536×1024 RGBA, 76.97% fully transparent pixels.
- Thresholding source alpha >30 finds **exactly six major connected components** (>33k alpha-strong pixels each), no connected overlap. Faint halos/antialiasing need preserving carefully.
- Sprite islands (x0,y0,x1,y1 in source canvas):
  - motor hub: (188,11,571,529)
  - left upper link: (721,161,989,452)
  - right upper link: (1113,158,1380,448)
  - left curved finger: (144,538,418,995)
  - right curved finger: (691,541,966,996)
  - center/rear visible prong: (1150,559,1303,986)
- Six islands are independent graphic objects; this **does not prove a complete functional rig**. The rear prong lacks a distinct upper linkage, and correct pivot placement is not specified in the source.

## Offline kinematic experiment
Component alpha was isolated, links were attached by provisional pivots, and open / partially closed poses were composed deterministically. Both side arms converge with independent link and distal-finger rotations. The prototype was *offline* pixel composition, **not a Godot capture**. Remaining mechanical limitations: rear finger needs a valid third-prong articulation scheme, finger contact on varying plush shapes has not been tested, image-space projection may reveal joints and overlaps that require retouching, and closed tips may not meet for small prizes. Do not call this "rig passed."

## Required M01 overhead gantry
**Yes, a complete claw machine requires a two-axis overhead bridge and vertical actuator.**
1. Fixed back/side guide rails at the top of the empty chamber (these are permanent stage geometry).
2. Moving overhead bridge/carriage representing X lateral and Y depth travel.
3. Trolley/hoist module with cable drum, sheaves, and visually credible motor.
4. Extendable/retractable cable or polished telescoping shaft for controlled lowering Z and lifting.
5. Claw root connected to the actuator. The claw hub and independent finger rotations occur in this coordinate space.
6. Cabinet mounting brackets, mechanical travel stops, subtle cable tension and highlights.

## Implementation rules
- Compose fixed rails behind the moving trolley. Dynamic prize sprites must sit on inventory-authoritative placement positions in front of the chamber walls.
- Keep the moving claw inside the top and side frame. Depth movement is not the same as vertical movement; preserve a consistent 3/4 projection and occlusion.
- The exact purchase, admission, reservation, attempt, win/loss and restock outcomes continue to come from the accepted Stage 1 simulation; presentation follows the authoritative tick and authored trajectories.
- A machine can show READY attract movement, PLAYING trolley travel/descend/grab/return, OUTPUT_HELD payout, RESET_REQUIRED and restock/maintenance animations only when corresponding state warrants it.
- No fake simulation outcome from presentation-only claw overlap; no cutout wiggle; no unused painted gantry in the background.
- M01 asset production may use an illustrated **multi-part gantry atlas**. Do not pay to regenerate full cabinet or six-part claw again.

## Proposed Godot node hierarchy (not yet integrated)
```text
M01CabinetRoot
  FixedCabinetChamber
  RailGuideSprite
  DynamicGantryRoot
    MovingBridgeSprite
    TrolleySprite
    WinchSprite
    CableOrTelescopingShaft
    ClawRoot
      MotorHubSprite
      LeftUpperPivot
        LeftUpperSprite
        LeftFingerPivot
          LeftFingerSprite
      RightUpperPivot
        RightUpperSprite
        RightFingerPivot
          RightFingerSprite
      RearFingerPivot
        RearFingerSprite
  InventoryDrivenPrizes
  ForegroundChassisAndGlass
```
Adjust render order for trolley/stock depth; this diagram describes responsibilities, not final z-index.

## Next steps
1. Produce gantry atlas (independent rails, bridge, trolley, winch and vertical shaft) as matched perspective artwork. No integrated claw illustration.
2. Rig existing 6-part claw with exact anchors, open/closed/in-motion physics. Resolve the third-prong pivot and visual seam gaps in a Godot isolated proof.
3. Build a full travel envelope with stock items and physically plausible grab-to-chute path, independently animated but deterministic with authored attempt events.
4. Only then capture real Godot 1280x720 screenshot/video, compare to reference and request visual acceptance.
5. Preserve `scripts/core/` and `scripts/managers/`; no premature R5.2 crowd work.

## Reuse vs regenerate
The current atlas has useful independent components. Preserve it unless in-engine pivot and collision tests prove a specific component unusable. If so, request the missing **rear linkage** or a particular segment, not another entire claw.
