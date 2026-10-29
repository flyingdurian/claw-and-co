class_name LiveCrowdDirector
extends Node2D
## Busy arcade crowd with deterministic trajectories and state-derived performances.
## Ambient spectators are visual-only. Gameplay customers are bound to visits/sessions.
const ACTOR_SCRIPT = preload("res://scripts/presentation/LiveActor.gd")
const PERSPECTIVE = preload("res://scripts/presentation/PerspectiveCrowdRoutes.gd")
const COUNT := 10
const MACHINE_X := {"M01":315.0, "M02":575.0, "M03":843.0, "M04":1095.0}
var actors: Dictionary = {}
var patrons: Array = []
var visit_machine: Dictionary = {}
var visit_actor: Dictionary = {}
var stage_visits: Dictionary = {}
var session_map: Dictionary = {}
var events: Dictionary = {}
var last_visit_moods: Dictionary = {}
var last_frame_tick: int = -1
var far_crowd: Node2D
var actor_depth: Dictionary = {}

func setup_stage(stage: Dictionary) -> void:
    stage_visits.clear()
    session_map.clear()
    visit_machine.clear()
    for s in stage.get("sessions",[]): session_map[str(s["session_id"])] = s
    for w in stage.get("waves", []):
        for v in w.get("visits", []):
            var vid: String = str(v["visit_id"])
            stage_visits[vid] = v
            visit_machine[vid] = "M01"
            for step in v.get("steps",[]):
                var sid: String = str(step.get("session_id",step.get("intended_session_id","")))
                if session_map.has(sid):
                    visit_machine[vid] = str(session_map[sid]["machine_id"])
                    break
    far_crowd = get_node_or_null("../FarCrowd") as Node2D
    for a in get_children(): a.queue_free()
    if far_crowd != null:
        for a in far_crowd.get_children(): a.queue_free()
    actor_depth.clear()
    actors.clear()
    patrons.clear()
    visit_actor.clear()
    var ids: Array = stage_visits.keys()
    ids.sort()
    for i in ids.size():
        var id: String = str(ids[i])
        var person: LiveActor = _spawn(id, (i * 3 + 2) % COUNT, i, .62)
        actors[id] = person
        visit_actor[id] = person
    # Atmosphere is not a painted crowd; every background patron receives a schedule.
    for i in 12:
        var id: String = "BG_%02d" % i
        var p: LiveActor = _spawn(id, i % COUNT, 20+i, .32 + float(i%4)*.08)
        patrons.append(p)

func _spawn(person_id: String, sprite_no: int, i: int, magnitude: float) -> LiveActor:
    var body: LiveActor = ACTOR_SCRIPT.new() as LiveActor
    body.name = "Animated_" + person_id
    add_child(body)
    var texture: Texture2D = load("res://art/living/actor_%02d.png" % (sprite_no+1)) as Texture2D
    body.configure(person_id, texture, i, magnitude)
    return body

func _place_layer(actor: LiveActor, at: Vector2) -> void:
    # Stage depth can genuinely occlude background pedestrians behind cabinets.
    if far_crowd == null: return
    var desired: Node2D = self if at.y >= 451.0 else far_crowd
    if actor.get_parent() != desired:
        actor.reparent(desired, false)
    actor_depth[actor.person_id] = PERSPECTIVE.depth_for_y(at.y)

func _pingpong(a: float) -> float:
    var p: float = fposmod(a, 2.0)
    return p if p <= 1.0 else 2.0-p

func _interpolate_route(tick: int, index: int) -> Vector2:
    # Authored deterministic loop with 3 independently timed stations and dwell windows.
    var t: int = tick + index * 149
    var period: int = 970 + (index % 4) * 157
    var u: float = float(t % period) / float(period)
    var p0 := Vector2(35 + (index % 5)*45, 420 + (index % 3)*12)
    var p1 := Vector2(275 + (index % 4)*135, 442 + (index % 2)*20)
    var p2 := Vector2(950 + (index % 4)*75, 435 + (index % 3)*15)
    if u < .23: return p0.lerp(p1, u/.23)
    if u < .35: return p1 + Vector2(2.0*sin(float(t)*.09),0)
    if u < .62: return p1.lerp(p2,(u-.35)/.27)
    if u < .73: return p2 + Vector2(sin(float(t)*.08)*3,0)
    if u < .92: return p2.lerp(p0,(u-.73)/.19)
    return p0

