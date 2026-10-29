class_name SimulationRoot
extends RefCounted
## Sole authoritative command gateway and 60Hz timeline. Never driven by area changes.
var content: Dictionary
var stage: Dictionary
var clock: SimulationClock
var ledger: InventoryLedger
var customers: CustomerManager
var cart: CartManager
var machines: MachineManager
var workshop: WorkshopManager
var revenue_minor: int = 0
var cash_minor: int = 0
var area: String = "arcade_floor"
var command_results: Dictionary = {}
var event_log: Array = []
var staff_jobs: Dictionary = {}
var staff_started: Dictionary = {}
var session_visits: Dictionary = {}
var finished_sessions: Dictionary = {}

static func create() -> SimulationRoot:
    var r := SimulationRoot.new()
    var data: Dictionary = SchemaLoader.load_stage()
    if data.is_empty(): return null
    r.setup(data)
    return r

func setup(bundle: Dictionary) -> void:
    content = bundle
    stage = content["stage"]
    clock = SimulationClock.new()
    ledger = InventoryLedger.new()
    customers = CustomerManager.new(stage)
    cart = CartManager.new(ledger, content["items"])
    machines = MachineManager.new(stage, content["machine_types"], ledger, customers, cart)
    workshop = WorkshopManager.new(stage, ledger, customers)
    revenue_minor = int(stage["economy"]["starting_revenue_minor"])
    cash_minor = int(stage["economy"]["starting_cash_minor"])
    for job in stage["staff_jobs"]: staff_jobs[job["job_id"]] = job
    for item in stage["initial_inventory"]["workshop"]:
        var _commit_41: bool = ledger.register_item(str(item["instance_id"]), str(item["item_id"]), "workshop", {"charged": false})
        assert(_commit_41)
    for cassette in stage["initial_inventory"]["machine_bay"]:
        var _commit_43: bool = ledger.register_cassette(cassette, "machine_bay")
        assert(_commit_43)
    for item in stage["initial_inventory"]["trade_counter"]:
        var _commit_45: bool = ledger.register_item(str(item["instance_id"]), str(item["item_id"]), "trade_counter")
        assert(_commit_45)
    for data in stage["initial_inventory"]["customer_owned"]:
        for item in data["items"]:
            var _commit_48: bool = ledger.register_item(str(item["instance_id"]), str(item["item_id"]), "customer:" + str(data["customer_id"]))
            assert(_commit_48)
    for acc in stage["customer_accounts"]:
        if acc["card_instance_id"] != null:
            var _commit_51: bool = ledger.register_item(str(acc["card_instance_id"]), "card_starter", "customer:" + str(acc["customer_id"]), {"charged": true})
            assert(_commit_51)
    customers.advance(0, machines.sessions)

func advance() -> int:
    var tick: int = clock.step()
    customers.advance(tick, machines.sessions)
    workshop.advance(tick)
    machines.advance(tick)
    var ids: Array = machines.completed_sessions.keys()
    ids.sort()
    for sid in ids:
        if finished_sessions.has(sid): continue
        finished_sessions[sid] = true
        var vid: String = str(session_visits.get(sid, ""))
        if not vid.is_empty():
            var _commit_65: bool = customers.finish_step(vid, "admit_session", tick)
            assert(_commit_65)
    return tick


## UI must display this read-only quote (queue and cabinet status) before confirmation.
## Purchase revalidates the quote at commit time to close the stale-availability race.
func quote_card_purchase(visit_id: String) -> Dictionary:
    if customers.next_action(visit_id) != "purchase_card":
        return {"ok": false, "reason": "NOT_CURRENT_STEP"}
    var visit: Dictionary = customers.visits[visit_id]["definition"]
    var step: Dictionary = visit["steps"][int(customers.visits[visit_id]["next"])]
    var offer: Dictionary = customers.offers[step["offer_id"]]
    var quote: Dictionary = {"ok": true, "reason": "OK", "price_minor": int(offer["price_minor"]), "credit_units": int(offer["credit_units"]), "offer_id": step["offer_id"], "customer_id": visit["customer_id"], "intended_session_id": str(step.get("intended_session_id", ""))}
    if not quote["intended_session_id"].is_empty():
        var sid: String = str(quote["intended_session_id"])
        var availability: Dictionary = machines.availability(sid)
        quote["cabinet_id"] = machines.sessions[sid]["machine_id"]
        quote["machine_availability"] = availability
        quote["ok"] = availability["ok"]
        quote["reason"] = availability.get("reason", "OK")
    return quote

