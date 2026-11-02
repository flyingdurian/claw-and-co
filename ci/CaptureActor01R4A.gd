extends SceneTree
## 18-second continuous 1280x720 *Godot engine* Actor 01 pilot.
## The arcade scene and M01 are real; choreography is a visual proof timeline,
## not an authoritative session or a payout demonstration.
const OUT="res://ci/output/r4a/screenshots/"
const ROUTES=preload("res://scripts/presentation/PerspectiveCrowdRoutes.gd")
const FPS:int=24
const FRAMES:int=432
var main:GamePresentation
var performer:LiveActor
var preview_label:Label
func _initialize()->void:call_deferred("run")
func _ease(u:float)->float:
    var t:float=clampf(u,0,1)
    return t*t*(3-2*t)
func _shot(name:String)->void:
    await RenderingServer.frame_post_draw
    var im:Image=root.get_texture().get_image()
    assert(im.get_size()==Vector2i(1280,720))
    assert(im.save_png(ProjectSettings.globalize_path(OUT+name+".png"))==OK)
    print("R4A_GODOT_FRAME=",name)
func run()->void:
    root.size=Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    main=(load("res://scenes/Main.tscn") as PackedScene).instantiate() as GamePresentation
    root.add_child(main)
    for i in range(5):await process_frame
    main.driver.set_physics_process(false)
    main.bridge.set_physics_process(false)
    main.switch_tab("arcade_floor")
    # Hide the non-approved R3 cutout performers only in this focused rig
    # proof. The game and their simulation routes are otherwise untouched.
    for node in main.arcade.living_crowd.actors.values():
        (node as Node2D).visible=false
    for node in main.arcade.living_crowd.patrons:
        (node as Node2D).visible=false
    performer=LiveActor.new()
    performer.name="R4A_Actor01_OriginalModular"
    main.arcade.living_crowd.add_child(performer)
    performer.configure("R4A_DEMO",load("res://art/living/actor_01.png") as Texture2D,0,.55)
    assert(performer.articulated!=null and performer.articulated.rig_valid)
    var demo_m01:MachineView=main.arcade.machine_nodes["M01"] as MachineView
    var demo_gantry:Node2D=demo_m01.m01_v31_rig
    assert(demo_gantry!=null)
    var labels:=CanvasLayer.new()
    main.add_child(labels)
    var banner:=ColorRect.new()
    banner.position=Vector2(10,10)
    banner.size=Vector2(740,50)
    banner.color=Color(.10,.04,.15,.80)
    labels.add_child(banner)
    preview_label=Label.new()
    preview_label.position=Vector2(20,16)
    preview_label.add_theme_font_size_override("font_size",22)
    labels.add_child(preview_label)
    for frame in range(FRAMES):
        var sec:float=float(frame)/float(FPS)
        var point:Vector2=Vector2.ZERO
        var pose:String="WATCH"
        var prop:String=""
        if sec<5.0:
            var t:float=_ease(sec/5.0)
            point=Vector2(760,275).lerp(Vector2(338,462),t)
            pose="ARRIVE"
        elif sec<6.7:
            point=Vector2(338,462)
            pose="ANTICIPATE"
        elif sec<10.5:
            point=Vector2(338,462)
            pose="CONCENTRATE"
        elif sec<12.5:
            point=Vector2(338,462)
            pose="CHEER"
        elif sec<14.5:
            point=Vector2(338,462)
            pose="HOLD_PRIZE"
            prop="plush_panda"
        else:
            var t:float=_ease((sec-14.5)/(18.0-14.5))
            point=Vector2(338,462).lerp(Vector2(1150,510),t)
            pose="LEAVE"
            prop="plush_panda"
        # Drive the EXISTING approved M01 gantry in the visual-only
        # play demonstration; do not synthesize win/payout transactions.
        if sec>=6.7 and sec<10.5:
            demo_gantry.call("set_demo_tick",int((sec-6.7)*60.0))
        var scale_factor:float=ROUTES.sprite_scale(point.y)
        performer.render_at(frame*2,point,pose,"",prop,-1.0,scale_factor)
        preview_label.text="R4-A · Actor 01 · "+pose+"  |  "+("%.1f"%sec)+" s"
        if frame in [0,96,150,210,260,325,410]:
            await process_frame
            await _shot("actor01_%03d"%frame)
        else:
            await process_frame
    print("R4A_CONTINUOUS_GODOT_PROOF_FRAMES=",FRAMES)
    quit(0)
