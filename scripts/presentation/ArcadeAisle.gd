class_name ArcadeAisle
extends Control
signal cabinet_selected(machine_id: String)
signal customer_selected(visit_id: String)
signal help_requested
signal restock_requested
signal counter_requested
@onready var living_crowd: LiveCrowdDirector = $Crowd
var stages: Dictionary = {}
var machine_nodes: Dictionary = {}
var customer_nodes: Dictionary = {}
var reactions: Dictionary = {}
var visits_by_machine: Dictionary = {"M01": [], "M02": [], "M03": [], "M04": []}

func _ready() -> void:
    for id in ["M01", "M02", "M03", "M04"]:
        var mv: MachineView = get_node("Cabinets/" + id) as MachineView
        var cv: CustomerView = get_node("Customers/" + id) as CustomerView
        machine_nodes[id] = mv
        customer_nodes[id] = cv
        mv.cabinet_selected.connect(func(mid: String) -> void: cabinet_selected.emit(mid))
        cv.request_selected.connect(func(vid: String) -> void: customer_selected.emit(vid))
    $StaffKeyButton.pressed.connect(func() -> void: help_requested.emit())
    $RestockButton.pressed.connect(func() -> void: restock_requested.emit())
    $CounterButton.pressed.connect(func() -> void: counter_requested.emit())

func setup_stage(stage: Dictionary) -> void:
    visits_by_machine = {"M01": [], "M02": [], "M03": [], "M04": []}
    var session_map: Dictionary = {}
    for s in stage.get("sessions", []): session_map[str(s["session_id"])] = s
    stages = session_map
    # Stage metadata is routed only to the read-only M01 visual selector.
    # The authoritative stage schema remains unchanged.
    (machine_nodes["M01"] as MachineView).set_m01_visual_identity(
        str(stage.get("stage_id","stage_01")),1731)
    living_crowd.setup_stage(stage)
    for wave in stage.get("waves", []):
        for visit in wave.get("visits", []):
            for step in visit["steps"]:
                var sid: String = str(step.get("session_id", step.get("intended_session_id", "")))
                if not sid.is_empty() and session_map.has(sid):
                    var mid: String = str(session_map[sid]["machine_id"])
                    if not visits_by_machine[mid].has(visit["visit_id"]):
                        visits_by_machine[mid].append(str(visit["visit_id"]))
                    break

func apply_snapshot(snapshot: Dictionary) -> void:
    living_crowd.apply_snapshot(snapshot)
    var visits: Dictionary = snapshot.get("customers", {}).get("visits", {})
    for mid in machine_nodes:
        (machine_nodes[mid] as MachineView).apply_snapshot(snapshot, stages)
        var card: CustomerView = customer_nodes[mid] as CustomerView
        var active_id: String = ""
        for vid in visits_by_machine[mid]:
            var state: String = str(visits.get(vid, {}).get("state", "SCHEDULED"))
            var mid_state: String = str(snapshot.get("machines",{}).get("machines",{}).get(mid,{}).get("state",""))
            var stuck_session: bool = mid == "M02" and mid_state == "RESET_REQUIRED" and str(visits.get(vid, {}).get("active_step","")) == "admit_session"
            if state == "WAITING_FOR_SERVICE" or stuck_session:
                active_id = str(vid)
                break
        var recent: Dictionary = reactions.get(mid, {})
        var reaction: String = ""
        if not recent.is_empty() and int(snapshot.get("tick", 0)) - int(recent["tick"]) <= 105:
            reaction = str(recent["kind"])
            if active_id.is_empty():
                for completed_id in visits_by_machine[mid]:
                    if str(visits.get(completed_id, {}).get("state", "")) == "COMPLETE": active_id = str(completed_id)
        card.visible = not active_id.is_empty()
        if not active_id.is_empty():
            card.show_visit(active_id, snapshot, reaction)
            # Only display the panel if this is an actionable stage request.
            card.visible = card.button.visible or reaction == "STUCK"
            var at: Vector2 = living_crowd.actor_position(active_id)
            card.position = Vector2(clampf(at.x-93.0, 0, 1060), clampf(at.y-226.0,138.0,348.0))
    var machine: Dictionary = snapshot.get("machines", {}).get("machines", {}).get("M02", {})
    $StaffKeyButton.disabled = str(machine.get("state", "")) != "RESET_REQUIRED"
    $RestockButton.disabled = int(snapshot.get("tick", 0)) < 2100 or snapshot.get("staff_started", {}).has("J02")

func receive_event(event_data: Dictionary) -> void:
    living_crowd.receive_event(event_data)
    var mid: String = str(event_data.get("machine", ""))
    if not reactions.has(mid) and not machine_nodes.has(mid): return
    var kind: String = str(event_data.get("kind", ""))
    if kind in ["STUCK", "MISS_RELEASED", "SELF_COLLECTED", "OUTPUT_HELD"]:
        reactions[mid] = {"kind": kind, "tick": int(event_data.get("tick", 0))}
