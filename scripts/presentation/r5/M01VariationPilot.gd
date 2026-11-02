class_name M01VariationPilot
extends RefCounted
## Visual-only, deterministic M01 common-prefix variation library V1.
## No RNG, gameplay command, credit, reservation or stock mutation.
const VERSION := "m01-common-prefix-v1"
const REVEAL_TICK := 180
const ATTEMPT_TICKS := 240
const IDS_WIN := ["W1","W2","W3"]
const IDS_MISS := ["M1","M2","M3"]

static func _smooth(v: float) -> float:
    var t: float=clampf(v,0.0,1.0)
    return t*t*(3.0-2.0*t)

static func _hash(stage_id: String, session_id: String, attempt_index: int, visual_seed: int) -> int:
    var key: String=VERSION+"|"+stage_id+"|"+session_id+"|"+str(attempt_index)+"|"+str(visual_seed)
    var state: int=5381
    for byte_value in key.to_utf8_buffer():
        state=(state*131+int(byte_value))%2147483647
    return state

static func select(stage_id: String, session_id: String, attempt_index: int, visual_seed: int) -> Dictionary:
    var pair_index: int=_hash(stage_id,session_id,attempt_index,visual_seed)%3
    return {"pair_index":pair_index,"common_prefix":"P"+str(pair_index+1),
        "win_id":IDS_WIN[pair_index],"miss_id":IDS_MISS[pair_index],
        "version":VERSION}

static func sample(selection: Dictionary, outcome: String, visual_tick: int) -> Dictionary:
    var t: int=clampi(visual_tick,0,239)
    var pair: int=int(selection.get("pair_index",0))
    var p: Dictionary={"visual_tick":t,"phase":"ALIGN","x":.5,"y":.35,
        "z":0.0,"grip":0.0,"carry":false,"drop":false,"fall_progress":0.0,"fall_rotation":0.0,
        "offset":Vector2.ZERO,
        "rotation":0.0,"squash":1.0,"variant":"P"+str(pair+1),
        "resolved":false}
    # Both authoritative outcomes take EXACTLY the same branch until tick 180.
    if t < REVEAL_TICK:
        if t < 60:
            var u: float=_smooth(float(t)/59.0)
            p["x"]=lerpf(.5,.82,u)
            p["y"]=lerpf(.35,.75,u)
            p["phase"]="ALIGN"
        elif t < 118:
            p["x"]=.82;p["y"]=.75
            p["z"]=_smooth(float(t-60)/57.0)
            p["phase"]="DESCEND"
        elif t < 144:
            p["x"]=.82;p["y"]=.75;p["z"]=1.0
            p["grip"]=_smooth(float(t-118)/25.0)
            p["phase"]="CLENCH"
        else:
            var lift: float=_smooth(float(t-144)/35.0)
            p["x"]=.82;p["y"]=.75
            p["z"]=lerpf(1.0,.47,lift)
            p["grip"]=1.0
            p["carry"]=true
            p["phase"]="AMBIGUOUS_LIFT"
            # Three *common* micro-gestures, shared by paired W/M cases.
            if pair==1:
                p["offset"]=Vector2(-9.0*lift,3.0*lift)
                p["rotation"]=-.10*lift
            elif pair==2:
                p["offset"]=Vector2(2.0*sin(float(t-144)*.30),7.0*(1.0-lift))
                p["squash"]=.93+.07*lift
        return p
    var u: float=_smooth(float(t-180)/59.0)
    var lift_to_top: float=_smooth(float(t-180)/43.0)
    p["x"]=lerpf(.82,.23,u)
    p["y"]=lerpf(.75,.38,u)
    p["z"]=lerpf(.47,0.0,lift_to_top)
    p["grip"]=1.0
    p["carry"]=true
    p["resolved"]=true
    p["phase"]="RESOLVE"
    if outcome=="win":
        p["variant"]=IDS_WIN[pair]
        if pair==0:
            p["phase"]="W1_CLEAN_CARRY"
        elif pair==1:
            p["phase"]="W2_EDGE_SETTLE"
            p["offset"]=Vector2(lerpf(-9.0,0.0,u),lerpf(3.0,0.0,u))
            p["rotation"]=-.10*(1.0-u)
        else:
            p["phase"]="W3_DEEP_PILE_RECOVERY"
            p["offset"]=Vector2(2.0*sin(float(t-180)*.24)*(1.0-u),7.0*(1.0-u))
            p["squash"]=lerpf(.93,1.0,u)
    elif outcome=="miss":
        p["variant"]=IDS_MISS[pair]
        var release_tick: int=[215,195,220][pair]
        p["phase"]=["M1_APEX_TENSION_LOSS","M2_EDGE_DROP","M3_UNSTABLE_TUMBLE"][pair]
        if pair==1:
            p["rotation"]=-.10+ .24*_smooth(float(t-180)/15.0)
            p["offset"]=Vector2(-9.0+20.0*_smooth(float(t-180)/15.0),0)
        elif pair==2:
            p["offset"]=Vector2(10.0*sin(float(t-180)*.24),4.0*sin(float(t-180)*.32))
            p["rotation"]=.17*sin(float(t-180)*.23)
        if t>=release_tick:
            p["carry"]=false
            p["drop"]=true
            p["fall_progress"]=_smooth(float(t-release_tick)/float(maxi(1,239-release_tick)))
            p["fall_rotation"]=float([.15,1.35,-2.20][pair])*float(p["fall_progress"])
            p["grip"]=lerpf(1.0,.22,_smooth(float(t-release_tick)/12.0))
            p["phase"]="M"+str(pair+1)+"_FALLING"
    else:
        # No unknown outcome can produce a giveaway 'win' reveal.
        p["carry"]=false
        p["variant"]="UNKNOWN"
        p["phase"]="UNRESOLVED"
    return p
