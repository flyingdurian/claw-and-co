@tool
class_name MachineData
extends Resource
## Immutable machine-type specification.
@export var machine_type_id: String = ""
@export var kind: String = ""
@export var label: String = ""
@export var cassette_formats: PackedStringArray = []
@export var accepted_prize_kinds: PackedStringArray = []
@export var admission_credits: int = 0
@export var attempt_ticks: int = 0
@export var settle_ticks: int = 0
@export var changeover_ticks: int = 0
@export var reset_ticks: int = 0

static func from_json(source: Dictionary) -> MachineData:
    var r := MachineData.new()
    r.machine_type_id = str(source["id"])
    r.kind = str(source["kind"])
    r.label = str(source["label"])
    r.cassette_formats = PackedStringArray(source["cassette_formats"])
    r.accepted_prize_kinds = PackedStringArray(source["accepted_prize_kinds"])
    r.admission_credits = int(source["admission_credits"])
    var timing: Dictionary = source["timing"]
    r.attempt_ticks = int(timing["attempt_ticks"])
    r.settle_ticks = int(timing["settle_ticks"])
    r.changeover_ticks = int(timing["changeover_ticks"])
    r.reset_ticks = int(timing["reset_ticks"])
    return r
