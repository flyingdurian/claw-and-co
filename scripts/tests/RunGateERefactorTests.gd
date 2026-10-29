extends SceneTree
## Real Godot scene / UI integration tests. Execute under 4.7.2 after import.
var checks: int = 0
var failed: Array = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failed.append(label)
        printerr("FAIL: ", label)

func _initialize() -> void:
    call_deferred("run_gate_e_refactor")

func run_gate_e_refactor() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    check(scene != null, "main scene imports")
    if scene == null:
        quit(1)
        return
    var main: GamePresentation = scene.instantiate() as GamePresentation
    root.add_child(main)
    await process_frame
    var sim: SimulationRoot = main.driver.simulation
    var bridge: PresentationBridge = main.bridge
    var cart: ServiceCartUI = main.cart
    var aisle: ArcadeAisle = main.arcade
    var shop: BackstageWorkshop = main.workshop
    check(sim != null, "authoritative sim initialized")
    if sim == null:
        quit(1)
        return
    check(sim.clock.tick < 10, "stage starts at fixed simulation tick 0")
    check(cart.slot_buttons.size() == 12, "11 physical slots + 1 permanent tool")
    check(ServiceCartUI.SLOTS.size() == 11, "precise tray slot contract")
    check(sim.cart.slots.size() == 11, "presentation and ledger cart agree")
    check(main.has_node("CartCanvas/ServiceCartUI"), "cart lives in CanvasLayer")
    check(main.has_node("WorldEnvironment"), "HDR environment node")
    check(aisle.has_node("ParallaxBackground/ParallaxLayer/IllustratedArcade"), "photographic aisle background")
    check(shop.has_node("ParallaxBackground/Layer/IllustratedWorkshop"), "photographic workshop background")
    check(shop.has_node("ChargerGlow"), "workshop PointLight2D")
    for mid in ["M01", "M02", "M03", "M04"]:
        var machine: MachineView = aisle.machine_nodes[mid]
        check(machine != null, mid + " machine instance")
        if machine == null: continue
        check(machine.art != null, mid + " full resolution base body")
        check(machine.get_node("BaseBody") is Sprite2D, mid + " body is Sprite2D")
        check(machine.get_node("PrizeInterior") is Sprite2D, mid + " prize interior is Sprite2D")
        check(machine.get_node("Mechanism") is Sprite2D, mid + " mechanism is Sprite2D")
        check(machine.get_node("SpecularGlassOverlay") is Sprite2D, mid + " real specular texture")
        check(machine.get_node("NeonMarquee") is Sprite2D, mid + " marquee is Sprite2D")
        check(machine.get_node("GlowLight") is PointLight2D, mid + " bloom light")
    for slot in ServiceCartUI.SLOTS:
        check(sim.cart.slots.has(slot), slot + " ledger slot exists")
        check(cart.slot_buttons.has(slot), slot + " clickable button exists")
        check(cart.slot_icons.has(slot), slot + " dedicated icon exists")
        check(str(sim.cart.slots[slot]).is_empty(), slot + " begins empty")
    check(cart.slot_buttons.has("staff_key"), "permanent Staff Key tool")
    check(not cart.slot_labels["staff_key"].visible, "Staff Key never displays EMPTY")
    check(main.selected_cart_slot.is_empty(), "no tool or item selected at start")
    var no_mutation_before: String = sim.state_digest()
    (cart.slot_buttons["supply_0"] as Button).pressed.emit()
    check(main.selected_cart_slot.is_empty(), "empty pocket cannot be carried")
    check(sim.state_digest() == no_mutation_before, "clicking empty slot does not mutate simulation")
    # Workshop supply: charge individual physical card, then load selected instance into first card pocket.
    shop.job_requested.emit("PB01")
    check(sim.workshop.active.has("PB01"), "Card Multi-Charger command connected")
    while sim.clock.tick < 200:
        sim.advance()
    bridge.publish()
    check(sim.workshop.done.has("PB01"), "offscreen charger completes")
    main.switch_tab("workshop")
    check(shop.visible and not aisle.visible, "workshop visible after area change")
    var before_load: int = sim.clock.tick
    shop.get_node("LoadCardButton").pressed.emit()
    var loaded_card: String = str(sim.cart.slots.get("supply_0", ""))
    check(loaded_card == "CARD_BLANK_01", "first exact charged IC card transferred to pocket")
    check(sim.ledger.owner_of(loaded_card) == "cart:supply_0", "single authoritative owner for loaded card")
    check(sim.clock.tick == before_load, "loading card does not advance game clock")
    bridge.publish()
    check(cart.slot_icons["supply_0"].texture != null, "loaded card has physical sprite")
    (cart.slot_buttons["supply_0"] as Button).pressed.emit()
    check(main.selected_cart_slot == "supply_0", "touch selects one exact physical card")
    check(sim.cart.slots["supply_0"] == loaded_card, "selection does not prematurely remove item")
    check(cart.slot_glows["supply_0"].visible, "selected card has tactile highlight")
    main.switch_tab("arcade_floor")
    check(main.selected_cart_slot == "supply_0", "selection persists across areas")
    aisle.customer_selected.emit("V01")
    check(main.selected_visit == "V01", "customer touch requests availability quote")
    check(sim.revenue_minor == 0, "quote never creates revenue")
    main.quote_popup.confirmed.emit()
    check(sim.cart.slots["supply_0"] == "", "successful card sale empties exact clicked slot")
    check(sim.ledger.owner_of(loaded_card) == "customer:C01", "card delivered to actual intended customer")
    check(sim.revenue_minor == 500, "sale creates exactly CAD $5.00 revenue")
    check(int(sim.customers.customers["C01"]["credits"]) == 6, "card credits loaded once")
    check(main.selected_cart_slot.is_empty(), "selection clears on successful delivery")
    aisle.customer_selected.emit("V01")
    check(sim.machines.machines["M01"]["state"] == "PLAYING", "customer starts machine attempt")
    check(int(sim.customers.customers["C01"]["credits"]) == 3, "admission debits exactly once")
    check(sim.revenue_minor == 500, "admission creates no duplicate revenue")
    check(sim.verify_invariants(), "click to sell, admit preserves ledger invariants")
    # Finishing inventory uses TWO gift pockets and TWO ribbon pockets, never phantom stacks.
    main.switch_tab("workshop")
    shop.get_node("LoadGiftButton").pressed.emit()
    shop.get_node("LoadRibbonButton").pressed.emit()
    check(str(sim.cart.slots["gift_0"]) == "BOX_01", "gift box occupies one dedicated slot")
    check(str(sim.cart.slots["ribbon_0"]) == "RIBBON_01", "ribbon occupies one dedicated slot")
    check(str(sim.cart.slots["gift_1"]).is_empty(), "second gift pocket remains physically empty")
    check(str(sim.cart.slots["ribbon_1"]).is_empty(), "second ribbon pocket remains physically empty")
    check(sim.verify_invariants(), "gift/ribbon pickup uses atomic ownership transfer")
    # Explicitly deliver finishing items back to wrapping station before processing.
    while sim.clock.tick < 1940:
        sim.advance()
    bridge.publish()
    (cart.slot_buttons["gift_0"] as Button).pressed.emit()
    shop.wrap_requested.emit("V04")
    check(str(sim.cart.slots["gift_0"]).is_empty(), "gift material delivery empties selected slot")
    check(sim.ledger.owner_of("BOX_01") == "workshop", "gift box now physically owned by wrapping bench")
    (cart.slot_buttons["ribbon_0"] as Button).pressed.emit()
    shop.wrap_requested.emit("V04")
    check(str(sim.cart.slots["ribbon_0"]).is_empty(), "ribbon material delivery empties selected slot")
    check(sim.ledger.owner_of("RIBBON_01") == "workshop", "ribbon now physically owned by wrapping bench")
    shop.wrap_requested.emit("V04")
    check(sim.workshop.active.has("WRAP:V04"), "re-loaded real materials start gift-wrap")
    check(sim.verify_invariants(), "wrap operation remains atomic")
    # M02 Staff Key reset hop derives from authoritative 90-tick deadline.
    check(cart.slot_icons["staff_key"].texture != null, "permanent staff key has illustrated sprite")
    main.switch_tab("arcade_floor")
    (cart.slot_buttons["staff_key"] as Button).pressed.emit()
    check(main.selected_cart_slot == "staff_key", "Staff Key selected")
    aisle.machine_nodes["M01"].cabinet_selected.emit("M01")
    check(main.selected_cart_slot == "staff_key", "wrong target does not consume Staff Key selection")
    check(sim.verify_invariants(), "invalid Staff Key target does not mutate inventory")
    # switching views must not advance or pause clock.
    var tab_tick: int = sim.clock.tick
    main.switch_tab("workshop")
    main.switch_tab("arcade_floor")
    check(sim.clock.tick == tab_tick, "two view switches never advance fixed ticks")
    check(not sim.clock.paused, "60Hz simulation stays running when areas change")
    check(sim.verify_invariants(), "full interaction sequence preserves inventory ownership")
    print("GATE_E_REFACTOR_ASSERTIONS=", checks)
    print("GATE_E_REFACTOR_FAILURES=", failed.size())
    if failed.is_empty():
        print("GATE_E_REFACTOR_PASS")
        quit(0)
    else:
        print("GATE_E_REFACTOR_FAIL ", failed)
        quit(1)
