extends Node2D
## R5.1-M: independent mechanical sprites in cabinet-local (1024x1536) art coordinates.
## Demonstration-only kinematics: no result/randomness, money, stock or session mutations.
## Future runtime adapter must supply authored machine-event tick trajectories.
const BASE := "res://art/r5/mechanics/"
const GANTRY := BASE + "gantry/"
const CLAW := BASE + "claw/"

var bridge_root: Node2D
var bridge_sprite: Sprite2D
var trolley_root: Node2D
var trolley_sprite: Sprite2D
var winch_sprite: Sprite2D
var cable_sprite: Sprite2D
var connector_sprite: Sprite2D
var claw_root: Node2D
var left_upper: Node2D
var left_finger: Node2D
var right_upper: Node2D
var right_finger: Node2D
var rear_finger: Node2D
var assets_loaded: bool = false
var last_pose: Dictionary = {}
var last_tick: int = 0

func _sprite(parent: Node, label: String, path: String, local_pos: Vector2 = Vector2.ZERO, local_scale: Vector2 = Vector2.ONE, is_centered: bool = true) -> Sprite2D:
    var tex := load(path) as Texture2D
    if tex == null:
        push_error("R5.1-M missing production sprite: " + path)
        return null
    var node := Sprite2D.new()
    node.name = label
    node.texture = tex
    node.centered = is_centered
    node.position = local_pos
    node.scale = local_scale
    parent.add_child(node)
    return node

func _pivot(parent: Node2D, label: String, p: Vector2) -> Node2D:
    var n := Node2D.new()
    n.name = label
    n.position = p
    parent.add_child(n)
    return n

func _ready() -> void:
    bridge_root = _pivot(self, "DepthBridge", Vector2.ZERO)
    bridge_sprite = _sprite(bridge_root, "BridgeChrome", GANTRY + "cross_bridge.png")
    trolley_root = _pivot(bridge_root, "LateralTrolley", Vector2.ZERO)
    trolley_sprite = _sprite(trolley_root, "RollerTrolley", GANTRY + "trolley.png", Vector2(0, 8), Vector2(0.17, 0.17))
    winch_sprite = _sprite(trolley_root, "HoistWinch", GANTRY + "winch.png", Vector2(0, 30), Vector2(0.135, 0.135))
    cable_sprite = _sprite(trolley_root, "HoistCable", GANTRY + "suspension_cable.png", Vector2.ZERO)
    connector_sprite = _sprite(trolley_root, "CableToClawConnector", GANTRY + "claw_connector.png", Vector2.ZERO, Vector2(0.12, 0.12))
    claw_root = _pivot(trolley_root, "ClawRoot", Vector2.ZERO)
    claw_root.scale = Vector2(0.19, 0.19)
    # Pixel-level pivot anchors from the six-piece Astra atlas extraction.
    _sprite(claw_root, "MotorHub", CLAW + "motor_hub.png", Vector2(-200, -8), Vector2.ONE, false)
    left_upper = _pivot(claw_root, "LeftShoulder", Vector2(-116, 343))
    _sprite(left_upper, "LeftUpperLink", CLAW + "left_upper_link.png", Vector2(-205, -58), Vector2.ONE, false)
    left_finger = _pivot(left_upper, "LeftElbow", Vector2(-127, 165))
    _sprite(left_finger, "LeftGrippingTip", CLAW + "left_gripper.png", Vector2(-234, -49), Vector2.ONE, false)
    right_upper = _pivot(claw_root, "RightShoulder", Vector2(118, 343))
    _sprite(right_upper, "RightUpperLink", CLAW + "right_upper_link.png", Vector2(-65, -60), Vector2.ONE, false)
    right_finger = _pivot(right_upper, "RightElbow", Vector2(132, 172))
    _sprite(right_finger, "RightGrippingTip", CLAW + "right_gripper.png", Vector2(-42, -43), Vector2.ONE, false)
    rear_finger = _pivot(claw_root, "RearFingerPivot", Vector2(0, 472))
    _sprite(rear_finger, "ForeshortenedThirdProng", CLAW + "rear_gripper.png", Vector2(-58, -31), Vector2.ONE, false)
    assets_loaded = bridge_sprite != null and trolley_sprite != null and winch_sprite != null and cable_sprite != null and connector_sprite != null
    if assets_loaded:
        set_pose(0.50, 0.42, 0.0, 0.0)

