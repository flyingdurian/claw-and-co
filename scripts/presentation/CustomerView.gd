class_name CustomerView
extends Control
signal request_selected(visit_id: String)
@export var visit_id: String = ""
@onready var face: TextureRect = $Face
@onready var bubble: Label = $SpeechBubble
@onready var button: Button = $ActionButton
@onready var expression: Label = $ReactionLabel
var last_action: String = ""

func _ready() -> void:
    face.visible = false # Live sprite actor is the character; the request panel is UI only.
    button.pressed.connect(func() -> void: request_selected.emit(visit_id))

func show_visit(id: String, snapshot: Dictionary, reaction: String = "") -> void:
    visit_id = id
    var n: int = int(id.trim_prefix("V"))
    var portrait: int = 1
    if n == 2: portrait = 2
    elif n in [5, 7]: portrait = 3
    elif n in [4, 6]: portrait = 4
    var filename: String = "res://art/parity/customer/portrait_%d.png" % portrait
    face.visible = false
    var visit: Dictionary = snapshot.get("customers", {}).get("visits", {}).get(visit_id, {})
    var state: String = str(visit.get("state", "SCHEDULED"))
    var next: int = int(visit.get("next", 0))
    var steps: Array = visit.get("definition", {}).get("steps", [])
    last_action = ""
    if next < steps.size() and str(visit.get("active_step", "")).is_empty():
        last_action = str(steps[next].get("action", ""))
    var messages: Dictionary = {"purchase_card":"IC card, please!", "admit_session":"Let's play!", "gift_wrap":"Gift wrap, please!", "trade_up":"Prize trade-up!"}
    # Requests come only from stage-authored steps that need player service.
    # A playing, watching or idle customer does NOT display an order bubble.
    if reaction == "STUCK":
        bubble.text = "Staff Key, please!"
    else:
        bubble.text = str(messages.get(last_action, ""))
    bubble.visible = not bubble.text.is_empty()
    button.text = visit_id + " · SERVE"
    button.visible = not last_action.is_empty()
    button.disabled = last_action.is_empty()
    expression.text = ""
    if reaction in ["SELF_COLLECTED", "OUTPUT_HELD"]:
        expression.text = "✦ ★ ✦"
    elif reaction == "MISS_RELEASED":
        expression.text = "!"
    elif reaction == "STUCK":
        expression.text = "!?"

