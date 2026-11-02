extends SceneTree
## Dedicated deterministic V2 visual suite: no game authority changes.
const PILOT = preload("res://scripts/presentation/r5/M01VariationPilot.gd")
const FIXTURE_PATH = "res://data/tests/m01_v2_variation_fixtures.json"
var assertions: int=0
var failures: int=0
func check(ok: bool, label: String)->void:
    assertions+=1
    if not ok:
        failures+=1
        printerr("M01_V2_FAIL ",label)

func _seed_for(sid: String, pair_index: int) -> int:
    for seed in range(0,700):
        var v: Dictionary=PILOT.select("stage_01",sid,0,seed)
        if int(v["pair_index"])==pair_index: return seed
    return -1

func _initialize()->void:call_deferred("run")
func run()->void:
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
    check(int(data.get("attempt_duration_ticks",0))==240,"240-tick attempt")
    check(PILOT.REVEAL_TICK==180,"first 75 percent strictly ambiguous")
    check(PILOT.IDS_WIN.size()==5 and PILOT.IDS_MISS.size()==5,
        "all ten library definitions present")
    var machine: Node=(load("res://scenes/machines/M01_Machine.tscn") as PackedScene).instantiate()
    root.add_child(machine)
    for i in range(4):await process_frame
    var rig: Node2D=machine.get("m01_v31_rig") as Node2D
    var carry: Sprite2D=machine.get("m01_authoritative_carry") as Sprite2D
    var fall_proxy: Sprite2D=machine.get("m01_falling_proxy") as Sprite2D
    var calibration_digest: String=JSON.stringify(rig.config).sha256_text()
    var accepted: Array=[]
    for pair in data["pairs"]:
        var index: int=int(pair["pair_index"])
        var sid: String=str(pair["session_id"])
        var instance: String=str(pair["prize_instance_id"])
        var seed: int=_seed_for(sid,index)
        check(seed>=0,"deterministic seed found for pair "+str(index))
        var selection: Dictionary=PILOT.select("stage_01",sid,0,seed)
        check(selection==PILOT.select("stage_01",sid,0,seed),"stable selector "+str(index))
        check(str(selection["win_id"])=="W"+str(index+1) and
            str(selection["miss_id"])=="M"+str(index+1),"pair mapping "+str(index))
        var differs: bool=false
        for tick in range(0,240):
            var win: Dictionary=PILOT.sample(selection,"win",tick)
            var miss: Dictionary=PILOT.sample(selection,"miss",tick)
            check(float(win["x"])>=0.0 and float(win["x"])<=1.0 and
                float(win["y"])>=0.0 and float(win["y"])<=1.0 and
                float(win["z"])>=0.0 and float(win["z"])<=1.0,
                "win physical pose bounds "+str(index)+":"+str(tick))
            check(float(miss["x"])>=0.0 and float(miss["x"])<=1.0 and
                float(miss["y"])>=0.0 and float(miss["y"])<=1.0 and
                float(miss["z"])>=0.0 and float(miss["z"])<=1.0,
                "miss physical pose bounds "+str(index)+":"+str(tick))
            for sample in [win,miss]:
                check(float(sample["squash"])>=.86 and float(sample["squash"])<=1.08 and
                    float(sample["stretch"])>=.92 and float(sample["stretch"])<=1.14 and
                    float(sample["tension"])>=0.0 and float(sample["tension"])<=1.0 and
                    absf(float(sample["rotation"]))<=.28 and
                    (sample["offset"] as Vector2).length()<=22.0,
                    "plush deformation and offset extremes "+str(index)+":"+str(tick))
            if tick<180:
                check(win==miss,"entire shared prefix identical "+str(index)+":"+str(tick))
                check(not bool(win["resolved"]) and not bool(miss["resolved"]),
                    "no early outcome reveal "+str(index)+":"+str(tick))
            elif win!=miss:differs=true
        check(differs,"outcomes resolve only after tick 179 "+str(index))
        check(bool(PILOT.sample(selection,"win",239)["carry"]),"winning prize still held at 239")
        var final_miss: Dictionary=PILOT.sample(selection,"miss",239)
        check(not bool(final_miss["carry"]) and bool(final_miss["drop"]),
            "miss release committed visually before attempt end")
        if index==3:
            var near_slip: Dictionary=PILOT.sample(selection,"win",194)
            var tug: Dictionary=PILOT.sample(selection,"miss",194)
            check(str(near_slip["phase"])=="W4_NEAR_SLIP_RECOVERY" and
                float(near_slip["stretch"])>1.02,
                "W4 near-slip stretch resolved")
            check(str(tug["phase"])=="M4_PARTIAL_CLAMP_TUG" and
                float(tug["tension"])>.0,"M4 tension during partial tug")
            check(bool(PILOT.sample(selection,"miss",202)["drop"]),
                "M4 drop starts only after authored partial clamp")
        if index==4:
            var far: Dictionary=PILOT.sample(selection,"win",213)
            check(str(far["phase"])=="W5_OFF_CENTER_STABILIZE" and
                absf(float(far["rotation"]))<.12,
                "W5 off-center sway damps toward stable carrying")
            check(bool(PILOT.sample(selection,"miss",224)["carry"]),
                "M5 remains near delivery before late release")
            check(bool(PILOT.sample(selection,"miss",225)["drop"]),
                "M5 late release at tick 225")
            check(float(PILOT.sample(selection,"miss",236)["fall_progress"])<1.0,
                "M5 fall still moving before landing")
            for terminal in [237,238,239]:
                var landed: Dictionary=PILOT.sample(selection,"miss",terminal)
                check(bool(landed["landed"]) and
                    float(landed["fall_progress"])>=.999 and
                    str(landed["phase"])=="M5_SETTLED",
                    "M5 fully back into chamber before 240 at tick "+str(terminal))
            var drop_position: Dictionary=PILOT.sample(selection,"miss",225)
            var settled: Dictionary=PILOT.sample(selection,"miss",239)
            check(Vector2(drop_position["x"],drop_position["y"]).distance_to(
                    Vector2(settled["x"],settled["y"]))<.00001,
                "M5 drop origin remains still while plush falls")
        machine.call("set_m01_visual_identity","stage_01",seed)
        for outcome in ["win","miss"]:
            var session: Dictionary={"requested_prize_instance_id":instance,
                "attempts":[{"duration_ticks":240,"result":outcome}]}
            var snap: Dictionary={"tick":163,"machines":{"machines":{"M01":{
                "state":"PLAYING","session":sid,"attempt":0,"due":240,
                "cassette":"V2","output":""}}},"inventory":{instance:{
                    "item_id":"plush_panda","owner":"cassette:V2","reservation":sid}}}
            var original_snapshot: Dictionary=snap.duplicate(true)
            machine.call("apply_snapshot",snap,{sid:session})
            check(carry.visible and not fall_proxy.visible,
                "both outcomes physically pick up identical reserved plush")
            check(machine.get("m01_last_visual")==PILOT.sample(selection,outcome,163),
                "actual machine uses pure outcome-neutral sample")
            check(snap==original_snapshot,"presentation does not mutate authoritative snapshot")
            snap["tick"]=239
            machine.call("apply_snapshot",snap,{sid:session})
            check(carry.visible==(outcome=="win") and
                fall_proxy.visible==(outcome=="miss"),
                "final visible outcome obeys authored result "+outcome)
            check(not (machine.get("stock_sprites")[0] as Sprite2D).visible,
                "no duplicate in stock while visual proxy active")
            if index==4 and outcome=="miss":
                check(fall_proxy.position.distance_to(Vector2(405,775))<.001,
                    "M5 landed on exact chamber pile target before end")
            check(snap["inventory"]==original_snapshot["inventory"],
                "no inventory reservation or owner mutation")
            accepted.append(str(selection["win_id"]) if outcome=="win" else str(selection["miss_id"]))
    check(JSON.stringify(rig.config).sha256_text()==calibration_digest,
        "approved V3.1 calibration hash unchanged")
    check(accepted==["W1","M1","W2","M2","W3","M3","W4","M4","W5","M5"],
        "all ten pre-made win and miss sequences exercised")
    machine.queue_free()
    print("M01_V2_VARIANTS=",JSON.stringify(accepted))
    print("M01_V2_ASSERTIONS=",assertions," PASSED=",assertions-failures," FAILED=",failures)
    quit(0 if failures==0 else 1)