func receive_event(e: Dictionary) -> void:
    var kind: String = str(e.get("kind",""))
    var mid: String = str(e.get("machine",""))
    if kind in ["STUCK","MISS_RELEASED","OUTPUT_HELD","SELF_COLLECTED","STAFF_RESET_DONE_NEXT_ATTEMPT"] and not mid.is_empty():
        events[mid] = {"kind":kind,"tick":int(e.get("tick",0))}

func _owned_prop(snapshot: Dictionary, cid: String) -> String:
    var inv: Dictionary = snapshot.get("inventory",{})
    var ids: Array = inv.keys()
    ids.sort()
    for instance_id in ids:
        var rec: Dictionary = inv[instance_id]
        if str(rec.get("owner","")) == "customer:" + cid and str(rec.get("item_id","")) in ["plush_mochi","plush_panda","figure_fox","figure_star"]:
            return str(rec["item_id"])
    return ""

func _stage_action(visit: Dictionary) -> String:
    var steps: Array = visit.get("definition",{}).get("steps",[])
    var next_index: int = int(visit.get("next",0))
    if next_index >= 0 and next_index < steps.size(): return str(steps[next_index].get("action",""))
    return ""

func apply_snapshot(s: Dictionary) -> void:
    var tick: int = int(s.get("tick",0))
    last_frame_tick = tick
    var visits: Dictionary = s.get("customers",{}).get("visits",{})
    var machines: Dictionary = s.get("machines",{}).get("machines",{})
    var accounts: Dictionary = s.get("customers",{}).get("accounts",{})
    var active_wins: Array = []
    var active_misses: Array = []
    for mid in events:
        if tick - int(events[mid]["tick"]) < 85 and str(events[mid]["kind"]) in ["OUTPUT_HELD","SELF_COLLECTED"]: active_wins.append(mid)
        if tick - int(events[mid]["tick"]) < 60 and str(events[mid]["kind"]) == "MISS_RELEASED": active_misses.append(mid)
    for i in patrons.size():
        var actor: LiveActor = patrons[i]
        var route_state: Dictionary = PERSPECTIVE.ambient_pose(tick, i)
        var at: Vector2 = route_state["position"]
        var mood: String = route_state["action"]
        var extra: String = ""
        for mid in active_wins:
            if absf(at.x-float(MACHINE_X[mid])) < 240.0 and at.y > 435:
                mood = "CHEER"
                extra = "SELF_COLLECTED"
                break
        if extra.is_empty():
            for mid in active_misses:
                if absf(at.x-float(MACHINE_X[mid])) < 190.0 and at.y > 435:
                    mood = "WATCH"
                    extra = "MISS_RELEASED"
                    break
        _place_layer(actor, at)
        actor.render_at(tick, at, mood, extra, "", -1.0, float(route_state["scale"]))
    var vids: Array = visits.keys()
    vids.sort()
    for vid_variant in vids:
        var vid: String = str(vid_variant)
        if not actors.has(vid): continue
        var v: Dictionary = visits[vid]
        var mid: String = str(visit_machine.get(vid,"M01"))
        var machine: Dictionary = machines.get(mid,{})
        var state: String = str(v.get("state","SCHEDULED"))
        var active_step: String = str(v.get("active_step",""))
        var acc: Dictionary = accounts.get(str(v.get("definition",{}).get("customer_id","")),{})
        var e: Dictionary = events.get(mid,{})
        var recent: String = str(e.get("kind","")) if tick-int(e.get("tick",-1000)) < 100 else ""
        var arrival: int = int(v.get("definition",{}).get("arrival_tick",0))
        var elapsed: int = maxi(0,tick-arrival)
        var deadline: int = int(v.get("definition",{}).get("deadline_tick",tick+1))
        var pct: float = clampf(float(deadline-tick)/float(maxi(1,deadline-arrival))*100.0,0,100)
        var at: Vector2 = Vector2(float(MACHINE_X[mid]), 467.0)
        var mood: String = "CHAT"
        var actor: LiveActor = actors[vid]
        actor.visible = true
        var route_index: int = int(vid.trim_prefix("V")) + 5
        # An eventual buyer is already an independently moving member of the crowd.
        # Their service request appears ONLY when CustomerManager authors arrival.
        if state == "SCHEDULED":
            var roam_state: Dictionary = PERSPECTIVE.ambient_pose(tick,route_index)
            var roaming: Vector2 = roam_state["position"]
            var ambient_pose: String = "CHAT" if (int(float(tick)/120.0)+route_index)%4 == 0 else "WALK"
            _place_layer(actor,roaming)
            actor.render_at(tick,roaming,ambient_pose,"","",-1.0,float(roam_state["scale"]))
            continue
        # Individual transition from previous browse route into the exact authored machine queue.
        if elapsed < 85:
            var previous: Vector2 = PERSPECTIVE.ambient_pose(maxi(0,arrival-1),route_index)["position"]
            at = PERSPECTIVE.approach(previous,Vector2(float(MACHINE_X[mid])-35.0,455.0),float(elapsed)/85.0)["position"]
            mood = "ARRIVE"
        elif state == "COMPLETE":
            var finish_tick: int = int(last_visit_moods.get(vid,{}).get("completed_at",tick))
            var depart_fraction: float = clampf(float(tick-finish_tick)/135.0,0.0,1.0)
            at = Vector2(float(MACHINE_X[mid]),457).lerp(Vector2(1320,472),depart_fraction)
            mood = "LEAVE" if depart_fraction > .25 else ("SAD" if recent == "MISS_RELEASED" else "CELEBRATE")
            if depart_fraction >= 1.0: actor.visible = false
        elif active_step == "admit_session":
            at = Vector2(float(MACHINE_X[mid]) + 9.0,457)
            mood = "CONCENTRATE"
            if str(machine.get("state","")) == "RESET_REQUIRED": mood = "FRUSTRATED"
            elif str(machine.get("state","")) == "RESETTING": mood = "ANTICIPATE"
            elif str(machine.get("state","")) == "OUTPUT_HELD": mood = "WIN"
        elif state == "WAITING_FOR_SERVICE":
            mood = "TRY_AGAIN" if recent == "MISS_RELEASED" else "REQUEST"
            at = Vector2(float(MACHINE_X[mid])-32,455)
        elif state == "WAITING_FOR_CABINET":
            at = Vector2(float(MACHINE_X[mid])-40,465)
            mood = "QUEUE"
        else:
            mood = "WATCH"
        var old: Dictionary = last_visit_moods.get(vid,{})
        if state == "COMPLETE" and str(old.get("state","")) != "COMPLETE":
            last_visit_moods[vid] = {"state":"COMPLETE","completed_at":tick}
        elif not last_visit_moods.has(vid): last_visit_moods[vid] = {"state":state}
        var r: String = recent if tick-int(e.get("tick",-1000)) < 70 else ""
        var prop: String = _owned_prop(s,str(v.get("definition",{}).get("customer_id","")))
        # Customer patience and due-time are authoritative read-only values.
        pct = minf(pct,100.0*float(int(acc.get("patience",3)))/3.0)
        _place_layer(actor,at)
        actor.render_at(tick,at,mood,r,prop,pct if state != "COMPLETE" else -1.0,PERSPECTIVE.sprite_scale(at.y))

func actor_position(visit_id: String) -> Vector2:
    if actors.has(visit_id): return (actors[visit_id] as LiveActor).position
    return Vector2(-100,-100)
