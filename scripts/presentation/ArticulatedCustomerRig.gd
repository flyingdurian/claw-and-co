class_name ArticulatedCustomerRig
extends Node2D
## R4-A: actual independently articulated elbow/knee/wrist/ankle sprite bones.
## No procedural body primitives. Body parts are original registered SVG artwork.
## Simulation outcomes and customer routing remain external and read-only.
const REQUIRED: Array[String]=["torso","head","upper_arm_l","forearm_l","upper_arm_r","forearm_r",
    "thigh_l","shin_l","thigh_r","shin_r","hand_l","hand_r","foot_l","foot_r",
    "hair_back","hair_front","bow"]
const EMOTIONS: Array[String]=["neutral","focus","joy","anticipation",
    "angry","sad","speaking","determined"]
const EXPRESSION: Dictionary={
    "WIN":"joy","CHEER":"joy","CELEBRATE":"joy",
    "PLAY":"focus","CONCENTRATE":"focus","ANTICIPATE":"anticipation",
    "MISS":"sad","SAD":"sad","FRUSTRATED":"angry","REQUEST":"speaking",
    "CHAT":"speaking","HOLD_PRIZE":"joy","TRY_AGAIN":"determined",
    "QUEUE":"anticipation","WATCH":"anticipation"}
var parts: Dictionary={}
var joints: Dictionary={}
var pose_data: Dictionary={}
var rig_valid: bool=false
var current_pose: String=""
var start_tick: int=0
var facing_sign: float=1.0
var walk_cycle: Array=[]
var rest_foot_positions: Dictionary={"l":Vector2(-14,-7),"r":Vector2(14,-7)}
var expression: Sprite2D
var head_pivot: Node2D
var torso_pivot: Node2D
var root_motion: Node2D
var last_contact: Dictionary={}
const LEG_UPPER:float=35.0
const LEG_LOWER:float=34.0
const WALK_PERIOD_TICKS:int=48

static func art_complete(directory: String)->bool:
    var path: String=directory.path_join("rig.json")
    if not FileAccess.file_exists(path):return false
    for name in REQUIRED:
        if not ResourceLoader.exists(directory.path_join(name+".svg")):return false
    for emotion in EMOTIONS:
        if not ResourceLoader.exists(directory.path_join("face_"+emotion+".svg")):return false
    return true

func _add_joint(parent: Node2D, name: String, pos: Vector2)->Node2D:
    var j:=Node2D.new()
    j.name=name
    j.position=pos
    parent.add_child(j)
    joints[name]=j
    return j

func _add_art(parent: Node2D, directory: String, part_name: String, z: int=0)->Sprite2D:
    var sprite:=Sprite2D.new()
    sprite.name=part_name
    sprite.texture=load(directory.path_join(part_name+".svg")) as Texture2D
    sprite.centered=true
    sprite.z_index=z
    parent.add_child(sprite)
    parts[part_name]=sprite
    return sprite

func _point(config: Dictionary,key:String,fallback:Vector2)->Vector2:
    var a: Array=config.get(key,[fallback.x,fallback.y])
    return Vector2(float(a[0]),float(a[1]))

func setup(directory:String)->bool:
    if not art_complete(directory):return false
    var f:=FileAccess.open(directory.path_join("rig.json"),FileAccess.READ)
    if f==null:return false
    var parsed:Variant=JSON.parse_string(f.get_as_text())
    if not parsed is Dictionary:return false
    pose_data=parsed
    var config:Dictionary=pose_data.get("joints",{})
    if pose_data.get("schema","")!="clawco.performer-rig/v2":return false
    root_motion=_add_joint(self,"BodyMotion",Vector2.ZERO)
    torso_pivot=_add_joint(root_motion,"TorsoPivot",Vector2(0,-116))
    head_pivot=_add_joint(root_motion,"HeadPivot",_point(config,"head",Vector2(0,-165)))
    # Actual painted parts must belong to the rotating head/torso pivots.
    _add_art(head_pivot,directory,"hair_back",-3)
    _add_art(torso_pivot,directory,"torso",1)
    _add_art(head_pivot,directory,"head",6)
    expression=_add_art(head_pivot,directory,"face_neutral",8)
    _add_art(head_pivot,directory,"hair_front",9)
    _add_art(head_pivot,directory,"bow",10)
    for side in ["l","r"]:
        var shoulder:=_add_joint(root_motion,"Shoulder_"+side,
            _point(config,"shoulder_"+side,Vector2(-30 if side=="l" else 30,-122)))
        var arm_name: String="upper_arm_"+side
        _add_art(shoulder,directory,arm_name,0)
        var elbow:=_add_joint(shoulder,"Elbow_"+side,_point(config,"elbow_"+side,Vector2(0,31)))
        _add_art(elbow,directory,"forearm_"+side,0)
        var wrist:=_add_joint(elbow,"Wrist_"+side,_point(config,"wrist_"+side,Vector2(0,27)))
        _add_art(wrist,directory,"hand_"+side,0)
        var hip:=_add_joint(root_motion,"Hip_"+side,
            _point(config,"hip_"+side,Vector2(-14 if side=="l" else 14,-70)))
        _add_art(hip,directory,"thigh_"+side,-2)
        var knee:=_add_joint(hip,"Knee_"+side,
            _point(config,"knee_"+side,Vector2(0,35)))
        _add_art(knee,directory,"shin_"+side,-2)
        var ankle:=_add_joint(knee,"Ankle_"+side,
            _point(config,"ankle_"+side,Vector2(0,34)))
        _add_art(ankle,directory,"foot_"+side,2)
    rig_valid=true
    sample(0,"REST",1.0)
    return true

