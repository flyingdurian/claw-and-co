extends Node2D
## R5.1-M isolated scene: never modifies Stage 1 simulation state.
## Actual Godot composition: original architecture, original cabinet body, independent parts.
var mechanic: Node2D
var cabinet: Node2D
var elapsed: float = 0.0
var run_demo: bool = true
var assets_loaded: bool = false

func _ready() -> void:
    var backdrop := Sprite2D.new()
    backdrop.name = "FrontAisleEnvironment"
    backdrop.texture = load("res://art/r5/front_aisle_architecture.png") as Texture2D
    backdrop.centered = false
    add_child(backdrop)
    cabinet = Node2D.new()
    cabinet.name = "CabinetM01"
    cabinet.position = Vector2(455, 16)
    cabinet.scale = Vector2(0.44, 0.44)
    add_child(cabinet)
    _layer("EmptyChamber", "res://art/r5/m01_interior_recovered.png")
    _layer("CameraMatchedCeilingRails", "res://art/r5/m01_fixed_depth_rails.png")
    mechanic = load("res://scenes/r5/M01MechanicalRig.tscn").instantiate() as Node2D
    cabinet.add_child(mechanic)
    _layer("OriginalM01Exterior", "res://art/r5/m01_body.png")
    assets_loaded = backdrop.texture != null and mechanic != null and bool(mechanic.get("assets_loaded"))
    if assets_loaded:
        set_demo_tick(0)

func _layer(label: String, texture_path: String) -> void:
    var tex := load(texture_path) as Texture2D
    if tex == null:
        push_error("R5.1-M missing layer " + texture_path)
        return
    var spr := Sprite2D.new()
    spr.name = label
    spr.texture = tex
    spr.centered = false
    cabinet.add_child(spr)

func set_demo_tick(tick: int) -> void:
    if mechanic != null and bool(mechanic.get("assets_loaded")):
        mechanic.call("set_demo_tick", tick)

func _process(delta: float) -> void:
    if run_demo and assets_loaded:
        elapsed += delta
        set_demo_tick(int(elapsed * 60.0) % 720)

func set_zoom_for_capture(use_detail: bool) -> void:
    if use_detail:
        cabinet.scale = Vector2(0.71, 0.71)
        cabinet.position = Vector2(275, -165)
    else:
        cabinet.scale = Vector2(0.44, 0.44)
        cabinet.position = Vector2(455, 16)
