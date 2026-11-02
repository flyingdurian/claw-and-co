class_name MachineView
extends Control
const PERFORMANCE = preload("res://scripts/presentation/MachinePerformanceTimeline.gd")
## Illustrated cabinet with authoritative inventory-aware prizes and preset tick-locked actions.
## No procedural outcome decisions: all actions are purely presentation of MachineManager.
signal cabinet_selected(machine_id: String)
@export var machine_id: String = "M01"
@export var art: Texture2D
const ITEM_TEXTURES := {
    "plush_mochi":"res://art/prizes/plush_mochi.png",
    "plush_panda":"res://art/prizes/plush_panda.png",
    "figure_fox":"res://art/prizes/figure_fox.png",
    "figure_star":"res://art/prizes/figure_star.png"
}
@onready var artwork: Sprite2D = $BaseBody
@onready var mechanism: Sprite2D = $Mechanism
@onready var interior: Sprite2D = $PrizeInterior
@onready var glass: Sprite2D = $SpecularGlassOverlay
@onready var marquee: Sprite2D = $NeonMarquee
@onready var light: PointLight2D = $GlowLight
@onready var status_label: Label = $Status
@onready var select_button: Button = $SelectButton
@onready var stock_hero: Sprite2D = $StockHero
@onready var output_prize: Sprite2D = $ChutePrize
@onready var sparkle: Sprite2D = $ActionSparkle
var machine: Dictionary = {}
var session: Dictionary = {}
var tick: int = 0
var initial_position: Vector2 = Vector2.ZERO
var initial_glass_position: Vector2 = Vector2.ZERO
var stock_sprites: Array = []
var loaded_items: Array = []
var last_machine_state: String = ""
var m01_v31_rig: Node2D = null
var m01_chamber_backdrop: Sprite2D = null
var m01_authoritative_carry: Sprite2D = null

func _ready() -> void:
    initial_position = mechanism.position
    initial_glass_position = glass.position
    select_button.pressed.connect(func() -> void: cabinet_selected.emit(machine_id))
    mouse_filter = Control.MOUSE_FILTER_PASS
    stock_sprites.append(stock_hero)
    for i in range(1,7):
        var p := Sprite2D.new()
        p.name = "LiveStock_%d" % i
        p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        add_child(p)
        move_child(p, get_children().find($ChutePrize))
        stock_sprites.append(p)
    sparkle.texture = load("res://art/living/sparkle.png") as Texture2D
    # The approved V3.1 gantry is a child of the ORIGINAL cabinet's art
    # transform, so its 1024x1536 coordinates scale identically with the frame.
    # All M02-M04 machines and authoritative transactions are unchanged.
    if machine_id=="M01":
        artwork.texture=load("res://art/m01_v31/M01Cabinet.png") as Texture2D
        artwork.position=Vector2(0,27)
        artwork.scale=Vector2.ONE*(242.0/1024.0)
        mechanism.visible=false
        interior.visible=false
        glass.visible=false
        marquee.visible=false
        m01_v31_rig=load("res://scenes/r5/M01V31GantryRig.tscn").instantiate() as Node2D
        artwork.add_child(m01_v31_rig)
        # Original registered chamber art must be behind the cabinet facade.
        # M01 is not a flat machine-body texture with an empty window.
        m01_chamber_backdrop=Sprite2D.new()
        m01_chamber_backdrop.name="M01OriginalPrizeChamber"
        m01_chamber_backdrop.texture=load("res://art/m01_v31/m01_chamber_backdrop.png") as Texture2D
        m01_chamber_backdrop.centered=false
        m01_chamber_backdrop.show_behind_parent=true
        artwork.add_child(m01_chamber_backdrop)
        # Presentation-only item carried on the approved real animated claw.
        # This sprite never creates/removes inventory: the authoritative
        # MachineManager reservation and authored attempt decide visibility.
        m01_authoritative_carry=Sprite2D.new()
        m01_authoritative_carry.name="M01ReservedPrizeInClaw"
        m01_authoritative_carry.visible=false
        # Part of the articulated claw rather than a free-floating cabinet
        # sprite: the root supplies the exact cable/drop-shaft connection.
        # Draw the prize UNDER the left/right/rear finger rigs, not over them.
        var claw_grip: Node2D=m01_v31_rig.get("claw_root") as Node2D
        claw_grip.add_child(m01_authoritative_carry)
        claw_grip.move_child(m01_authoritative_carry,1)
        m01_authoritative_carry.z_index=0
        # Claw-local coordinates: the central motor hub is at y=0, and the
        # gripper tips converge below y≈600. Place the prize between them.
        m01_authoritative_carry.position=Vector2(0,640)

