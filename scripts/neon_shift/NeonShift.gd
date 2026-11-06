class_name NeonShiftGame
extends NeonCanvas
const SESSION = preload("res://scripts/neon_shift/ShiftSession.gd")
const CABINET = preload("res://scripts/neon_shift/NeonCabinet.gd")
const VISITOR = preload("res://scripts/neon_shift/NeonVisitor.gd")
const HUD = preload("res://scripts/neon_shift/NeonHUD.gd")
const MACHINE_NAMES := ["Mochi Club", "Lucky UFO", "Prize Lab", "Panda Party"]
const ACCENTS := [Color("ff79ad"),Color("79ddff"),Color("ffc774"),Color("bca3ff")]
var session: NeonShiftSession
var mode := "title"
var area := "floor"
var chosen_shift := 0
var selected_visit := ""
var selected_machine := "M01"
var selected_slot := ""
var hovered := ""
var clock_visual := 0.0
var flash := 0.0
var toast := ""
var toast_time := 0.0
var toast_ok := true
var clickables: Array[Dictionary] = []
var cabinets: Array[Node2D] = []
var visitors: Dictionary = {}
var departure_at: Dictionary = {}
var world: Node2D
var crowd: Node2D
var hud: Control
var background: Texture2D
var identity: Texture2D
var cart_art: Texture2D
var icons: Dictionary = {}
var best: Dictionary = {}
var unlocked := 0
var muted := false
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var settings: ConfigFile
var mouse_down := Vector2.ZERO
var drag_id := ""
var help_open := false
var snapshot: Dictionary = {}
var completed_cache := 0
var revenue_cache := 0
var summary_data: Dictionary = {}
var capture_mode := false
var effects: Array[Dictionary] = []
var faces: Dictionary = {}
const DESIGNS := ["mika","ren","yuki","yuki","ren","mika","ren","mika"]

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    mouse_filter=Control.MOUSE_FILTER_STOP
    background=load("res://art/r5/front_aisle_architecture.png") as Texture2D
    identity=load("res://art/neon_shift/actor01_identity.png") as Texture2D
    cart_art=load("res://art/neon_shift/service_cart.png") as Texture2D
    for item in ["card","cassette","gift","ribbon","plush","figure","staff_key"]:
        icons[item]=load("res://art/living/icon_"+item+".png") as Texture2D
    var props:=load("res://art/neon_shift/sources/service_props.png") as Texture2D
    var prop_names: Array[String]=["card","cassette","gift","ribbon","staff_key","figure"]
    for i in prop_names.size(): icons[prop_names[i]]=VISITOR._atlas_cell(props,i,3,2)
    var equipment:=load("res://art/neon_shift/sources/prep_equipment.png") as Texture2D
    for i in 3: icons["station%d"%i]=VISITOR._atlas_cell(equipment,i,3,1)
    for item in ["plush_mochi","plush_panda","figure_fox","figure_star"]:
        icons[item]=load("res://art/prizes/"+item+".png") as Texture2D
    world=Node2D.new();add_child(world)
    for i in 4:
        var cabinet: Node2D=CABINET.new()
        cabinet.machine_id="M%02d" % (i+1)
        cabinet.color_index=i
        cabinet.position=Vector2(24+i*230,161)
        cabinet.scale=Vector2.ONE*.88
        world.add_child(cabinet)
        cabinets.append(cabinet)
    crowd=Node2D.new();add_child(crowd)
    hud=HUD.new();hud.z_index=2000;hud.game=self;hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(hud)
    settings=ConfigFile.new()
    if settings.load("user://neon_shift.cfg") == OK:
        best=settings.get_value("progress","best",{})
        unlocked=clampi(int(settings.get_value("progress","unlocked",0)),0,2)
        muted=bool(settings.get_value("audio","muted",false))
    music=AudioStreamPlayer.new();add_child(music)
    sfx=AudioStreamPlayer.new();add_child(sfx)
    if DisplayServer.get_name()!="headless" and ResourceLoader.exists("res://art/neon_shift/audio/arcade_evening.wav"):
        music.stream=load("res://art/neon_shift/audio/arcade_evening.wav")
        music.volume_db=-19
        music.finished.connect(func() -> void: music.play())
        music.play()
    _apply_audio()
    session=SESSION.new();session.begin()
    snapshot=session.sim.game_snapshot()
    _update_world()
    queue_redraw();hud.queue_redraw()

func start_shift(index: int = 0) -> void:
    session.begin(index)
    mode="playing";area="floor";chosen_shift=index
    selected_visit="";selected_machine="M01";selected_slot=""
    completed_cache=0;revenue_cache=0;summary_data={};effects.clear()
    for visitor in visitors.values(): visitor.queue_free()
    visitors.clear();departure_at.clear()
    _notify("First things first: charge a starter card at the Prep Bench.",true)
    snapshot=session.sim.game_snapshot()
    _update_world()

func _physics_process(_delta: float) -> void:
    if mode == "playing" and not help_open:
        session.advance()
        snapshot=session.sim.game_snapshot()
        if session.sim.customers.completed_steps>completed_cache:
            var gain:=session.sim.customers.completed_steps-completed_cache
            completed_cache=session.sim.customers.completed_steps
            flash=1.0
            effects.append({"time":0.0,"duration":1.2,"from":Vector2(742,99),"to":Vector2(742,70),"text":"NICE SERVICE","kind":""})
            _sound("success")
            if gain>0: _notify("Service complete. A little joy, delivered.",true)
        if session.finished() or _all_guests_served(): _finish()
    _update_world()

func _process(delta: float) -> void:
    clock_visual+=delta
    toast_time=maxf(0,toast_time-delta)
    flash=maxf(0,flash-delta*1.5)
    if mode=="playing" and not help_open:
        for effect in effects: effect.time=float(effect.time)+delta
        effects=effects.filter(func(effect:Dictionary)->bool: return float(effect.time)<float(effect.duration))
    var new_hover:=_target_at(get_local_mouse_position())
    if new_hover!=hovered:
        hovered=new_hover
        mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if not hovered.is_empty() else Control.CURSOR_ARROW
    queue_redraw();hud.queue_redraw()

