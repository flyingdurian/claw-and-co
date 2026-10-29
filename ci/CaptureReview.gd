extends SceneTree
## Actual Godot viewport screenshots. All gameplay commands come from the authored fixture.
## NEVER mix this evidence with fabricated/offline renders.
const OUT := "res://ci/output/screenshots/"
var queued: Dictionary = {}
var replay_commands: Array = []
var sim: SimulationRoot
var main: GamePresentation

func _initialize() -> void:
    call_deferred("make_review")

func make_review() -> void:
    root.size = Vector2i(1280,720)
    var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        printerr("CI_CAPTURE: main scene missing")
        quit(1)
        return
    main = packed.instantiate() as GamePresentation
    root.add_child(main)
    for i in range(8):
        await process_frame
    if main == null or main.driver == null or main.driver.simulation == null:
        printerr("CI_CAPTURE: simulation missing")
        quit(1)
        return
    # A frozen authored tick lets separate capture runs reproduce comparable views.
    main.driver.set_physics_process(false)
    main.bridge.set_physics_process(false)
    sim = main.driver.simulation
    var path = ProjectSettings.globalize_path(OUT)
    DirAccess.make_dir_recursive_absolute(path)
    var fixture: Dictionary = SchemaLoader.load_json("res://data/commands.stage1.json", "clawco.replay/v1")
    replay_commands = fixture.get("commands", [])
    for c in replay_commands:
        var t: int = int(c.get("tick", -1))
        if not queued.has(t):
            queued[t] = []
        queued[t].append(c)
    _commands_at(0)
    if not await _shot("01_arcade_start"):
        quit(1)
        return
    _advance_to(240)
    if not await _shot("02_arcade_arrivals"):
        quit(1)
        return
    _advance_to(900)
    if not await _shot("03_arcade_activity"):
        quit(1)
        return
    main.switch_tab("workshop")
    if not await _shot("04_workshop"):
        quit(1)
        return
    main.switch_tab("arcade_floor")
    _advance_to(1800)
    if not await _shot("05_arcade_rush"):
        quit(1)
        return
    print("CI_CAPTURE_SUCCESS: 5 actual Godot 1280x720 screenshots")
    quit(0)

func _commands_at(tick: int) -> void:
    for c in queued.get(tick, []):
        var result: Dictionary = sim.command(str(c["command_id"]), str(c["action"]), c["payload"])
        if bool(result.get("ok",false)) != bool(c.get("expect_ok",false)):
            printerr("CI_CAPTURE_FIXTURE_MISMATCH: ",c.get("command_id")," tick=",tick)

func _advance_to(target: int) -> void:
    for t in range(sim.clock.tick + 1, target+1):
        sim.advance()
        _commands_at(t)

func _shot(label: String) -> bool:
    main.bridge.publish()
    for i in range(4):
        await process_frame
    await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img.get_size() != Vector2i(1280,720):
        printerr("CI_CAPTURE_SIZE_ERROR: ", img.get_size())
        return false
    var outfile: String = ProjectSettings.globalize_path(OUT + label + ".png")
    if img.save_png(outfile) != OK:
        printerr("CI_CAPTURE_WRITE_ERROR: ",outfile)
        return false
    print("CI_CAPTURE_FRAME: ",label," @tick=",sim.clock.tick)
    return true
