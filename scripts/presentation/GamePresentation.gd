class_name GamePresentation
extends Control
## Single persistent 2D hierarchy. Tabs never free or pause the simulation.
@onready var driver: SimulationDriver = $SimulationDriver
@onready var bridge: PresentationBridge = $PresentationBridge
@onready var arcade: ArcadeAisle = $ArcadeAisle
@onready var workshop: BackstageWorkshop = $BackstageWorkshop
@onready var hud: TopBarHUD = $TopBarHUD
@onready var cart: ServiceCartUI = $CartCanvas/ServiceCartUI
@onready var arcade_tab: Button = $ArcadeTab
@onready var workshop_tab: Button = $WorkshopTab
@onready var feedback: Label = $Feedback
var quote_popup: ConfirmationDialog
var selected_visit: String = ""
var action_popup: PopupPanel
var action_box: VBoxContainer
var selected_machine: String = ""
var selected_cart_slot: String = ""
var pending_sale_slot: String = ""

func _ready() -> void:
    if driver.simulation == null:
        feedback.text = "Stage data unavailable. Check JSON manifests."
        return
    var simulation: SimulationRoot = driver.simulation
    hud.setup_stage(simulation.stage)
    arcade.setup_stage(simulation.stage)
    workshop.setup_stage(simulation.stage)
    workshop.setup_catalog(simulation.content["items"])
    cart.setup_catalog(simulation.content["items"])
    bridge.frame_updated.connect(_apply_snapshot)
    bridge.command_feedback.connect(_on_feedback)
    bridge.quote_ready.connect(_on_quote)
    bridge.simulation_event.connect(_on_simulation_event)
    arcade.cabinet_selected.connect(_open_machine_actions)
    arcade.customer_selected.connect(_serve_visit)
    arcade.help_requested.connect(func() -> void: bridge.request_action("staff_key", {"job_id": "J01"}))
    arcade.restock_requested.connect(func() -> void: bridge.request_action("restock", {"job_id": "J02"}))
    arcade.counter_requested.connect(_open_customer_counter)
    workshop.job_requested.connect(func(id: String) -> void: bridge.request_action("start_production", {"job_id": id}))
    workshop.wrap_requested.connect(_on_workshop_wrap)
    workshop.trade_requested.connect(_on_workshop_trade)
    workshop.cart_pickup_requested.connect(func(id: String, source: String, slot: String) -> void:
        bridge.request_action("pickup_cart", {"instance_id": id, "from": source, "slot": slot}))
    cart.cart_slot_selected.connect(_on_cart_slot)
    cart.staff_key_selected.connect(func() -> void:
        selected_cart_slot = "staff_key"
        feedback.text = "Staff Key selected — tap M02 to reset the figure.")
    arcade_tab.pressed.connect(func() -> void: switch_tab("arcade_floor"))
    workshop_tab.pressed.connect(func() -> void: switch_tab("workshop"))
    quote_popup = ConfirmationDialog.new()
    quote_popup.title = "Confirm IC card purchase"
    quote_popup.ok_button_text = "SELL CARD"
    quote_popup.confirmed.connect(_confirm_sale)
    add_child(quote_popup)
    action_popup = PopupPanel.new()
    action_popup.title = "Cabinet service"
    action_box = VBoxContainer.new()
    action_box.custom_minimum_size = Vector2(370, 90)
    action_box.add_theme_constant_override("separation", 9)
    action_popup.add_child(action_box)
    add_child(action_popup)
    _apply_snapshot(bridge.last_snapshot)
    switch_tab("arcade_floor")

func _apply_snapshot(s: Dictionary) -> void:
    if s.is_empty(): return
    hud.apply_snapshot(s)
    arcade.apply_snapshot(s)
    workshop.apply_snapshot(s)
    cart.apply_snapshot(s)
    if int(s.get("tick", 0)) >= 7200:
        feedback.text = "SHIFT COMPLETE!  %d / 3 STARS" % int(s.get("customers", {}).get("stars", 0))