func _leg_ik(side:String,desired:Vector2)->void:
    var hip:Node2D=joints["Hip_"+side]
    var knee:Node2D=joints["Knee_"+side]
    var ankle:Node2D=joints["Ankle_"+side]
    var target:Vector2=desired-hip.position
    var dist:float=clampf(target.length(),8.0,LEG_UPPER+LEG_LOWER-.5)
    var a:float=atan2(target.x,target.y)
    var correction:float=acos(clampf(
        (LEG_UPPER*LEG_UPPER+dist*dist-LEG_LOWER*LEG_LOWER)/
        (2.0*LEG_UPPER*dist),-1.0,1.0))
    var bend:float=acos(clampf(
        (LEG_UPPER*LEG_UPPER+LEG_LOWER*LEG_LOWER-dist*dist)/
        (2.0*LEG_UPPER*LEG_LOWER),-1.0,1.0))
    var direction:float=1.0 if side=="l" else -1.0
    hip.rotation=a-direction*correction
    knee.rotation=direction*(PI-bend)
    ankle.rotation=-hip.rotation-knee.rotation
    last_contact[side]={"target":desired,"foot_local":desired,
        "is_planted":absf(desired.y+7.0)<.01}

func sample(tick:int,action:String,facing:float,locomotion:float=1.0)->void:
    if not rig_valid:return
    if current_pose!=action:
        current_pose=action
        start_tick=tick
    if absf(facing)>.1:facing_sign=signf(facing)
    scale.x=absf(scale.x)*facing_sign
    var walking:bool=action in ["WALK","ARRIVE","LEAVE"]
    var focus:bool=action in ["PLAY","CONCENTRATE","TRY_AGAIN"]
    var celebrating:bool=action in ["WIN","CHEER","CELEBRATE"]
    var upset:bool=action in ["SAD","MISS","FRUSTRATED"]
    var phi:float=TAU*float(posmod(tick,WALK_PERIOD_TICKS))/float(WALK_PERIOD_TICKS)
    root_motion.position.y=0.0
    torso_pivot.rotation=0.0
    head_pivot.rotation=0.0
    for side in ["l","r"]:
        var phase:float=fposmod(phi+(PI if side=="r" else 0.0),TAU)/TAU
        var ankle_target:Vector2=Vector2(-14 if side=="l" else 14,-7)
        if walking:
            # 60% planted stance with constant floor height, followed
            # by a raised swing phase; two independent feet and knee IK.
            if phase<.60:
                var u:float=phase/.60
                ankle_target.x+=lerpf(14.0,-14.0,u)*locomotion
            else:
                var u:float=(phase-.60)/.40
                var ease:float=u*u*(3.0-2.0*u)
                ankle_target.x+=lerpf(-14.0,14.0,ease)*locomotion
                ankle_target.y-=15.0*sin(PI*u)*locomotion
        elif celebrating:
            ankle_target.y-=3.0*absf(sin(float(tick)*.18))
        _leg_ik(side,ankle_target)
        var shoulder:Node2D=joints["Shoulder_"+side]
        var elbow:Node2D=joints["Elbow_"+side]
        var wrist:Node2D=joints["Wrist_"+side]
        var phase_sign:float=1.0 if side=="l" else -1.0
        shoulder.rotation=0.0
        elbow.rotation=0.0
        wrist.rotation=0.0
        if walking:
            shoulder.rotation=-.29*sin(phi+ (PI if side=="r" else 0.0))
            elbow.rotation=-.22+ .11*sin(phi+ (PI if side=="r" else 0.0))
        elif focus:
            shoulder.rotation=-phase_sign*.58
            elbow.rotation=-phase_sign*.33
            wrist.rotation=phase_sign*.12
        elif celebrating:
            shoulder.rotation=-phase_sign*1.20
            elbow.rotation=-phase_sign*.34-.12*sin(float(tick)*.16)
        elif upset:
            shoulder.rotation=phase_sign*.16+.12*sin(float(tick)*.10)
            elbow.rotation=phase_sign*.33
        elif action in ["WATCH","ANTICIPATE","QUEUE","CHAT"]:
            shoulder.rotation=-phase_sign*.10
            elbow.rotation=-phase_sign*.10
    if walking:
        torso_pivot.rotation=.017*sin(phi*2.0)
        head_pivot.rotation=-.016*sin(phi*2.0)
    elif celebrating:
        root_motion.position.y=-3.0*absf(sin(float(tick)*.17))
        torso_pivot.rotation=.07*sin(float(tick)*.12)
        head_pivot.rotation=-.06*sin(float(tick)*.12)
    elif upset:
        head_pivot.rotation=.12
        torso_pivot.rotation=-.035
    elif focus:
        torso_pivot.rotation=-.075
        head_pivot.rotation=.04
    else:
        root_motion.position.y=1.0*sin(float(tick)*.045)
        head_pivot.rotation=.02*sin(float(tick)*.048)
    var emotion:String=str(EXPRESSION.get(action,"neutral"))
    var dir:String=str(pose_data.get("directory","res://art/performers/actor_01"))
    var path:String=dir.path_join("face_"+emotion+".svg")
    if expression.get_meta("emotion","")!=emotion:
        expression.texture=load(path) as Texture2D
        expression.set_meta("emotion",emotion)
