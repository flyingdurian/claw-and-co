extends SceneTree
var game: NeonShiftGame
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failures.append(label);printerr("INPUT_FAIL "+label)
func settle() -> void:
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
func click(at:Vector2)->void:
    var move:=InputEventMouseMotion.new();move.position=at;Input.parse_input_event(move)
    var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=at;Input.parse_input_event(down)
    await process_frame
    var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=at;Input.parse_input_event(up)
    await settle()
func key(code:Key)->void:
    var k:=InputEventKey.new();k.keycode=code;k.pressed=true;Input.parse_input_event(k)
    await settle()
func click_target(id:String)->void:
    for item in game.clickables:
        if str(item.id)==id:
            await click(Rect2(item.rect).get_center());return
    check(false,"visible input target "+id)
func drag(from:Vector2,to:Vector2)->void:
    var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=from;Input.parse_input_event(down)
    await process_frame
    var move:=InputEventMouseMotion.new();move.position=to;move.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(move)
    await process_frame
    var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=to;Input.parse_input_event(up)
    await settle()
func run()->void:
    root.size=Vector2i(1280,720)
    game=load("res://scenes/neon_shift/NeonShift.tscn").instantiate();game.capture_mode=true
    root.add_child(game);await settle();game.set_physics_process(false)
    await click(Vector2(370,555));check(game.mode=="playing","real click starts shift")
    await key(KEY_TAB);check(game.area=="bench","keyboard opens bench")
    await click(Vector2(160,474));check(game.session.sim.workshop.active.has("PB01"),"real click starts card charger")
    for i in 185:game._physics_process(1.0/60.0)
    await settle()
    await drag(Vector2(160,474),Vector2(295,637));check(game.session.sim.cart.slots.supply_0=="CARD_BLANK_01","drag from charger loads real card")
    await drag(Vector2(295,637),Vector2(99,684));check(game.session.sim.cart.slots.supply_0=="","drag to bench returns card")
    check(game.session.sim.ledger.owner_of("CARD_BLANK_01")=="workshop:ready","returned card retains ownership")
    await click(Vector2(160,474));check(game.session.sim.cart.slots.supply_0=="CARD_BLANK_01","returned card can load again")
    await key(KEY_TAB);check(game.area=="floor","keyboard returns to floor")
    await drag(Vector2(295,637),Vector2(1100,155));check(game.session.sim.revenue_minor==500,"drag card to guest makes real sale")
    await click(Vector2(1120,460));check(game.session.sim.machines.machines.M01.state=="PLAYING","real click admits session")
    await key(KEY_SPACE);check(game.mode=="paused","keyboard pause")
    var t:int=game.session.sim.clock.tick;game._physics_process(1.0/60.0)
    check(t==game.session.sim.clock.tick,"clock frozen while paused")
    await click(Vector2(640,360));check(game.mode=="playing","click resumes")
    await click(Vector2(1090,38));check(game.help_open,"help click opens guide")
    t=game.session.sim.clock.tick;game._physics_process(1.0/60.0);check(t==game.session.sim.clock.tick,"help freezes clock")
    await click(Vector2(640,557));check(not game.help_open,"guide closes")
    while game.session.sim.clock.tick<600:game._physics_process(1.0/60.0)
    await settle()
    await click_target("visit:V02");await click(Vector2(1120,460));await click(Vector2(1120,460))
    while game.session.sim.clock.tick<1220:game._physics_process(1.0/60.0)
    await settle()
    check(game.session.sim.machines.machines.M02.state=="RESET_REQUIRED","real guest input reaches stuck claw")
    await drag(Vector2(1180,638),Vector2(365,380))
    check(game.session.sim.machines.machines.M02.state=="RESETTING","drag staff key starts real reset")
    check(game.session.sim.verify_invariants(),"drag service preserves item ownership")
    root.size=Vector2i(1600,900);await settle()
    # Canvas-items stretch maps 1600x900 physical coordinates to the 1280x720 layout.
    await click(Vector2(1195,38)*1.25);check(game.mode=="paused","scaled window click maps correctly")
    game.free();game=null;await create_timer(.25).timeout
    print("NEON_INPUT_CHECKS=%d PASSED=%d FAILED=%d"%[checks,checks-failures.size(),failures.size()])
    quit(0 if failures.is_empty() else 1)