func _result(ok: bool, reason: String) -> Dictionary:
    return {"ok": ok, "reason": reason}

## Idempotency is keyed on unique command_id; no command may contain yield/await.
func command(command_id: String, action: String, payload: Dictionary = {}) -> Dictionary:
    if command_results.has(command_id): return command_results[command_id].duplicate(true)
    var result: Dictionary = _dispatch(action, payload)
    command_results[command_id] = result.duplicate(true)
    event_log.append({"tick": clock.tick, "command": command_id, "action": action, "payload": payload.duplicate(true), "ok": result["ok"], "reason": result["reason"]})
    return result

func _dispatch(action: String, p: Dictionary) -> Dictionary:
    var tick: int = clock.tick
    if action == "switch_area":
        var target: String = str(p.get("area", ""))
        if not (target in ["arcade_floor", "machine_bay", "workshop"]): return _result(false, "INVALID_AREA")
        area = target
        return _result(true, "OK")
    if action == "start_production":
        return workshop.start_production(str(p.get("job_id", "")), tick)
    if action == "purchase_card":
        var vid: String = str(p.get("visit_id", ""))
        if customers.next_action(vid) != "purchase_card": return _result(false, "NOT_CURRENT_STEP")
        var visit: Dictionary = customers.visits[vid]["definition"]
        var customer_id: String = str(visit["customer_id"])
        var step: Dictionary = visit["steps"][int(customers.visits[vid]["next"])]
        var oid: String = str(step["offer_id"])
        if not customers.offers.has(oid): return _result(false, "UNKNOWN_OFFER")
        var offer: Dictionary = customers.offers[oid]
        var intended: String = str(step.get("intended_session_id", ""))
        if not intended.is_empty():
            var availability: Dictionary = machines.availability(intended)
            if not availability["ok"]: return _result(false, str(availability["reason"]))
        var acc: Dictionary = customers.customers[customer_id]
        var card_id: String = ""
        var card_owner: String = "workshop:ready"
        var source_slot: String = str(p.get("cart_slot", ""))
        if offer["kind"] == "starter_card":
            if acc["card"] != null: return _result(false, "ALREADY_HAS_CARD")
            if not source_slot.is_empty():
                if not source_slot.begins_with("supply_") or not cart.slots.has(source_slot): return _result(false, "INVALID_CARD_SLOT")
                card_id = str(cart.slots[source_slot])
                card_owner = "cart:" + source_slot
                if ledger.owner_of(card_id) != card_owner or ledger.item_of(card_id) != str(offer["card_item_id"]) or not bool(ledger.meta_of(card_id, "charged", false)):
                    return _result(false, "CART_CARD_NOT_READY")
            else:
                for id in ledger.items_at("workshop:ready"):
                    if ledger.item_of(str(id)) == offer["card_item_id"] and bool(ledger.meta_of(str(id), "charged", false)):
                        card_id = str(id)
                        break
            if card_id.is_empty(): return _result(false, "NO_PREPARED_STARTER_CARD")
        else:
            if acc["card"] == null: return _result(false, "NO_REGISTERED_CARD")
        if not card_id.is_empty():
            if not ledger.transfer(card_id, card_owner, "customer:" + customer_id): return _result(false, "CARD_TRANSFER_FAILED")
            if not source_slot.is_empty(): cart.slots[source_slot] = ""
            acc["card"] = card_id
        # Purchase is ONE sale. Machine credits are an account balance, never money.
        acc["credits"] = int(acc["credits"]) + int(offer["credit_units"])
        cash_minor += int(offer["price_minor"])
        revenue_minor += int(offer["price_minor"])
        var _commit_119: bool = customers.begin_step(vid, action)
        assert(_commit_119)
        var _commit_120: bool = customers.finish_step(vid, action, tick)
        assert(_commit_120)
        event_log.append({"tick": tick, "kind": "SALE", "customer": customer_id, "revenue_minor": int(offer["price_minor"]), "credits_added": int(offer["credit_units"]), "availability_disclosed": not intended.is_empty()})
        return _result(true, "OK")
    if action == "admit_session":
        var vid: String = str(p.get("visit_id", ""))
        if customers.next_action(vid) != "admit_session": return _result(false, "NOT_CURRENT_STEP")
        var step: Dictionary = customers.visits[vid]["definition"]["steps"][int(customers.visits[vid]["next"])]
        var sid: String = str(step["session_id"])
        var result: Dictionary = machines.admit(sid, tick)
        if result["ok"]:
            var _commit_130: bool = customers.begin_step(vid, action)
            assert(_commit_130)
            session_visits[sid] = vid
        return result
    if action == "staff_key":
        var jid: String = str(p.get("job_id", ""))
        if not staff_jobs.has(jid): return _result(false, "UNKNOWN_STAFF_JOB")
        var job: Dictionary = staff_jobs[jid]
        if job["kind"] != "position_reset": return _result(false, "WRONG_STAFF_JOB")
        if tick < int(job["available_tick"]): return _result(false, "JOB_NOT_AVAILABLE")
        if staff_started.has(jid): return _result(false, "JOB_ALREADY_STARTED")
        var result: Dictionary = machines.request_reset(str(job["machine_id"]), tick)
        if result["ok"]: staff_started[jid] = tick
        return result
    if action == "pickup_cart":
        var ok: bool = cart.pickup(str(p.get("instance_id", "")), str(p.get("from", "")), str(p.get("slot", "")))
        return _result(ok, "OK" if ok else "CART_PICKUP_DENIED")
    if action == "drop_cart":
        var ok: bool = cart.drop(str(p.get("slot", "")), str(p.get("to", "")))
        return _result(ok, "OK" if ok else "CART_DROP_DENIED")
    if action == "restock":
        var jid: String = str(p.get("job_id", ""))
        if not staff_jobs.has(jid): return _result(false, "UNKNOWN_STAFF_JOB")
        var job: Dictionary = staff_jobs[jid]
        if job["kind"] != "restock": return _result(false, "WRONG_STAFF_JOB")
        if tick < int(job["available_tick"]): return _result(false, "JOB_NOT_AVAILABLE")
        if staff_started.has(jid): return _result(false, "JOB_ALREADY_STARTED")
        var result: Dictionary = machines.start_changeover(str(job["machine_id"]), str(job["cassette_instance_id"]), tick)
        if result["ok"]: staff_started[jid] = tick
        return result
    if action == "gift_wrap": return workshop.start_wrap(str(p.get("visit_id", "")), tick)
    if action == "trade_up": return workshop.start_trade(str(p.get("visit_id", "")), tick)
    return _result(false, "UNKNOWN_ACTION")