func switch_tab(area: String) -> void:
    # Area command is presentation-only; advance() belongs solely to SimulationDriver.
    var result: Dictionary = bridge.request_action("switch_area", {"area": area})
    if not result.get("ok", false): return
    arcade.visible = area == "arcade_floor"
    workshop.visible = area == "workshop"
    arcade_tab.button_pressed = arcade.visible
    workshop_tab.button_pressed = workshop.visible

func _on_feedback(action: String, result: Dictionary) -> void:
    var label: String = action.replace("_", " ").capitalize()
    feedback.text = label + ("  ✓" if bool(result.get("ok", false)) else "  •  " + str(result.get("reason", "DENIED")))

func _serve_visit(visit_id: String) -> void:
    if driver.simulation == null: return
    var action: String = driver.simulation.customers.next_action(visit_id)
    if action == "purchase_card":
        bridge.request_quote(visit_id)
    elif action in ["admit_session", "gift_wrap", "trade_up"]:
        bridge.request_action(action, {"visit_id": visit_id})
    else:
        feedback.text = visit_id + " is not ready for another service."

func _on_quote(visit_id: String, quote: Dictionary) -> void:
    if not bool(quote.get("ok", false)):
        feedback.text = "Cannot sell to " + visit_id + ": " + str(quote.get("reason", "UNKNOWN"))
        return
    selected_visit = visit_id
    pending_sale_slot = selected_cart_slot if selected_cart_slot.begins_with("supply_") else ""
    var info: Dictionary = quote.get("machine_availability", {})
    var queue: Array = info.get("queue", [])
    var msg: String = "%s · $%.2f · %d credits" % [visit_id, float(quote["price_minor"]) / 100.0, int(quote["credit_units"])]
    if quote.has("cabinet_id"):
        msg += "\nCabinet %s is %s. Queue: %s (%d ahead)." % [str(quote["cabinet_id"]), str(info.get("cabinet_state", "READY")), str(queue), int(info.get("queue_position", 0))]
    msg += "\nThe sale will be revalidated before charging."
    quote_popup.dialog_text = msg
    quote_popup.popup_centered(Vector2i(510, 190))

func _confirm_sale() -> void:
    if selected_visit.is_empty(): return
    var payload: Dictionary = {"visit_id": selected_visit}
    var quote: Dictionary = driver.simulation.quote_card_purchase(selected_visit)
    if not pending_sale_slot.is_empty() and str(quote.get("offer_id", "")) == "offer_starter":
        payload["cart_slot"] = pending_sale_slot
    var result: Dictionary = bridge.request_action("purchase_card", payload)
    if bool(result.get("ok", false)) and payload.has("cart_slot"):
        cart.clear_selection()
        selected_cart_slot = ""
    pending_sale_slot = ""
    selected_visit = ""

func _button_for_action(label: String, handler: Callable) -> void:
    var b: Button = Button.new()
    b.text = label
    b.custom_minimum_size = Vector2(360, 42)
    action_box.add_child(b)
    b.pressed.connect(func() -> void:
        action_popup.hide()
        handler.call())

