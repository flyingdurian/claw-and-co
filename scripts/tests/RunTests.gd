extends SceneTree
## Invoke: godot --headless --path . --script res://scripts/tests/RunTests.gd
const Sim = preload("res://scripts/core/SimulationRoot.gd")
const Ledger = preload("res://scripts/core/InventoryLedger.gd")
const Carrier = preload("res://scripts/managers/CartManager.gd")
var failures: int = 0
var checks: int = 0

func test(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        printerr("FAIL %03d %s" % [checks, description])
    else:
        print("PASS %03d %s" % [checks, description])

func load_commands() -> Array:
    var doc: Dictionary = SchemaLoader.load_json("res://data/commands.stage1.json", "clawco.replay/v1")
    if doc.is_empty(): return []
    return doc.get("commands", [])

func run_replay(commands: Array, omit_area: bool = false) -> Dictionary:
    var sim: SimulationRoot = Sim.create()
    if sim == null: return {}
    var commands_by_tick: Dictionary = {}
    for cmd in commands:
        if omit_area and cmd["action"] == "switch_area": continue
        var t: int = int(cmd["tick"])
        if not commands_by_tick.has(t): commands_by_tick[t] = []
        commands_by_tick[t].append(cmd)
    for tick in range(7201):
        if tick > 0: sim.advance()
        for cmd in commands_by_tick.get(tick, []):
            if cmd["action"] == "purchase_card":
                var quote: Dictionary = sim.quote_card_purchase(str(cmd["payload"]["visit_id"]))
                test(bool(quote["ok"]), "card quote available before purchase %s" % cmd["command_id"])
                if not str(quote["intended_session_id"]).is_empty():
                    test(quote.has("machine_availability") and quote["machine_availability"].has("queue"), "quote discloses cabinet state and queue")
            var outcome: Dictionary = sim.command(str(cmd["command_id"]), str(cmd["action"]), cmd["payload"])
            test(bool(outcome["ok"]) == bool(cmd["expect_ok"]), "command %s @tick %d => %s" % [cmd["command_id"], tick, outcome["reason"]])
        if tick % 60 == 0: test(sim.verify_invariants(), "inventory/credit/cart invariants at second %d" % int(tick / 60))
    test(sim.clock.tick == 7200, "120s equals exactly 7200 simulation ticks")
    return {"sim": sim, "digest": sim.state_digest()}

func test_failure_rollbacks() -> void:
    var sim: SimulationRoot = Sim.create()
    for i in range(120): sim.advance()
    var before: Dictionary = sim.ledger.snapshot()
    var result: Dictionary = sim.machines.admit("S01", sim.clock.tick)
    test(not result["ok"] and result["reason"] == "INSUFFICIENT_CREDITS", "admission rejects insufficient balance")
    test(JSON.stringify(before) == JSON.stringify(sim.ledger.snapshot()), "failed admission preserves full inventory ledger")
    test(int(sim.customers.customers["C01"]["credits"]) == 0, "failed admission leaves balance untouched")
    sim.customers.customers["C01"]["credits"] = 6
    test(sim.ledger.reserve("P001", "cassette:K01", "CONFLICT"), "exclusive reservation can be claimed")
    var before_claim: Dictionary = sim.ledger.snapshot()
    result = sim.machines.admit("S01", sim.clock.tick)
    test(not result["ok"] and result["reason"] == "PRIZE_RESERVED", "admission detects exact-prize reservation")
    test(JSON.stringify(before_claim) == JSON.stringify(sim.ledger.snapshot()), "prize-conflict admission cannot change inventory")
    test(int(sim.customers.customers["C01"]["credits"]) == 6, "prize-conflict admission cannot debit balance")
    test(sim.ledger.release("P001", "CONFLICT"), "conflict cleanup succeeds")
    result = sim.machines.admit("S01", sim.clock.tick)
    test(result["ok"], "normal admission succeeds after conflict removed")
    test(sim.ledger.reservation_of("P001") == "S01" and sim.customers.customers["C01"]["credits"] == 3, "admission reserves prize and debits credits exactly once")
    result = sim.machines.admit("S01", sim.clock.tick)
    test(not result["ok"] and sim.customers.customers["C01"]["credits"] == 3, "duplicate admission never double-debits")
    test(sim.machines.start_changeover("M01", "K05", sim.clock.tick)["reason"] == "CABINET_BUSY_OR_OUTPUT_HELD", "restock prohibited during active session")
    test(sim.verify_invariants(), "failed-action cases leave system internally consistent")

func test_cart_capacity() -> void:
    var ledger := Ledger.new()
    var defs: Dictionary = {"card_starter": {"kind": "card"}, "plush_mochi": {"kind": "plush"}, "cassette_plush": {"kind": "cassette"}}
    var cart := Carrier.new(ledger, defs)
    for i in range(5): ledger.register_item("CARD_%d" % i, "card_starter", "workshop")
    for i in range(3): ledger.register_item("PRIZE_%d" % i, "plush_mochi", "workshop")
    for i in range(2): ledger.register_item("KIT_%d" % i, "cassette_plush", "machine_bay")
    for i in range(4): test(cart.pickup("CARD_%d" % i, "workshop", "supply_%d" % i), "supply slot %d accepts card" % i)
    test(not cart.pickup("CARD_4", "workshop", "supply_0"), "fifth supply item denied")
    for i in range(2): test(cart.pickup("PRIZE_%d" % i, "workshop", "prize_%d" % i), "prize pocket %d accepts prize" % i)
    test(not cart.pickup("PRIZE_2", "workshop", "prize_0"), "third prize item denied")
    test(cart.pickup("KIT_0", "machine_bay", "bulk_0"), "single bulk cassette accepted")
    test(not cart.pickup("KIT_1", "machine_bay", "bulk_0"), "second bulk cassette denied")
    test(not cart.pickup("PRIZE_2", "workshop", "supply_0"), "wrong item type denied")
    test(ledger.verify(), "cart capacity tests preserve unique ownership")

func test_output_block(commands: Array) -> void:
    var sim: SimulationRoot = Sim.create()
    var by_tick: Dictionary = {}
    for cmd in commands:
        if int(cmd["tick"]) > 510: continue
        if not by_tick.has(int(cmd["tick"])): by_tick[int(cmd["tick"])] = []
        by_tick[int(cmd["tick"])].append(cmd)
    for t in range(511):
        if t > 0: sim.advance()
        for cmd in by_tick.get(t, []): sim.command(str(cmd["command_id"]), str(cmd["action"]), cmd["payload"])
    test(sim.machines.machines["M01"]["state"] == "OUTPUT_HELD", "prize output is physically occupied")
    test(sim.machines.start_changeover("M01", "K05", sim.clock.tick)["reason"] == "CABINET_BUSY_OR_OUTPUT_HELD", "occupied hatch blocks restocking")

func test_idempotent_sale() -> void:
    var sim: SimulationRoot = Sim.create()
    for t in range(200):
        sim.advance()
        if t == 0: sim.command("charge", "start_production", {"job_id": "PB01"})
    var first: Dictionary = sim.command("CARD-TXN-01", "purchase_card", {"visit_id": "V01"})
    var second: Dictionary = sim.command("CARD-TXN-01", "purchase_card", {"visit_id": "V01"})
    test(first["ok"] and second["ok"], "duplicate command returns cached purchase response")
    test(sim.revenue_minor == 500 and sim.customers.customers["C01"]["credits"] == 6, "card sale generates one payment and one credit grant")
    var third: Dictionary = sim.command("CARD-TXN-02", "purchase_card", {"visit_id": "V01"})
    test(not third["ok"] and sim.revenue_minor == 500, "new duplicate purchase command is rejected without revenue")

func without_command_results(snapshot: Dictionary) -> Dictionary:
    var copy: Dictionary = snapshot.duplicate(true)
    copy.erase("command_results")
    return copy

func _initialize() -> void:
    print("=== CLAW & CO. GODOT 4.7.2 — GATES A-D HEADLESS TESTS ===")
    var commands: Array = load_commands()
    test(commands.size() >= 20, "authored input timeline loaded")
    test_failure_rollbacks()
    test_cart_capacity()
    test_output_block(commands)
    test_idempotent_sale()
    var first: Dictionary = run_replay(commands)
    var second: Dictionary = run_replay(commands)
    var area_independent: Dictionary = run_replay(commands, true)
    if not first.is_empty() and not second.is_empty() and not area_independent.is_empty():
        var sim: SimulationRoot = first["sim"]
        test(first["digest"] == second["digest"], "identical 7200-tick command streams produce identical SHA256 state digest")
        test(JSON.stringify(without_command_results(sim.game_snapshot())) == JSON.stringify(without_command_results(area_independent["sim"].game_snapshot())), "offscreen/area changes cannot alter simulation outcomes")
        test(sim.revenue_minor == 2700 and sim.cash_minor == 4700, "only six card purchases create CAD 27.00 revenue")
        test(sim.customers.completed_steps == 13 and sim.customers.stars() == 3, "eight visits finish thirteen steps and earn three stars")
        test(sim.machines.completed_sessions == {"S01": "win", "S02": "win", "S03": "miss", "S04": "win", "S05": "win"}, "all five authored session outcomes match")
        test(sim.ledger.owner_of("P003") == "cassette:K03" and sim.ledger.reservation_of("P003").is_empty(), "Barber Cut miss releases claim without removing prize")
        test(sim.customers.customers["C05"]["patience"] == 2, "Barber Cut missed attempt updates patience")
        test(sim.machines.machines["M03"]["state"] == "READY", "Barber Cut returns READY after terminal miss")
        test(sim.ledger.owner_of("P900") == "customer:C03", "trade-up delivers exactly one grand prize")
        test(sim.ledger.owner_of("BOX_01").begins_with("consumed:") and sim.ledger.owner_of("RIBBON_01").begins_with("consumed:"), "gift-wrapping consumes box and ribbon once")
        test(sim.ledger.owner_of("P401") == "customer:C04", "wrapped original figure returns to its customer")
        test(sim.machines.machines["M01"]["cassette"] == "K05", "M01 receives K05 cassette from cart")
        test(sim.workshop.done.size() == 6, "three charging, one cassette preparation, gift-wrap, trade-up all complete")
        var reset_start: int = -1
        var reset_done: int = -1
        for e in sim.machines.events:
            if e["kind"] == "STAFF_RESET_STARTED": reset_start = int(e["tick"])
            if e["kind"] == "STAFF_RESET_DONE_NEXT_ATTEMPT": reset_done = int(e["tick"])
        test(reset_start == 1200 and reset_done == 1290, "Staff Key reset lasts exactly 90 ticks (1.5s)")
        test(sim.machines.machines["M02"]["aligned_for_win"] == true, "Staff Key reset aligns target to drop zone")
        test(sim.verify_invariants(), "final atomic ownership and accounting invariants")
        print("FINAL_SHA256=" + str(first["digest"]))
        print("FINAL_SCORE=%d STARS=%d REVENUE_MINOR=%d" % [sim.customers.score, sim.customers.stars(), sim.revenue_minor])
    if failures == 0:
        print("ALL TESTS PASSED (%d assertions; 7200 ticks per full replay)" % checks)
        quit(0)
    else:
        printerr("TESTS FAILED %d/%d assertions" % [failures, checks])
        quit(1)