func verify_invariants() -> bool:
    if not ledger.verify() or cash_minor < 0 or revenue_minor < 0: return false
    for cid in customers.customers:
        if int(customers.customers[cid]["credits"]) < 0: return false
    for slot in cart.slots:
        var id: String = str(cart.slots[slot])
        if not id.is_empty() and ledger.owner_of(id) != "cart:" + str(slot): return false
    var reserved_ids: Dictionary = {}
    for mid in machines.machines:
        var m: Dictionary = machines.machines[mid]
        if m["session"] != "":
            var sid: String = str(m["session"])
            var prize: String = str(machines.sessions[sid]["requested_prize_instance_id"])
            if m["state"] in ["PLAYING", "RESET_REQUIRED", "RESETTING", "SETTLING"]:
                if ledger.reservation_of(prize) != sid or reserved_ids.has(prize): return false
                reserved_ids[prize] = true
            if m["state"] == "OUTPUT_HELD" and ledger.owner_of(prize) != "output:" + str(mid): return false
    return true

func game_snapshot() -> Dictionary:
    return {"tick": clock.tick, "inventory": ledger.snapshot(), "customers": customers.snapshot(), "machines": machines.snapshot(), "workshop": workshop.snapshot(), "cart": cart.snapshot(), "finance": {"cash_minor": cash_minor, "revenue_minor": revenue_minor}, "staff_started": staff_started.duplicate(true), "command_results": command_results.duplicate(true)}

func state_digest() -> String:
    return JSON.stringify(game_snapshot()).sha256_text()
