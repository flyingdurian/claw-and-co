extends Node2D
## Isolated visual-proof composition. Never modifies gameplay, cart or stock.
## All art is independently authored. Missing art is an error, NOT a fallback.
const SOURCE := "res://art/r5/"
const ART := {
  "Environment": "arcade_environment.png",
  "M01/Shadow": "m01_shadow.png",
  "M01/Interior": "m01_interior.png",
  "M01/Mechanism": "m01_mechanism.png",
  "M01/Body": "m01_body.png",
  "M01/Marquee": "m01_marquee.png",
  "M01/Glass": "m01_glass.png",
  "M01/LightMask": "m01_lightmask.png"
}
const PRIZES := ["res://art/prizes/plush_panda.png", "res://art/prizes/plush_mochi.png"]
@onready var machine: Node2D = $M01
@onready var a: Sprite2D = $M01/Stock/PrizeA
@onready var b: Sprite2D = $M01/Stock/PrizeB
var art_ready: bool = false

func _ready() -> void:
    for node_path in ART.keys():
        var path: String = SOURCE + str(ART[node_path])
        if not ResourceLoader.exists(path):
            push_error("R5.1 original art missing; refusing substitute: " + path)
            return
        var tex: Texture2D = load(path) as Texture2D
        if tex == null:
            push_error("R5.1 could not decode independent art: " + path)
            return
        (get_node(NodePath(node_path)) as Sprite2D).texture = tex
    a.texture = load(PRIZES[0]) as Texture2D
    b.texture = load(PRIZES[1]) as Texture2D
    if a.texture == null or b.texture == null:
        push_error("R5.1 fixture prize art is missing")
        return
    art_ready = true
    set_stock_demo("plush")
    set_view_demo("normal")

func set_stock_demo(kind: String) -> void:
    ## Visual fixture only, NOT the authoritative machine ledger.
    if not art_ready:
        return
    match kind:
        "plush": a.visible = true; b.visible = true
        "empty": a.visible = false; b.visible = false
        _:
            push_error("R5.1 invalid proof inventory state: " + kind)

func set_view_demo(kind: String) -> void:
    if not art_ready:
        return
    match kind:
        "normal":
            machine.position = Vector2(640, 385)
            machine.scale = Vector2.ONE
        "detail":
            machine.position = Vector2(640, 470)
            machine.scale = Vector2(1.5, 1.5)
        _:
            push_error("R5.1 invalid proof camera state: " + kind)
