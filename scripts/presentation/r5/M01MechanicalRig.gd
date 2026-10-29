extends Node2D
## R5.1-M: independent mechanical sprites in cabinet-local (1024x1536) art coordinates.
## Demonstration-only kinematics: no result/randomness, money, stock or session mutations.
## Future runtime adapter must supply authored machine-event tick trajectories.
const BASE := "res://art/r5/mechanics/"
const GANTRY := BASE + "gantry/"
const CLAW := BASE + "claw/"

var fixed_left_rail: Sprite2D
var fixed_right_rail: Sprite2D
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
    # Rail guides mount to the cabinet, NOT beneath the moving DepthBridge.
    # These are original high-fidelity gantry textures, not substitute primitives.
    fixed_left_rail = _sprite(self, "FixedDepthRailLeft", GANTRY + "depth_rail_a.png",
        Vector2(346, 405), Vector2(0.098, 0.075))
    fixed_right_rail = _sprite(self, "FixedDepthRailRight", GANTRY + "depth_rail_b.png",
        Vector2(563, 405), Vector2(0.098, 0.075))
    if fixed_left_rail != null:
        fixed_left_rail.rotation_degrees = -12.0
    if fixed_right_rail != null:
        fixed_right_rail.rotation_degrees = -12.0
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
    assets_loaded = fixed_left_rail != null and fixed_right_rail != null and bridge_sprite != null and trolley_sprite != null and winch_sprite != null and cable_sprite != null and connector_sprite != null
    if assets_loaded:
        set_pose(0.50, 0.42, 0.0, 0.0)

func set_pose(lateral: float, depth: float, drop_fraction: float, grip_fraction: float) -> void:
    if not assets_loaded:
        return
    var x := clampf(lateral, 0.08, 0.92)
    var y := clampf(depth, 0.08, 0.92)
    var z := clampf(drop_fraction, 0.0, 1.0)
    var g := clampf(grip_fraction, 0.0, 1.0)

    # M01 front display opening is x=272..652, y=400..865 in the
    # authoritative cabinet PNG. The claw silhouette has a sizeable radius.
    # Constrain the *entire claw* to the front chamber, never the side window
    # at x=731..936 or the central metal divider at x=653..730.
    # The y axis changes bridge depth along fixed rails, not the rails themselves.
    var bridge_y := lerpf(409.0, 439.0, y)
    bridge_root.position = Vector2(459.0 + 7.0 * y, bridge_y)
    bridge_sprite.scale = Vector2(352.0 / float(bridge_sprite.texture.get_width()),
        lerpf(0.105, 0.14, y))
    var projected_x := lerpf(365.0, 551.0, x)
    trolley_root.position = Vector2(projected_x - bridge_root.position.x, 14.0)
    # The hoist's moving head, cable, and claw all share this trolley root.
    # Maximum 180px descent keeps the finger tips above the front opening lip.
    var drop_max := lerpf(153.0, 163.0, y)
    var claw_height := 79.0 + drop_max * z
    claw_root.position = Vector2(0.0, claw_height)

    # Physical suspension anchors are calculated from the same claw mount.
    # Cable starts at the bottom of the fixed-size winch. Its *length alone*
    # changes. The connector's bottom slightly overlaps the motor-hub socket.
    var connector_height := float(connector_sprite.texture.get_height()) * connector_sprite.scale.y
    var hub_mount_y := claw_height - 1.5
    var connector_bottom_y := hub_mount_y + 5.0
    var connector_center_y := connector_bottom_y - connector_height * 0.5
    connector_sprite.position = Vector2(0, connector_center_y)
    var connector_top_y := connector_center_y - connector_height * 0.5
    var cable_top_y := 52.0
    var cable_bottom_y := connector_top_y + 2.0
    var cable_length := maxf(2.0, cable_bottom_y - cable_top_y)
    cable_sprite.position = Vector2(0, cable_top_y + cable_length * 0.5)
    cable_sprite.scale = Vector2(0.24, cable_length / float(cable_sprite.texture.get_height()))

    left_upper.rotation_degrees = lerpf(0.0, -25.0, g)
    right_upper.rotation_degrees = lerpf(0.0, 25.0, g)
    left_finger.rotation_degrees = lerpf(0.0, -17.0, g)
    right_finger.rotation_degrees = lerpf(0.0, 17.0, g)
    rear_finger.rotation_degrees = lerpf(0.0, 10.0, g)
    # The third upper linkage is still provisional; do not claim gripping physics.
    var claw_screen_y := bridge_y + trolley_root.position.y + claw_height
    last_pose = {
        "lateral": x, "depth": y, "drop": z, "grip": g,
        "bridge_x": bridge_root.position.x, "bridge_y": bridge_y,
        "trolley_screen_x": projected_x, "claw_top_screen_y": claw_screen_y,
        "cable_length": cable_length,
        "cable_to_connector_error": absf(cable_bottom_y - connector_top_y),
        "connector_to_hub_overlap": connector_bottom_y - hub_mount_y,
        "fixed_left_x": fixed_left_rail.position.x,
        "fixed_left_y": fixed_left_rail.position.y,
        "fixed_right_x": fixed_right_rail.position.x,
        "fixed_right_y": fixed_right_rail.position.y
    }

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
