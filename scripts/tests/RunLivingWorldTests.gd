extends SceneTree
## Run with Godot 4.7.2 --headless --script res://scripts/tests/RunLivingWorldTests.gd
## Tests actual instantiated Sprite2D scenes and rendered state wiring, not PNG mockups.
var count: int = 0
var failures: Array = []

func check(ok: bool, label: String) -> void:
    count += 1
    if not ok:
        failures.append(label)
        printerr("LIVE_WORLD_FAIL: ",label)

func _initialize() -> void:
    call_deferred("run_living_tests")

func run_living_tests() -> void:
    var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    check(packed != null,"main scene loads")
    if packed == null:
        quit(1)
        return
    var main: GamePresentation = packed.instantiate() as GamePresentation
    root.add_child(main)
    await process_frame
    var sim: SimulationRoot = main.driver.simulation
    check(sim != null,"authoritative stage initialized")
    if sim == null:
        quit(1)
        return
    var aisle: ArcadeAisle = main.arcade
    var crowd: LiveCrowdDirector = aisle.living_crowd
    check(aisle.has_node("Crowd"),"crowd is an independent living sprite layer")
    check(crowd != null,"live crowd director connected")
    check(crowd.actors.size() == 8,"all authored customers have an actor")
    check(crowd.patrons.size() == 12,"12 independent background patrons")
    check(crowd.get_child_count() + aisle.get_node("FarCrowd").get_child_count() == 20,"20 simultaneous runtime character instances across depth layers")
    check(crowd.actors["V01"].visible,"future customer is already browsing the floor")
    check(crowd.actors["V01"].pose in ["CHAT","WALK"],"pre-arrival shopper has no request yet")
    var baseline: String = sim.state_digest()
    aisle.apply_snapshot(sim.game_snapshot())
    check(sim.state_digest() == baseline,"visual refresh cannot mutate gameplay state")
    for i in crowd.patrons.size():
        var p: LiveActor = crowd.patrons[i]
        check(p.body is Sprite2D,"background %d is a textured Sprite2D puppet" % i)
        check(p.body.texture != null,"background %d has imported pose frame" % i)
        check(p.shadow.texture != null,"background %d has an illuminated foot contact" % i)
    for vid in crowd.actors:
        var actor: LiveActor = crowd.actors[vid]
        check(actor.body is Sprite2D,vid+" has independent physical sprite")
        check(actor.patience_back is TextureProgressBar,vid+" has timeline-driven patience meter")
    var p0: LiveActor = crowd.patrons[0]
    var point_start: Vector2 = p0.position
    var texture_start: Texture2D = p0.body.texture
    var first_machine: MachineView = aisle.machine_nodes["M01"] as MachineView
    check(first_machine.loaded_items.size() == 1,"M01 renders its actual starting cassette contents")
    check(str(first_machine.loaded_items[0]["item"]) == "plush_mochi","M01 stock reflects exact authoritative SKU")
    for mid in ["M01","M02","M03","M04"]:
        var m: MachineView = aisle.machine_nodes[mid]
        check(m.has_node("StockHero"),mid+" has interactive visual stock sprite")
        check(m.has_node("ChutePrize"),mid+" has physical prize output visual")
        check(m.has_node("ActionSparkle"),mid+" has animated effect texture")
        check(m.get_node("GlowLight") is PointLight2D,mid+" has animated neon lighting")
        check(m.stock_sprites.size() >= 5,mid+" can display multiple cassette SKUs")
    # Advance only the approved simulation, never write directly to it from a visual actor.
    for t in range(1,165): sim.advance()
    main.bridge.publish()
    check(p0.position.distance_to(point_start) > 8.0,"background patron actually walks between stations")
    check(p0.body.texture != texture_start,"animated character uses different image frames")
    check(crowd.actors["V01"].visible,"first customer physically arrives")
    check(crowd.actors["V01"].pose in ["ARRIVE","REQUEST","QUEUE"],"customer first arrival triggers authored pose")
    var sprite: LiveActor = crowd.actors["V01"]
    var before_pose: Texture2D = sprite.body.texture
    sprite.render_at(166,Vector2(320,445),"CONCENTRATE")
    check(sprite.body.texture != before_pose,"playing uses distinct rendered pose frames")
    sprite.render_at(170,Vector2(320,445),"FRUSTRATED")
    check(sprite.pose == "FRUSTRATED","frustration is an authored animation state")
    sprite.render_at(171,Vector2(320,445),"CHEER")
    check(sprite.mood_label.text.contains("★"),"winners visibly react")
    sprite.render_at(175,Vector2(320,445),"HOLD_PRIZE","","plush_panda")
    check(sprite.carried.visible,"carrying a won prize displays physical prop")
    sprite.render_at(176,Vector2(320,445),"LEAVE")
    check(sprite.pose == "LEAVE","customer departure animated")
    var before_switch: int = sim.clock.tick
    main.switch_tab("workshop")
    main.switch_tab("arcade_floor")
    check(sim.clock.tick == before_switch,"tab changes never pause/advance time")
    check(sim.verify_invariants(),"living world does not corrupt validated inventory")
    print("LIVE_WORLD_ASSERTIONS=",count)
    print("LIVE_WORLD_FAILURES=",failures.size())
    if failures.is_empty():
        print("LIVE_WORLD_PASS")
        quit(0)
    else:
        print("LIVE_WORLD_FAIL ",failures)
        quit(1)
