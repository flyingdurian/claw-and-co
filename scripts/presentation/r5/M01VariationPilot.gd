class_name M01VariationPilot
extends RefCounted
## Visual-only M01 V2 variation library: five paired outcomes, common first 180 ticks.
## No RNG, gameplay command, credit, reservation or stock mutation.
const VERSION := "m01-complete-library-v2"
const REVEAL_TICK := 180
const ATTEMPT_TICKS := 240
const IDS_WIN := ["W1","W2","W3","W4","W5"]
const IDS_MISS := ["M1","M2","M3","M4","M5"]

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
    var pair_index: int=_hash(stage_id,session_id,attempt_index,visual_seed)%5
    return {"pair_index":pair_index,"common_prefix":"P"+str(pair_index+1),
        "win_id":IDS_WIN[pair_index],"miss_id":IDS_MISS[pair_index],
        "version":VERSION}

static func sample(selection: Dictionary, outcome: String, visual_tick: int) -> Dictionary:
    var t: int=clampi(visual_tick,0,239)
    var pair: int=int(selection.get("pair_index",0))
    var p: Dictionary={"visual_tick":t,"phase":"ALIGN","x":.5,"y":.35,
        "z":0.0,"grip":0.0,"carry":false,"drop":false,"fall_progress":0.0,"fall_rotation":0.0,
        "offset":Vector2.ZERO,"tension":0.0,"stretch":1.0,
        "rotation":0.0,"squash":1.0,"landed":false,"variant":"P"+str(pair+1),
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
            elif pair==3:
                # Same *ambiguous* preparatory tension in paired W4/M4.
                p["offset"]=Vector2(1.8*sin(float(t-144)*.22),5.0*(1.0-lift))
                p["tension"]=.30*lift
                p["stretch"]=1.0+.035*lift
                p["squash"]=1.0-.03*lift
            elif pair==4:
                # Both W5 and M5 start with the SAME deceptive edge lift.
                p["offset"]=Vector2(-12.0*lift,2.0*lift)
                p["rotation"]=-.12*lift
                p["tension"]=.28*lift
                p["stretch"]=1.0+.03*lift
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
        elif pair==2:
            p["phase"]="W3_DEEP_PILE_RECOVERY"
            p["offset"]=Vector2(2.0*sin(float(t-180)*.24)*(1.0-u),7.0*(1.0-u))
            p["squash"]=lerpf(.93,1.0,u)
        elif pair==3:
            # W4: near-slip dip, then a visibly *damped* secure recovery.
            p["phase"]="W4_NEAR_SLIP_RECOVERY"
            var slip: float=sin(PI*_smooth(float(t-180)/32.0))
            p["offset"]=Vector2(4.0*slip,11.0*slip)
            p["rotation"]=.13*slip
            p["tension"]=.55*slip
            p["stretch"]=1.0+.095*slip
            p["squash"]=1.0-.045*slip
        else:
            # W5: initial off-centre pull, damped toward stable transit.
            p["phase"]="W5_OFF_CENTER_STABILIZE"
            var damping: float=(1.0-u)*(1.0-u)
            p["offset"]=Vector2(-12.0*damping+3.0*sin(float(t-180)*.34)*damping,
                2.0*damping)
            p["rotation"]=-.12*damping
            p["tension"]=.25*damping
            p["stretch"]=1.0+.055*damping
    elif outcome=="miss":
        p["variant"]=IDS_MISS[pair]
        var release_tick: int=[215,195,220,202,225][pair]
        p["phase"]=["M1_APEX_TENSION_LOSS","M2_EDGE_DROP","M3_UNSTABLE_TUMBLE",
        "M4_PARTIAL_CLAMP_TUG","M5_LATE_DELIVERY_SLIP"][pair]
        if pair==1:
            p["rotation"]=-.10+ .24*_smooth(float(t-180)/15.0)
            p["offset"]=Vector2(-9.0+20.0*_smooth(float(t-180)/15.0),0)
        elif pair==2:
            p["offset"]=Vector2(10.0*sin(float(t-180)*.24),4.0*sin(float(t-180)*.32))
            p["rotation"]=.17*sin(float(t-180)*.23)
        elif pair==3:
            # M4 partially closes, pulls briefly, and lets go.
            var tug: float=sin(PI*_smooth(float(t-180)/float(release_tick-180)))
            p["offset"]=Vector2(3.0*tug,9.0*tug)
            p["squash"]=1.0-.09*tug
            p["tension"]=.76*tug
            p["stretch"]=1.0+.075*tug
            p["grip"]=lerpf(.78,.94,tug)
        elif pair==4:
            # M5 gets near the delivery side BEFORE losing grip.
            var edge_u: float=_smooth(float(t-180)/float(release_tick-180))
            p["offset"]=Vector2(lerpf(-12.0,-3.0,edge_u),2.0*(1.0-edge_u))
            p["rotation"]=-.12*(1.0-edge_u)
            p["tension"]=.42*edge_u
            p["stretch"]=1.0+.08*edge_u
        if t>=release_tick:
            p["carry"]=false
            p["drop"]=true
            var fall_end: int=237 if pair==4 else 239
            p["fall_progress"]=_smooth(float(t-release_tick)/float(maxi(1,fall_end-release_tick)))
            p["landed"]=bool(t>=fall_end)
            p["fall_rotation"]=float([.15,1.35,-2.20,.60,-.95][pair])*float(p["fall_progress"])
            p["grip"]=lerpf(1.0,.22,_smooth(float(t-release_tick)/12.0))
            p["phase"]="M"+str(pair+1)+("_SETTLED" if bool(p["landed"]) else "_FALLING")
            if pair==4:
                # Hold mechanism at release pose: a falling prize must NOT
                # follow a moving claw after separation. Landing is inside
                # the original chamber by tick 237 (before due tick 240).
                var release_u: float=_smooth(float(release_tick-180)/59.0)
                p["x"]=lerpf(.82,.23,release_u)
                p["y"]=lerpf(.75,.38,release_u)
                p["z"]=lerpf(.47,0.0,_smooth(float(release_tick-180)/43.0))
                p["offset"]=Vector2.ZERO
                p["rotation"]=0.0
                p["squash"]=1.0
                p["stretch"]=1.0
                p["tension"]=0.0
    else:
        # No unknown outcome can produce a giveaway 'win' reveal.
        p["carry"]=false
        p["variant"]="UNKNOWN"
        p["phase"]="UNRESOLVED"
    return p
