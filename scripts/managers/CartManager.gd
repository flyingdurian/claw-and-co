class_name CartManager
extends RefCounted
## Stage 1 carrier contract: 4 supply, 2 prize, 1 cassette cradle.
var ledger: InventoryLedger
var items: Dictionary
const SLOT_NAMES = ["supply_0", "supply_1", "supply_2", "supply_3", "gift_0", "gift_1", "ribbon_0", "ribbon_1", "prize_0", "prize_1", "bulk_0"]
var slots: Dictionary = {}

func _init(p_ledger: InventoryLedger, item_catalog: Dictionary) -> void:
    ledger = p_ledger
    items = item_catalog
    for slot in SLOT_NAMES: slots[slot] = ""

func compatible(slot: String, instance_id: String) -> bool:
    if not slots.has(slot) or not items.has(ledger.item_of(instance_id)): return false
    var kind: String = str(items[ledger.item_of(instance_id)]["kind"])
    if slot.begins_with("supply_"): return kind == "card"
    if slot.begins_with("gift_"): return kind == "gift_box"
    if slot.begins_with("ribbon_"): return kind == "ribbon"
    if slot.begins_with("prize_"): return kind in ["plush", "figure"]
    return slot == "bulk_0" and kind == "cassette"

func pickup(instance_id: String, source: String, slot: String) -> bool:
    if not (source in ["workshop", "workshop:ready", "machine_bay", "machine_bay:ready", "trade_counter"]): return false
    if not compatible(slot, instance_id) or not str(slots[slot]).is_empty(): return false
    if ledger.reservation_of(instance_id) != "": return false
    if not ledger.transfer(instance_id, source, "cart:" + slot): return false
    slots[slot] = instance_id
    return true

func drop(slot: String, target: String) -> bool:
    if not (target in ["workshop", "workshop:ready", "machine_bay", "machine_bay:ready", "trade_counter"]): return false
    if not slots.has(slot) or str(slots[slot]).is_empty(): return false
    var id: String = str(slots[slot])
    if not ledger.transfer(id, "cart:" + slot, target): return false
    slots[slot] = ""
    return true

func snapshot() -> Dictionary:
    return slots.duplicate(true)
