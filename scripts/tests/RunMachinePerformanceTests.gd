extends SceneTree
## Presentation-only machine animation contract: no simulation mutation or RNG.
const MOTION = preload("res://scripts/presentation/MachinePerformanceTimeline.gd")
var checks: int = 0
var failures: Array = []
func expect(ok: bool, msg: String) -> void:
    checks += 1
    if not ok:
        failures.append(msg)
        printerr("R4_MACHINE_FAIL: ",msg)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    for mid in ["M01", "M02", "M03", "M04"]:
        var a: Dictionary = MOTION.sample(mid,"PLAYING",.8,120,"win")
        var b: Dictionary = MOTION.sample(mid,"PLAYING",.8,120,"win")
        expect(a == b,mid+" animation is deterministic at a given tick")
        expect(not str(a.get("cue","")).is_empty(),mid+" has an explicit play cue")
        expect(float(a.get("stock_lift",-1))>=0.0,mid+" has nonnegative stock lift")
    var miss: Dictionary = MOTION.sample("M03","PLAYING",.96,201,"miss")
    expect(str(miss["cue"])=="CUT_MISS","Barber failure has miss visual cue")
    var win: Dictionary = MOTION.sample("M01","PLAYING",.91,200,"win")
    var lost: Dictionary = MOTION.sample("M01","PLAYING",.91,200,"miss")
    expect(float(win["stock_lift"])==0.0 and float(lost["stock_lift"])==0.0,
        "M01 legacy stock lift cannot reveal result; V1 paired pickup supplies both visuals")
    var broken: Dictionary = MOTION.sample("M02","RESET_REQUIRED",0.0,100,"stuck")
    var reset: Dictionary = MOTION.sample("M02","RESETTING",.5,145,"stuck")
    expect(str(broken["cue"])=="FAULT","M02 jam indicator derives from actual machine state")
    expect(str(reset["cue"])=="REPOSITION_TO_DROP_ZONE","90-tick reset has separate motion")
    expect(float(reset["stock_lift"])>0.0,"M02 actual box reposition is visible")
    var refill: Dictionary = MOTION.sample("M01","CHANGEOVER",0,100)
    expect(str(refill["cue"])=="MAINTENANCE_RESTOCK","cassette changeover has service cue")
    print("R4_MACHINE_ASSERTIONS=",checks)
    print("R4_MACHINE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
