extends SceneTree
## REAL RUNTIME CAPTURE. Requires a graphical Godot 4.7.2 session (do not use --headless).
func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var stage: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    if stage == null:
        printerr("CAPTURE_FAIL: Main.tscn missing")
        quit(1)
        return
    var main: GamePresentation = stage.instantiate() as GamePresentation
    root.add_child(main)
    root.size = Vector2i(1280, 720)
    for i in range(5): await process_frame
    var first: Image = root.get_texture().get_image()
    if first.get_size() != Vector2i(1280, 720):
        printerr("CAPTURE_FAIL: viewport not 1280x720: ", first.get_size())
        quit(1)
        return
    var dir: String = ProjectSettings.globalize_path("res://previews/")
    var saved_arcade: Error = first.save_png(dir.path_join("gate_e_runtime_arcade_1280x720.png"))
    main.switch_tab("workshop")
    for i in range(5): await process_frame
    var second: Image = root.get_texture().get_image()
    var saved_workshop: Error = second.save_png(dir.path_join("gate_e_runtime_workshop_1280x720.png"))
    if saved_arcade != OK or saved_workshop != OK:
        printerr("CAPTURE_FAIL: cannot write PNG")
        quit(1)
        return
    print("CAPTURE_PASS: 1280x720 engine screenshots saved under previews/")
    quit(0)
