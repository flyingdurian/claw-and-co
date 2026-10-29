extends SceneTree
## Mechanical demonstration contract. This is NOT a gameplay/artist acceptance suite.
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
    call_deferred("run_all")

func check(cond: bool, name: String) -> void:
    checks += 1
    if not cond:
        failures += 1
        printerr("R51M_FAIL: ", name)

func run_all() -> void:
    var packed := load("res://scenes/r5/R51MechanicalProof.tscn") as PackedScene
    check(packed != null, "independent proof scene imports")
    if packed == null:
        quit(1); return
    var scene := packed.instantiate() as Node2D
    root.add_child(scene)
    for i in range(5):
        await process_frame
    scene.set("run_demo", false)
    check(bool(scene.get("assets_loaded")), "all source art loaded")
    var rig := scene.get("mechanic") as Node2D
    check(rig != null, "rig instance attached")
    if rig == null:
        quit(1); return
    check(bool(rig.get("assets_loaded")), "rig component loading")
    var structural_nodes := [
        "FixedDepthRails/LeftGuide", "FixedDepthRails/RightGuide",
        "FixedRoofCradle/RearLoadBeam", "FixedRoofCradle/FrontLoadBeam",
        "DepthBridge/LeftRollerEngagement/LeftBearingBogie",
        "DepthBridge/RightRollerEngagement/RightBearingBogie",
        "FixedRoofMounts/LeftRear/BoltedRoofBracket",
        "FixedRoofMounts/LeftFront/BoltedRoofBracket",
        "FixedRoofMounts/RightRear/BoltedRoofBracket",
        "FixedRoofMounts/RightFront/BoltedRoofBracket",
        "DepthBridge/LeftRollerEngagement",
        "DepthBridge/RightRollerEngagement",
        "DepthBridge/BridgeChrome", "DepthBridge/LateralTrolley/RollerTrolley",
        "DepthBridge/LateralTrolley/HoistWinch", "DepthBridge/LateralTrolley/HoistCable",
        "DepthBridge/LateralTrolley/CableToClawConnector",
        "DepthBridge/LateralTrolley/ClawRoot/MotorHub",
        "DepthBridge/LateralTrolley/ClawRoot/LeftShoulder/LeftElbow/LeftGrippingTip",
        "DepthBridge/LateralTrolley/ClawRoot/RightShoulder/RightElbow/RightGrippingTip",
        "DepthBridge/LateralTrolley/ClawRoot/RearFingerPivot/ForeshortenedThirdProng"
    ]
    for path in structural_nodes:
        check(rig.has_node(path), "separate part: " + path)
    var rails_left := rig.get_node("FixedDepthRails/LeftGuide") as Polygon2D
    var rails_right := rig.get_node("FixedDepthRails/RightGuide") as Polygon2D
    var left_initial := rails_left.global_transform
    var right_initial := rails_right.global_transform
    # Actual artwork geometry, not merely numerical mount markers.
    check(rails_left.texture != null and rails_right.texture != null,
        "two fixed rails use real Astra chrome textures")
    check(rails_left.polygon.size() == 4 and rails_right.polygon.size() == 4,
        "both camera-matched guides have four physical corner points")
    check(rails_left.uv.size() == 4 and rails_right.uv.size() == 4,
        "both roof rails have UV-mapped premium chrome material")
    var left_edge := (rails_left.polygon[1] + rails_left.polygon[2]) * 0.5
    var right_edge := (rails_right.polygon[1] + rails_right.polygon[2]) * 0.5
    check(left_edge.distance_to(Vector2(300.0,415.0)) < 0.1,
        "left metal guide front endpoint coincides with roof mount")
    check(right_edge.distance_to(Vector2(645.0,414.0)) < 0.1,
        "right metal guide front endpoint coincides with roof mount")
    var cradle_rear := rig.get_node("FixedRoofCradle/RearLoadBeam") as Polygon2D
    var cradle_front := rig.get_node("FixedRoofCradle/FrontLoadBeam") as Polygon2D
    check(cradle_rear.texture != null and cradle_front.texture != null,
        "fixed structural cradle uses high-fidelity original metal textures")
    check(cradle_rear.polygon.size() == 4 and cradle_front.polygon.size() == 4,
        "load-bearing roof crossmembers are correctly textured physical strips")
    var expected_rear_mid := (Vector2(383.0,371.0) + Vector2(562.0,371.0)) * 0.5
    var expected_front_mid := (Vector2(300.0,415.0) + Vector2(645.0,414.0)) * 0.5
    check(((cradle_rear.polygon[0] + cradle_rear.polygon[1] +
        cradle_rear.polygon[2] + cradle_rear.polygon[3]) * 0.25).distance_to(
        expected_rear_mid) < 0.1, "rear load beam connects rear structural mounts")
    check(((cradle_front.polygon[0] + cradle_front.polygon[1] +
        cradle_front.polygon[2] + cradle_front.polygon[3]) * 0.25).distance_to(
        expected_front_mid) < 0.1, "front load beam connects front structural mounts")
    var rear_initial := cradle_rear.global_transform
    var front_initial := cradle_front.global_transform
    var original_mounts: Dictionary = {}
    for name in ["LeftRear", "LeftFront", "RightRear", "RightFront"]:
        var roof_anchor := rig.get_node("FixedRoofMounts/" + name) as Marker2D
        original_mounts[name] = roof_anchor.global_transform
        var mount_hardware := roof_anchor.get_node("BoltedRoofBracket") as Sprite2D
        check(mount_hardware.texture != null and mount_hardware.region_enabled,
            "physical textured bracket fixed to cabinet: " + name)
        var visible_roof_plate := roof_anchor.get_node("RoofAttachmentPlate") as Sprite2D
        check(visible_roof_plate.texture != null and visible_roof_plate.region_enabled and
              visible_roof_plate.z_index > 0,
              "roof bolt cap visibly meets fixed cabinet fascia: " + name)
    var left_wheel := rig.get_node("DepthBridge/LeftRollerEngagement") as Marker2D
    var right_wheel := rig.get_node("DepthBridge/RightRollerEngagement") as Marker2D
    var left_bogie := rig.get_node("DepthBridge/LeftRollerEngagement/LeftBearingBogie") as Sprite2D
    var right_bogie := rig.get_node("DepthBridge/RightRollerEngagement/RightBearingBogie") as Sprite2D
    check(left_bogie.texture != null and right_bogie.texture != null and
        left_bogie.region_enabled and right_bogie.region_enabled,
        "both bridge bogies use distinct illustrated roller-bearing regions")
    var first: Array[String] = []
    for tick in range(0, 721, 9):
        rig.call("set_demo_tick", tick)
        var state: Dictionary = rig.get("last_pose")
        check(float(state.get("lateral", -1)) >= 0.08 and float(state.get("lateral", 2)) <= 0.92, "X limit @" + str(tick))
        check(float(state.get("depth", -1)) >= 0.08 and float(state.get("depth", 2)) <= 0.92, "Y limit @" + str(tick))
        check(float(state.get("drop", -1)) >= 0.0 and float(state.get("drop", 2)) <= 1.0, "Z limit @" + str(tick))
        check(float(state.get("grip", -1)) >= 0.0 and float(state.get("grip", 2)) <= 1.0, "grip limit @" + str(tick))
        check(float(state.get("cable_length", -1)) >= 0.0, "connected cable length @" + str(tick))
        # These are visual geometry invariants the R5.1-M R1 tests missed.
        check(float(state.get("trolley_screen_x", -1)) >= 365.0 and
              float(state.get("trolley_screen_x", 800)) <= 551.0,
              "claw must remain inside front glass, never central divider/side window @" + str(tick))
        check(float(state.get("cable_to_connector_error", -1)) <= 3.0,
              "cable lower tip must reach connector @" + str(tick))
        check(float(state.get("connector_to_hub_overlap", -1)) >= 3.0,
              "connector must reach claw hub @" + str(tick))
        check(is_equal_approx(float(state.get("fixed_left_x", -1)), 341.5) and
              is_equal_approx(float(state.get("fixed_left_y", -1)), 393.0) and
              is_equal_approx(float(state.get("fixed_right_x", -1)), 603.5) and
              is_equal_approx(float(state.get("fixed_right_y", -1)), 392.5),
              "guide rails anchored to cabinet across all demo ticks @" + str(tick))
        check(float(state.get("left_roller_error", 1000)) <= 0.75 and
              float(state.get("right_roller_error", 1000)) <= 0.75,
              "moving bridge roller contact with BOTH fixed tracks @" + str(tick))
        var bridge_l := Vector2(float(state.get("bridge_left_x",0)),
            float(state.get("bridge_left_y",0)))
        var bridge_r := Vector2(float(state.get("bridge_right_x",0)),
            float(state.get("bridge_right_y",0)))
        var depth_fraction: float = float(state.get("depth", 0))
        check(bridge_l.distance_to(Vector2(383,371).lerp(Vector2(300,415), depth_fraction)) < 0.1 and
              bridge_r.distance_to(Vector2(562,371).lerp(Vector2(645,414), depth_fraction)) < 0.1,
              "both bridge ends interpolate same roof-mounted depth @" + str(tick))
        check(float(state.get("trolley_screen_x", -1)) >= 300 and float(state.get("trolley_screen_x", 1200)) <= 875, "trolley travel envelope @" + str(tick))
        check(float(state.get("claw_top_screen_y", -1)) >= 380 and
              float(state.get("claw_top_screen_y", 1500)) <= 700,
              "claw mount stays above front lip at full drop @" + str(tick))
        first.append(rig.call("pose_signature"))
    var second: Array[String] = []
    for tick in range(0, 721, 9):
        rig.call("set_demo_tick", tick)
        second.append(rig.call("pose_signature"))
    check(first == second, "same timeline produces same mechanical states")
    check(rails_left.global_transform == left_initial, "left depth guide never follows moving bridge")
    check(rails_right.global_transform == right_initial, "right depth guide never follows moving bridge")
    check(cradle_rear.global_transform == rear_initial,
        "rear roof cradle remains fixed throughout the entire cycle")
    check(cradle_front.global_transform == front_initial,
        "front roof cradle remains fixed throughout the entire cycle")
    for name in original_mounts.keys():
        check((rig.get_node("FixedRoofMounts/" + str(name)) as Marker2D).global_transform ==
            original_mounts[name], "cabinet roof mount is immobile: " + str(name))
    var mechanical_parent := rig.get_node("DepthBridge") as Node2D
    check(rails_left.get_parent() != mechanical_parent and
          rails_right.get_parent() != mechanical_parent,
          "stationary rails cannot inherit moving bridge transform")
    rig.call("set_pose", 0.25, 0.10, 0.0, 0.0)
    var y_far: float = (rig.get_node("DepthBridge") as Node2D).position.y
    rig.call("set_pose", 0.25, 0.90, 0.0, 0.0)
    var y_near: float = (rig.get_node("DepthBridge") as Node2D).position.y
    check(y_near > y_far + 18.0, "Y depth projection changes bridge but not fixed rails")
    rig.call("set_pose", 0.85, 0.50, 0.0, 0.0)
    var cable_high: float = float((rig.get("last_pose") as Dictionary).get("cable_length", -1))
    rig.call("set_pose", 0.85, 0.50, 1.0, 0.0)
    var cable_low: float = float((rig.get("last_pose") as Dictionary).get("cable_length", -1))
    check(cable_low > cable_high + 150.0, "Z descent increases real cable length without moving fixed guides")
    rig.call("set_pose", 0.0, 1.0, 1.0, 1.0)
    var extrema: Dictionary = rig.get("last_pose")
    check(is_equal_approx(float(extrema.get("lateral",0)),0.08), "min lateral clamp")
    check(is_equal_approx(float(extrema.get("depth",0)),0.92), "max depth clamp")
    check(is_equal_approx(float(extrema.get("drop",0)),1.0), "max hoist clamp")
    check(is_equal_approx(float(extrema.get("grip",0)),1.0), "closed finger clamp")
    check((rig.get_node("DepthBridge/LateralTrolley/ClawRoot/LeftShoulder") as Node2D).rotation_degrees < 0, "left shoulder closes")
    check((rig.get_node("DepthBridge/LateralTrolley/ClawRoot/RightShoulder") as Node2D).rotation_degrees > 0, "right shoulder closes")
    check((rig.get_node("DepthBridge/LateralTrolley/ClawRoot/RearFingerPivot") as Node2D).rotation_degrees > 0, "third prong articulates provisionally")
    var rig_cable := rig.get_node("DepthBridge/LateralTrolley/HoistCable") as Sprite2D
    check(rig_cable.scale.y > 0.01, "winch cable extends")
    print("R51M_TEST_ASSERTIONS=",checks," PASSED=",checks-failures," FAILED=",failures)
    print("R51M_VISUAL_ACCEPTANCE=PENDING; no actual grip collision claim")
    quit(0 if failures == 0 else 1)