func _stock_items(snapshot: Dictionary) -> Array:
    var contents: Array = []
    var owner: String = "cassette:"+str(machine.get("cassette",""))
    var inventory: Dictionary = snapshot.get("inventory", {})
    var ids: Array = inventory.keys()
    ids.sort()
    for item_id in ids:
        var record: Dictionary = inventory[item_id]
        if str(record.get("owner","")) == owner:
            contents.append({"instance":str(item_id),"item":str(record.get("item_id",""))})
    return contents

func _set_prize(sprite: Sprite2D, item_id: String) -> void:
    var candidate: String = "res://art/prizes/"+item_id+".png"
    var path: String = candidate if ResourceLoader.exists(candidate) else str(ITEM_TEXTURES.get(item_id,""))
    sprite.visible = not path.is_empty()
    if path.is_empty(): return
    if str(sprite.get_meta("item_id","")) != item_id:
        sprite.texture = load(path) as Texture2D
        sprite.set_meta("item_id",item_id)

# Read-only physical prize presentation for the accepted M01 gantry.
# A sprite is carried only while the EXACT reserved instance belongs to the
# currently authored winning session. Miss, no reservation and output-held
# states never create a speculative catch or mutate inventory.
func _apply_m01_authored_carry(snapshot: Dictionary, sid: String, state: String,
        progress: float, outcome: String, stock: Array) -> void:
    if m01_authoritative_carry==null or m01_v31_rig==null: return
    m01_authoritative_carry.visible=false
    if state!="PLAYING" or outcome!="win" or progress<.58 or progress>=.94: return
    var requested: String=str(session.get("requested_prize_instance_id",""))
    if requested.is_empty() or sid.is_empty(): return
    var inventory: Dictionary=snapshot.get("inventory",{})
    var record: Dictionary=inventory.get(requested,{})
    var expected_owner: String="cassette:"+str(machine.get("cassette",""))
    if str(record.get("owner",""))!=expected_owner or str(record.get("reservation",""))!=sid:
        return
    var item_id: String=str(record.get("item_id",""))
    if item_id.is_empty(): return
    _set_prize(m01_authoritative_carry,item_id)
    if m01_authoritative_carry.texture==null: return
    var claw_grip: Node2D=m01_v31_rig.get("claw_root") as Node2D
    # The approved rig's root is scaled. Convert the illustrated plush
    # to 106 cabinet pixels (instead of the prior 203px floating sprite).
    # This is a visual-scale transform only; never alter the grip geometry.
    var source_width: float=float(m01_authoritative_carry.texture.get_width())
    var grip_scale: float=maxf(0.001,claw_grip.scale.x)
    m01_authoritative_carry.scale=Vector2.ONE*(106.0/maxf(1.0,source_width)/grip_scale)
    m01_authoritative_carry.visible=true
    # The same exact instance cannot appear simultaneously on the floor.
    for i in stock.size():
        if str(stock[i].get("instance",""))==requested and i<stock_sprites.size():
            (stock_sprites[i] as Sprite2D).visible=false

