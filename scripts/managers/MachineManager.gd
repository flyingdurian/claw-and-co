class_name MachineManager
extends RefCounted
var machines: Dictionary = {}
var sessions: Dictionary = {}
var types: Dictionary
var ledger: InventoryLedger
var customers: CustomerManager
var cart: CartManager
var events: Array = []
var completed_sessions: Dictionary = {}

func _init(stage: Dictionary, type_catalog: Dictionary, p_ledger: InventoryLedger, p_customers: CustomerManager, p_cart: CartManager) -> void:
    types = type_catalog
    ledger = p_ledger
    customers = p_customers
    cart = p_cart
    for s in stage["sessions"]: sessions[s["session_id"]] = s
    for m in stage["cabinet_instances"]:
        var cid: String = str(m["machine_id"])
        var cassette: Dictionary = m["loaded_cassette"]
        var kid: String = str(cassette["cassette_instance_id"])
        machines[cid] = {"type": m["machine_type_id"], "state": "READY", "cassette": kid, "session": "", "attempt": 0, "due": -1, "output": "", "access": m["access_policy"], "queue_limit": m["queue_limit"], "reset_requested": false, "aligned_for_win": false, "changeover_new": "", "changeover_old": ""}
        var _commit_22: bool = ledger.register_cassette(cassette, "cabinet:" + cid)
        assert(_commit_22)

func availability(session_id: String) -> Dictionary:
    if not sessions.has(session_id): return {"ok": false, "reason": "UNKNOWN_SESSION"}
    var s: Dictionary = sessions[session_id]
    var mid: String = str(s["machine_id"])
    var m: Dictionary = machines[mid]
    var q: Array = customers.queues[mid]
    var cid: String = str(s["customer_id"])
    var prize: String = str(s["requested_prize_instance_id"])
    if not q.has(cid): return {"ok": false, "reason": "QUEUE_NOT_JOINED", "queue": q.duplicate()}
    if q.size() > int(m["queue_limit"]): return {"ok": false, "reason": "QUEUE_FULL", "queue": q.duplicate()}
    if not ledger.records.has(prize): return {"ok": false, "reason": "EXACT_PRIZE_MISSING", "queue": q.duplicate()}
    if ledger.owner_of(prize) != "cassette:" + str(m["cassette"]) or ledger.reservation_of(prize) != "":
        return {"ok": false, "reason": "EXACT_PRIZE_UNAVAILABLE", "queue": q.duplicate()}
    return {"ok": true, "queue": q.duplicate(), "cabinet_state": m["state"], "queue_position": q.find(cid)}

func admit(session_id: String, tick: int) -> Dictionary:
    if not sessions.has(session_id): return {"ok": false, "reason": "UNKNOWN_SESSION"}
    var s: Dictionary = sessions[session_id]
    var cid: String = str(s["customer_id"])
    var mid: String = str(s["machine_id"])
    var machine: Dictionary = machines[mid]
    var price: int = int(types[machine["type"]]["admission_credits"])
    if completed_sessions.has(session_id): return {"ok": false, "reason": "ALREADY_PLAYED"}
    if machine["state"] != "READY": return {"ok": false, "reason": "CABINET_BUSY"}
    if not customers.at_queue_head(cid, mid): return {"ok": false, "reason": "NOT_QUEUE_HEAD"}
    if int(customers.customers[cid]["credits"]) < price: return {"ok": false, "reason": "INSUFFICIENT_CREDITS"}
    var prize: String = str(s["requested_prize_instance_id"])
    if ledger.owner_of(prize) != "cassette:" + str(machine["cassette"]):
        return {"ok": false, "reason": "EXACT_PRIZE_UNAVAILABLE"}
    if not ledger.reservation_of(prize).is_empty(): return {"ok": false, "reason": "PRIZE_RESERVED"}
    # SINGLE synchronous commit boundary: no yield/await in this method.
    if not ledger.reserve(prize, "cassette:" + str(machine["cassette"]), session_id):
        return {"ok": false, "reason": "RESERVATION_CONFLICT"}
    customers.customers[cid]["credits"] = int(customers.customers[cid]["credits"]) - price
    customers.leave_queue(cid, mid)
    machine["session"] = session_id
    machine["attempt"] = 0
    machine["state"] = "PLAYING"
    machine["due"] = tick + int(s["attempts"][0]["duration_ticks"])
    customers.customers[cid]["state"] = "PLAYING"
    events.append({"tick": tick, "kind": "ADMISSION", "session": session_id, "credit_debit": price, "sale_minor": 0})
    return {"ok": true, "reason": "OK"}

func request_reset(machine_id: String, tick: int) -> Dictionary:
    if not machines.has(machine_id): return {"ok": false, "reason": "UNKNOWN_CABINET"}
    var m: Dictionary = machines[machine_id]
    if m["state"] != "RESET_REQUIRED": return {"ok": false, "reason": "NO_RESET_REQUEST"}
    m["state"] = "RESETTING"
    # M02 Staff Key rule: exactly 90 simulation ticks = 1.5 sec.
    m["due"] = tick + 90
    events.append({"tick": tick, "kind": "STAFF_RESET_STARTED", "machine": machine_id})
    return {"ok": true, "reason": "OK"}

