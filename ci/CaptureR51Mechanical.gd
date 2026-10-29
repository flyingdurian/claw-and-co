extends SceneTree
## Actual frame captures from Godot 4.7.2 renderer, not offline composites.
const OUT := "res://ci/output/r51m/screenshots/"
var scene: Node2D
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    root.size = Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    scene = (load("res://scenes/r5/R51MechanicalProof.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(scene)
    for i in range(6):
        await process_frame
    scene.set("run_demo", false)
    if not bool(scene.get("assets_loaded")):
        printerr("R51M_CAPTURE: scene missing sprite art"); quit(1); return
    var keyframes := {
        "01_idle":0,
        "02_xy_positioning":135,
        "03_descending":209,
        "04_closed_grip":284,
        "05_lifting":354,
        "06_transit":451,
        "07_release":510,
        "08_return":580
    }
    for label in keyframes.keys():
        scene.call("set_demo_tick", int(keyframes[label]))
        if not await shot(label):
            quit(1); return
    scene.call("set_demo_tick",284)
    scene.call("set_zoom_for_capture", true)
    if not await shot("09_closeup_finger_joints"):
        quit(1); return
    print("R51M_ENGINE_CAPTURE=9 authentic 1280x720 frames; owner visual approval pending")
    quit(0)
func shot(label:String)->bool:
    for i in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    var im:Image = root.get_texture().get_image()
    if im.get_size()!=Vector2i(1280,720):
        printerr("R51M_BAD_SIZE ",im.get_size()); return false
    if im.save_png(ProjectSettings.globalize_path(OUT+label+".png"))!=OK:
        printerr("R51M_SAVE_FAIL ",label); return false
    print("R51M_ACTUAL_GODOT_FRAME: ",label)
    return true