func _update_world() -> void:
    if session==null: return
    world.visible=area=="floor" and mode not in ["results","title"]
    crowd.visible=world.visible and mode!="title"
    for cabinet in cabinets: cabinet.apply(snapshot,session.sim.machines.sessions)
    if mode=="title": return
    for id in session.sim.customers.visit_order:
        if not session.sim.customers.arrived.has(id): continue
        var visit: Dictionary=session.sim.customers.visits[id]
        var index:=int(str(id).trim_prefix("V"))-1
        var mid:=session.visit_machine(id)
        var mi:=int(mid.trim_prefix("M"))-1 if not mid.is_empty() else 2
        if not visitors.has(id):
            var actor: Node2D=VISITOR.new()
            actor.design=DESIGNS[index]
            # The entrance is on the floor beside the right cabinet, not inside
            # its glass chamber. Depth scaling completes on the approach.
            actor.origin=Vector2(1010,497)
            actor.target=Vector2(155+mi*225+(index%2)*22,535-(index%2)*18) if not mid.is_empty() else Vector2(888,535)
            actor.height=167.0+(index%2)*12
            actor.phase=index*2
            crowd.add_child(actor);visitors[id]=actor
        var age:=float(session.sim.clock.tick-int(visit["definition"]["arrival_tick"]))/60.0
        var done:=str(visit["state"])=="COMPLETE"
        if done and not departure_at.has(id): departure_at[id]=session.sim.clock.tick
        if done: age=float(session.sim.clock.tick-int(departure_at[id]))/60.0
        var node: Node2D=visitors[id]
        node.visible=not done or age<4.0
        var reaction:=_visitor_reaction(str(id),mid,done)
        node.selected=selected_visit==id
        node.present(age,done,reaction)
        node.z_index=roundi(node.position.y)
    var active:=session.available_visits()
    if not active.has(selected_visit): selected_visit=active[0] if not active.is_empty() else ""

func _finish() -> void:
    mode="results"
    summary_data=session.summary()
    var key:=str(chosen_shift)
    if int(summary_data["score"])>int(best.get(key,{}).get("score",-1)): best[key]=summary_data.duplicate(true)
    if int(summary_data["stars"])>=2: unlocked=maxi(unlocked,mini(2,chosen_shift+1))
    _save()
    _sound("complete")

func _save() -> void:
    if capture_mode: return
    settings.set_value("progress","best",best)
    settings.set_value("progress","unlocked",unlocked)
    settings.set_value("audio","muted",muted)
    var error:=settings.save("user://neon_shift.cfg")
    if error!=OK: _notify("Could not save your best score on this device.",false)

func _apply_audio() -> void:
    if music!=null: music.volume_db=-80 if muted else -19
    if sfx!=null: sfx.volume_db=-80 if muted else -10
func _sound(sound_name: String) -> void:
    if DisplayServer.get_name()=="headless": return
    var path: String="res://art/neon_shift/audio/"+sound_name+".wav"
    if sfx!=null and ResourceLoader.exists(path): sfx.stream=load(path);sfx.play()
func _notify(message: String, ok: bool) -> void:
    toast=message;toast_ok=ok;toast_time=4.0
func _handle_result(result: Dictionary, success: String) -> void:
    var ok:=bool(result.get("ok",false))
    _notify(success if ok else _reason(str(result.get("reason",""))),ok)
    _sound("tap" if ok else "error")
    if ok: _cart_feedback()
    snapshot=session.sim.game_snapshot()
    _update_world()
func _reason(reason: String) -> String:
    return str({"NO_PREPARED_STARTER_CARD":"Charge a starter card at the Prep Bench first.","NOT_PREPARED":"Prepare this item at the bench first.","NOT_AVAILABLE":"This preparation unlocks with the next wave.","JOB_NOT_AVAILABLE":"The staff job opens shortly. Keep serving the floor.","CART_FULL":"Your cart is full. Use or return an item first.","CABINET_BUSY":"This cabinet is busy. Serve another guest while it finishes.","NOT_QUEUE_HEAD":"Another guest is ahead in this cabinet's queue.","WRAP_INPUT_UNAVAILABLE":"Return the gift box and ribbon to the Prep Bench.","SERVICE_IN_PROGRESS":"This service is already underway.","JOB_ALREADY_STARTED":"That job is already underway or complete.","NOT_READY":"The cabinet is still finishing its current play.","CASSETTE_NOT_ON_CART":"Prepare the refill at the bench, then load it onto your cart.","CABINET_BUSY_OR_OUTPUT_HELD":"Wait for the current play and prize pickup to finish.","PREVIOUS_CASSETTE_NOT_EMPTY":"The cabinet still has stock. Serve its waiting guest first.","EXACT_PRIZE_UNAVAILABLE":"This guest needs the Mochi refill. Prepare and install it first.","NO_RESET_REQUEST":"This cabinet does not need a staff reset."}.get(reason,reason.replace("_"," ").capitalize()+"."))

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.pressed:
            mouse_down=event.position;drag_id=_target_at(event.position)
        else:
            var target:=_target_at(event.position)
            if mouse_down.distance_to(event.position)>12 and not drag_id.is_empty(): _drop(drag_id,target)
            elif not target.is_empty(): activate(target)
            drag_id=""
    if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
        var ids:=session.available_visits()
        if not ids.is_empty():
            var i:=ids.find(selected_visit)
            selected_visit=ids[posmod(i+(1 if event.button_index==MOUSE_BUTTON_WHEEL_DOWN else -1),ids.size())]
func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    match event.keycode:
        KEY_SPACE,KEY_ESCAPE: activate("pause")
        KEY_TAB: activate("bench" if area=="floor" else "floor")
        KEY_E,KEY_ENTER: activate("primary" if mode=="playing" else "start")
        KEY_1,KEY_2,KEY_3,KEY_4: activate("machine:M%02d" % (event.keycode-KEY_1+1))
        KEY_M: activate("mute")
        KEY_H: activate("help")
        KEY_F11:
            var fullscreen:=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
    get_viewport().set_input_as_handled()
