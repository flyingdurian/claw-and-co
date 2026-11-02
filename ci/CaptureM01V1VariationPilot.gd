extends SceneTree
## Godot 4.7.2 proof: six actual M01_Machine.tscn pilot performances.
const PILOT=preload("res://scripts/presentation/r5/M01VariationPilot.gd")
const OUTPUT:="res://ci/output/m01v1/screenshots/"
const INPUT:="res://data/tests/m01_v1_pilot_fixtures.json"
var machine: Node
var label: Label

func _initialize()->void:call_deferred("run")

func _seed_for(sid: String, index: int) -> int:
    for seed in range(0,300):
        if int(PILOT.select("stage_01",sid,0,seed)["pair_index"])==index:
            return seed
    return -1

func _shot(name: String)->void:
    for i in range(3):await process_frame
    await RenderingServer.frame_post_draw
    var img: Image=root.get_texture().get_image()
    assert(img.get_size()==Vector2i(1280,720))
    assert(img.save_png(ProjectSettings.globalize_path(OUTPUT+name+".png"))==OK)
    print("M01_V1_CAPTURE=",name)

func run()->void:
    root.size=Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    var backdrop:=Sprite2D.new()
    backdrop.name="OriginalArcadeBackground"
    backdrop.centered=false
    backdrop.texture=load("res://art/r5/front_aisle_architecture.png") as Texture2D
    root.add_child(backdrop)
    machine=(load("res://scenes/machines/M01_Machine.tscn") as PackedScene).instantiate()
    machine.position=Vector2(465,145)
    machine.scale=Vector2.ONE*1.30
    root.add_child(machine)
    var title_panel:=ColorRect.new()
    title_panel.position=Vector2(15,15)
    title_panel.size=Vector2(495,68)
    title_panel.color=Color(.08,.08,.12,.82)
    root.add_child(title_panel)
    label=Label.new()
    label.position=Vector2(25,24)
    label.add_theme_font_size_override("font_size",22)
    root.add_child(label)
    for i in range(5):await process_frame
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(INPUT))
    var n:=0
    for pair in data["pairs"]:
        var index: int=int(pair["pair_index"])
        var sid: String=str(pair["win"]["session_id"])
        var seed: int=_seed_for(sid,index)
        assert(seed>=0)
        machine.call("set_m01_visual_identity","stage_01",seed)
        for result_name in ["win","miss"]:
            var chosen: Dictionary=PILOT.select("stage_01",sid,0,seed)
            var id: String=str(chosen["win_id"]) if result_name=="win" else str(chosen["miss_id"])
            var instance: String=str(pair[result_name]["requested_prize_instance_id"])
            var session_data: Dictionary={
                "requested_prize_instance_id":instance,
                "attempts":[{"duration_ticks":240,"result":result_name}]}
            var inventory: Dictionary={instance:{
                "item_id":"plush_panda","owner":"cassette:V1_FIX","reservation":sid}}
            var snapshot: Dictionary={"tick":0,"machines":{"machines":{"M01":{
                "state":"PLAYING","session":sid,"attempt":0,"due":240,
                "cassette":"V1_FIX","output":""}}},"inventory":inventory}
            for visual_tick in [163,205,229]:
                snapshot["tick"]=visual_tick
                machine.call("apply_snapshot",snapshot,{sid:session_data})
                var phase: String=str((machine.get("m01_last_visual") as Dictionary).get("phase",""))
                label.text="M01 V1  "+id+"   |   Tick "+str(visual_tick)+" / 240\n"+phase
                await _shot(id+"_%03d"%visual_tick)
                n+=1
    assert(n==18)
    print("M01_V1_GODOT_CAPTURES=18")
    quit(0)