func start_changeover(machine_id: String, cassette_id: String, tick: int) -> Dictionary:
    if not machines.has(machine_id): return {"ok": false, "reason": "UNKNOWN_CABINET"}
    var m: Dictionary = machines[machine_id]
    if m["state"] != "READY" or m["output"] != "": return {"ok": false, "reason": "CABINET_BUSY_OR_OUTPUT_HELD"}
    if ledger.owner_of(cassette_id) != "cart:bulk_0" or cart.slots["bulk_0"] != cassette_id:
        return {"ok": false, "reason": "CASSETTE_NOT_ON_CART"}
    var machine_type: Dictionary = types[m["type"]]
    var cassette_item: String = ledger.item_of(cassette_id)
    var format: String = str(cart.items[cassette_item].get("cassette_format", ""))
    if not machine_type["cassette_formats"].has(format): return {"ok": false, "reason": "WRONG_CASSETTE_FORMAT"}
    for prize_id in ledger.items_at("cassette:" + cassette_id):
        var prize_kind: String = str(cart.items[ledger.item_of(str(prize_id))]["kind"])
        if not machine_type["accepted_prize_kinds"].has(prize_kind):
            return {"ok": false, "reason": "INCOMPATIBLE_CASSETTE_CONTENTS"}
    if not ledger.items_at("cassette:" + str(m["cassette"])).is_empty():
        return {"ok": false, "reason": "PREVIOUS_CASSETTE_NOT_EMPTY"}
    var old: String = str(m["cassette"])
    if not ledger.transfer_many([
        {"id": old, "from": "cabinet:" + machine_id, "to": "machine_bay"},
        {"id": cassette_id, "from": "cart:bulk_0", "to": "cabinet:" + machine_id}
    ]): return {"ok": false, "reason": "TRANSFER_FAILED"}
    cart.slots["bulk_0"] = ""
    m["cassette"] = cassette_id
    m["state"] = "CHANGEOVER"
    m["due"] = tick + int(machine_type["timing"]["changeover_ticks"])
    events.append({"tick": tick, "kind": "CHANGEOVER_STARTED", "machine": machine_id})
    return {"ok": true, "reason": "OK"}

func advance(tick: int) -> void:
    var keys: Array = machines.keys()
    keys.sort()
    for mid in keys:
        var m: Dictionary = machines[mid]
        if int(m["due"]) < 0 or tick < int(m["due"]): continue
        var state: String = str(m["state"])
        var sid: String = str(m["session"])
        if state == "CHANGEOVER":
            m["state"] = "READY"
            m["due"] = -1
            events.append({"tick": tick, "kind": "CHANGEOVER_DONE", "machine": mid})
        elif state == "RESETTING":
            m["aligned_for_win"] = true
            m["attempt"] = int(m["attempt"]) + 1
            var s: Dictionary = sessions[sid]
            if int(m["attempt"]) >= s["attempts"].size():
                push_error("Reset without next authored attempt")
                continue
            m["state"] = "PLAYING"
            m["due"] = tick + int(s["attempts"][int(m["attempt"])]["duration_ticks"])
            events.append({"tick": tick, "kind": "STAFF_RESET_DONE_NEXT_ATTEMPT", "machine": mid, "drop_zone": true})
        elif state == "PLAYING":
            var s: Dictionary = sessions[sid]
            var attempt: Dictionary = s["attempts"][int(m["attempt"])]
            var result: String = str(attempt["result"])
            if result == "stuck":
                m["state"] = "RESET_REQUIRED"
                m["due"] = -1
                events.append({"tick": tick, "kind": "STUCK", "machine": mid})
            elif result == "miss":
                var prize: String = str(s["requested_prize_instance_id"])
                var _commit_133: bool = ledger.release(prize, sid)
                assert(_commit_133)
                customers.customers[s["customer_id"]]["patience"] = maxi(0, int(customers.customers[s["customer_id"]]["patience"]) - 1)
                m["state"] = "READY"
                m["session"] = ""
                m["due"] = -1
                completed_sessions[sid] = "miss"
                events.append({"tick": tick, "kind": "MISS_RELEASED", "machine": mid, "stock_delta": 0})
            elif result == "win":
                m["state"] = "SETTLING"
                m["due"] = tick + int(types[m["type"]]["timing"]["settle_ticks"])
            else:
                push_error("Unexpected authored attempt outcome " + result)
        elif state == "SETTLING":
            var s: Dictionary = sessions[sid]
            var prize: String = str(s["requested_prize_instance_id"])
            var _commit_148: bool = ledger.transfer(prize, "cassette:" + str(m["cassette"]), "output:" + str(mid), sid)
            assert(_commit_148)
            m["state"] = "OUTPUT_HELD"
            m["output"] = prize
            m["due"] = tick + int(s["collection_delay_ticks"])
            events.append({"tick": tick, "kind": "OUTPUT_HELD", "machine": mid, "prize": prize})
        elif state == "OUTPUT_HELD":
            var s: Dictionary = sessions[sid]
            var prize: String = str(m["output"])
            var _commit_156: bool = ledger.transfer(prize, "output:" + str(mid), "customer:" + str(s["customer_id"]))
            assert(_commit_156)
            m["output"] = ""
            m["state"] = "READY"
            m["session"] = ""
            m["due"] = -1
            completed_sessions[sid] = "win"
            events.append({"tick": tick, "kind": "SELF_COLLECTED", "machine": mid, "prize": prize})

func snapshot() -> Dictionary:
    return {"machines": machines.duplicate(true), "completed": completed_sessions.duplicate(true)}