func _target_at(p: Vector2) -> String:
    for i in range(clickables.size()-1,-1,-1):
        if Rect2(clickables[i]["rect"]).has_point(p): return str(clickables[i]["id"])
    return ""
func _drop(source: String,target: String) -> void:
    if mode!="playing": return
    if source.begins_with("slot:"):
        selected_slot=source.trim_prefix("slot:")
        if target.begins_with("machine:"): _machine_click(target.trim_prefix("machine:"))
        elif target.begins_with("visit:") or target=="primary":
            if target.begins_with("visit:"): selected_visit=target.trim_prefix("visit:")
            _serve_selected()
        elif target=="bench": _return_slot()
    elif source in ["load_card","load_cassette"] and target.begins_with("slot:"): activate(source)
func _return_slot() -> void:
    if selected_slot.is_empty() or selected_slot=="key": return
    var destination: String="machine_bay:ready" if selected_slot=="bulk_0" else "workshop:ready"
    _handle_result(session.act("drop_cart",{"slot":selected_slot,"to":destination}),"Returned to the preparation shelf.")
    selected_slot=""

func activate(id: String) -> void:
    if id=="mute": muted=not muted;_apply_audio();_save();return
    if id=="help": help_open=not help_open;return
    if help_open: return
    if id=="pause":
        if mode=="playing": mode="paused"
        elif mode=="paused": mode="playing"
        return
    if id=="start" and mode in ["title","results"]: start_shift(chosen_shift);return
    if id=="title": mode="title";area="floor";return
    if id=="retry": start_shift(chosen_shift);return
    if id=="next": start_shift(mini(unlocked,chosen_shift+1));return
    if id.begins_with("shift:"):
        var idx:=int(id.trim_prefix("shift:"))
        if idx<=unlocked: chosen_shift=idx
        return
    if mode!="playing": return
    if id in ["floor","bench"]: area=id;_sound("tap");return
    if id.begins_with("visit:"):
        selected_visit=id.trim_prefix("visit:");selected_machine=session.visit_machine(selected_visit);_sound("tap");return
    if id.begins_with("machine:"): _machine_click(id.trim_prefix("machine:"));return
    if id.begins_with("slot:"):
        var slot:=id.trim_prefix("slot:")
        selected_slot="" if selected_slot==slot else slot
        _sound("tap");return
    match id:
        "primary": _serve_selected()
        "charge":
            var jid:=session.next_job("charge_cards")
            _handle_result(session.act("start_production",{"job_id":jid}) if not jid.is_empty() else {"ok":false,"reason":"NOT_AVAILABLE"},"Charging a starter card. Ready in three seconds.")
        "cassette":
            var jid:=session.next_job("prepare_cassette")
            _handle_result(session.act("start_production",{"job_id":jid}) if not jid.is_empty() else {"ok":false,"reason":"NOT_AVAILABLE"},"Preparing the Mochi Club refill.")
        "load_card": _handle_result(session.load_ready("card"),"Starter card loaded. Select a guest to sell it.")
        "load_cassette": _handle_result(session.load_ready("cassette"),"Refill loaded. Drop it on Mochi Club or press RESTOCK.")
        "reset": _handle_result(session.act("staff_key",{"job_id":"J01"}),"Staff assist underway. Ren can try again.")
        "restock": _handle_result(session.act("restock",{"job_id":"J02"}),"Mochi Club is refilling. The remaining stock stays in its cassette.")
        "return": _return_slot()
func _machine_click(mid: String) -> void:
    selected_machine=mid
    if selected_slot=="key" and mid=="M02": activate("reset");selected_slot="";return
    if selected_slot=="bulk_0" and mid=="M01": activate("restock");selected_slot="";return
    for id in session.available_visits():
        if session.visit_machine(id)==mid:
            selected_visit=id
            if selected_slot.begins_with("supply_"): _serve_selected();selected_slot=""
            return
    _notify(MACHINE_NAMES[int(mid.trim_prefix("M"))-1]+" · "+_machine_state(mid),true)
func _serve_selected() -> void:
    if selected_visit.is_empty(): return
    var action:=session.sim.customers.next_action(selected_visit)
    var machine:=session.visit_machine(selected_visit)
    if action.is_empty() and not machine.is_empty() and str(session.sim.machines.machines[machine].state)=="RESET_REQUIRED":
        activate("reset");return
    if action in ["gift_wrap","trade_up"] and area!="bench":
        area="bench";_notify("The guest is ready at the Prep Bench. Press the service button.",true);return
    _handle_result(session.serve(selected_visit),str({"purchase_card":"Card sold. Now welcome the guest to their cabinet.","admit_session":"Play started. Keep an eye on the floor.","gift_wrap":"Wrapping a little happiness.","trade_up":"Trading two Mochi prizes for a Star figure."}.get(action,"Service underway.")))
func _machine_state(mid: String) -> String:
    var state: String=str(session.sim.machines.machines[mid]["state"])
    return str({"READY":"Ready to play","PLAYING":"Playing","RESET_REQUIRED":"Staff key needed","RESETTING":"Helping guest","CHANGEOVER":"Refilling","OUTPUT_HELD":"Prize won!","SETTLING":"Finishing play","EMPTY":"Needs a refill"}.get(state,state.capitalize()))
func _action_copy(id: String) -> String:
    var action:=session.sim.customers.next_action(id)
    var active: String=str(session.sim.customers.visits[id].active_step)
    if active=="gift_wrap": return "Wrapping their gift"
    if active=="trade_up": return "Preparing their trade"
    if action=="purchase_card":
        var quote:=session.sim.quote_card_purchase(id)
        var starter:=str(quote.get("offer_id",""))=="offer_starter"
        return "Starter card · $5" if starter else "Top up · $4"
    return str({"admit_session":"Start their game","gift_wrap":"Gift wrapping","trade_up":"Prize trade-up"}.get(action,"Enjoying the arcade"))