func apply_snapshot(snapshot: Dictionary, stage_sessions: Dictionary = {}) -> void:
    tick = int(snapshot.get("tick",0))
    machine = snapshot.get("machines",{}).get("machines",{}).get(machine_id,{})
    var sid: String = str(machine.get("session",""))
    session = stage_sessions.get(sid,{})
    var state: String = str(machine.get("state","UNLOADED"))
    last_machine_state = state
    status_label.text = machine_id+"   "+state.replace("_"," ")
    if state == "RESET_REQUIRED": status_label.text += "  KEY!"
    elif state == "CHANGEOVER": status_label.text = machine_id+"   RESTOCKING"
    var due: int = int(machine.get("due",-1))
    var progress: float = 0.0
    if state == "PLAYING" and not session.is_empty():
        var attempts: Array = session.get("attempts",[])
        var index: int = int(machine.get("attempt",0))
        if index >= 0 and index < attempts.size():
            var duration: int = maxi(1,int(attempts[index].get("duration_ticks",1)))
            progress = clampf(1.0-float(due-tick)/float(duration),0.0,1.0)
    var phase: float = float(tick % 240)*TAU/240.0
    # Active inventory: a depleted cabinet empties visually; changeover displays new stock.
    var stock: Array = _stock_items(snapshot)
    loaded_items = stock
    for i in stock_sprites.size():
        var sprite: Sprite2D = stock_sprites[i]
        sprite.visible = i < stock.size()
        if i >= stock.size(): continue
        var item: Dictionary = stock[i]
        _set_prize(sprite,str(item["item"]))
        var col: int = i%3
        var row: int = i/3
        sprite.position = Vector2(size.x*.5+(float(col)-float(mini(stock.size(),3)-1)*.5)*70.0, 233.0+row*69.0)
        sprite.scale = Vector2.ONE*(.81 if stock.size()<=1 else .45)
        if machine_id=="M01":
            # The old 145px plush sprites were pasted across the outside of
            # M01's 242px face. Register each item inside the ORIGINAL chamber
            # in the same source-image coordinates as the approved V3.1 rig.
            # This is presentation-only: stock still comes from InventoryLedger.
            var chamber_slots: Array[Vector2]=[
                Vector2(405,775),Vector2(660,770),Vector2(530,650),
                Vector2(355,645),Vector2(735,630),Vector2(500,560),
                Vector2(640,540)]
            sprite.position=artwork.position+chamber_slots[mini(i,chamber_slots.size()-1)]*artwork.scale.x
            sprite.scale=Vector2.ONE*.30
            sprite.z_index=1
        sprite.rotation = .026*sin(phase*1.3+float(i)*1.7)
        if state == "PLAYING" and i==0:
            sprite.rotation += .17*sin(progress*PI*2.0)
            sprite.position.y -= 7.0*sin(progress*PI)
        if state == "RESETTING" and i==0:
            var reset_u: float = clampf(1.0-float(due-tick)/90.0,0.0,1.0)
            sprite.position.x += 13.0*sin(reset_u*PI)
            sprite.rotation += .28*sin(reset_u*TAU)
    var output_instance: String = str(machine.get("output",""))
    var records: Dictionary = snapshot.get("inventory",{})
    var out_record: Dictionary = records.get(output_instance,{})
    output_prize.visible = state=="OUTPUT_HELD" and not output_instance.is_empty()
    if output_prize.visible:
        _set_prize(output_prize,str(out_record.get("item_id","")))
        if machine_id=="M01":
            # M01's illustrated pickup hatch is front-left, inside the body.
            # The authoritative output state alone controls visibility.
            output_prize.scale=Vector2.ONE*.30
            output_prize.position=Vector2(size.x*.48,318.0+2.0*sin(phase*3))
        else:
            output_prize.scale = Vector2.ONE*.48
            output_prize.position = Vector2(size.x*.76,360.0+5.0*sin(phase*3))
        output_prize.rotation = .10*sin(phase*2)
    mechanism.position = initial_position
    mechanism.rotation = 0.0
    mechanism.scale = Vector2.ONE
    glass.position = initial_glass_position
    glass.modulate.a = .12 + .075 * (1.0+sin(phase*2.3))*.5
    interior.rotation = 0.0
    interior.scale = Vector2.ONE
    marquee.modulate.a = .32 + .12*(1.0+sin(phase*2.2))*.5
    light.energy = .18+.1*(1.0+sin(phase*2.0))*.5
    sparkle.visible = false
    match machine_id:
        "M01":
            if state=="PLAYING":
                # move → drop → grip → lift → deliver
                var reach: float = clampf(progress*3.0,0.0,1.0)
                var drop: float = clampf((progress-.23)*3.3,0.0,1.0)
                var lift: float = clampf((progress-.59)*3.6,0.0,1.0)
                mechanism.position.x += 51.0*reach
                mechanism.position.y += 94.0*(drop-lift)
                mechanism.rotation = .018*sin(float(tick)*.22)
                mechanism.scale.x = 1.0+.1*sin(progress*TAU)
                if progress>.72:
                    sparkle.visible=true
                    sparkle.position=Vector2(size.x*.58,240)
            else:
                mechanism.position.x += 8.0*sin(phase)
                mechanism.position.y += 4.0*sin(phase*1.3)
        "M02":
            if state=="PLAYING":
                mechanism.position.x += 56.0*clampf(progress*1.7,0,1)
                mechanism.position.y += 77.0*sin(progress*PI)*.90
                mechanism.rotation = .05*sin(progress*PI*3)
                if not stock.is_empty(): stock_sprites[0].rotation += .20*sin(progress*PI)
            elif state=="RESETTING":
                var reset_fraction: float = clampf(1.0-float(due-tick)/90.0,0,1)
                mechanism.position.x += 37.0*reset_fraction
                mechanism.position.y -= 48.0*sin(reset_fraction*PI)
                mechanism.rotation = .14*sin(reset_fraction*PI)
                sparkle.visible=true
                sparkle.position=Vector2(size.x*.52,225)
            else:
                mechanism.position.x += 10.0*sin(phase*.85)
                mechanism.position.y += 6.0*sin(phase*1.3)
        "M03":
            if state=="PLAYING":
                mechanism.position.x += 42.0*progress
                mechanism.position.y += 54.0*progress
                mechanism.rotation = -.04 + .22*clampf((progress-.69)*6.0,0.0,1.0)
                if progress>.68:
                    sparkle.visible=true
                    sparkle.position = Vector2(size.x*.49,245)
                    light.energy = .72
            else:
                mechanism.position.x += 11.0*sin(phase*.9)
                mechanism.rotation += .03*sin(phase*1.6)
        "M04":
            interior.scale.x = 1.0 + .014*sin(phase*2)
            if not stock.is_empty():
                stock_sprites[0].scale.x *= cos(phase)*.24 + .78
                stock_sprites[0].rotation += .05*sin(phase*1.4)
            light.energy = .37+.15*sin(phase*2.5)
            sparkle.visible = tick%70<35
            sparkle.position=Vector2(size.x*.48+55*sin(phase*3),202+53*sin(phase*2))
    if state=="OUTPUT_HELD":
        sparkle.visible=true
        sparkle.position=Vector2(size.x*.76,345)
        light.energy=.68
    if state=="RESET_REQUIRED":
        sparkle.visible = tick%45<22
        sparkle.position = Vector2(size.x*.6,215)
        light.energy=.65
    # This preset is driven only by the existing attempt manifest and state machine.
    # It cannot decide whether an attempt wins, loses, or requires staff service.
    var outcome: String = ""
    var attempt_idx: int = int(machine.get("attempt",0))
    var attempts: Array = session.get("attempts",[])
    if attempt_idx>=0 and attempt_idx<attempts.size():
        outcome = str(attempts[attempt_idx].get("result",""))
    var choreography_u: float = progress
    if state=="RESETTING": choreography_u=clampf(1.0-float(due-tick)/90.0,0.0,1.0)
    var motion: Dictionary = PERFORMANCE.sample(machine_id,state,choreography_u,tick,outcome)
    mechanism.position = initial_position+Vector2(float(motion["dx"]),float(motion["dy"]))
    mechanism.rotation = float(motion["angle"])
    light.energy = maxf(light.energy,float(motion["light"]))
    if bool(motion["flash"]):
        sparkle.visible = true
    if state=="PLAYING" and stock_sprites.size()>0 and stock_sprites[0].visible:
        stock_sprites[0].position.y -= float(motion["stock_lift"])
        stock_sprites[0].rotation += float(motion["stock_tilt"])
    if state=="CHANGEOVER":
        glass.position.y += 4.0*sin(float(tick)*.22)
        marquee.modulate.a = .25+.28*(1.0+sin(float(tick)*.32))*.5
    if machine_id=="M01" and m01_v31_rig!=null:
        # Read-only adapter driven by the existing authoritative machine state
        # and authored attempts. No prize or money logic is duplicated.
        m01_v31_rig.call("apply_machine_presentation",state,progress,tick)
        _apply_m01_authored_carry(snapshot,sid,state,progress,outcome,stock)
    if sparkle.visible:
        sparkle.scale = Vector2.ONE*(.65+.22*sin(float(tick)*.22))
        sparkle.rotation = .10*sin(float(tick)*.19)
