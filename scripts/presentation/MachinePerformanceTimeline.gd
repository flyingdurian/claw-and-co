class_name MachinePerformanceTimeline
extends RefCounted
## Stage-outcome-driven choreography only: never changes reservation/stock/attempt result.
## The machine's authoritative snapshot decides all outcomes.
static func _ease(u: float) -> float:
    var t: float = clampf(u,0.0,1.0)
    return t*t*(3.0-2.0*t)

static func _pulse(u: float, first: float, last: float) -> float:
    return _ease((u-first)/.085)* (1.0-_ease((u-last)/.085))

static func sample(machine_id: String, state: String, attempt_progress: float, tick: int, attempt_result: String = "") -> Dictionary:
    var t: float = clampf(attempt_progress,0.0,1.0)
    var p: float = float(tick)*TAU/120.0
    var r: Dictionary = {"dx":0.0,"dy":0.0,"angle":0.0,"grip":0.0,"flash":false,"stock_lift":0.0,"stock_tilt":0.0,"light":.25,"cue":"IDLE"}
    if state == "RESET_REQUIRED":
        r["cue"] = "FAULT"
        r["flash"] = tick%42<20
        r["light"] = .64
        return r
    if state == "RESETTING":
        r["cue"] = "REPOSITION_TO_DROP_ZONE"
        r["dx"] = 46.0*_ease(t)
        r["dy"] = -58.0*sin(t*PI)
        r["stock_tilt"] = .24*sin(t*PI)
        r["stock_lift"] = 21.0*sin(t*PI)
        r["flash"] = t > .76
        r["light"] = .58
        return r
    if state == "CHANGEOVER":
        r["cue"] = "MAINTENANCE_RESTOCK"
        r["dx"] = 3.0*sin(p*3.0)
        r["light"] = .23+.15*absf(sin(p*3.0))
        return r
    if state == "OUTPUT_HELD" or state == "SETTLING":
        r["cue"] = "CHUTE_COLLECTION" if state == "OUTPUT_HELD" else "PRIZE_SETTLING"
        r["flash"] = true
        r["light"] = .72
        return r
    if state != "PLAYING":
        r["dx"] = 5.0*sin(p*.4)
        r["light"] = .25+.09*sin(p)
        r["cue"] = "ATTRACT_LOOP"
        return r
    match machine_id:
        "M01":
            # Authentic sequence: track -> lower -> contact -> grip -> rise -> chute.
            r["dx"] = 66.0*_ease(t/.28) - 31.0*_ease((t-.78)/.20)
            r["dy"] = 115.0*_ease((t-.26)/.22)-115.0*_ease((t-.58)/.21)
            r["grip"] = _ease((t-.48)/.07)
            # M01 V1 owns the *same* visible pickup for both outcomes.
            # Never allow a separate legacy win-only stock lift to leak the
            # result before the protected 75% ambiguity threshold.
            r["stock_lift"] = 0.0
            r["cue"] = "ALIGN" if t<.26 else ("DESCEND" if t<.50 else ("GRIP" if t<.58 else ("LIFT" if t<.81 else "CHUTE")))
        "M02":
            r["dx"] = 64.0*_ease(t/.28)-26.0*_ease((t-.81)/.17)
            r["dy"] = 95.0*_ease((t-.28)/.26)-95.0*_ease((t-.70)/.20)
            r["grip"] = _ease((t-.53)/.12)
            r["stock_tilt"] = .24*sin(t*PI*2.0) if attempt_result=="stuck" else .10*sin(t*PI)
            r["stock_lift"] = 62.0*_ease((t-.60)/.25) if attempt_result == "win" else 0.0
            r["cue"] = "UFO_ALIGN" if t<.28 else ("PRONG_CONTACT" if t<.65 else ("BOX_STUCK" if attempt_result=="stuck" else "BOX_TIP"))
        "M03":
            r["dx"] = 49.0*_ease(t/.56)
            r["dy"] = 54.0*_ease((t-.45)/.35)
            r["angle"] = .23*_ease((t-.78)/.12)
            r["flash"] = t>.82 and t<.96
            r["cue"] = "SCISSOR_TRACK" if t<.75 else ("SNIP" if t<.91 else ("CUT_MISS" if attempt_result=="miss" else "CUT_WIN"))
        "M04":
            r["angle"] = .12*sin(p*1.6)
            r["stock_tilt"] = .05*sin(p)
            r["stock_lift"] = 64.0*_ease((t-.64)/.22) if attempt_result=="win" else 0.0
            r["cue"] = "SHOWCASE_ORBIT" if t<.68 else "PEDESTAL_DELIVER"
            r["light"] = .55
            r["flash"] = t>.72
    return r