func _open_machine_actions(mid: String) -> void:
    selected_machine = mid
    if selected_cart_slot == "staff_key":
        if mid != "M02":
            feedback.text = "Staff Key is for M02 only."
            return
        var key_result: Dictionary = bridge.request_action("staff_key", {"job_id": "J01"})
        if bool(key_result.get("ok", false)):
            selected_cart_slot = ""
            cart.clear_selection()
        return
    if selected_cart_slot == "bulk_0":
        if mid != "M01":
            feedback.text = "This cassette belongs in M01."
            return
        var stock_result: Dictionary = bridge.request_action("restock", {"job_id": "J02"})
        if bool(stock_result.get("ok", false)):
            selected_cart_slot = ""
            cart.clear_selection()
        return
    if selected_cart_slot.begins_with("supply_"):
        for cid in arcade.visits_by_machine.get(mid, []):
            if driver.simulation.customers.next_action(str(cid)) == "purchase_card":
                _serve_visit(str(cid))
                return
        feedback.text = "No card customer is ready at " + mid + "."
        return
    if selected_cart_slot.begins_with("gift_") or selected_cart_slot.begins_with("ribbon_") or selected_cart_slot.begins_with("prize_"):
        feedback.text = "Take this item to a compatible Workshop counter."
        return
    for c in action_box.get_children(): c.queue_free()
    var title: Label = Label.new()
    title.text = "  " + mid + " — CABINET SERVICE"
    action_box.add_child(title)
    var visits: Dictionary = bridge.last_snapshot.get("customers", {}).get("visits", {})
    var visit_ids: Array = visits.keys()
    visit_ids.sort()
    var found: bool = false
    for vid in visit_ids:
        if driver.simulation.customers.next_action(str(vid)).is_empty(): continue
        var definition: Dictionary = visits[vid].get("definition", {})
        for step in definition.get("steps", []):
            var sid: String = str(step.get("session_id", step.get("intended_session_id", "")))
            if sid.is_empty(): continue
            if driver.simulation.machines.sessions.has(sid) and str(driver.simulation.machines.sessions[sid]["machine_id"]) == mid:
                var name: String = str(vid)
                var step_name: String = driver.simulation.customers.next_action(name)
                _button_for_action("Serve " + name + " · " + step_name.replace("_", " "), func() -> void: _serve_visit(name))
                found = true
                break
    if mid == "M02":
        _button_for_action("Use Staff Key (1.5s)", func() -> void: bridge.request_action("staff_key", {"job_id": "J01"}))
        found = true
    if mid == "M01":
        _button_for_action("Install prepared cassette from cart", func() -> void: bridge.request_action("restock", {"job_id": "J02"}))
        found = true
    if not found:
        var l: Label = Label.new()
        l.text = "No customers need this cabinet yet."
        action_box.add_child(l)
    action_popup.popup_centered(Vector2i(420, 340))

func _open_customer_counter() -> void:
    for c in action_box.get_children(): c.queue_free()
    var heading: Label = Label.new()
    heading.text = "  CUSTOMER SERVICE DESK"
    action_box.add_child(heading)
    var ids: Array = bridge.last_snapshot.get("customers", {}).get("visits", {}).keys()
    ids.sort()
    for visit_id in ids:
        var id: String = str(visit_id)
        var action: String = driver.simulation.customers.next_action(id)
        if action.is_empty(): continue
        _button_for_action(id + " — " + action.replace("_", " "), func() -> void: _serve_visit(id))
    action_popup.popup_centered(Vector2i(420, 460))

func _on_cart_slot(slot: String) -> void:
    var item_id: String = str(bridge.last_snapshot.get("cart", {}).get(slot, ""))
    if item_id.is_empty():
        feedback.text = slot + " is empty. Pick up a prepared item in Workshop."
        return
    selected_cart_slot = slot
    feedback.text = "Selected " + item_id + " from " + slot + ". Tap a compatible customer, cabinet, or Workshop station."

func _on_workshop_wrap(visit_id: String) -> void:
    if selected_cart_slot.begins_with("gift_") or selected_cart_slot.begins_with("ribbon_"):
        var delivered: Dictionary = bridge.request_action("drop_cart", {"slot": selected_cart_slot, "to": "workshop"})
        if bool(delivered.get("ok", false)):
            selected_cart_slot = ""
            cart.clear_selection()
            feedback.text = "Finishing material delivered to wrap station. Tap WRAP again."
        return
    bridge.request_action("gift_wrap", {"visit_id": visit_id})

func _on_workshop_trade(visit_id: String) -> void:
    if selected_cart_slot.begins_with("prize_"):
        var delivered: Dictionary = bridge.request_action("drop_cart", {"slot": selected_cart_slot, "to": "trade_counter"})
        if bool(delivered.get("ok", false)):
            selected_cart_slot = ""
            cart.clear_selection()
            feedback.text = "Prize placed at trade counter."
        return
    bridge.request_action("trade_up", {"visit_id": visit_id})

func _on_simulation_event(event_data: Dictionary) -> void:
    arcade.receive_event(event_data)
