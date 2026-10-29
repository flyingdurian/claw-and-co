class_name SimulationDriver
extends Node
## Attach to a persistent root Node (later Gate E scene). No scene-switch pause.
var simulation: SimulationRoot

func _ready() -> void:
    Engine.physics_ticks_per_second = 60
    process_mode = Node.PROCESS_MODE_ALWAYS
    simulation = SimulationRoot.create()
    if simulation == null:
        push_error("Cannot load Claw & Co. stage manifest")
        set_physics_process(false)

func _physics_process(_delta: float) -> void:
    if simulation != null and simulation.clock.tick < simulation.stage["duration_ticks"]:
        simulation.advance()

func submit(command_id: String, action: String, payload: Dictionary = {}) -> Dictionary:
    if simulation == null: return {"ok": false, "reason": "NOT_LOADED"}
    return simulation.command(command_id, action, payload)

func snapshot() -> Dictionary:
    if simulation == null: return {}
    return simulation.game_snapshot()
