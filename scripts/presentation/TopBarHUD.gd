class_name TopBarHUD
extends Control
@onready var title_label: Label = $StageTitle
@onready var timer_label: Label = $Timer
@onready var money_label: Label = $Money
@onready var score_label: Label = $Score
@onready var stars_label: Label = $Stars
@onready var score_meter: TextureProgressBar = $ScoreMeter
var stage_title: String = "Opening Rush"
var duration_ticks: int = 7200
var thresholds: Array = []

func setup_stage(stage: Dictionary) -> void:
    stage_title = str(stage.get("title", "Opening Rush"))
    duration_ticks = int(stage.get("duration_ticks", 7200))
    thresholds = stage.get("scoring", {}).get("thresholds", [])
    title_label.text = "CLAW & CO.  •  " + stage_title
    if not thresholds.is_empty(): score_meter.max_value = float(thresholds[-1]["minimum_score"])

func apply_snapshot(snapshot: Dictionary) -> void:
    var remaining: int = maxi(0, (duration_ticks - int(snapshot.get("tick", 0)) + 59) / 60)
    timer_label.text = "%02d:%02d" % [remaining / 60, remaining % 60]
    var money: int = int(snapshot.get("finance", {}).get("cash_minor", 0))
    money_label.text = "$%.2f" % (float(money) / 100.0)
    var c: Dictionary = snapshot.get("customers", {})
    var score: int = int(c.get("score", 0))
    score_label.text = "SCORE %d" % score
    var earned: int = int(c.get("stars", 0))
    stars_label.text = "★".repeat(earned) + "☆".repeat(3 - earned)
    score_meter.value = score
