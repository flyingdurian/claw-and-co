extends SceneTree
## R4-A component-level technical acceptance for Actor 01 only.
## The ten-character global R4 art acceptance remains deliberately blocked.
const DIR="res://art/performers/actor_01"
var count:int=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
    count+=1
    if not ok:
        failures.append(label)
        printerr("R4A_ACTOR01_FAIL ",label)

func _initialize()->void:call_deferred("run")
func run()->void:
    check(ArticulatedCustomerRig.art_complete(DIR),"all original modular SVG art present")
    var actor:=LiveActor.new()
    root.add_child(actor)
    actor.configure("R4A_ACTOR01",load("res://art/living/actor_01.png") as Texture2D,0,.66)
    check(actor.articulated!=null,"first actor routes to real articulated rig")
    if actor.articulated==null:
        print("R4A_ASSERTIONS=",count," FAILED=",failures.size())
        quit(1)
        return
    var rig:ArticulatedCustomerRig=actor.articulated
    check(rig.rig_valid,"Actor 01 rig parsed and registered")
    check(rig.parts.size()>=18,"individual original illustrated parts are loaded")
    for side in ["l","r"]:
        var shoulder:Node2D=rig.joints["Shoulder_"+side]
        var elbow:Node2D=rig.joints["Elbow_"+side]
        var wrist:Node2D=rig.joints["Wrist_"+side]
        var hip:Node2D=rig.joints["Hip_"+side]
        var knee:Node2D=rig.joints["Knee_"+side]
        var ankle:Node2D=rig.joints["Ankle_"+side]
        check(elbow.get_parent()==shoulder and wrist.get_parent()==elbow,
            side+" elbow and wrist are separate independent transforms")
        check(knee.get_parent()==hip and ankle.get_parent()==knee,
            side+" knee and ankle are separate independent transforms")
        check(rig.parts["forearm_"+side].get_parent()==elbow and
            rig.parts["shin_"+side].get_parent()==knee and
            rig.parts["foot_"+side].get_parent()==ankle,
            side+" modular art layers follow independent joint ownership")
    var left_swing:bool=false
    var right_swing:bool=false
    var stance_contact_l:int=0
    var stance_contact_r:int=0
    var distinct_knees:bool=false
    for tick in range(0,48):
        rig.sample(tick,"WALK",1.0)
        var l:Dictionary=rig.last_contact["l"]
        var r:Dictionary=rig.last_contact["r"]
        if not bool(l["is_planted"]):left_swing=true
        if not bool(r["is_planted"]):right_swing=true
        if bool(l["is_planted"]):stance_contact_l+=1
        if bool(r["is_planted"]):stance_contact_r+=1
        if absf((rig.joints["Knee_l"] as Node2D).rotation-
            (rig.joints["Knee_r"] as Node2D).rotation)>.08:distinct_knees=true
    check(left_swing and right_swing,"both feet have separate raised swing phases")
    check(stance_contact_l>=26 and stance_contact_r>=26,
        "each foot plants for most of its gait cycle")
    check(distinct_knees,"left and right knee bend independently")
    actor.render_at(120,Vector2(650,280),"ARRIVE","","",-1.0,.24)
    check(not actor.body.visible and rig.visible,"Actor 01 does not animate old flattened cutout")
    check(rig.position==Vector2.ZERO,"articulated rig is anchored at floor contact")
    var resting:Texture2D=rig.expression.texture
    actor.render_at(150,Vector2(330,465),"CONCENTRATE","","",-1.0,.7)
    check(rig.expression.texture!=resting,"play face changes dynamically")
    actor.render_at(210,Vector2(330,465),"CHEER","","plush_panda",-1.0,.7)
    check(rig.expression.get_meta("emotion","")=="joy","win reaction uses illustrated joy face")
    check(actor.carried.visible,"win can display exact prize prop")
    actor.render_at(230,Vector2(330,465),"FRUSTRATED","","",-1.0,.7)
    check(rig.expression.get_meta("emotion","")=="angry","miss reaction expression changes")
    actor.render_at(350,Vector2(500,465),"LEAVE","","",-1.0,.7)
    check(rig.current_pose=="LEAVE","departure uses walk locomotion")
    check(rig.parts["head"].get_parent()==rig.head_pivot and
        rig.parts["torso"].get_parent()==rig.torso_pivot and
        rig.expression.get_parent()==rig.head_pivot,
        "real painted head and torso belong to independently moving pivots")
    rig.sample(301,"CHEER",1.0)
    check(absf(rig.head_pivot.rotation)>.005,
        "head artwork rotates independently during a cheerful reaction")
    check(rig.parts["hair_front"].texture!=null and rig.parts["bow"].texture!=null,
        "independent illustrated hairstyle and accessory")
    actor.queue_free()
    print("R4A_ACTOR01_ASSERTIONS=",count," PASSED=",count-failures.size()," FAILED=",failures.size())
    quit(0 if failures.is_empty() else 1)
