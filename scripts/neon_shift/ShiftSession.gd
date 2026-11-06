class_name NeonShiftSession
extends RefCounted
## Adapts the existing authoritative simulation. All item/money actions use command().
const NAMES := {"V01":"Mika", "V02":"Ren", "V03":"Yuki", "V04":"Hana", "V05":"Sora", "V06":"Kai", "V07":"Aoi", "V08":"Momo"}
const TITLES := ["Opening Shift", "Evening Rush", "Last Train"]
var sim: SimulationRoot
var serial := 0
var shift_index := 0
var events: Array[Dictionary] = []
var results: Dictionary = {}
var last_steps := 0

func begin(index: int = 0) -> void:
    shift_index = clampi(index, 0, 2)
    var bundle: Dictionary = SchemaLoader.load_stage().duplicate(true)
    var rate: float = [1.0, 0.84, 0.70][shift_index]
    var stage: Dictionary = bundle["stage"]
    stage["duration_ticks"] = roundi(float(stage["duration_ticks"]) * rate)
    # Difficulty changes authored schedules, never transaction rules or outcomes.
    for wave in stage["waves"]:
        wave["start_tick"] = roundi(float(wave["start_tick"]) * rate)
        for visit in wave["visits"]:
            visit["arrival_tick"] = roundi(float(visit["arrival_tick"]) * rate)
            visit["deadline_tick"] = roundi(float(visit["deadline_tick"]) * rate)
    for job in stage["production_jobs"]:
        job["available_tick"] = roundi(float(job["available_tick"]) * rate)
    for job in stage["staff_jobs"]:
        job["available_tick"] = roundi(float(job["available_tick"]) * rate)
        job["deadline_tick"] = roundi(float(job["deadline_tick"]) * rate)
    sim = SimulationRoot.new()
    sim.setup(bundle)
    serial = 0
    last_steps = 0
    events.clear()
    results.clear()

func act(action: String, payload: Dictionary = {}) -> Dictionary:
    if sim == null or finished(): return {"ok":false, "reason":"SHIFT_CLOSED"}
    serial += 1
    var result: Dictionary = sim.command("neon_%d_%d" % [sim.clock.tick, serial], action, payload)
    events.append({"action":action, "result":result, "tick":sim.clock.tick})
    return result

func advance() -> void:
    if not finished(): sim.advance()

func finished() -> bool:
    return sim != null and sim.clock.tick >= int(sim.stage["duration_ticks"])

func remaining_seconds() -> int:
    return maxi(0, ceili(float(int(sim.stage["duration_ticks"]) - sim.clock.tick) / 60.0))

func available_visits() -> Array[String]:
    var ids: Array[String] = []
    for id in sim.customers.visit_order:
        var visit: Dictionary = sim.customers.visits[id]
        if sim.customers.arrived.has(id) and str(visit["state"]) != "COMPLETE": ids.append(str(id))
    ids.sort_custom(func(a: String,b: String) -> bool:
        return int(sim.customers.visits[a]["definition"]["deadline_tick"]) < int(sim.customers.visits[b]["definition"]["deadline_tick"]))
    return ids

func visit_machine(id: String) -> String:
    if not sim.customers.visits.has(id): return ""
    for step in sim.customers.visits[id]["definition"]["steps"]:
        var sid: String = str(step.get("session_id", step.get("intended_session_id", "")))
        if sim.machines.sessions.has(sid): return str(sim.machines.sessions[sid]["machine_id"])
    return ""

func next_job(kind: String) -> String:
    for id in sim.workshop.jobs:
        var job: Dictionary = sim.workshop.jobs[id]
        if str(job["kind"]) == kind and sim.clock.tick >= int(job["available_tick"]) and not sim.workshop.active.has(id) and not sim.workshop.done.has(id): return str(id)
    return ""

func ready_item(kind: String) -> String:
    var source := "workshop:ready" if kind == "card" else "machine_bay:ready"
    for id in sim.ledger.items_at(source):
        if str(sim.content["items"].get(sim.ledger.item_of(str(id)), {}).get("kind", "")) == kind: return str(id)
    return ""

func load_ready(kind: String) -> Dictionary:
    var id := ready_item(kind)
    if id.is_empty(): return {"ok":false,"reason":"NOT_PREPARED"}
    var source := "workshop:ready" if kind == "card" else "machine_bay:ready"
    var candidates: Array = ["supply_0","supply_1","supply_2","supply_3"] if kind == "card" else ["bulk_0"]
    for slot in candidates:
        if str(sim.cart.slots[slot]).is_empty(): return act("pickup_cart", {"instance_id":id,"from":source,"slot":slot})
    return {"ok":false,"reason":"CART_FULL"}

func serve(id: String) -> Dictionary:
    var action := sim.customers.next_action(id)
    if action.is_empty(): return {"ok":false,"reason":"SERVICE_IN_PROGRESS"}
    var payload: Dictionary = {"visit_id":id}
    if action == "purchase_card":
        var quote: Dictionary = sim.quote_card_purchase(id)
        if not bool(quote.get("ok",false)): return quote
        if str(quote.get("offer_id", "")) == "offer_starter":
            for slot in ["supply_0","supply_1","supply_2","supply_3"]:
                if not str(sim.cart.slots[slot]).is_empty():
                    payload["cart_slot"] = slot
                    break
    return act(action, payload)

func summary() -> Dictionary:
    var served := 0
    for visit in sim.customers.visits.values():
        if str(visit["state"]) == "COMPLETE": served += 1
    return {"shift":shift_index, "score":sim.customers.score, "stars":sim.customers.stars(), "served":served, "total":sim.customers.visits.size(), "revenue":sim.revenue_minor, "steps":sim.customers.completed_steps, "digest":sim.state_digest()}
