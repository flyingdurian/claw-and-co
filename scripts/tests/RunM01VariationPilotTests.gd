extends SceneTree
## V1 tests read-only deterministic selector, complete prefixes, all 6
## authored outcomes, exact reserved visual carry and no ledger mutation.
const PILOT = preload("res://scripts/presentation/r5/M01VariationPilot.gd")
const FIXTURES = "res://data/tests/m01_v1_pilot_fixtures.json"
var assertions: int=0
var failures: int=0
func check(ok: bool, why: String)->void:
    assertions+=1
    if not ok:
        failures+=1
        printerr("M01_V1_FAIL ",why)

func _seed_for(stage_id: String, sid: String, wanted: int) -> int:
    for seed in range(0,300):
        if int(PILOT.select(stage_id,sid,0,seed)["pair_index"])==wanted:
            return seed
    return -1

func _initialize()->void:call_deferred("run")
func run()->void:
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURES))
    check(str(data.get("stage_id",""))=="stage_01","original stage identity")
    check(PILOT.REVEAL_TICK==180 and PILOT.ATTEMPT_TICKS==240,"75 percent threshold")
    var machine: Node=(load("res://scenes/machines/M01_Machine.tscn") as PackedScene).instantiate()
    root.add_child(machine)
    for i in range(4):await process_frame
    var rig: Node2D=machine.get("m01_v31_rig") as Node2D
    var claw: Node2D=rig.get("claw_root") as Node2D
    var carry: Sprite2D=machine.get("m01_authoritative_carry") as Sprite2D
    var initial_digest: String=JSON.stringify(rig.config).sha256_text()
    check(carry.get_parent()==claw,"uses approved real articulated claw parent")
    var tested: Array=[]
    for pair in data["pairs"]:
        var index: int=int(pair["pair_index"])
        var sid: String=str(pair["win"]["session_id"])
        var seed: int=_seed_for(str(data["stage_id"]),sid,index)
        check(seed>=0,"pair "+str(index)+" has a deterministic seed")
        var chosen: Dictionary=PILOT.select(str(data["stage_id"]),sid,0,seed)
        check(chosen==PILOT.select(str(data["stage_id"]),sid,0,seed),"same identity yields same variant")
        check(int(chosen["pair_index"])==index,"expected authored pair")
        check(PILOT.select(str(data["stage_id"]),sid,1,seed).has("win_id"),"attempt-index accepted")
        var changes_seen: int=0
        for visual_tick in range(0,180):
            var w: Dictionary=PILOT.sample(chosen,"win",visual_tick)
            var m: Dictionary=PILOT.sample(chosen,"miss",visual_tick)
            check(w==m,"prefix identical tick "+str(visual_tick)+" pair "+str(index))
            check(not bool(w["resolved"]),"no reveal before 180")
        var wlast: Dictionary=PILOT.sample(chosen,"win",179)
        var mlast: Dictionary=PILOT.sample(chosen,"miss",179)
        check(wlast==mlast and bool(wlast["carry"]),"identical held plush at ambiguity deadline")
        for visual_tick in [180,190,205,225,239]:
            var w: Dictionary=PILOT.sample(chosen,"win",visual_tick)
            var m: Dictionary=PILOT.sample(chosen,"miss",visual_tick)
            if w!=m:changes_seen+=1
        check(changes_seen>0,"win miss diverge AFTER tick 179")
        check(str(PILOT.sample(chosen,"win",235)["variant"])=="W"+str(index+1),
            "correct win sequence W"+str(index+1))
        check(str(PILOT.sample(chosen,"miss",235)["variant"])=="M"+str(index+1),
            "correct miss sequence M"+str(index+1))
        check(bool(PILOT.sample(chosen,"win",235)["carry"]) and
            not bool(PILOT.sample(chosen,"miss",235)["carry"]) and
            bool(PILOT.sample(chosen,"miss",235)["drop"]),
            "late resolution is carried win versus falling miss")
        for result_name in ["win","miss"]:
            var record: Dictionary=pair[result_name]
            var attempt: Dictionary={"duration_ticks":240,"result":result_name}
            var ses: Dictionary={"requested_prize_instance_id":record["requested_prize_instance_id"],
                "attempts":[attempt]}
            var inventory: Dictionary={record["requested_prize_instance_id"]:{
                "item_id":"plush_panda","owner":"cassette:FIX","reservation":sid}}
            var snapshot: Dictionary={"tick":160,
                "machines":{"machines":{"M01":{"state":"PLAYING","session":sid,"attempt":0,
                    "due":240,"cassette":"FIX","output":""}}},"inventory":inventory}
            var before: String=JSON.stringify(snapshot).sha256_text()
            machine.call("set_m01_visual_identity",str(data["stage_id"]),seed)
            machine.call("apply_snapshot",snapshot,{sid:ses})
            var prefix: Dictionary=machine.get("m01_last_visual")
            check(prefix==PILOT.sample(chosen,result_name,160),"scene matches deterministic pilot prefix")
            check(carry.visible and not (machine.get("stock_sprites")[0] as Sprite2D).visible,
                "same reserved prize visually picked up for both outcomes")
            check(JSON.stringify(snapshot).sha256_text()==before,"no snapshot writes during pickup")
            snapshot["tick"]=235
            machine.call("apply_snapshot",snapshot,{sid:ses})
            var fall_proxy: Sprite2D=machine.get("m01_falling_proxy") as Sprite2D
            check(carry.visible==(result_name=="win") and
                  fall_proxy.visible==(result_name=="miss"),
                  "win secure carry versus visible authored miss fall")
            check(not (machine.get("stock_sprites")[0] as Sprite2D).visible,
                  "no duplicate stock while visual carry or fall exists")
            check(JSON.stringify(snapshot).sha256_text()!=before,
                "test clock changed as expected while only snapshot is read")
            tested.append(str(chosen["win_id"]) if result_name=="win" else str(chosen["miss_id"]))
    check(JSON.stringify(rig.config).sha256_text()==initial_digest,
        "original V3.1 calibration remains untouched")
    check(tested==["W1","M1","W2","M2","W3","M3"],"all six pre-made pilots executed")
    machine.queue_free()
    print("M01_V1_VARIANTS=",JSON.stringify(tested))
    print("M01_V1_ASSERTIONS=",assertions," PASSED=",assertions-failures," FAILED=",failures)
    quit(0 if failures==0 else 1)
