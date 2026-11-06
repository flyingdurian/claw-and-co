extends SceneTree
var game: NeonShiftGame
const OUT := "res://ci/output/neon_shift/"
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
    root.size=Vector2i(1280,720)
    game=load("res://scenes/neon_shift/NeonShift.tscn").instantiate()
    game.capture_mode=true
    root.add_child(game)
    await process_frame
    game.set_physics_process(false)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    game.best={};game.unlocked=0
    await shot("01_title")
    game.start_shift(0)
    game.activate("bench");game.activate("charge")
    await shot("02_preparation")
    advance_to(190);game.activate("load_card");game.activate("floor")
    game.selected_visit="V01";game.activate("primary");game.activate("primary")
    advance_to(325)
    await shot("03_playing")
    advance_to(600);game.selected_visit="V02";game.activate("primary");game.activate("primary")
    advance_to(1010)
    await shot("04_staff_assist")
    advance_to(1220);game.activate("reset")
    game.selected_visit="V03";game.activate("bench");game.activate("primary")
    advance_to(1830);game.activate("charge")
    advance_to(2020);game.activate("load_card");game.activate("cassette")
    advance_to(2140);game.activate("load_cassette");game.activate("restock")
    game.selected_visit="V04";game.activate("primary")
    await shot("05_gift_and_refill")
    advance_to(2300);game.activate("floor");game.selected_visit="V05";game.activate("primary");game.activate("primary")
    advance_to(2490)
    await shot("06_evening_floor")
    advance_to(3080);game.selected_visit="V06";game.activate("primary");game.activate("primary")
    advance_to(3620);game.activate("bench");game.activate("charge")
    advance_to(3820);game.activate("load_card");game.activate("floor")
    advance_to(3920);game.selected_visit="V07";game.activate("primary")
    advance_to(4650);game.selected_visit="V08";game.activate("primary");game.activate("primary")
    advance_to(4790)
    await shot("07_refilled_machine")
    advance_to(7200)
    await shot("08_results")
    print("NEON_CAPTURE_SUMMARY ",JSON.stringify(game.summary_data))
    game.free();game=null
    await create_timer(0.25).timeout
    quit()
func advance_to(t: int) -> void:
    while game.session.sim.clock.tick<t and not game.session.finished(): game.session.advance()
    game.snapshot=game.session.sim.game_snapshot()
    game._update_world()
    if game.session.finished(): game._finish()
func shot(label: String) -> void:
    # State-jump screenshots omit wall-clock transfer effects from prior jumps.
    game.effects.clear()
    game.queue_redraw();game.hud.queue_redraw()
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
    var img:=root.get_texture().get_image()
    img.save_png(ProjectSettings.globalize_path(OUT+label+".png"))
    print("NEON_CAPTURE ",label," ",img.get_size()," tick=",game.session.sim.clock.tick)
