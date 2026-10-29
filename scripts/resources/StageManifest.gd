@tool
class_name StageManifest
extends Resource
@export var stage_id: String = ""
@export var title: String = ""
@export_file("*.json") var json_path: String = "res://data/stage_01.json"
@export var duration_ticks: int = 7200

func load_runtime_data() -> Dictionary:
    return SchemaLoader.load_json(json_path, "clawco.stage/v1")
