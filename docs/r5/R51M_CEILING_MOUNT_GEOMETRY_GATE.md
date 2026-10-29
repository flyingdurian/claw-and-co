# CLAW & CO. — R5.1-M4 Ceiling Mount Geometry Gate

**Status:** next implementation target; **NOT implemented / NOT visually accepted**.

**Basis:** user's review of genuine R5.1-M capture (ceiling rails look unsupported), review of current `scripts/presentation/r5/M01MechanicalRig.gd` at commit `c835b9a`. Accepted Stage 1 simulation remains frozen.

## Observed root cause in current rig

- Fixed rail sprites are `M01MechanicalRig` root children, good for transform immobility, but **they are not connected to actual cabinet roof attachment points**. Their positions/scales are independent constants at cabinet coordinates `(346,405)`, `(563,405)`, scale `(0.098,0.075)` and rotation `-12°`.
- The bridge depth track is a separate short screen-space interpolation: `bridge_y = lerp(409,439,depth)` with `bridge_x = 459 + 7*depth`; **not derived from the rail geometry**.
- The project has no mounting anchor model or wheel/rail mating constraint. Fixed rails can remain numerically motionless but look as if the bridge is hovering or moving independently.
- Source asset beams were illustrated almost horizontally. Blindly rotating/scaling them cannot certify a three-quarter depth-axis projection.

## Minimum physically credible overhead layout

Use one shared cabinet-local coordinate frame and **four surveyed roof mounts** (rear-left, rear-right, front-left, front-right) based on the *actual* M01 source artwork, not guessed numbers. Survey and document positions in original 1024×1536 PNG coordinates.

- **Cabinet structure:** opaque ceiling lip and roof support panels are stationary, draw over attachment brackets where appropriate.
- **Left fixed rail:** connects the rear-left bracket to front-left bracket.
- **Right fixed rail:** connects rear-right bracket to front-right bracket.
- **Depth carriage (moving bridge):** spans the two rails at *the same normalized depth parameter*. Its roller bogies/wheels intersect and mechanically engage each guide at the two computed bridge endpoints.
- **X trolley:** runs between the left/right bridge supports on that moving bridge. It has its own roller contact points.
- **Z hoist:** cable upper anchor starts at winch drum/sheave, bottom anchor ends at connector, whose lower end attaches to the original six-part claw hub.

## Projection and numerical model

In cabinet-image space:
```text
rail_left(depth)  = lerp(left_rear_mount,  left_front_mount,  depth)
rail_right(depth) = lerp(right_rear_mount, right_front_mount, depth)
bridge_left       = rail_left(depth)
bridge_right      = rail_right(depth)
trolley_anchor    = lerp(bridge_left, bridge_right, lateral)
claw_anchor       = trolley_anchor + projected_vertical_drop
```
Projective / perspective correction must be validated against source cabinet art; simple linear screen interpolation is an initial calibrated approximation, not a physically correct 3D simulation. The feet/rail contact locations and component scale/occlusion must remain coherent at near and far extremes.

Root hierarchy:
```text
CabinetRoot
  FixedRoofMounts
    RearLeftMount
    RearRightMount
    FrontLeftMount
    FrontRightMount
  FixedRails
    LeftGuide (rear-left → front-left)
    RightGuide (rear-right → front-right)
  MovingBridge (travels by shared depth)
    LeftRollerBogie / RightRollerBogie
    CrossBeam
    MovingTrolley (travels by shared lateral)
      Winch
      SuspensionCable
      Connector
      ArticulatedClawRoot
  CabinetFrontFrameAndGlassOcclusion
```

**Do not** place fixed guides under bridge/trolley parents. Moving rollers may be attached to bridge parent only; fixed mount hardware must remain under the cabinet root. Avoid clip art or draw-on primitive placeholders in the final proof.

## Implementation sequence

1. Produce a **roof anchor calibration review image** from original M01 body (with debug-only 4-point labels/lines). Agree upon actual mounting points before altering decorative art.
2. Replace arbitrary rail sprite placement with a camera-matched two-guide roof assembly. Reuse existing illustrated rail textures only if their perspective can be corrected convincingly without visible distortion. If not, request only one targeted Astra image: isolated pair of mounted, perspective-correct rails with brackets, clean alpha, anchored to existing M01 source. Do not regenerate the full cabinet/gantry.
3. Derive bridge endpoints/roller positions from the fixed guide endpoints, and trolley from bridge endpoints. Verify all grips remain inside front glass window with full silhouette bounds, not merely hub center.
4. Verify actual cable start/termination and shaft/connector alignment in every timeline pose; **no hovering**, detached ends, no stretching motor housing.
5. Validate idle/seek near/far + lower/grip/lift/transport extremes. Depth order must render hardware behind cabinet front lip and in front of rear chamber as physically plausible.
6. Add focused Godot tests and CI capture: fixed mounts unchanged under all poses; bridge wheels lie within epsilon of both rail centerlines; both ends of cable meet winch/connector; true foreground claw bounds clear glass lip/side divider; real screenshot/video still mandatory.
7. Inspect full-size, close-up, and several timeline frames next to approved style anchor. Owner acceptance required.

## Phase boundary

This is mechanical presentation quality inside R5.1-M. No extra cabinets, customers, crowd, pantry, cart overhaul or Stage 1 transaction changes. After passing M4, add variable inventory-driven plush test and prize chute handoff in a separate proof before claiming M01 fully functional.

## Deliverable standard

- 4 anchored roof bracket mounts; 2 visually continuous roof rails.
- 1 connected and visibly supported bridge + trolley.
- 1 continuous winch/cable/connector/claw assembly across full motion.
- Godot 4.7.2 actual 1280×720 multi-frame proof and close-up video.
- All source CI tests pass. **No pass claim from source-level assertions alone.**
