class_name InventoryLedger
extends RefCounted
## Physical item instances have exactly one owner. Reservation does not change owner.
var records: Dictionary = {}
var mutations: Array = []

func register_item(instance_id: String, item_id: String, owner: String, metadata: Dictionary = {}) -> bool:
    if instance_id.is_empty() or records.has(instance_id): return false
    records[instance_id] = {"item_id": item_id, "owner": owner, "reservation": "", "meta": metadata.duplicate(true)}
    return true

func register_cassette(source: Dictionary, owner: String) -> bool:
    var cid: String = source["cassette_instance_id"]
    var ids: Dictionary = {}
    ids[cid] = true
    for p in source["contents"]:
        var pid: String = str(p["instance_id"])
        if pid.is_empty() or records.has(pid) or ids.has(pid): return false
        ids[pid] = true
    if records.has(cid) or cid.is_empty(): return false
    if not register_item(cid, str(source["cassette_item_id"]), owner): return false
    for p in source["contents"]:
        if not register_item(str(p["instance_id"]), str(p["item_id"]), "cassette:" + cid): return false
    return true

func owner_of(instance_id: String) -> String:
    return str(records.get(instance_id, {}).get("owner", ""))

func item_of(instance_id: String) -> String:
    return str(records.get(instance_id, {}).get("item_id", ""))

func reservation_of(instance_id: String) -> String:
    return str(records.get(instance_id, {}).get("reservation", ""))

func set_item_metadata(instance_id: String, key: String, value: Variant) -> bool:
    if not records.has(instance_id): return false
    records[instance_id]["meta"][key] = value
    return true

func meta_of(instance_id: String, key: String, fallback: Variant = null) -> Variant:
    if not records.has(instance_id): return fallback
    return records[instance_id]["meta"].get(key, fallback)

func reserve(instance_id: String, expected_owner: String, token: String) -> bool:
    if token.is_empty() or owner_of(instance_id) != expected_owner or not reservation_of(instance_id).is_empty(): return false
    records[instance_id]["reservation"] = token
    mutations.append({"action": "reserve", "item": instance_id, "token": token})
    return true

func release(instance_id: String, token: String) -> bool:
    if token.is_empty() or reservation_of(instance_id) != token: return false
    records[instance_id]["reservation"] = ""
    mutations.append({"action": "release", "item": instance_id, "token": token})
    return true

## Transfer list is one commit: [{id, from, to, token?}]. No partial transfers.
func transfer_many(transfers: Array) -> bool:
    var seen: Dictionary = {}
    for op in transfers:
        var id: String = str(op.get("id", ""))
        var src: String = str(op.get("from", ""))
        var dst: String = str(op.get("to", ""))
        var token: String = str(op.get("token", ""))
        if id.is_empty() or dst.is_empty() or src == dst or seen.has(id): return false
        seen[id] = true
        if owner_of(id) != src: return false
        var current_claim: String = reservation_of(id)
        if current_claim != token or src.begins_with("consumed:"): return false
    for op in transfers:
        var id: String = str(op["id"])
        records[id]["owner"] = str(op["to"])
        if not str(op.get("token", "")).is_empty():
            records[id]["reservation"] = ""
        mutations.append({"action": "transfer", "item": id, "from": op["from"], "to": op["to"]})
    return true

func transfer(id: String, src: String, dst: String, token: String = "") -> bool:
    return transfer_many([{"id": id, "from": src, "to": dst, "token": token}])

func items_at(owner: String) -> Array:
    var ids: Array = []
    for id in records.keys():
        if owner_of(str(id)) == owner: ids.append(id)
    ids.sort()
    return ids

func find_at(owner: String, item_id: String) -> String:
    for id in items_at(owner):
        if item_of(str(id)) == item_id and reservation_of(str(id)).is_empty(): return str(id)
    return ""

func verify() -> bool:
    for id in records.keys():
        var owner: String = owner_of(str(id))
        if owner.is_empty(): return false
        if owner.begins_with("cassette:"):
            var cassette: String = owner.substr(9)
            if not records.has(cassette) or cassette == id: return false
    return true

func snapshot() -> Dictionary:
    return records.duplicate(true)
