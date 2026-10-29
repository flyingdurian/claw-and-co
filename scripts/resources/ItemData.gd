@tool
class_name ItemData
extends Resource
## Immutable catalog metadata. Live quantities and ownership belong to InventoryLedger.
@export var item_id: String = ""
@export_enum("card", "plush", "figure", "gift_box", "ribbon", "cassette") var kind: String = "plush"
@export var label: String = ""
@export var sprite_key: String = ""
@export var card_mode: String = ""
@export var credit_units: int = 0
@export var trade_value: int = 0
@export var prize_size: String = ""
@export var wrap_capacity: int = 0
@export var cassette_format: String = ""
@export var capacity_units: int = 0

static func from_json(source: Dictionary) -> ItemData:
    var result := ItemData.new()
    for prop in ["id", "kind", "label", "sprite_key", "card_mode", "credit_units", "trade_value", "prize_size", "wrap_capacity", "cassette_format", "capacity_units"]:
        if source.has(prop):
            result.set("item_id" if prop == "id" else prop, source[prop])
    return result
