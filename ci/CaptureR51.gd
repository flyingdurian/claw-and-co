extends SceneTree
## Real Godot 4.7.2 engine captures. No offline mockups.
const PATH := "res://ci/output/r51/"
var scene: Node2D
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    root.size = Vector2i(1280, 720)
    var packed := load("res://scenes/r5/R51VisualProof.tscn") as PackedScene
    if packed == null:
        printerr("R51_CAPTURE: missing proof scene"); quit(1); return
    scene = packed.instantiate()
    root.add_child(scene)
    for i in range(4):
        await process_frame
    if not scene.art_ready:
        printerr("R51_CAPTURE: art not loaded"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PATH))
    scene.set_stock_demo("plush")
    scene.set_view_demo("normal")
    if not await shot("01_M01_populated"): quit(1); return
    scene.set_stock_demo("empty")
    if not await shot("02_M01_empty"): quit(1); return
    scene.set_stock_demo("plush")
    scene.set_view_demo("detail")
    if not await shot("03_M01_detail"): quit(1); return
    print("R51_ENGINE_CAPTURE=3 frames; ART_OWNER_APPROVAL=PENDING")
    quit(0)
func shot(label: String) -> bool:
    for i in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img.get_size() != Vector2i(1280,720):
        printerr("R51_BAD_RESOLUTION: ",img.get_size()); return false
    var out := ProjectSettings.globalize_path(PATH + label + ".png")
    if img.save_png(out) != OK:
        printerr("R51_SAVE_FAILED: ",out); return false
    print("R51_ACTUAL_GODOT_FRAME: ", label)
    return true
