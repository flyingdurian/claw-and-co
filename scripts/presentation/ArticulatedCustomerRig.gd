class_name ArticulatedCustomerRig
extends Node2D
## Production 2D NPC articulation using independent painted PNG layers.
## No procedural placeholder primitives. Not used unless the complete artist export exists.
## Pivots are standardized in a character's art manifest in pixel coordinates.
const REQUIRED := ["torso", "head", "upper_arm_l", "forearm_l", "upper_arm_r", "forearm_r", "thigh_l", "shin_l", "thigh_r", "shin_r"]
const EXPRESSION := {
    "WIN":"joy", "CHEER":"joy", "CELEBRATE":"joy", "PLAY":"focus",
    "CONCENTRATE":"focus", "ANTICIPATE":"anticipation", "MISS":"sad",
    "SAD":"sad", "FRUSTRATED":"angry", "REQUEST":"speaking",
    "CHAT":"speaking", "HOLD_PRIZE":"joy", "TRY_AGAIN":"determined"
}
var parts: Dictionary = {}
var limbs: Dictionary = {}
var base_scale: float = 1.0
var current_pose: String = ""
var start_tick: int = 0
var pose_data: Dictionary = {}
var rig_valid: bool = false
var expression: Sprite2D

static func art_complete(directory: String) -> bool:
    if not FileAccess.file_exists(directory.path_join("rig.json")): return false
    for part in REQUIRED:
        if not ResourceLoader.exists(directory.path_join(part + ".png")): return false
    return true

func setup(directory: String) -> bool:
    if not art_complete(directory): return false
    var f: FileAccess = FileAccess.open(directory.path_join("rig.json"), FileAccess.READ)
    if f == null: return false
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    if not (parsed is Dictionary): return false
    pose_data = parsed
    for part in REQUIRED:
        var item: Sprite2D = Sprite2D.new()
        item.name = part
        item.texture = load(directory.path_join(part + ".png")) as Texture2D
        var settings: Dictionary = pose_data.get(part,{})
        var xy: Array = settings.get("position",[0,0])
        var offset: Array = settings.get("offset",[0,0])
        item.position = Vector2(float(xy[0]),float(xy[1]))
        item.offset = Vector2(float(offset[0]),float(offset[1]))
        item.z_index = int(settings.get("z",0))
        add_child(item)
        parts[part] = item
    for side in ["l","r"]:
        var arm: Node2D = Node2D.new()
        var leg: Node2D = Node2D.new()
        arm.name = "arm_joint_"+side
        leg.name = "leg_joint_"+side
        add_child(arm)
        add_child(leg)
        var torso_settings: Dictionary = pose_data.get("joints",{})
        var shoulder: Array = torso_settings.get("shoulder_"+side,[0,0])
        var hip: Array = torso_settings.get("hip_"+side,[0,0])
        arm.position = Vector2(float(shoulder[0]),float(shoulder[1]))
        leg.position = Vector2(float(hip[0]),float(hip[1]))
        for component in ["upper_arm_"+side,"forearm_"+side]:
            var limb: Sprite2D = parts[component]
            remove_child(limb)
            arm.add_child(limb)
            limb.position -= arm.position
        for component in ["thigh_"+side,"shin_"+side]:
            var limb: Sprite2D = parts[component]
            remove_child(limb)
            leg.add_child(limb)
            limb.position -= leg.position
        limbs["arm_"+side] = arm
        limbs["leg_"+side] = leg
    expression = Sprite2D.new()
    expression.name = "Expression"
    expression.position = parts["head"].position
    expression.z_index = 30
    add_child(expression)
    rig_valid = true
    return true

func sample(tick: int, action: String, facing: float, locomotion: float = 1.0) -> void:
    if not rig_valid: return
    if current_pose != action:
        current_pose = action
        start_tick = tick
    var t: float = float(tick)
    var f: float = t * .27
    var envelope: float = clampf(float(tick-start_tick)/9.0,0.0,1.0)
    var walking: float = locomotion if action in ["WALK","ARRIVE","LEAVE"] else 0.0
    var playing: float = 1.0 if action in ["PLAY","CONCENTRATE","TRY_AGAIN"] else 0.0
    var cheering: float = 1.0 if action in ["WIN","CHEER","CELEBRATE"] else 0.0
    var upset: float = 1.0 if action in ["SAD","MISS","FRUSTRATED"] else 0.0
    var chat: float = 1.0 if action == "CHAT" else 0.0
    for side in ["l","r"]:
        var phase: float = 0.0 if side == "l" else PI
        var leg: Node2D = limbs["leg_"+side]
        var arm: Node2D = limbs["arm_"+side]
        leg.rotation = envelope * walking * .48 * sin(f+phase)
        arm.rotation = envelope * (-walking*.32*sin(f+phase)+playing*.31+cheering*(-.9)+chat*.12*sin(t*.13+phase)+upset*.16)
        (parts["shin_"+side] as Sprite2D).rotation = envelope*walking*.23*maxf(0.0,sin(f+phase+.5))
        (parts["forearm_"+side] as Sprite2D).rotation = envelope*(playing*(-.24)+cheering*(-.22)+upset*.16)
    (parts["head"] as Sprite2D).rotation = .045*sin(t*.06)+upset*.13-cheering*.07
    (parts["torso"] as Sprite2D).rotation = .02*sin(t*.07)+playing*(-.11)+upset*.08
    (parts["torso"] as Sprite2D).position.y = float(pose_data.get("torso",{}).get("position",[0,0])[1])-walking*absf(sin(f))*3.5-cheering*absf(sin(f*.8))*8.0
    # Face atlases are authored as distinct illustrated expression layers.
    var emotion: String = str(EXPRESSION.get(action,"neutral"))
    var face_path: String = str(pose_data.get("expression_prefix",""))+emotion+".png"
    if ResourceLoader.exists(face_path) and str(expression.get_meta("emotion","")) != emotion:
        expression.texture = load(face_path) as Texture2D
        expression.set_meta("emotion",emotion)
    expression.visible = expression.texture != null
    scale.x = absf(scale.x) * (-1.0 if facing < 0.0 else 1.0)
