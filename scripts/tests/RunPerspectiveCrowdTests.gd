extends SceneTree
## R4 depth-geometry contract tests, run using --headless --script.
const ROUTES = preload("res://scripts/presentation/PerspectiveCrowdRoutes.gd")
var total: int = 0
var failures: Array = []
func check(ok: bool, msg: String) -> void:
    total += 1
    if not ok:
        failures.append(msg)
        printerr("R4_DEPTH_FAIL: ",msg)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    check(ROUTES.sprite_scale(530.0) > ROUTES.sprite_scale(265.0)*3.0,"pedestrian grows over 3x from far to near")
    check(ROUTES.depth_for_y(245.0)==0.0,"vanishing plane mapped to depth zero")
    check(ROUTES.depth_for_y(540.0)==1.0,"foreground plane mapped to depth one")
    for i in range(12):
        var far: Dictionary = ROUTES.ambient_pose(0,i)
        var first: Dictionary = ROUTES.ambient_pose(10,i)
        var same: Dictionary = ROUTES.ambient_pose(10,i)
        check(first == same,"actor %d route is deterministic" % i)
        check((far["position"] as Vector2).x >= -100.0 and (far["position"] as Vector2).x <= 1400.0,"actor %d stays within authored perspective lanes" % i)
        var seen_near: bool = false
        var seen_far: bool = false
        for t in range(0,1800,18):
            var at: Dictionary = ROUTES.ambient_pose(t,i)
            seen_near = seen_near or at["near"]
            seen_far = seen_far or not at["near"]
        check(seen_far and seen_near,"actor %d enters foreground and returns to deep arcade" % i)
    var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    check(packed != null,"main scene loads")
    if packed != null:
        var main: GamePresentation = packed.instantiate() as GamePresentation
        root.add_child(main)
        await process_frame
        check(main.arcade.get_node("FarCrowd") is Node2D,"far crowd has independent occlusion layer")
        var before: String = main.driver.simulation.state_digest()
        main.arcade.apply_snapshot(main.driver.simulation.game_snapshot())
        check(main.driver.simulation.state_digest()==before,"crowd doesn't mutate simulation state")
        var first_card: CustomerView = main.arcade.customer_nodes["M01"]
        check(not first_card.visible,"no bubble for non-arrived customer")
        main.queue_free()
    print("R4_DEPTH_ASSERTIONS=",total)
    print("R4_DEPTH_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
