class_name CustomerManager
extends RefCounted
var customers: Dictionary = {}
var visits: Dictionary = {}
var visit_order: Array = []
var queues: Dictionary = {}
var stages: Dictionary = {}
var offers: Dictionary = {}
var score: int = 0
var completed_steps: int = 0
var wave_events: Array = []
var spectator_count: int = 0
var scoring: Dictionary
var emitted_waves: Dictionary = {}
var arrived: Dictionary = {}

func _init(stage: Dictionary) -> void:
    scoring = stage["scoring"]
    for acc in stage["customer_accounts"]:
        customers[acc["customer_id"]] = {"credits": int(acc["initial_credits"]), "card": acc["card_instance_id"], "state": "NOT_ARRIVED", "patience": 3}
    for m in stage["cabinet_instances"]: queues[m["machine_id"]] = []
    for off in stage["offers"]: offers[off["offer_id"]] = off
    for wave in stage["waves"]:
        wave_events.append(wave)
        for v in wave["visits"]:
            visits[v["visit_id"]] = {"definition": v, "next": 0, "state": "SCHEDULED", "active_step": ""}
            visit_order.append(v["visit_id"])
    visit_order.sort()

func advance(tick: int, sessions: Dictionary) -> void:
    for wave in wave_events:
        if int(wave["start_tick"]) == tick and not emitted_waves.has(wave["wave_id"]):
            emitted_waves[wave["wave_id"]] = true
            spectator_count += int(wave["spectator_count"])
    for vid in visit_order:
        var v: Dictionary = visits[vid]["definition"]
        if int(v["arrival_tick"]) != tick or arrived.has(vid): continue
        arrived[vid] = true
        visits[vid]["state"] = "WAITING_FOR_SERVICE"
        customers[v["customer_id"]]["state"] = "WAITING_FOR_SERVICE"
        for step in v["steps"]:
            var sid: String = str(step.get("session_id", step.get("intended_session_id", "")))
            if not sid.is_empty() and sessions.has(sid):
                var machine_id: String = str(sessions[sid]["machine_id"])
                queues[machine_id].append(v["customer_id"])
                customers[v["customer_id"]]["state"] = "WAITING_FOR_CABINET"
                break

func next_action(visit_id: String) -> String:
    if not arrived.has(visit_id): return ""
    var v: Dictionary = visits.get(visit_id, {})
    if v.is_empty() or not str(v["active_step"]).is_empty(): return ""
    var i: int = int(v["next"])
    if i >= v["definition"]["steps"].size(): return ""
    return str(v["definition"]["steps"][i]["action"])

func begin_step(visit_id: String, action: String) -> bool:
    if next_action(visit_id) != action: return false
    visits[visit_id]["active_step"] = action
    return true

func finish_step(visit_id: String, action: String, tick: int) -> bool:
    if not visits.has(visit_id) or visits[visit_id]["active_step"] != action: return false
    var v: Dictionary = visits[visit_id]
    v["active_step"] = ""
    v["next"] = int(v["next"]) + 1
    var deadline: int = int(v["definition"]["deadline_tick"])
    score += int(scoring["on_time_step"] if tick <= deadline else scoring["late_step"])
    if action == "gift_wrap": score += int(scoring["perfect_wrap_bonus"])
    if action == "trade_up": score += int(scoring["correct_tradeup_bonus"])
    completed_steps += 1
    if int(v["next"]) >= v["definition"]["steps"].size():
        v["state"] = "COMPLETE"
        customers[v["definition"]["customer_id"]]["state"] = "DEPARTED"
    else:
        v["state"] = "WAITING_FOR_SERVICE"
    return true

func at_queue_head(customer_id: String, machine_id: String) -> bool:
    var q: Array = queues.get(machine_id, [])
    return not q.is_empty() and q[0] == customer_id

func leave_queue(customer_id: String, machine_id: String) -> bool:
    if not at_queue_head(customer_id, machine_id): return false
    queues[machine_id].pop_front()
    return true

func stars() -> int:
    var total: int = 0
    for threshold in scoring["thresholds"]:
        if score >= int(threshold["minimum_score"]): total = int(threshold["stars"])
    return total

func snapshot() -> Dictionary:
    return {"accounts": customers.duplicate(true), "visits": visits.duplicate(true), "queues": queues.duplicate(true), "score": score, "steps": completed_steps, "spectators": spectator_count, "stars": stars()}