func _draw() -> void:
    draw_texture_rect(background,Rect2(0,0,1280,720),false)
    draw_rect(Rect2(0,0,1280,720),Color(.07,.035,.13,.22))
    if area=="floor":
        for i in 4:
            var r:=Rect2(20+i*230,471,211,54)
            box(r,Color(.08,.04,.16,.48),20)
            draw_line(Vector2(r.position.x+20,522),Vector2(r.end.x-20,522),Color(ACCENTS[i],.7),2)
    else:
        draw_rect(Rect2(0,80,960,510),Color(.07,.04,.12,.82))
    if mode=="title": draw_rect(Rect2(0,0,1280,720),Color(.05,.025,.12,.64))

func _button(c: NeonCanvas,r: Rect2,label: String,id: String,accent: Color=MINT,enabled: bool=true,filled: bool=true) -> void:
    var hot:=hovered==id
    var bg: Color=accent if filled else Color("32273e")
    if hot: bg=bg.lightened(.10)
    if not enabled: bg=Color("3b3345")
    c.box(r,bg,10,accent if not filled and enabled else Color.TRANSPARENT)
    c.centered(r,label,14,INK if filled and enabled else (CREAM if enabled else MUTED),true)
    if enabled: clickables.append({"rect":r,"id":id})

func render_hud(c: NeonCanvas) -> void:
    clickables.clear()
    if mode=="title": _title(c);return
    if mode=="results": _results(c);return
    _header(c)
    if area=="floor":
        _floor_labels(c)
        _floor_guests(c)
    else: _bench(c)
    _sidebar(c)
    _cart(c)
    _draw_effects(c)
    if toast_time>0:
        c.box(Rect2(34,543,892,30),Color("21192e"),10,MINT if toast_ok else PINK)
        c.centered(Rect2(43,543,875,30),toast,12,CREAM)
    if not drag_id.is_empty() and mouse_down.distance_to(get_local_mouse_position())>12:
        var p:=get_local_mouse_position()
        var kind: String="card" if drag_id=="load_card" else ("cassette" if drag_id=="load_cassette" else _slot_kind(drag_id.trim_prefix("slot:")))
        c.box(Rect2(p-Vector2(36,36),Vector2(72,72)),Color(.12,.08,.2,.9),12,MINT)
        c.fitted(icons.get(kind),Rect2(p-Vector2(30,30),Vector2(60,60)))
    if mode=="paused": _pause(c)
    if help_open: _help(c)

func _header(c: NeonCanvas) -> void:
    c.box(Rect2(0,0,1280,79),Color("171225"),0)
    c.txt(Vector2(26,36),"CLAW & CO.",25,CREAM,true)
    c.txt(Vector2(28,58),"LITTLE PRIZES. BIG FEELINGS.",9,PINK,true)
    c.txt(Vector2(280,30),"0%d / %s" % [chosen_shift+1,SESSION.TITLES[chosen_shift].to_upper()],12,MUTED,true)
    var left:=session.remaining_seconds()
    c.txt(Vector2(280,58),"%d:%02d" % [left/60,left%60],24,CREAM,true)
    c.line_bar(Rect2(382,42,142,5),1.0-float(session.sim.clock.tick)/float(session.sim.stage["duration_ticks"]),MINT)
    c.txt(Vector2(548,29),"REVENUE",10,MUTED,true)
    c.txt(Vector2(548,58),"$%.2f" % (float(session.sim.revenue_minor)/100.0),23,GOLD,true)
    c.txt(Vector2(690,29),"SERVICE SCORE",10,MUTED,true)
    c.txt(Vector2(690,58),str(session.sim.customers.score),23,CREAM,true)
    c.txt(Vector2(785,52),_stars(session.sim.customers.stars()),22,GOLD,true)
    _button(c,Rect2(960,22,84,34),"SOUND" if not muted else "MUTED","mute",MINT,true,false)
    _button(c,Rect2(1054,22,74,34),"HELP","help",MINT,true,false)
    _button(c,Rect2(1138,22,116,34),"PAUSE  II","pause",MINT,true,false)

func _floor_labels(c: NeonCanvas) -> void:
    c.txt(Vector2(27,110),"THE PRIZE FLOOR",13,CREAM,true)
    c.txt(Vector2(27,131),"Four cabinets. One cart. Make every guest's night.",12,Color("f1dae9"))
    _button(c,Rect2(751,91,183,39),"PREP BENCH   [TAB]","bench",CREAM,true,false)
    for i in 4:
        var mid: String="M%02d" % (i+1)
        var x:=24+i*230
        c.box(Rect2(x+12,141,190,28),Color("231a32"),9,ACCENTS[i] if selected_machine==mid else Color("53405e"))
        c.centered(Rect2(x+12,141,190,28),MACHINE_NAMES[i],13,ACCENTS[i],true)
        clickables.append({"rect":Rect2(x,141,215,382),"id":"machine:"+mid})
        c.box(Rect2(x+17,172,181,22),Color("21182d"),8)
        c.centered(Rect2(x+17,172,181,22),_machine_state(mid),11,ACCENTS[i],true)
        var state: String=str(session.sim.machines.machines[mid]["state"])
        if state=="RESET_REQUIRED":
            var wait_seconds:=_staff_wait()
            _button(c,Rect2(x+22,450,170,36),"STAFF ASSIST" if wait_seconds==0 else "STAFF READY · %ds"%wait_seconds,"reset",GOLD,wait_seconds==0)
        if mid=="M01" and session.sim.clock.tick>=int(session.sim.staff_jobs["J02"]["available_tick"]) and not session.sim.staff_started.has("J02"):
            _button(c,Rect2(x+22,450,170,36),"RESTOCK","restock",PINK)

