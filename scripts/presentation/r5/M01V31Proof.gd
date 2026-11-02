extends Node2D
## Genuine Godot rendering proof: authoritative original cabinet plus exact
## V3.1 calibration in source-image coordinates. Does not run prize transactions.
var mechanic: Node2D
var cabinet: Node2D
var run_demo: bool = true
var elapsed: float = 0
var assets_loaded: bool = false

func _ready() -> void:
    var backdrop := Sprite2D.new()
    backdrop.name = "ArcadeEnvironment"
    backdrop.texture = load("res://art/r5/front_aisle_architecture.png") as Texture2D
    backdrop.centered = false
    add_child(backdrop)
    cabinet = Node2D.new()
    cabinet.name = "ApprovedM01Cabinet"
    cabinet.position = Vector2(380,-30)
    cabinet.scale = Vector2.ONE*.49
    add_child(cabinet)
    _layer("ApprovedChamber","m01_chamber_backdrop")
    _layer("OriginalCabinet","M01Cabinet")
    mechanic = load("res://scenes/r5/M01V31GantryRig.tscn").instantiate() as Node2D
    cabinet.add_child(mechanic)
    assets_loaded = bool(mechanic.get("ready_assets"))
    if assets_loaded:
        mechanic.call("set_pose",.5,.35,0.0,0.0)

func _layer(label: String, filename: String) -> void:
    var s := Sprite2D.new()
    s.name=label
    s.centered=false
    s.texture=load("res://art/m01_v31/"+filename+".png") as Texture2D
    cabinet.add_child(s)

func set_pose(x:float,y:float,z:float,g:float=0) -> void:
    if mechanic!=null: mechanic.call("set_pose",x,y,z,g)

func set_demo_tick(tick:int) -> void:
    if mechanic!=null: mechanic.call("set_demo_tick",tick)

func set_capture_zoom(large:bool) -> void:
    if large:
        cabinet.position=Vector2(235,-150)
        cabinet.scale=Vector2.ONE*.76
    else:
        cabinet.position=Vector2(380,-30)
        cabinet.scale=Vector2.ONE*.49

func _physics_process(delta:float) -> void:
    if run_demo and assets_loaded:
        elapsed+=delta
        set_demo_tick(int(elapsed*60.0)%720)
