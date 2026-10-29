extends SceneTree
## Capture only from the REAL Godot renderer; NEVER synthesize benchmark parity claims.
## Graphical call: godot --path . --script res://scripts/tests/CaptureLivingSequences.gd
func _initialize() -> void:
    call_deferred("capture")

func _shot(name: String, main: GamePresentation) -> bool:
    main.bridge.publish()
    for i in range(5): await process_frame
    var img: Image = root.get_texture().get_image()
    if img.get_size() != Vector2i(1280,720):
        printerr("CAPTURE_FAIL: wrong viewport ",img.get_size())
        return false
    var path: String = ProjectSettings.globalize_path("res://previews/"+name+".png")
    var result: Error = img.save_png(path)
    if result != OK:
        printerr("CAPTURE_FAIL: could not save ",path)
        return false
    print("CAPTURED_REAL_GODOT_FRAME ",name," tick=",main.driver.simulation.clock.tick)
    return true

func capture() -> void:
    var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        quit(1)
        return
    var main: GamePresentation = packed.instantiate() as GamePresentation
    root.add_child(main)
    root.size = Vector2i(1280,720)
    for i in range(10): await process_frame
    var sim: SimulationRoot = main.driver.simulation
    if sim == null:
        quit(1)
        return
    if not await _shot("living_00_ambient",main):
        quit(1)
        return
    main.bridge.request_action("start_production",{"job_id":"PB01"})
    while sim.clock.tick < 190: sim.advance()
    main.bridge.publish()
    if not await _shot("living_01_arrivals",main):
        quit(1)
        return
    main.bridge.request_action("purchase_card",{"visit_id":"V01"})
    main.bridge.request_action("admit_session",{"visit_id":"V01"})
    while sim.clock.tick < 250: sim.advance()
    if not await _shot("living_02_play",main):
        quit(1)
        return
    while sim.clock.tick < 680: sim.advance()
    if not await _shot("living_03_reactions",main):
        quit(1)
        return
    main.switch_tab("workshop")
    if not await _shot("living_04_workshop",main):
        quit(1)
        return
    print("LIVING_CAPTURE_COMPLETE: REAL Godot 1280x720 images under res://previews/")
    quit(0)
