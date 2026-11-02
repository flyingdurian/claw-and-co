extends SceneTree
## Exact win/miss reservation carries, no inventory changes or speculative wins.
var assertions := 0
var failures := 0
func check(condition: bool, label: String) -> void:
    assertions+=1
    if not condition:
        failures+=1
        printerr("M01_PRIZE_FAIL ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
    var machine:=load("res://scenes/machines/M01_Machine.tscn").instantiate()
    root.add_child(machine)
    for i in 4: await process_frame
    check(machine.m01_v31_rig!=null and machine.m01_authoritative_carry!=null,
        "actual Gate E M01 creates approved gantry and reserved prize sprite")
    check(machine.m01_chamber_backdrop!=null and machine.m01_chamber_backdrop.show_behind_parent,
        "original registered chamber renders behind cabinet")
    var session_win: Dictionary={"requested_prize_instance_id":"TEST_PRIZE","attempts":[{"duration_ticks":100,"result":"win"}]}
    var snapshot: Dictionary={"tick":85,
        "machines":{"machines":{"M01":{"state":"PLAYING","session":"S01","attempt":0,
        "due":100,"cassette":"C01","output":""}}},
        "inventory":{"TEST_PRIZE":{"item_id":"plush_panda","owner":"cassette:C01","reservation":"S01"}}}
    var unchanged: Dictionary=snapshot.duplicate(true)
    machine.apply_snapshot(snapshot,{"S01":session_win})
    check(machine.m01_authoritative_carry.visible,
        "authored win carries exactly reserved prize during real M01 animation")
    check(not machine.stock_sprites[0].visible,"reserved physical stock is not drawn twice")
    var pose: Dictionary=machine.m01_v31_rig.last_pose
    check(machine.m01_authoritative_carry.position.distance_to(
        (pose["wire_bottom"] as Vector2)+Vector2(0,73))<.001,
        "prize follows real Z cable end without changing gantry motion")
    check(snapshot==unchanged,"presentation never mutates inventory, reservations or machine state")
    var session_miss: Dictionary={"requested_prize_instance_id":"TEST_PRIZE","attempts":[{"duration_ticks":100,"result":"miss"}]}
    machine.apply_snapshot(snapshot,{"S01":session_miss})
    check(not machine.m01_authoritative_carry.visible and machine.stock_sprites[0].visible,
        "miss never carries prize and stock remains visible")
    var wrong: Dictionary=snapshot.duplicate(true)
    wrong["inventory"]["TEST_PRIZE"]["reservation"]="DIFFERENT_SESSION"
    machine.apply_snapshot(wrong,{"S01":session_win})
    check(not machine.m01_authoritative_carry.visible,
        "reservation mismatch blocks speculative carried prize")
    var held: Dictionary=snapshot.duplicate(true)
    held["machines"]["machines"]["M01"]["state"]="OUTPUT_HELD"
    held["machines"]["machines"]["M01"]["output"]="TEST_PRIZE"
    held["inventory"]["TEST_PRIZE"]["owner"]="output:M01"
    held["inventory"]["TEST_PRIZE"]["reservation"]=""
    machine.apply_snapshot(held,{"S01":session_win})
    check(not machine.m01_authoritative_carry.visible and machine.output_prize.visible,
        "authentic output slot is used after the authoritative state transfers")
    machine.queue_free()
    print("M01_AUTHORED_PRIZE_ASSERTIONS=",assertions," PASSED=",assertions-failures," FAILED=",failures)
    quit(0 if failures==0 else 1)