func set_pose(lateral: float, depth: float, drop_fraction: float, grip_fraction: float) -> void:
    if not assets_loaded:
        return
    var x := clampf(lateral, 0.08, 0.92)
    var y := clampf(depth, 0.08, 0.92)
    var z := clampf(drop_fraction, 0.0, 1.0)
    var g := clampf(grip_fraction, 0.0, 1.0)
    # Far and near endpoints are calibrated to the original perspective. The fixed
    # guide rail imagery was projected into the same exact source coordinate space.
    var left := Vector2(400, 350).lerp(Vector2(315, 403), y)
    var right := Vector2(711, 350).lerp(Vector2(867, 403), y)
    var span := right.x - left.x
    bridge_root.position = Vector2((left.x + right.x) * 0.5, (left.y + right.y) * 0.5)
    bridge_sprite.scale = Vector2(span / 1480.0, lerpf(0.095, 0.135, y))
    trolley_root.position = Vector2(lerpf(-span * 0.5, span * 0.5, x), 15)
    var drop_max := lerpf(156.0, 198.0, y)
    var claw_height := 92.0 + drop_max * z
    claw_root.position = Vector2(0, claw_height)
    # Cable and connector share the trolley local x-coordinate with the claw hub.
    # Only cable length changes. The winch casing and chrome connector do not stretch.
    var cable_top := 54.0
    var cable_bottom := claw_height - 23.0
    cable_sprite.position = Vector2(0, (cable_top + cable_bottom) * 0.5)
    cable_sprite.scale = Vector2(0.24, maxf(0.01, (cable_bottom - cable_top) / 325.0))
    connector_sprite.position = Vector2(0, claw_height - 5.0)
    left_upper.rotation_degrees = lerpf(0.0, -25.0, g)
    right_upper.rotation_degrees = lerpf(0.0, 25.0, g)
    left_finger.rotation_degrees = lerpf(0.0, -17.0, g)
    right_finger.rotation_degrees = lerpf(0.0, 17.0, g)
    rear_finger.rotation_degrees = lerpf(0.0, 10.0, g)
    # The third prong's independent upper linkage is not supplied; its hinge remains
    # provisional. The visual gate cannot be accepted until this is reviewed.
    last_pose = {"lateral": x, "depth": y, "drop": z, "grip": g,
        "bridge_x": bridge_root.position.x, "bridge_y": bridge_root.position.y,
        "trolley_screen_x": bridge_root.position.x + trolley_root.position.x,
        "claw_top_screen_y": bridge_root.position.y + trolley_root.position.y + claw_height,
        "cable_length": maxf(0.0, cable_bottom - cable_top)}

func set_demo_tick(tick: int) -> void:
    last_tick = maxi(0, tick)
    var t := last_tick
    var x := 0.5
    var y := 0.42
    var down := 0.0
    var grip := 0.0
    if t < 72: # cabinet ready
        pass
    elif t < 156: # XY seek
        var p := _smooth(float(t - 72) / 84.0)
        x = lerpf(0.5, 0.73, p)
        y = lerpf(0.42, 0.78, p)
    elif t < 258: # lower onto a target
        x = 0.73; y = 0.78
        down = _smooth(float(t - 156) / 102.0)
    elif t < 306: # all three fingers actuate
        x = 0.73; y = 0.78; down = 1.0
        grip = _smooth(float(t - 258) / 48.0)
    elif t < 393: # hoist and retract
        x = 0.73; y = 0.78
        down = 1.0 - _smooth(float(t - 306) / 87.0)
        grip = 1.0
    elif t < 492: # carry over chute
        var p := _smooth(float(t - 393) / 99.0)
        x = lerpf(0.73, 0.13, p)
        y = lerpf(0.78, 0.89, p)
        grip = 1.0
    elif t < 528: # release
        x = 0.13; y = 0.89
        grip = 1.0 - _smooth(float(t - 492) / 36.0)
    elif t < 642: # return to idle
        var p := _smooth(float(t - 528) / 114.0)
        x = lerpf(0.13, 0.50, p)
        y = lerpf(0.89, 0.42, p)
    else:
        pass
    set_pose(x, y, down, grip)

func _smooth(t: float) -> float:
    var v := clampf(t, 0.0, 1.0)
    return v * v * (3.0 - 2.0 * v)

func pose_signature() -> String:
    return var_to_str(last_pose)
