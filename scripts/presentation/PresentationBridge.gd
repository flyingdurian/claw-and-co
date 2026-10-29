class_name PresentationBridge
extends Node
## Gate E adapter. No authority over inventory, credits, queues or attempts.
signal frame_updated(snapshot: Dictionary)
signal simulation_event(event_data: Dictionary)
signal command_feedback(action: String, result: Dictionary)
signal quote_ready(visit_id: String, quote: Dictionary)

@onready var driver: SimulationDriver = get_node("../SimulationDriver") as SimulationDriver
var _event_cursor: int = 0
var _machine_event_cursor: int = 0
var _workshop_event_cursor: int = 0
var _command_counter: int = 0
var last_snapshot: Dictionary = {}

func _ready() -> void:
    process_priority = 20  # Driver priority -20; present after authoritative tick.
    if driver == null or driver.simulation == null:
        push_error("PresentationBridge requires an initialized SimulationDriver")
        set_physics_process(false)
        return
    publish()

func _physics_process(_delta: float) -> void:
    publish()

func publish() -> void:
    if driver == null or driver.simulation == null: return
    last_snapshot = driver.snapshot()
    frame_updated.emit(last_snapshot)
    var history: Array = driver.simulation.event_log
    while _event_cursor < history.size():
        simulation_event.emit(history[_event_cursor])
        _event_cursor += 1
    var machine_events: Array = driver.simulation.machines.events
    while _machine_event_cursor < machine_events.size():
        simulation_event.emit(machine_events[_machine_event_cursor])
        _machine_event_cursor += 1
    var work_events: Array = driver.simulation.workshop.tick_events
    while _workshop_event_cursor < work_events.size():
        simulation_event.emit(work_events[_workshop_event_cursor])
        _workshop_event_cursor += 1


func request_action(action: String, payload: Dictionary = {}) -> Dictionary:
    if driver == null or driver.simulation == null:
        return {"ok": false, "reason": "NOT_LOADED"}
    _command_counter += 1
    var id: String = "gate_e_%d_%d_%s" % [driver.simulation.clock.tick, _command_counter, action]
    var result: Dictionary = driver.submit(id, action, payload)
    command_feedback.emit(action, result)
    publish()
    return result

func request_quote(visit_id: String) -> Dictionary:
    if driver == null or driver.simulation == null:
        return {"ok": false, "reason": "NOT_LOADED"}
    var quote: Dictionary = driver.simulation.quote_card_purchase(visit_id)
    quote_ready.emit(visit_id, quote)
    return quote