func _sidebar(c: NeonCanvas) -> void:
    c.box(Rect2(958,79,322,506),Color("20172d"),0)
    c.txt(Vector2(981,111),"GUEST REQUESTS",12,PINK,true)
    var ids:=session.available_visits()
    c.txt(Vector2(1206,111),"%02d" % ids.size(),17,CREAM,true)
    var show_ids: Array[String]=ids.duplicate()
    if show_ids.size()>3 and show_ids.find(selected_visit)>2:
        show_ids.erase(selected_visit);show_ids.insert(0,selected_visit)
    for i in mini(3,show_ids.size()):
        var id:=show_ids[i]
        var r:=Rect2(977,127+i*70,282,62)
        var is_selected:=id==selected_visit
        c.box(r,Color("403047") if is_selected else Color("2c2238"),11,PINK if is_selected else Color("45334d"))
        c.box(Rect2(r.position+Vector2(10,11),Vector2(38,38)),Color("69435f"),19)
        c.fitted(_guest_face(id),Rect2(r.position+Vector2(8,7),Vector2(43,46)))
        c.txt(r.position+Vector2(59,23),SESSION.NAMES[id],14,CREAM,true)
        c.txt(r.position+Vector2(59,43),_action_copy(id),11,MUTED)
        var def: Dictionary=session.sim.customers.visits[id]["definition"]
        var left:=float(int(def["deadline_tick"])-session.sim.clock.tick)/float(int(def["deadline_tick"])-int(def["arrival_tick"]))
        c.line_bar(Rect2(r.position+Vector2(59,52),Vector2(208,3)),left,MINT if left>.35 else GOLD)
        clickables.append({"rect":r,"id":"visit:"+id})
    if ids.is_empty():
        c.box(Rect2(977,128,282,150),Color("2c2238"),12)
        c.centered(Rect2(989,151,258,35),"A MOMENT TO PREPARE",13,MINT,true)
        c.centered(Rect2(989,190,258,30),"The next guests are on their way.",12,MUTED)
        c.centered(Rect2(989,217,258,30),"Charge cards. Check your cart.",12,MUTED)
    elif ids.size()>3: c.txt(Vector2(982,350),"%d more guests · scroll to select" % (ids.size()-3),10,MUTED)
    c.draw_line(Vector2(980,363),Vector2(1255,363),Color("49354d"),1)
    if not selected_visit.is_empty():
        c.txt(Vector2(980,391),SESSION.NAMES[selected_visit]+"'s request",19,CREAM,true)
        var action:=session.sim.customers.next_action(selected_visit)
        var detail: String="The cabinet handles this play. Help another guest."
        var label: String="IN PROGRESS"
        var active:=not action.is_empty()
        var work: String=str(session.sim.customers.visits[selected_visit].active_step)
        if work in ["gift_wrap","trade_up"]: detail="Finishing at the Prep Bench. Help another guest."
        if action=="purchase_card":
            var q:=session.sim.quote_card_purchase(selected_visit)
            detail="%d credits · %s" % [int(q.get("credit_units",0)),MACHINE_NAMES[maxi(0,int(session.visit_machine(selected_visit).trim_prefix("M"))-1)]]
            if session.visit_machine(selected_visit).is_empty(): detail="5 credits · existing guest card"
            label="SELL CARD · $%.0f" % (float(q.get("price_minor",0))/100.0)
            if not bool(q.get("ok",false)): detail="Cabinet unavailable · serve another guest";active=false
        elif action=="admit_session": detail="Their card is ready. Welcome them to the machine.";label="START THEIR GAME"
        elif action=="gift_wrap": detail="Gift box + pink ribbon · 6 seconds";label="WRAP GIFT" if area=="bench" else "GO TO WRAP BENCH"
        elif action=="trade_up": detail="Two Mochi prizes become one Star figure.";label="TRADE PRIZES" if area=="bench" else "GO TO TRADE BENCH"
        var primary_id: String="primary"
        var mid:=session.visit_machine(selected_visit)
        if action.is_empty() and not mid.is_empty() and str(session.sim.machines.machines[mid].state)=="RESET_REQUIRED":
            detail="The claw is stuck. A quick staff reset gets it moving."
            var wait_seconds:=_staff_wait()
            label="HELP WITH STAFF KEY" if wait_seconds==0 else "STAFF READY IN %d SECONDS"%wait_seconds
            primary_id="reset";active=wait_seconds==0
        c.txt(Vector2(980,418),detail,11,MUTED,false,278)
        _button(c,Rect2(979,438,280,45),label,primary_id,MINT,active)
        c.txt(Vector2(981,507),"[E] serve selected guest",10,MUTED)
    else:
        c.txt(Vector2(981,398),"Small acts. Big smiles.",20,CREAM,true)
        c.txt(Vector2(981,426),"Prepare a card before the first arrival.",12,MUTED)
        _button(c,Rect2(979,448,280,43),"OPEN PREP BENCH","bench",MINT)
    c.txt(Vector2(982,555),"Stars: 250 / 650 / 950 points",10,GOLD)

func _floor_guests(c: NeonCanvas) -> void:
    # Real illustrated bodies are selectable as well as queue cards. Keep staff
    # actions above body targets where a cabinet button overlaps its guest.
    var priority: Array[Dictionary]=[]
    for item in clickables.duplicate():
        if str(item.id) in ["reset","restock"]:
            priority.append(item);clickables.erase(item)
    for id in session.available_visits():
        if not visitors.has(id): continue
        var actor: Node2D=visitors[id]
        if not actor.visible or actor.sprite.texture==null: continue
        var r: Rect2=actor.sprite.get_global_transform()*Rect2(Vector2.ZERO,actor.sprite.texture.get_size())
        r=r.intersection(Rect2(24,198,912,340))
        if r.size.x<12 or r.size.y<12: continue
        clickables.append({"rect":r,"id":"visit:"+id})
        if hovered=="visit:"+id:
            var label_rect:=Rect2(clampf(r.get_center().x-70,25,789),maxf(199,r.position.y-25),140,22)
            c.box(label_rect,Color("241a32"),8,PINK)
            c.centered(label_rect,SESSION.NAMES[id]+" · SELECT GUEST",9,CREAM,true)
    clickables.append_array(priority)

