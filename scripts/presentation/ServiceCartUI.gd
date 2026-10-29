class_name ServiceCartUI
extends Control
## Physical items: 4 IC cards + 2 gift boxes + 2 ribbons + 2 prizes + 1 cassette.
## The Staff Key is a permanent tool, NOT an inventory instance.
signal cart_slot_selected(slot_id: String)
signal staff_key_selected
const SLOTS = ["supply_0", "supply_1", "supply_2", "supply_3", "gift_0", "gift_1", "ribbon_0", "ribbon_1", "prize_0", "prize_1", "bulk_0"]
var slot_buttons: Dictionary = {}
var slot_icons: Dictionary = {}
var slot_labels: Dictionary = {}
var slot_glows: Dictionary = {}
var catalog: Dictionary = {}
var selected_slot: String = ""
var latest_snapshot: Dictionary = {}

func _ready() -> void:
    for slot in SLOTS:
        var group: Control = get_node(slot) as Control
        var button: Button = group.get_node("Button") as Button
        slot_buttons[slot] = button
        slot_icons[slot] = group.get_node("ItemSprite")
        slot_labels[slot] = group.get_node("Empty")
        slot_glows[slot] = group.get_node("Selected")
        button.pressed.connect(_slot_pressed.bind(slot))
    var tool: Control = $staff_key
    slot_buttons["staff_key"] = tool.get_node("Button")
    slot_icons["staff_key"] = tool.get_node("ItemSprite")
    slot_labels["staff_key"] = tool.get_node("Empty")
    slot_labels["staff_key"].visible = false
    slot_glows["staff_key"] = tool.get_node("Selected")
    (slot_buttons["staff_key"] as Button).pressed.connect(_staff_key_pressed)

func setup_catalog(items: Dictionary) -> void:
    catalog = items.duplicate(true)

func _slot_pressed(slot: String) -> void:
    if str(latest_snapshot.get("cart", {}).get(slot, "")).is_empty():
        clear_selection()
    else:
        selected_slot = slot
        _apply_selection()
    cart_slot_selected.emit(slot)

func _staff_key_pressed() -> void:
    selected_slot = "staff_key"
    _apply_selection()
    staff_key_selected.emit()

func select_slot(slot: String) -> void:
    selected_slot = slot
    _apply_selection()

func clear_selection() -> void:
    selected_slot = ""
    _apply_selection()

func _apply_selection() -> void:
    for name in slot_glows:
        (slot_glows[name] as TextureRect).visible = selected_slot == name

func apply_snapshot(snapshot: Dictionary) -> void:
    latest_snapshot = snapshot
    var slots: Dictionary = snapshot.get("cart", {})
    var records: Dictionary = snapshot.get("inventory", {})
    for slot in SLOTS:
        var instance_id: String = str(slots.get(slot, ""))
        var label_node: Label = slot_labels[slot]
        var image_node: TextureRect = slot_icons[slot]
        label_node.visible = instance_id.is_empty()
        label_node.text = "EMPTY"
        image_node.texture = null
        if instance_id.is_empty(): continue
        var rec: Dictionary = records.get(instance_id, {})
        var item: Dictionary = catalog.get(str(rec.get("item_id", "")), {})
        var kind: String = str(item.get("kind", ""))
        var icon_name: String = ""
        match kind:
            "card": icon_name = "card"
            "cassette": icon_name = "cassette"
            "plush": icon_name = "plush"
            "figure": icon_name = "figure"
            "gift_box": icon_name = "gift"
            "ribbon": icon_name = "ribbon"
        if not icon_name.is_empty():
            image_node.texture = load("res://art/living/icon_" + icon_name + ".png") as Texture2D
    _apply_selection()
