extends SceneTree
## Real Godot 4.7.2 1280x720 proof, 10 authored variants across six phases.
const PILOT = preload("res://scripts/presentation/r5/M01VariationPilot.gd")
const INPUT = "res://data/tests/m01_v2_variation_fixtures.json"
const OUTPUT = "res://ci/output/m01v2/screenshots/"
var machine: Node
var label: Label

func _seed_for(sid: String, pair_index: int)->int:
    for seed in range(0,700):
        if int(PILOT.select("stage_01",sid,0,seed)["pair_index"])==pair_index:
            return seed
    return -1

func _initialize()->void:call_deferred("run")
func _shot(name: String)->void:
    for i in range(3):await process_frame
    await RenderingServer.frame_post_draw
    var img: Image=root.get_texture().get_image()
    assert(img.get_size()==Vector2i(1280,720))
    assert(img.save_png(ProjectSettings.globalize_path(OUTPUT+name+".png"))==OK)
    print("M01_V2_CAPTURE=",name)

func run()->void:
    root.size=Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    var backdrop:=Sprite2D.new()
    backdrop.centered=false
    backdrop.texture=load("res://art/r5/front_aisle_architecture.png") as Texture2D
    root.add_child(backdrop)
    machine=(load("res://scenes/machines/M01_Machine.tscn") as PackedScene).instantiate()
    machine.position=Vector2(465,145)
    machine.scale=Vector2.ONE*1.30
    root.add_child(machine)
    var panel:=ColorRect.new()
    panel.position=Vector2(15,15)
    panel.size=Vector2(540,80)
    panel.color=Color(.07,.05,.10,.82)
    root.add_child(panel)
    label=Label.new()
    label.position=Vector2(26,23)
    label.add_theme_font_size_override("font_size",22)
    root.add_child(label)
    for i in range(5):await process_frame
    var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(INPUT))
    var count:int=0
    for pair in fixtures["pairs"]:
        var sid:String=str(pair["session_id"])
        var index:int=int(pair["pair_index"])
        var instance:String=str(pair["prize_instance_id"])
        var seed:int=_seed_for(sid,index)
        assert(seed>=0)
        machine.call("set_m01_visual_identity","stage_01",seed)
        for outcome in ["win","miss"]:
            var selection: Dictionary=PILOT.select("stage_01",sid,0,seed)
            var id:String=str(selection["win_id"]) if outcome=="win" else str(selection["miss_id"])
            var session: Dictionary={"requested_prize_instance_id":instance,
                "attempts":[{"duration_ticks":240,"result":outcome}]}
            var snap:Dictionary={"tick":0,"machines":{"machines":{"M01":{
                "state":"PLAYING","session":sid,"attempt":0,"due":240,
                "cassette":"V2","output":""}}},"inventory":{instance:{
                    "item_id":"plush_panda","owner":"cassette:V2","reservation":sid}}}
            var marks:Array=[163,205,228,238]
            if id=="W4":marks=[163,194,205,228,238]
            if id=="W5":marks=[163,187,205,213,228,238]
            if id=="M4":marks=[163,194,201,205,228,238]
            if id=="M5":marks=[163,205,225,228,237,238]
            for visual_tick in marks:
                snap["tick"]=visual_tick
                machine.call("apply_snapshot",snap,{sid:session})
                var phase:String=str((machine.get("m01_last_visual") as Dictionary).get("phase",""))
                label.text="M01 V2  "+id+"   |   Tick "+str(visual_tick)+" / 240\n"+phase
                await _shot(id+"_%03d"%visual_tick)
                count+=1
    assert(count==47)
    print("M01_V2_GODOT_CAPTURES=47")
    quit(0)