func _bench(c: NeonCanvas) -> void:
    c.txt(Vector2(30,116),"THE PREP BENCH",24,CREAM,true)
    c.txt(Vector2(31,142),"A little preparation keeps the whole floor moving.",12,MUTED)
    _button(c,Rect2(752,98,180,39),"BACK TO FLOOR [TAB]","floor",CREAM,true,false)
    var titles: Array[String]=["CARD CHARGER","REFILL STATION","GIFT & TRADE"]
    var sub: Array[String]=["A fresh start, fully charged.","Keep the good prizes coming.","Make the win feel special."]
    for i in 3:
        var r:=Rect2(28+i*306,177,289,338)
        c.box(r,Color("2b2038"),18,Color("56405b"))
        c.box(Rect2(r.position+Vector2(16,16),Vector2(257,148)),Color("1c182b"),12)
        _bench_equipment(c,i,Rect2(r.position+Vector2(28,11),Vector2(233,157)))
        c.txt(r.position+Vector2(20,187),titles[i],15,ACCENTS[i],true)
        c.txt(r.position+Vector2(20,210),sub[i],11,MUTED)
        if i<2:
            var kind: String="charge_cards" if i==0 else "prepare_cassette"
            var ready_kind: String="card" if i==0 else "cassette"
            var ready:=not session.ready_item(ready_kind).is_empty()
            var busy:=false
            for id in session.sim.workshop.active:
                var job: Dictionary=session.sim.workshop.active[id]
                if str(job["kind"])==kind:
                    busy=true
                    var duration:=float(session.sim.workshop.jobs[id]["duration_ticks"])
                    var u:=1.0-float(int(job["due"])-session.sim.clock.tick)/duration
                    c.line_bar(Rect2(r.position+Vector2(21,230),Vector2(247,5)),u,MINT)
                    c.txt(r.position+Vector2(21,255),"PREPARING · %0.1fs" % (float(int(job["due"])-session.sim.clock.tick)/60.0),11,MINT,true)
            if not busy:
                c.txt(r.position+Vector2(21,249),"READY FOR YOUR CART" if ready else ("READY TO PREPARE" if not session.next_job(kind).is_empty() else "NEXT DELIVERY INCOMING"),10,MINT if ready else MUTED,true)
            var available:=ready or not session.next_job(kind).is_empty()
            var action: String=("load_card" if i==0 else "load_cassette") if ready else ("charge" if i==0 else "cassette")
            _button(c,Rect2(r.position+Vector2(17,276),Vector2(255,42)),"LOAD ONTO CART" if ready else ("CHARGE CARD · 3s" if i==0 else "PREPARE REFILL · 1.5s"),action,ACCENTS[i],available and not busy)
        else:
            var wrap_busy:=false
            for job in session.sim.workshop.active.values():
                if str(job["kind"]) in ["gift_wrap","trade_up"]:
                    wrap_busy=true
                    c.txt(r.position+Vector2(21,249),"FINISHING · %0.1fs" % (float(int(job["due"])-session.sim.clock.tick)/60.0),11,MINT,true)
            if not wrap_busy: c.txt(r.position+Vector2(21,249),"BOX + RIBBON AT THE BENCH",10,MUTED,true)
            var available:=not selected_visit.is_empty() and session.sim.customers.next_action(selected_visit) in ["gift_wrap","trade_up"]
            _button(c,Rect2(r.position+Vector2(17,276),Vector2(255,42)),"SERVE SELECTED GUEST","primary",GOLD,available)

func _cart(c: NeonCanvas) -> void:
    c.box(Rect2(0,584,1280,136),Color("171622"),0)
    c.draw_line(Vector2(0,584),Vector2(1280,584),Color("6e526d"),2)
    c.txt(Vector2(25,613),"YOUR SERVICE CART",12,CREAM,true)
    c.txt(Vector2(25,633),"Select or drag an item",10,MUTED)
    c.txt(Vector2(25,650),"to a guest or cabinet.",10,MUTED)
    _button(c,Rect2(24,669,157,30),"PREP BENCH","bench",MINT,true,false)
    c.draw_texture_rect(cart_art,Rect2(185,588,918,111),false)
    var slots: Array[String]=["supply_0","supply_1","supply_2","supply_3","prize_0","prize_1","bulk_0","key"]
    var positions: Array[Rect2]=[Rect2(264,611,62,51),Rect2(336,611,59,51),Rect2(405,611,59,51),Rect2(474,611,58,51),Rect2(543,611,115,51),Rect2(669,611,115,51),Rect2(797,611,233,51),Rect2(1126,607,109,63)]
    for i in slots.size():
        var slot:=slots[i]
        var r: Rect2=positions[i]
        var selected:=selected_slot==slot
        if i==7: c.box(r,Color("292433"),12,Color("554458"))
        if selected: c.box(r,Color(0.4,1.0,.8,.12),7,MINT,2)
        elif hovered=="slot:"+slot: c.box(r,Color(1,1,1,.08),7,Color(1,1,1,.25))
        var item_id: String=str(session.sim.cart.slots.get(slot,""))
        var kind: String="staff_key" if slot=="key" else ""
        if not item_id.is_empty():
            var item: String=session.sim.ledger.item_of(item_id)
            kind="card" if slot.begins_with("supply") else ("cassette" if slot=="bulk_0" else item)
        if not kind.is_empty(): c.fitted(icons.get(kind),Rect2(r.position+Vector2(6,2),r.size-Vector2(12,4)))
        else: c.centered(r,"·",23,Color("88708c"))
        c.centered(Rect2(r.position.x,674,r.size.x,16),"CARD %d" % (i+1) if i<4 else ("PRIZE %d" % (i-3) if i<6 else ("REFILL CASSETTE" if i==6 else "STAFF KEY")),8,MUTED,true)
        clickables.append({"rect":r.grow(4),"id":"slot:"+slot})
    if not selected_slot.is_empty() and selected_slot!="key": _button(c,Rect2(1114,678,133,27),"RETURN TO SHELF","return",CREAM,true,false)
    c.txt(Vector2(250,714),"[1–4] cabinets     [TAB] bench     [E] serve     [SPACE] pause     [M] sound     [F11] fullscreen",9,Color("9989a7"))

func _stars(n: int) -> String:
    return "★".repeat(n)+"☆".repeat(3-n)

func _staff_wait() -> int:
    return maxi(0,ceili(float(int(session.sim.staff_jobs.J01.available_tick)-session.sim.clock.tick)/60.0))

