extends SceneTree
# Render actual M01_Machine.tscn (not a fabricated claw diagram).
const OUT:="res://ci/output/m01slice/screenshots/"
var machine: Node
func _initialize()->void:call_deferred("run")
func _shot(name:String)->void:
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
    var im:Image=root.get_texture().get_image()
    assert(im.get_size()==Vector2i(1280,720))
    assert(im.save_png(ProjectSettings.globalize_path(OUT+name+".png"))==OK)
    print("M01_SLICE_ENGINE_FRAME=",name)
func run()->void:
    root.size=Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var backdrop:=Sprite2D.new()
    backdrop.centered=false
    backdrop.texture=load("res://art/r5/front_aisle_architecture.png")
    root.add_child(backdrop)
    machine=(load("res://scenes/machines/M01_Machine.tscn") as PackedScene).instantiate()
    machine.position=Vector2(375,-210)
    machine.scale=Vector2.ONE*1.65
    root.add_child(machine)
    for i in 5:await process_frame
    var stock:Dictionary={"TEST_PRIZE":{"item_id":"plush_panda","owner":"cassette:C01","reservation":"S01"}}
    var snap:Dictionary={"tick":15,"machines":{"machines":{"M01":{"state":"PLAYING","session":"S01","attempt":0,"due":100,"cassette":"C01","output":""}}},"inventory":stock}
    var win:Dictionary={"S01":{"requested_prize_instance_id":"TEST_PRIZE","attempts":[{"duration_ticks":100,"result":"win"}]}}
    machine.call("apply_snapshot",snap,win)
    await _shot("01_game_machine_early_attempt")
    snap["tick"]=85
    machine.call("apply_snapshot",snap,win)
    await _shot("02_game_machine_reserved_prize_lift")
    var miss:Dictionary={"S01":{"requested_prize_instance_id":"TEST_PRIZE","attempts":[{"duration_ticks":100,"result":"miss"}]}}
    machine.call("apply_snapshot",snap,miss)
    await _shot("03_game_machine_missed_attempt_stock_intact")
    snap["machines"]["machines"]["M01"]["state"]="OUTPUT_HELD"
    snap["machines"]["machines"]["M01"]["output"]="TEST_PRIZE"
    stock["TEST_PRIZE"]["owner"]="output:M01"
    stock["TEST_PRIZE"]["reservation"]=""
    machine.call("apply_snapshot",snap,win)
    await _shot("04_game_machine_authoritative_output")
    print("M01_SLICE_GODOT_CAPTURES=4")
    quit(0)
