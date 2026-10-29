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
    var first: Array[String] = []
    for tick in range(0, 721, 9):
        rig.call("set_demo_tick", tick)
        var state: Dictionary = rig.get("last_pose")
        check(float(state.get("lateral", -1)) >= 0.08 and float(state.get("lateral", 2)) <= 0.92, "X limit @" + str(tick))
        check(float(state.get("depth", -1)) >= 0.08 and float(state.get("depth", 2)) <= 0.92, "Y limit @" + str(tick))
        check(float(state.get("drop", -1)) >= 0.0 and float(state.get("drop", 2)) <= 1.0, "Z limit @" + str(tick))
        check(float(state.get("grip", -1)) >= 0.0 and float(state.get("grip", 2)) <= 1.0, "grip limit @" + str(tick))
        check(float(state.get("cable_length", -1)) >= 0.0, "connected cable length @" + str(tick))
        check(float(state.get("trolley_screen_x", -1)) >= 300 and float(state.get("trolley_screen_x", 1200)) <= 875, "trolley travel envelope @" + str(tick))
        check(float(state.get("claw_top_screen_y", -1)) >= 380 and float(state.get("claw_top_screen_y", 1500)) <= 780, "top claw travel envelope @" + str(tick))
        first.append(rig.call("pose_signature"))
    var second: Array[String] = []
    for tick in range(0, 721, 9):
        rig.call("set_demo_tick", tick)
        second.append(rig.call("pose_signature"))
    check(first == second, "same timeline produces same mechanical states")
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