func _guest_face(id: String) -> Texture2D:
    var design: String=DESIGNS[int(id.trim_prefix("V"))-1]
    if faces.has(design): return faces[design]
    var full: AtlasTexture=VISITOR.load_bank(design).poses.idle
    var face:=AtlasTexture.new();face.atlas=full.atlas
    face.region=Rect2(full.region.position,Vector2(full.region.size.x,full.region.size.y*.43))
    faces[design]=face
    return face

func _bench_equipment(c: NeonCanvas,index: int,rect: Rect2) -> void:
    var tex: Texture2D=icons["station%d"%index]
    var size:=tex.get_size()
    var dims:=size*minf(rect.size.x/size.x,rect.size.y/size.y)
    var fitted_rect:=Rect2(rect.position+(rect.size-dims)*.5,dims)
    c.draw_texture_rect(tex,fitted_rect,false)
    var kind: String=["charge_cards","prepare_cassette","gift_wrap"][index]
    var progress:=-1.0
    for job_id in session.sim.workshop.active:
        var job: Dictionary=session.sim.workshop.active[job_id]
        if str(job.kind)==kind or (index==2 and str(job.kind)=="trade_up"):
            var duration:=1.0
            if session.sim.workshop.jobs.has(job_id):
                duration=float(session.sim.workshop.jobs[job_id].duration_ticks)
            else:
                var visit: Dictionary=session.sim.customers.visits[str(job.visit)]
                duration=float(visit.definition.steps[int(visit.next)].duration_ticks)
            progress=1.0-float(int(job.due)-session.sim.clock.tick)/duration
    if index==0:
        var screen:=Rect2(fitted_rect.position+fitted_rect.size*Vector2(.23,.25),fitted_rect.size*Vector2(.39,.24))
        c.box(screen,Color("151d32"),2)
        c.centered(Rect2(screen.position,Vector2(screen.size.x,screen.size.y*.55)),"CHARGING" if progress>=0 else "CARD STATION",6,MINT,true)
        c.line_bar(Rect2(screen.position+Vector2(5,screen.size.y*.65),Vector2(screen.size.x-10,3)),progress if progress>=0 else 1.0,MINT)
    elif progress>=0:
        var center:=fitted_rect.position+fitted_rect.size*Vector2(.5,.68)
        c.draw_arc(center,17,-PI*.5,-PI*.5+TAU*progress,32,Color(MINT,.95),2.5,true)
    if progress>=0:
        var led:=fitted_rect.position+Vector2(fitted_rect.size.x*.88,12)
        c.draw_circle(led,3,Color(MINT,.55+.45*sin(clock_visual*6.0)))

func _slot_kind(slot: String) -> String:
    if slot=="key": return "staff_key"
    var id: String=str(session.sim.cart.slots.get(slot,""))
    if id.is_empty(): return ""
    return "card" if slot.begins_with("supply_") else ("cassette" if slot=="bulk_0" else session.sim.ledger.item_of(id))

func _cart_feedback() -> void:
    var old: Dictionary=snapshot.get("cart",{})
    var now: Dictionary=session.sim.cart.slots
    var centers: Dictionary={"supply_0":Vector2(295,637),"supply_1":Vector2(365,637),"supply_2":Vector2(434,637),"supply_3":Vector2(503,637),"bulk_0":Vector2(914,637)}
    for slot in centers:
        if str(old.get(slot,""))==str(now.get(slot,"")): continue
        var loading:=not str(now.get(slot,"")).is_empty()
        var kind: String="cassette" if slot=="bulk_0" else "card"
        var station:=Vector2(475,270) if kind=="cassette" else Vector2(172,270)
        var destination:=station
        if area=="floor":
            var mid:=session.visit_machine(selected_visit)
            var cabinet_index:=maxi(0,int(mid.trim_prefix("M"))-1)
            destination=Vector2(150+cabinet_index*230,425)
        effects.append({"time":0.0,"duration":.55,"from":station if loading else centers[slot],"to":centers[slot] if loading else destination,"kind":kind,"text":""})

func _draw_effects(c: NeonCanvas) -> void:
    for effect in effects:
        var u:=clampf(float(effect.time)/float(effect.duration),0,1)
        var at: Vector2=Vector2(effect.from).lerp(effect.to,smoothstep(0,1,u))
        at.y-=sin(u*PI)*32
        var alpha:=1.0-smoothstep(.7,1.0,u)
        if not str(effect.kind).is_empty():
            c.fitted(icons.get(effect.kind),Rect2(at-Vector2(26,26),Vector2(52,52)),Color(1,1,1,alpha))
        else:
            c.centered(Rect2(at-Vector2(70,15),Vector2(140,30)),effect.text,11,Color(MINT,alpha),true)
func _title(c: NeonCanvas) -> void:
    c.draw_rect(Rect2(0,0,1280,720),Color(.06,.035,.12,.35))
    c.box(Rect2(47,55,667,611),Color(.09,.065,.14,.96),24,Color("63455e"))
    c.txt(Vector2(86,100),"WELCOME TO YOUR LITTLE ARCADE",12,PINK,true)
    c.txt(Vector2(81,167),"CLAW & CO.",54,CREAM,true)
    c.txt(Vector2(85,211),"NEON SHIFT",29,MINT,true)
    c.txt(Vector2(86,253),"A busy floor. A cart full of possibility.",18,CREAM)
    c.txt(Vector2(86,280),"Turn small requests into someone's best night.",16,MUTED)
    for i in 3:
        var r:=Rect2(84,316+i*63,590,52)
        var open:=i<=unlocked
        c.box(r,Color("443145") if chosen_shift==i else Color("271e34"),10,PINK if chosen_shift==i else Color("4b3752"))
        c.txt(r.position+Vector2(16,22),"0%d   %s" % [i+1,SESSION.TITLES[i]],15,CREAM if open else MUTED,true)
        c.txt(r.position+Vector2(49,41),["120 seconds · learn the rhythm","101 seconds · keep the floor moving","84 seconds · every decision counts"][i] if open else "Earn two stars in the previous shift to unlock",10,MUTED)
        var record: Dictionary=best.get(str(i),{})
        c.txt(r.position+Vector2(440,32),_stars(int(record.get("stars",0))) if open else "LOCKED",17,GOLD if open else MUTED,true)
        if open: clickables.append({"rect":r,"id":"shift:"+str(i)})
    _button(c,Rect2(84,533,590,53),"OPEN THE ARCADE     →","start",MINT)
    c.txt(Vector2(86,616),"Charge cards. Serve guests. Reset claws. Refill the joy.",12,MUTED)
    c.txt(Vector2(86,638),"Mouse or keyboard · your best shifts save automatically",10,MUTED)
    c.fitted(identity,Rect2(756,147,390,489))
    c.box(Rect2(813,569,351,64),Color("fff6e6"),16)
    c.txt(Vector2(836,595),"“Let's make it a good night.”",16,INK,true)
    c.txt(Vector2(837,617),"Mika · first in line, every time",11,Color("6e4964"))
    _button(c,Rect2(1064,32,95,34),"SOUND" if not muted else "MUTED","mute",MINT,true,false)
    _button(c,Rect2(1170,32,78,34),"HELP","help",MINT,true,false)
    if help_open: _help(c)
