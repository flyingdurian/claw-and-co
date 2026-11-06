extends SceneTree
## A real Godot playthrough with scripted input. The simulation decides every transaction.
var game: NeonShiftGame
var frame := 0
var ready_to_record := false
var schedule: Dictionary={
    0:[["bench"],["charge"]],
    190:[["load_card"],["floor"],["select","V01"],["primary"]],
    235:[["primary"]],
    560:[["select","V02"],["primary"]],
    605:[["primary"]],
    930:[["select","V03"],["bench"]],
    980:[["primary"]],
    1110:[["floor"]],
    1230:[["reset"]],
    1830:[["bench"],["charge"]],
    2020:[["load_card"],["cassette"]],
    2140:[["load_cassette"],["floor"],["restock"]],
    2230:[["select","V04"],["bench"],["primary"]],
    2330:[["floor"],["select","V05"],["primary"]],
    2390:[["primary"]],
    3090:[["select","V06"],["primary"]],
    3150:[["primary"]],
    3630:[["bench"],["charge"]],
    3820:[["load_card"],["floor"]],
    3950:[["select","V07"],["primary"]],
    4650:[["select","V08"],["primary"]],
    4700:[["primary"]]
}
var submitted: Dictionary={}
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
    root.size=Vector2i(1280,720)
    game=load("res://scenes/neon_shift/NeonShift.tscn").instantiate()
    game.capture_mode=true
    root.add_child(game)
    await process_frame
    game.set_physics_process(false)
    game.best={};game.unlocked=0
    ready_to_record=true
func _process(_delta:float)->bool:
    if not ready_to_record:return false
    frame+=1
    if frame==90: game.start_shift(0)
    if frame>=90 and game.mode=="playing":
        for substep in 2:
            var t:int=game.session.sim.clock.tick
            for target in schedule:
                if t>=int(target) and not submitted.has(target):
                    for op in schedule[target]:
                        if op[0]=="select": game.selected_visit=op[1]
                        else: game.activate(op[0])
                    submitted[target]=true
            game._physics_process(1.0/60.0)
    if frame==2830:
        print("NEON_MOVIE_SUMMARY ",JSON.stringify(game.session.summary()))
        game.music.stop();game.sfx.stop()
    if frame>=2840:
        game.free();game=null
        quit()
    return false
