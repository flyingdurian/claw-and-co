class_name BackstageWorkshop
extends Control
signal job_requested(job_id: String)
signal wrap_requested(visit_id: String)
signal trade_requested(visit_id: String)
signal cart_pickup_requested(instance_id: String, source: String, slot: String)
var jobs: Array = []
var catalog: Dictionary = {}
var next_charge: String = ""
var current_wrap: String = ""
var current_trade: String = ""
var pickup_map: Dictionary = {}

func _ready() -> void:
    $ChargeButton.pressed.connect(_emit_charge)
    $CassetteButton.pressed.connect(func() -> void: job_requested.emit("PB04"))
    $WrapButton.pressed.connect(_emit_wrap)
    $TradeButton.pressed.connect(_emit_trade)
    $PickupButton.pressed.connect(_pickup.bind("bulk"))
    $LoadCardButton.pressed.connect(_pickup.bind("card"))
    $LoadGiftButton.pressed.connect(_pickup.bind("gift_box"))
    $LoadRibbonButton.pressed.connect(_pickup.bind("ribbon"))

func _emit_charge() -> void:
    if not next_charge.is_empty(): job_requested.emit(next_charge)

func _emit_wrap() -> void:
    if not current_wrap.is_empty(): wrap_requested.emit(current_wrap)

func _emit_trade() -> void:
    if not current_trade.is_empty(): trade_requested.emit(current_trade)

func setup_stage(stage: Dictionary) -> void:
    jobs = stage.get("production_jobs", []).duplicate(true)

func setup_catalog(items: Dictionary) -> void:
    catalog = items.duplicate(true)

func _pickup(kind: String) -> void:
    if pickup_map.has(kind):
        var info: Dictionary = pickup_map[kind]
        cart_pickup_requested.emit(str(info["id"]), str(info["owner"]), str(info["slot"]))

func apply_snapshot(snapshot: Dictionary) -> void:
    var tick: int = int(snapshot.get("tick", 0))
    var prod: Dictionary = snapshot.get("workshop", {})
    var started: Dictionary = prod.get("active", {})
    var done: Dictionary = prod.get("done", {})
    next_charge = ""
    for job in jobs:
        if job["kind"] != "charge_cards": continue
        var id: String = str(job["job_id"])
        if tick >= int(job["available_tick"]) and not started.has(id) and not done.has(id):
            next_charge = id
            break
    $ChargeButton.disabled = next_charge.is_empty()
    $ChargeButton.text = "CHARGE " + next_charge if not next_charge.is_empty() else "CARDS READY"
    $CassetteButton.disabled = tick < 1980 or started.has("PB04") or done.has("PB04")
    $CassetteButton.text = "UNBOX K05" if not done.has("PB04") else "CASSETTE READY"
    current_wrap = ""
    current_trade = ""
    var visits: Dictionary = snapshot.get("customers", {}).get("visits", {})
    var ids: Array = visits.keys()
    ids.sort()
    for vid in ids:
        var v: Dictionary = visits[vid]
        var n: int = int(v.get("next", 0))
        var steps: Array = v.get("definition", {}).get("steps", [])
        if str(v.get("state", "SCHEDULED")) == "SCHEDULED" or n >= steps.size() or str(v.get("active_step", "")) != "": continue
        var action: String = str(steps[n]["action"])
        if action == "gift_wrap" and current_wrap.is_empty(): current_wrap = str(vid)
        elif action == "trade_up" and current_trade.is_empty(): current_trade = str(vid)
    $WrapButton.disabled = current_wrap.is_empty()
    $TradeButton.disabled = current_trade.is_empty()
    $WrapButton.text = "WRAP " + current_wrap if not current_wrap.is_empty() else "NO WRAP REQUEST"
    $TradeButton.text = "TRADE " + current_trade if not current_trade.is_empty() else "NO TRADE REQUEST"
    pickup_map.clear()
    var slots: Dictionary = snapshot.get("cart", {})
    var records: Dictionary = snapshot.get("inventory", {})
    var sorted_ids: Array = records.keys()
    sorted_ids.sort()
    for id in sorted_ids:
        var rec: Dictionary = records[id]
        var owner: String = str(rec.get("owner", ""))
        var kind: String = str(catalog.get(str(rec.get("item_id", "")), {}).get("kind", ""))
        var category: String = "bulk" if kind == "cassette" else kind
        if category not in ["bulk", "card", "gift_box", "ribbon"] or pickup_map.has(category): continue
        if category == "bulk" and owner != "machine_bay:ready": continue
        if category == "card" and (owner != "workshop:ready" or not bool(rec.get("meta", {}).get("charged", false))): continue
        if category in ["gift_box", "ribbon"] and owner not in ["workshop", "workshop:ready"]: continue
        var slot: String = ""
        if category == "bulk":
            if str(slots.get("bulk_0", "")).is_empty(): slot = "bulk_0"
        else:
            var prefix: String = "supply" if category == "card" else "gift" if category == "gift_box" else "ribbon"
            for i in range(4 if category == "card" else 2):
                var candidate: String = prefix + "_" + str(i)
                if str(slots.get(candidate, "")).is_empty():
                    slot = candidate
                    break
        if slot.is_empty(): continue
        pickup_map[category] = {"id": id, "owner": owner, "slot": slot}
    $PickupButton.disabled = not pickup_map.has("bulk")
    $LoadCardButton.disabled = not pickup_map.has("card")
    $LoadGiftButton.disabled = not pickup_map.has("gift_box")
    $LoadRibbonButton.disabled = not pickup_map.has("ribbon")
    $WorkStatus.text = "PRODUCTION  •  %d ACTIVE   |   %d COMPLETED" % [started.size(), done.size()]