func _pause(c: NeonCanvas) -> void:
    c.draw_rect(Rect2(0,0,1280,720),Color(.05,.03,.09,.78));clickables.clear()
    c.box(Rect2(410,200,460,315),Color("231a30"),22,PINK)
    c.centered(Rect2(440,226,400,50),"TAKE A BREATHER",25,CREAM,true)
    c.centered(Rect2(440,281,400,35),"The arcade will be right here.",14,MUTED)
    _button(c,Rect2(449,336,382,46),"BACK TO THE FLOOR","pause",MINT)
    _button(c,Rect2(449,393,183,42),"RETRY SHIFT","retry",PINK,true,false)
    _button(c,Rect2(647,393,184,42),"MAIN MENU","title",CREAM,true,false)
    _button(c,Rect2(449,450,382,36),"SOUND ON" if not muted else "SOUND OFF","mute",MINT,true,false)
func _help(c: NeonCanvas) -> void:
    c.draw_rect(Rect2(0,0,1280,720),Color(.05,.03,.09,.86));clickables.clear()
    c.box(Rect2(303,105,674,510),Color("231a30"),22,MINT)
    c.txt(Vector2(340,157),"A LITTLE GUIDE TO A GREAT SHIFT",22,CREAM,true)
    var lines: Array[String]=["1. At the Prep Bench, charge cards and load your cart.","2. Select a guest. Read the price, then sell their card.","3. Start their game. Each cabinet animates its real outcome.","4. A stuck claw? Use the Staff Key on Lucky UFO.","5. Prepare a refill, load it, then restock Mochi Club.","6. Wrap gifts and trade prizes at the Prep Bench.","Serve before patience runs out to earn the highest score."]
    for i in lines.size(): c.txt(Vector2(341,207+i*37),lines[i],13,MUTED)
    c.txt(Vector2(342,491),"[TAB] bench    [E] serve    [1–4] cabinet    [SPACE] pause",12,MINT,true)
    _button(c,Rect2(341,535,596,44),"GOT IT — LET'S PLAY","help",MINT)
func _results(c: NeonCanvas) -> void:
    c.draw_rect(Rect2(0,0,1280,720),Color(.06,.03,.12,.78))
    c.box(Rect2(294,69,692,585),Color("24192f"),24,Color("71516d"))
    c.centered(Rect2(332,98,616,28),"THE LIGHTS DIM. THE SMILES STAY.",12,PINK,true)
    c.centered(Rect2(332,144,616,64),"SHIFT COMPLETE",38,CREAM,true)
    c.centered(Rect2(332,208,616,75),_stars(int(summary_data.get("stars",0))),50,GOLD,true)
    var stats: Array[String]=[str(summary_data.get("score",0)),"$%.2f" % (float(summary_data.get("revenue",0))/100),"%d / %d" % [summary_data.get("served",0),summary_data.get("total",8)]]
    for i in 3:
        c.box(Rect2(334+i*207,312,197,110),Color("34253f"),12)
        c.centered(Rect2(342+i*207,328,181,46),stats[i],29,CREAM,true)
        c.centered(Rect2(342+i*207,379,181,25),["SERVICE SCORE","REVENUE","HAPPY GUESTS"][i],10,MUTED,true)
    var earned:=int(summary_data.get("stars",0))>=2
    c.centered(Rect2(333,443,614,31),"Next shift unlocked. Ready for a little more rush?" if earned and chosen_shift<2 else "Every little service made a difference.",14,MINT)
    _button(c,Rect2(334,501,612,48),"NEXT SHIFT →" if earned and chosen_shift<2 else "PLAY THIS SHIFT AGAIN","next" if earned and chosen_shift<2 else "retry",MINT)
    _button(c,Rect2(334,564,295,40),"RETRY FOR A BETTER SCORE","retry",PINK,true,false)
    _button(c,Rect2(644,564,302,40),"BACK TO THE ARCADE","title",CREAM,true,false)

func _exit_tree() -> void:
    if music!=null: music.stop();music.stream=null
    if sfx!=null: sfx.stop();sfx.stream=null

func _all_guests_served() -> bool:
    for visit in session.sim.customers.visits.values():
        if str(visit["state"])!="COMPLETE": return false
    return true

func _visitor_reaction(id: String,mid: String,done: bool) -> String:
    var v: Dictionary=session.sim.customers.visits[id]
    if done:
        if id in ["V01","V02","V04","V08"]: return "hold"
        if id=="V05": return "miss"
        return "cheer" if id!="V07" else "card"
    if str(v.active_step)=="admit_session" and not mid.is_empty():
        var m: Dictionary=session.sim.machines.machines[mid]
        var state: String=str(m.state)
        if state=="OUTPUT_HELD": return "cheer"
        if state in ["RESET_REQUIRED","RESETTING"]: return "miss"
        if state=="PLAYING":
            return "anticipation" if int(m.due)-session.sim.clock.tick<85 else "play"
    return "card" if session.sim.customers.next_action(id)=="admit_session" else "idle"
