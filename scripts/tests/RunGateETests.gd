extends SceneTree
## Run after '--headless --path . --import --quit'. No graphics required.
var assertions: int = 0
var failures: Array = []

func check(value: bool, label: String) -> void:
    assertions += 1
    if not value:
        failures.append(label)
        printerr("FAIL: " + label)

func _initialize() -> void:
    call_deferred("run_tests")

func run_tests() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    check(scene != null, "main scene imported")
    if scene == null:
        quit(1)
        return
    var main: GamePresentation = scene.instantiate() as GamePresentation
    root.add_child(main)
    await process_frame
    var driver: SimulationDriver = main.get_node("SimulationDriver")
    var bridge: PresentationBridge = main.get_node("PresentationBridge")
    var arcade: ArcadeAisle = main.get_node("ArcadeAisle")
    var workshop: BackstageWorkshop = main.get_node("BackstageWorkshop")
    var cart: ServiceCartUI = main.get_node("CartCanvas/ServiceCartUI")
    var hud: TopBarHUD = main.get_node("TopBarHUD")
    check(driver.simulation != null, "frozen Stage 1 simulation loads")
    check(bridge.driver == driver, "bridge connects to validated driver")
    check(hud.stage_title == "Opening Rush", "HUD title reads stage manifest")
    check(cart.slot_buttons.size() == 12, "4 cards + 2 gifts + 2 ribbons + 2 prizes + 1 cassette + tool")
    for mid in ["M01", "M02", "M03", "M04"]:
        var machine: MachineView = arcade.machine_nodes.get(mid) as MachineView
        check(machine != null, mid + " is instantiated")
        if machine != null:
            check(machine.art != null, mid + " has production illustration")
            check(machine.select_button != null, mid + " interaction button exists")
    check(arcade.visible and not workshop.visible, "arcade first-person default")
    var initial_tick: int = driver.simulation.clock.tick
    main.workshop_tab.pressed.emit()
    check(workshop.visible and not arcade.visible, "workshop tab signal controls presentation")
    check(driver.simulation.clock.tick == initial_tick, "tab switch did not advance or pause simulation")
    main.arcade_tab.pressed.emit()
    check(arcade.visible and not workshop.visible, "arcade tab signal controls presentation")
    check(not driver.simulation.clock.paused, "offscreen simulation stays unpaused")
    workshop.job_requested.emit("PB01")
    check(driver.simulation.workshop.active.has("PB01"), "workshop charging button reaches command gateway")
    # Advance enough for V01 arrival and PB01 to complete; no time or random reliance.
    while driver.simulation.clock.tick < 200:
        driver.simulation.advance()
    bridge.publish()
    check(driver.simulation.workshop.done.has("PB01"), "offscreen card production completed")
    check(hud.timer_label.text != "02:00", "HUD timer follows clock")
    arcade.customer_selected.emit("V01")
    check(main.selected_visit == "V01", "tap requests a card quote (no immediate sale)")
    check(driver.simulation.revenue_minor == 0, "quoted purchase does not mutate money")
    main.quote_popup.confirmed.emit()
    check(driver.simulation.revenue_minor == 500, "confirmed card sale credits money exactly once")
    check(int(driver.simulation.customers.customers["C01"]["credits"]) == 6, "card sale adds six credit units")
    arcade.customer_selected.emit("V01")
    check(int(driver.simulation.customers.customers["C01"]["credits"]) == 3, "admission debits three credits once")
    check(driver.simulation.machines.machines["M01"]["state"] == "PLAYING", "cabinet enters PLAYING")
    check(driver.simulation.revenue_minor == 500, "admission is not second revenue")
    check(bridge.last_snapshot["machines"]["machines"]["M01"]["state"] == "PLAYING", "UI uses authoritative snapshot")
    check(arcade.machine_nodes["M01"].status_label.text.contains("PLAYING"), "machine label responds to fixed tick snapshot")
    var bad: Dictionary = bridge.request_action("admit_session", {"visit_id": "V01"})
    check(not bool(bad["ok"]), "duplicate admission rejected by core")
    check(driver.simulation.revenue_minor == 500, "failed admission leaves sale amount intact")
    check(driver.simulation.verify_invariants(), "ledger invariants preserved by UI interactions")
    check(main.get_node("CartCanvas/ServiceCartUI").visible, "cart remains persistent across both tabs")
    for i in range(1, 9):
        check((load("res://art/customers/chibi_%02d.png" % i) as Texture2D) != null, "chibi portrait %d imported" % i)
    for station in ["charger", "wrapping", "cassette", "counter"]:
        check((load("res://art/stations/" + station + ".png") as Texture2D) != null, station + " illustrated workstation imported")
    print("GATE_E assertions: ", assertions)
    print("GATE_E failed: ", failures.size())
    if failures.is_empty():
        print("GATE_E_INTERACTION_SMOKE_PASS")
        quit(0)
    else:
        print("GATE_E_INTERACTION_SMOKE_FAIL ", failures)
        quit(1)
