extends SceneTree
var checks := 0
var failures: Array[String] = []
const SESSION = preload("res://scripts/neon_shift/ShiftSession.gd")
func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition: failures.append(label);printerr("FAIL: "+label)
func _initialize() -> void:
    call_deferred("run")
func operate(s: NeonShiftSession) -> void:
    for kind in ["charge_cards","prepare_cassette"]:
        var job:=s.next_job(kind)
        if not job.is_empty(): s.act("start_production",{"job_id":job})
    if not s.ready_item("card").is_empty(): s.load_ready("card")
    if not s.ready_item("cassette").is_empty(): s.load_ready("cassette")
    if str(s.sim.machines.machines["M02"]["state"])=="RESET_REQUIRED" and s.sim.clock.tick>=int(s.sim.staff_jobs["J01"]["available_tick"]):
        if not s.sim.staff_started.has("J01"): s.act("staff_key",{"job_id":"J01"})
    if s.sim.clock.tick>=int(s.sim.staff_jobs["J02"]["available_tick"]) and str(s.sim.cart.slots["bulk_0"])!="" and not s.sim.staff_started.has("J02"):
        s.act("restock",{"job_id":"J02"})
    for id in s.available_visits():
        var a:=s.sim.customers.next_action(id)
        if not a.is_empty(): s.serve(id)
func run() -> void:
    for level in 3:
        var s: NeonShiftSession=SESSION.new();s.begin(level)
        check(s.sim.verify_invariants(),"initial ledger invariants shift %d"%level)
        check(not s.load_ready("card").ok,"unprepared card cannot enter cart")
        for t in int(s.sim.stage.duration_ticks):
            if t%6==0: operate(s)
            s.advance()
            if t%60==0: check(s.sim.verify_invariants(),"ledger invariants shift %d tick %d"%[level,t])
        var result:=s.summary()
        print("SHIFT_RESULT ",JSON.stringify(result))
        check(result.served==8,"all eight visitors served in shift %d"%level)
        check(result.stars==3,"three stars achievable in shift %d"%level)
        check(result.revenue==2700,"card sales recorded exactly once shift %d"%level)
        check(s.sim.ledger.owner_of("P005")=="customer:C08","refill prize delivered to final guest")
        check(s.sim.ledger.owner_of("P900")=="customer:C03","trade prize delivered")
        check(not s.act("purchase_card",{"visit_id":"V01"}).ok,"closed shift rejects new commands")
    var idle: NeonShiftSession=SESSION.new();idle.begin()
    for i in 7200: idle.advance()
    check(idle.summary().stars==0,"doing nothing earns zero stars")
    check(idle.summary().served==0,"unserved guests are not counted happy")
    var game=load("res://scenes/neon_shift/NeonShift.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_physics_process(false)
    check(game.mode=="title","game opens at shift selection")
    game.activate("start")
    check(game.mode=="playing","start action opens playable shift")
    game.activate("bench");game.activate("charge")
    check(game.session.sim.workshop.active.has("PB01"),"prep button starts real production")
    for i in 181: game._physics_process(1.0/60.0)
    game.activate("load_card")
    check(game.session.sim.cart.slots.supply_0=="CARD_BLANK_01","load button places charged card in cart")
    game.selected_visit="V01";game.activate("primary")
    check(game.session.sim.revenue_minor==500,"service button makes real sale")
    check(game.session.sim.cart.slots.supply_0=="","sold card leaves cart")
    game.activate("pause")
    var tick: int=game.session.sim.clock.tick
    game._physics_process(1.0/60.0)
    check(game.session.sim.clock.tick==tick,"pause freezes authoritative clock")
    game.activate("pause");game.activate("retry")
    check(game.session.sim.clock.tick==0 and game.session.sim.revenue_minor==0,"retry resets time and finances")
    check(game.session.sim.verify_invariants(),"retry restores valid initial ownership")
    game.queue_free()
    await create_timer(0.25).timeout
    print("NEON_SHIFT_CHECKS=%d PASSED=%d FAILED=%d" % [checks,checks-failures.size(),failures.size()])
    quit(0 if failures.is_empty() else 1)
