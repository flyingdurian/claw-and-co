extends Node2D
## R5.1-M: independent mechanical sprites in cabinet-local (1024x1536) art coordinates.
## Demonstration-only kinematics: no result/randomness, money, stock or session mutations.
## Future runtime adapter must supply authored machine-event tick trajectories.
const BASE := "res://art/r5/mechanics/"
const GANTRY := BASE + "gantry/"
const CLAW := BASE + "claw/"

# Cabinet-local anchor survey. These four points are on the underside of M01's roof.
# Front is nearer the player; far/rear positions converge toward the back.
const LEFT_REAR := Vector2(383.0, 371.0)
const RIGHT_REAR := Vector2(562.0, 371.0)
const LEFT_FRONT := Vector2(300.0, 415.0)
const RIGHT_FRONT := Vector2(645.0, 414.0)
const TRACK_EPSILON := 0.75

var roof_mounts: Node2D
var fixed_rails: Node2D
var mount_markers: Dictionary = {}
var bracket_sprites: Dictionary = {}
var fixed_left_rail: Sprite2D
var fixed_right_rail: Sprite2D
var left_roller_anchor: Marker2D
var right_roller_anchor: Marker2D
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

func _mount(label: String, at: Vector2, texture: String) -> void:
    # Crop a genuine chrome ceiling bracket from the existing rail artwork.
    # No debug geometry or flat vector placeholder is used for the mounted scene.
    var marker := Marker2D.new()
    marker.name = label
    marker.position = at
    roof_mounts.add_child(marker)
    mount_markers[label] = marker
    var bracket := _sprite(marker, "BoltedRoofBracket",
        GANTRY + texture, Vector2.ZERO, Vector2(0.18, 0.18))
    if bracket != null:
        bracket.region_enabled = true
        bracket.region_rect = Rect2(90.0, 0.0, 180.0, 108.0)
    bracket_sprites[label] = bracket

func _mount_rail(label: String, source: String, far: Vector2,
        near: Vector2) -> Sprite2D:
    var middle := (far + near) * 0.5
    var ray := near - far
    var rail := _sprite(fixed_rails, label, GANTRY + source, middle)
    if rail != null:
        rail.rotation = ray.angle()
        rail.scale = Vector2(ray.length() / float(rail.texture.get_width()), 0.106)
    return rail

func _ready() -> void:
    roof_mounts = _pivot(self, "FixedRoofMounts", Vector2.ZERO)
    fixed_rails = _pivot(self, "FixedDepthRails", Vector2.ZERO)
    _mount("LeftRear", LEFT_REAR, "depth_rail_a.png")
    _mount("LeftFront", LEFT_FRONT, "depth_rail_a.png")
    _mount("RightRear", RIGHT_REAR, "depth_rail_b.png")
    _mount("RightFront", RIGHT_FRONT, "depth_rail_b.png")
    fixed_left_rail = _mount_rail("LeftGuide", "depth_rail_a.png",
        LEFT_REAR, LEFT_FRONT)
    fixed_right_rail = _mount_rail("RightGuide", "depth_rail_b.png",
        RIGHT_REAR, RIGHT_FRONT)
    # Stationary mounts and rails are direct children of M01MechanicalRig,
    # never descendants of the moving bridge.
    bridge_root = _pivot(self, "DepthBridge", Vector2.ZERO)
    bridge_sprite = _sprite(bridge_root, "BridgeChrome", GANTRY + "cross_bridge.png")
    left_roller_anchor = Marker2D.new()
    left_roller_anchor.name = "LeftRollerEngagement"
    bridge_root.add_child(left_roller_anchor)
    right_roller_anchor = Marker2D.new()
    right_roller_anchor.name = "RightRollerEngagement"
    bridge_root.add_child(right_roller_anchor)
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
    for bracket in bracket_sprites.values():
        assets_loaded = assets_loaded and bracket != null
    if assets_loaded:
        set_pose(0.50, 0.42, 0.0, 0.0)

func set_pose(lateral: float, depth: float, drop_fraction: float, grip_fraction: float) -> void:
    if not assets_loaded:
        return
    var x := clampf(lateral, 0.08, 0.92)
    var y := clampf(depth, 0.08, 0.92)
    var z := clampf(drop_fraction, 0.0, 1.0)
    var g := clampf(grip_fraction, 0.0, 1.0)

    # One source of truth: moving roller positions come from the very same
    # endpoints that mount both fixed roof rails. No independent bridge track.
    var bridge_left := LEFT_REAR.lerp(LEFT_FRONT, y)
    var bridge_right := RIGHT_REAR.lerp(RIGHT_FRONT, y)
    var bridge_middle := (bridge_left + bridge_right) * 0.5
    var span := bridge_right.x - bridge_left.x
    bridge_root.position = bridge_middle
    bridge_sprite.scale = Vector2(
        span / float(bridge_sprite.texture.get_width()),
        lerpf(0.105, 0.135, y))
    left_roller_anchor.position = bridge_left - bridge_middle
    right_roller_anchor.position = bridge_right - bridge_middle
    # Clamp center so the ENTIRE open claw stays inside the front window.
    var proposed_x := lerpf(bridge_left.x, bridge_right.x, x)
    var projected_x := clampf(proposed_x, 365.0, 551.0)
    trolley_root.position = Vector2(projected_x - bridge_middle.x, 14.0)
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
    var claw_screen_y := bridge_middle.y + trolley_root.position.y + claw_height
    var left_engagement_error := left_roller_anchor.global_position.distance_to(
        to_global(bridge_left))
    var right_engagement_error := right_roller_anchor.global_position.distance_to(
        to_global(bridge_right))
    last_pose = {
        "lateral": x, "depth": y, "drop": z, "grip": g,
        "bridge_x": bridge_middle.x, "bridge_y": bridge_middle.y,
        "trolley_screen_x": projected_x, "claw_top_screen_y": claw_screen_y,
        "cable_length": cable_length,
        "cable_to_connector_error": absf(cable_bottom_y - connector_top_y),
        "connector_to_hub_overlap": connector_bottom_y - hub_mount_y,
        "fixed_left_x": fixed_left_rail.position.x,
        "fixed_left_y": fixed_left_rail.position.y,
        "fixed_right_x": fixed_right_rail.position.x,
        "fixed_right_y": fixed_right_rail.position.y,
        "bridge_left_x": bridge_left.x, "bridge_left_y": bridge_left.y,
        "bridge_right_x": bridge_right.x, "bridge_right_y": bridge_right.y,
        "left_roller_error": left_engagement_error,
        "right_roller_error": right_engagement_error
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
