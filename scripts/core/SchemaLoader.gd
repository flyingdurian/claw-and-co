class_name SchemaLoader
extends RefCounted
## Runtime subset of validation; full JSON Schema checks live under tests/.
static func load_json(path: String, expected: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("Missing JSON catalog: " + path)
        return {}
    var p := JSON.new()
    var err := p.parse(FileAccess.get_file_as_string(path))
    if err != OK or not (p.data is Dictionary):
        push_error("Invalid JSON %s at line %d: %s" % [path, p.get_error_line(), p.get_error_message()])
        return {}
    var doc: Dictionary = p.data
    if doc.get("schema_version") != expected:
        push_error("Schema version mismatch at " + path)
        return {}
    return doc

static func load_stage() -> Dictionary:
    var items: Dictionary = load_json("res://data/items.stage1.json", "clawco.items/v1")
    var machines: Dictionary = load_json("res://data/machine_types.stage1.json", "clawco.machine_types/v1")
    var stage: Dictionary = load_json("res://data/stage_01.json", "clawco.stage/v1")
    if items.is_empty() or machines.is_empty() or stage.is_empty():
        return {}
    if int(stage.get("tick_hz", 0)) != 60 or int(stage.get("duration_ticks", 0)) != 7200:
        push_error("Stage 1 must be 7200 ticks at 60Hz")
        return {}
    var ids: Dictionary = {}
    for d in items["items"]:
        if ids.has(d["id"]): return {}
        ids[d["id"]] = d
    var types: Dictionary = {}
    for d in machines["machine_types"]:
        if types.has(d["id"]): return {}
        types[d["id"]] = d
    for c in stage["cabinet_instances"]:
        if not types.has(c["machine_type_id"]):
            push_error("Unknown cabinet type " + str(c["machine_type_id"]))
            return {}
        if not ids.has(c["loaded_cassette"]["cassette_item_id"]): return {}
        for prize in c["loaded_cassette"]["contents"]:
            if not ids.has(prize["item_id"]): return {}
    for s in stage["sessions"]:
        if not (s.has("attempts") and s["attempts"].size() > 0): return {}
    return {"items": ids, "machine_types": types, "stage": stage}
