class_name WorkshopManager
extends RefCounted
var jobs: Dictionary = {}
var active: Dictionary = {}
var done: Dictionary = {}
var ledger: InventoryLedger
var customers: CustomerManager
var trade_rules: Dictionary = {}
var tick_events: Array = []

func _init(stage: Dictionary, p_ledger: InventoryLedger, p_customers: CustomerManager) -> void:
    ledger = p_ledger
    customers = p_customers
    for job in stage["production_jobs"]: jobs[job["job_id"]] = job
    for rule in stage["tradeup_rules"]: trade_rules[rule["rule_id"]] = rule

func start_production(job_id: String, tick: int) -> Dictionary:
    if not jobs.has(job_id): return {"ok": false, "reason": "UNKNOWN_JOB"}
    var job: Dictionary = jobs[job_id]
    if tick < int(job["available_tick"]): return {"ok": false, "reason": "NOT_AVAILABLE"}
    if active.has(job_id) or done.has(job_id): return {"ok": false, "reason": "ALREADY_STARTED"}
    var src: String = "workshop" if job["kind"] == "charge_cards" else "machine_bay"
    var ops: Array = []
    for item in job["input_items"]:
        ops.append({"id": item["instance_id"], "from": src, "to": "production:" + job_id})
    if not ledger.transfer_many(ops): return {"ok": false, "reason": "INPUT_UNAVAILABLE"}
    active[job_id] = {"kind": job["kind"], "due": tick + int(job["duration_ticks"]), "items": job["input_items"], "visit": ""}
    tick_events.append({"tick": tick, "kind": "PRODUCTION_STARTED", "job": job_id})
    return {"ok": true, "reason": "OK"}

func start_wrap(visit_id: String, tick: int) -> Dictionary:
    if customers.next_action(visit_id) != "gift_wrap": return {"ok": false, "reason": "NOT_CURRENT_STEP"}
    var v: Dictionary = customers.visits[visit_id]["definition"]
    var c: String = str(v["customer_id"])
    var step: Dictionary = v["steps"][int(customers.visits[visit_id]["next"])]
    var job_id: String = "WRAP:" + visit_id
    var ops: Array = [
        {"id": step["prize_instance_id"], "from": "customer:" + c, "to": "production:" + job_id},
        {"id": step["gift_box_id"], "from": "workshop", "to": "production:" + job_id},
        {"id": step["ribbon_id"], "from": "workshop", "to": "production:" + job_id}
    ]
    if not ledger.transfer_many(ops): return {"ok": false, "reason": "WRAP_INPUT_UNAVAILABLE"}
    var _commit_42: bool = customers.begin_step(visit_id, "gift_wrap")
    assert(_commit_42)
    active[job_id] = {"kind": "gift_wrap", "due": tick + int(step["duration_ticks"]), "prize": step["prize_instance_id"], "consumed": [step["gift_box_id"], step["ribbon_id"]], "customer": c, "visit": visit_id}
    return {"ok": true, "reason": "OK"}

func start_trade(visit_id: String, tick: int) -> Dictionary:
    if customers.next_action(visit_id) != "trade_up": return {"ok": false, "reason": "NOT_CURRENT_STEP"}
    var v: Dictionary = customers.visits[visit_id]["definition"]
    var c: String = str(v["customer_id"])
    var step: Dictionary = v["steps"][int(customers.visits[visit_id]["next"])]
    var rule: Dictionary = trade_rules[step["rule_id"]]
    var owned: Array = []
    for id in ledger.items_at("customer:" + c):
        if ledger.item_of(str(id)) == rule["input_item_id"]: owned.append(id)
    if owned.size() < int(rule["input_count"]): return {"ok": false, "reason": "INSUFFICIENT_TRADE_ITEMS"}
    var job_id: String = "TRADE:" + visit_id
    var ops: Array = []
    for i in range(int(rule["input_count"])):
        ops.append({"id": owned[i], "from": "customer:" + c, "to": "production:" + job_id})
    ops.append({"id": rule["output_instance_id"], "from": "trade_counter", "to": "production:" + job_id})
    if not ledger.transfer_many(ops): return {"ok": false, "reason": "TRADE_INPUT_UNAVAILABLE"}
    var _commit_62: bool = customers.begin_step(visit_id, "trade_up")
    assert(_commit_62)
    active[job_id] = {"kind": "trade_up", "due": tick + int(step["duration_ticks"]), "consumed": owned.slice(0, int(rule["input_count"])), "prize": rule["output_instance_id"], "customer": c, "visit": visit_id}
    return {"ok": true, "reason": "OK"}

func advance(tick: int) -> void:
    var keys: Array = active.keys()
    keys.sort()
    for job_id in keys:
        var job: Dictionary = active[job_id]
        if tick < int(job["due"]): continue
        var kind: String = str(job["kind"])
        if kind in ["charge_cards", "prepare_cassette"]:
            var destination: String = "workshop:ready" if kind == "charge_cards" else "machine_bay:ready"
            var ops: Array = []
            for item in job["items"]:
                ops.append({"id": item["instance_id"], "from": "production:" + str(job_id), "to": destination})
            var _commit_78: bool = ledger.transfer_many(ops)
            assert(_commit_78)
            if kind == "charge_cards":
                for item in job["items"]: ledger.set_item_metadata(str(item["instance_id"]), "charged", true)
        elif kind in ["gift_wrap", "trade_up"]:
            var ops: Array = [{"id": job["prize"], "from": "production:" + str(job_id), "to": "customer:" + str(job["customer"])}]
            for id in job["consumed"]:
                ops.append({"id": id, "from": "production:" + str(job_id), "to": "consumed:" + str(job_id)})
            var _commit_85: bool = ledger.transfer_many(ops)
            assert(_commit_85)
            var _commit_86: bool = customers.finish_step(str(job["visit"]), kind, tick)
            assert(_commit_86)
        done[job_id] = tick
        active.erase(job_id)
        tick_events.append({"tick": tick, "kind": "PRODUCTION_DONE", "job": job_id})

func snapshot() -> Dictionary:
    return {"active": active.duplicate(true), "done": done.duplicate(true)}
