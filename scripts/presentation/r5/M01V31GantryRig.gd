extends Node2D
## M01 owner's approved V3.1 visual configuration, cabinet-local 1024x1536 units.
## Pure presentation; authoritative simulation never mutates here.
const ART := "res://art/m01_v31/"
const CAL := "res://data/r5/M01V31Calibration.json"
var config: Dictionary = {}
var ready_assets := false
var fixed: Node2D
var moving_bridge: Node2D
var carriage: Node2D
var chain_root: Node2D
var cable: Sprite2D
var connector: Sprite2D
var claw_root: Node2D
var left_shoulder: Node2D
var left_elbow: Node2D
var right_shoulder: Node2D
var right_elbow: Node2D
var rear_pivot: Node2D
var bridge_slices: Array[Sprite2D] = []
var chain_links: Array[Sprite2D] = []
var last_pose: Dictionary = {}
var last_tick: int = 0

func _node(parent: Node2D, label: String) -> Node2D:
    var n := Node2D.new()
    n.name=label
    parent.add_child(n)
    return n

func _sprite(parent: Node2D, label: String, filename: String, pos: Vector2=Vector2.ZERO, scale_value: float=1.0, centered: bool=true) -> Sprite2D:
    var s := Sprite2D.new()
    s.name=label
    s.texture=load(ART+filename+".png") as Texture2D
    if s.texture==null:
        push_error("V31 missing approved source artwork "+filename)
    s.centered=centered
    s.position=pos
    s.scale=Vector2.ONE*scale_value
    parent.add_child(s)
    return s

func _point(d: Dictionary) -> Vector2:
    return Vector2(float(d["x"]),float(d["y"]))

func _anchors() -> Dictionary:
    var raw: Dictionary=config["four_anchor_positions"]
    return { "leftBack":_point(raw["leftBack"]), "leftFront":_point(raw["leftFront"]),
        "rightBack":_point(raw["rightBack"]), "rightFront":_point(raw["rightFront"]) }

func _ready() -> void:
    var file := FileAccess.open(CAL,FileAccess.READ)
    if file==null:
        push_error("V31 calibration not staged "+CAL)
        return
    var parsed: Variant=JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        push_error("V31 calibration JSON invalid")
        return
    config=parsed
    if str(config.get("schema",""))!="claw-co.m01-connected-gantry/v3" or float(config.get("version",0))!=3.1:
        push_error("Wrong gantry calibration version: refusing older V3/R10")
        return
    fixed=_node(self,"CabinetFixedHardware")
    var a:=_anchors()
    for name in ["leftBack","leftFront","rightBack","rightFront"]:
        var plate := "roof_bracket_left" if name.begins_with("left") else "roof_bracket_right"
        if name.ends_with("Back"):
            plate+="_stub"
        var mount:=_sprite(fixed,name+"Mount",plate,a[name],.16*float(config["individual_scales"]["bracket"])/100.0)
        mount.z_index=0
        # Owner correction A: the exposed near-left mounting block is inside
        # the original opaque front pillar. Keep its calibrated anchor and
        # fixed structure unchanged; only conceal the decorative sprite.
        if name=="leftFront" or name=="leftBack":
            mount.visible=false
    _beam(fixed,"LeftFixedDepthGuide","depth_rail_left",a["leftBack"],a["leftFront"],float(config["guide_thickness"]))
    _beam(fixed,"RightFixedDepthGuide","depth_rail_right",a["rightBack"],a["rightFront"],float(config["guide_thickness"]))
    moving_bridge=_node(self,"MovingYBridge")
    moving_bridge.z_index=1
    # Preserve actual source bridge endplates; only repeat/stetch the center profile.
    var tex:=load(ART+"cross_bridge.png") as Texture2D
    var cap_src:=int(floor(float(tex.get_width())*.115))
    for i in 3:
        var section:=_sprite(moving_bridge,"OriginalAstraBridgeSegment"+str(i),"cross_bridge",Vector2.ZERO,1,false)
        section.region_enabled=true
        var a0:=0 if i==0 else cap_src if i==1 else tex.get_width()-cap_src
        var w:=cap_src if i!=1 else tex.get_width()-cap_src*2
        section.region_rect=Rect2(a0,0,w,tex.get_height())
        bridge_slices.append(section)
    # Trim only the occluded extreme tip of the first rail cap. This affects
    # presentation pixels, not its anchor, geometry, movement or end bearing.
    var end_trim_shader := Shader.new()
    end_trim_shader.code = "shader_type canvas_item; uniform float trim_pixels = 0.0; varying float local_x; void vertex(){ local_x = VERTEX.x; } void fragment(){ if (local_x < trim_pixels) discard; }"
    var end_trim_material := ShaderMaterial.new()
    end_trim_material.shader = end_trim_shader
    end_trim_material.set_shader_parameter("trim_pixels",float(cap_src)*0.25)
    bridge_slices[0].material = end_trim_material
    chain_root=_node(self,"FlexibleChain")
    chain_root.z_index=2
    # Downscale only the individual approved chain-link art to 65% within
    # its existing 39x86 draw footprint. Existing chain positions, count,
    # curvature, endpoints and motion logic remain completely unchanged.
    var chain_source := load(ART+"cable_chain.png") as Texture2D
    var chain_tile := chain_source.get_image().get_region(Rect2i(285,21,39,86))
    # Link width is exactly 65% of original; its longitudinal overlap is
    # retained so 0.65-scale teeth do NOT separate at the fixed link cadence.
    chain_tile.resize(25,86,Image.INTERPOLATE_LANCZOS)
    var chain_footprint := Image.create(39,86,false,Image.FORMAT_RGBA8)
    chain_footprint.fill(Color.TRANSPARENT)
    chain_footprint.blit_rect(chain_tile,Rect2i(0,0,25,86),Vector2i(7,0))
    var reduced_chain_art := ImageTexture.create_from_image(chain_footprint)
    for i in 72:
        var link:=_sprite(chain_root,"OriginalAstraChainLink_%02d"%i,"cable_chain")
        link.texture=reduced_chain_art
        link.region_enabled=false
        chain_links.append(link)
    carriage=_node(self,"MovingXTrolley")
    carriage.z_index=3
    var trolley_scale:=.18*float(config["trolley_scale_percent"])/70.0
    _sprite(carriage,"OriginalAstraTrolley","moving_trolley",Vector2.ZERO,trolley_scale)
    _sprite(carriage,"WinchMotor","winch_motor",Vector2(0,22.0*float(config["trolley_scale_percent"])/100.0),
        .14*float(config["trolley_scale_percent"])/70.0*float(config["individual_scales"]["winch"])/100.0)
    cable=_sprite(carriage,"ZSuspensionCable","hoist_cable",Vector2.ZERO,1.0)
    connector=_sprite(carriage,"IndependentConnector","claw_connector",Vector2.ZERO,
        .095*float(config["individual_scales"]["connector"])/100.0)
    claw_root=_node(carriage,"SixPartClaw")
    claw_root.scale=Vector2.ONE*(.108*float(config["trolley_scale_percent"])/70.0*float(config["individual_scales"]["claw"])/100.0)
    _sprite(claw_root,"MotorHub","motor_hub",Vector2(-200,-8),1,false)
    left_shoulder=_node(claw_root,"LeftShoulder")
    left_shoulder.position=Vector2(-116,343)
    _sprite(left_shoulder,"LeftUpperLink","left_upper_link",Vector2(-205,-58),1,false)
    left_elbow=_node(left_shoulder,"LeftElbow")
    left_elbow.position=Vector2(-127,165)
    _sprite(left_elbow,"LeftTip","left_gripper",Vector2(-234,-49),1,false)
    right_shoulder=_node(claw_root,"RightShoulder")
    right_shoulder.position=Vector2(118,343)
    _sprite(right_shoulder,"RightUpperLink","right_upper_link",Vector2(-65,-60),1,false)
    right_elbow=_node(right_shoulder,"RightElbow")
    right_elbow.position=Vector2(132,172)
    _sprite(right_elbow,"RightTip","right_gripper",Vector2(-42,-43),1,false)
    rear_pivot=_node(claw_root,"RearPivot")
    rear_pivot.position=Vector2(0,472)
    _sprite(rear_pivot,"ThirdFinger","rear_gripper",Vector2(-58,-31),1,false)
    # Original roof fascia and registered chain-entry paint. Critically, no
    # rectangular crop from M01Cabinet is drawn over the moving front rail.
    _sprite(self,"OriginalRoofFasciaOcclusion","roof_fascia_mask",Vector2.ZERO,1,false).z_index=6
    _sprite(self,"ChainFeedRoofTerminationMask","chain_feed_occlusion",Vector2.ZERO,1,false).z_index=7
    _sprite(self,"OriginalLeftPillarForegroundMask","left_pillar_occlusion",Vector2.ZERO,1,false).z_index=8
    # The source 'front_posts_mask' stops at x=782: it is NOT the far-right
    # pillar. Restore the true right-front edge from unchanged cabinet source
    # pixels (full 1024x1536 registration); fill only tiny internal alpha
    # slits, never paint an arbitrary opaque rectangle over the chamber.
    var original_body := (load(ART+"M01Cabinet.png") as Texture2D).get_image()
    var original_chamber := (load(ART+"m01_chamber_backdrop.png") as Texture2D).get_image()
    # Seamlessly extend the original illustrated right chamber wall beneath
    # the source-authentic front pillar, using one coherent texture resample.
    # Unlike a row-by-row alpha fill, shapes remain continuous at every y.
    # Only presentation pixels change; the source art is never overwritten.
    var chamber_infill := Image.create(1024,1536,false,Image.FORMAT_RGBA8)
    chamber_infill.fill(Color.TRANSPARENT)
    var illustrated_right_wall := original_chamber.get_region(Rect2i(738,315,165,590))
    illustrated_right_wall.resize(205,590,Image.INTERPOLATE_LANCZOS)
    chamber_infill.blit_rect(illustrated_right_wall,Rect2i(0,0,205,590),Vector2i(738,315))
    var wall_fill := _sprite(self,"RightChamberGapClosure","m01_chamber_backdrop",Vector2.ZERO,1,false)
    wall_fill.texture=ImageTexture.create_from_image(chamber_infill)
    wall_fill.z_index=0
    var right_pillar := Image.create(1024,1536,false,Image.FORMAT_RGBA8)
    right_pillar.fill(Color.TRANSPARENT)
    right_pillar.blit_rect(original_body,Rect2i(900,230,124,620),Vector2i(900,230))
    for yy in range(230,850):
        var last_x := -100
        var last_color := Color.TRANSPARENT
        for xx in range(900,1024):
            var source_color := original_body.get_pixel(xx,yy)
            if source_color.a >= 0.90:
                if xx-last_x>1 and xx-last_x<=5:
                    for fill_x in range(last_x+1,xx):
                        right_pillar.set_pixel(fill_x,yy,last_color.lerp(source_color,float(fill_x-last_x)/float(xx-last_x)))
                last_x=xx
                last_color=source_color
    var right_edge := _sprite(self,"OriginalRightPillarRestoration","M01Cabinet",Vector2.ZERO,1,false)
    right_edge.texture=ImageTexture.create_from_image(right_pillar)
    right_edge.z_index=9
    ready_assets=true
    var p: Dictionary=config["preview"]
    set_pose(float(p["x"]),float(p["y"]),float(p["z"]),float(p["grip"]))

func _beam(parent:Node2D, name:String, asset:String, p:Vector2, q:Vector2, width:float) -> void:
    var group:=_node(parent,name)
    group.position=p
    var span:=p.distance_to(q)
    group.rotation=(q-p).angle()
    var tex:=load(ART+asset+".png") as Texture2D
    if tex==null: return
    var cap_pixels:=int(tex.get_width()*.10)
    var h:=width
    var scale_h:=h/float(tex.get_height())
    var cap_display:=float(cap_pixels)*scale_h
    var center_display:=maxf(2,span-cap_display*2)
    for i in 3:
        var s:=_sprite(group,"RigidOriginalRailSection%d"%i,asset,Vector2.ZERO,1,false)
        s.region_enabled=true
        var sx:=0 if i==0 else cap_pixels if i==1 else tex.get_width()-cap_pixels
        var sw:=cap_pixels if i!=1 else tex.get_width()-2*cap_pixels
        s.region_rect=Rect2(sx,0,sw,tex.get_height())
        s.position=Vector2(0 if i==0 else cap_display if i==1 else cap_display+center_display,-h*.5)
        s.scale=Vector2((cap_display if i!=1 else center_display)/float(sw),scale_h)

func _bezier(a:Vector2,b:Vector2,c:Vector2,d:Vector2,t:float)->Vector2:
    var u:=1.0-t
    return a*u*u*u+b*3.0*u*u*t+c*3.0*u*t*t+d*t*t*t

func set_pose(x_value:float,y_value:float,z_value:float,grip_value:float)->void:
    if not ready_assets:return
    var x:=clampf(x_value,0.0,1.0)
    var y:=clampf(y_value,0.0,1.0)
    var z:=clampf(z_value,0.0,1.0)
    var grip:=clampf(grip_value,0.0,1.0)
    var a:=_anchors()
    var left: Vector2=a["leftBack"].lerp(a["leftFront"],y)
    var right: Vector2=a["rightBack"].lerp(a["rightFront"],y)
    var span:=left.distance_to(right)
    var direction:=right-left
    var bridge_angle:=direction.angle()
    var visual_width:=float(config["bridge"]["thickness"])*float(config["bridge"]["visual_scale_percent"])/100.0
    var original_width:=float(bridge_slices[0].texture.get_width())
    var cap_src:=floori(original_width*.115)
    var cap:=float(cap_src)*visual_width/float(bridge_slices[0].texture.get_height())
    var core:=maxf(10,span-cap)
    var offset:= -cap*.5-float(config["bridge"]["overhang"])
    moving_bridge.position=left
    moving_bridge.rotation=bridge_angle
    for i in 3:
        var spr:=bridge_slices[i]
        var w:=float(spr.region_rect.size.x)
        var width:=cap if i!=1 else core
        if i==0: width+=float(config["bridge"]["overhang"])
        if i==2: width+=float(config["bridge"]["overhang"])
        spr.scale=Vector2(width/w,visual_width/float(spr.texture.get_height()))
        spr.position=Vector2(offset if i==0 else offset+cap if i==1 else offset+cap+core,-visual_width*.5)
    var trolley_percent:=float(config["trolley_scale_percent"])
    var margin:=clampf(342.0*.18*(trolley_percent/70.0)*.42,19.0,39.0)
    var fraction:=(margin/span)+(1.0-2.0*margin/span)*x
    var on_bridge:=left.lerp(right,fraction)
    var trolley:=on_bridge+Vector2(0,4)
    var winch:=trolley+Vector2(0,22.0*trolley_percent/100.0)
    var wire_top:=winch+Vector2(0,17.0*trolley_percent/100.0)
    var cable_len:=float(config["suspension"]["rest_gap"])+float(config["suspension"]["max_drop"])*z
    var wire_end:=wire_top+Vector2(0,cable_len)
    var cable_top_local:=wire_top-trolley
    cable.position=Vector2(0,cable_top_local.y+cable_len*.5)
    cable.scale=Vector2(4.2/float(cable.texture.get_width()),cable_len/float(cable.texture.get_height()))
    connector.position=Vector2(0,wire_end.y+10.0-trolley.y)
    claw_root.position=Vector2(0,wire_end.y+18.0-trolley.y)
    carriage.position=trolley
    # Winch and vertical cable are never rotated with the pitched bridge.
    var start:=left.lerp(right,float(config["chain"]["feed_fraction"]))+Vector2(0,-21)
    var top_y:=trolley.y-(286.0*.18*(trolley_percent/70.0))*.47
    var attach:Dictionary=config["chain"]["trolley_attachment"]
    var chain_end:=Vector2(trolley.x+float(attach["x"]),top_y+float(attach["y"]))
    var dx:=chain_end.x-start.x
    var arch:=clampf(float(config["chain"]["sag"])*.60,10,46)*float(config["chain"]["scale_percent"])/100.0
    var c1:=Vector2(start.x+dx*.22,minf(start.y,chain_end.y)-arch)
    var c2:=Vector2(chain_end.x-dx*.22,minf(start.y,chain_end.y)-arch)
    var length:=0.0
    var prev:=start
    for k in range(1,37):
        var n:=_bezier(start,c1,c2,chain_end,float(k)/36.0)
        length+=n.distance_to(prev)
        prev=n
    var plate:=clampf(12.5*float(config["chain"]["scale_percent"])/100.0*
        float(config["individual_scales"]["chain_length"])/100.0,7.5,18.0)
    var count:=clampi(roundi(length/maxf(5.0,plate*.90)),6,70)
    for k in chain_links.size():
        var link:=chain_links[k]
        link.visible=k<=count
        if not link.visible:continue
        var t:=float(k)/float(count)
        var pos:=_bezier(start,c1,c2,chain_end,t)
        var p1:=_bezier(start,c1,c2,chain_end,clampf(t-.006,0,1))
        var p2:=_bezier(start,c1,c2,chain_end,clampf(t+.006,0,1))
        link.position=pos
        link.rotation=(p2-p1).angle()
        link.scale=Vector2.ONE*(plate/39.0)
    left_shoulder.rotation_degrees=-25.0*grip
    left_elbow.rotation_degrees=-17.0*grip
    right_shoulder.rotation_degrees=25.0*grip
    right_elbow.rotation_degrees=17.0*grip
    rear_pivot.rotation_degrees=10.0*grip
    last_pose={
      "x":x,"y":y,"z":z,"grip":grip,"left":left,"right":right,"bridge_angle":bridge_angle,
      "trolley":trolley,"wire_top":wire_top,"wire_bottom":wire_end,
      "chain_start":start,"chain_end":chain_end,"feed":start,"travel_fraction":fraction,
      "left_error":(moving_bridge.to_global(Vector2.ZERO)-to_global(left)).length(),
      "right_error":(moving_bridge.to_global(direction.rotated(-bridge_angle))-to_global(right)).length(),
      "cable_length":cable_len
    }

func set_demo_tick(tick:int)->void:
    last_tick=tick
    var t:=float(tick%720)/60.0
    var x:=.5
    var y:=.35
    var z:=0.0
    var grip:=0.0
    if t>=1.2 and t<3.2:
        var k:=smoothstep(0.0,1.0,(t-1.2)/2.0)
        x=.5+.34*k; y=.35+.48*k
    elif t>=3.2 and t<5.0:
        x=.84;y=.83;z=smoothstep(0,1,(t-3.2)/1.8)
    elif t>=5.0 and t<5.7:
        x=.84;y=.83;z=1;grip=smoothstep(0,1,(t-5.0)/.7)
    elif t>=5.7 and t<7.2:
        x=.84;y=.83;z=1-smoothstep(0,1,(t-5.7)/1.5);grip=1
    elif t>=7.2 and t<10.0:
        var k:=smoothstep(0,1,(t-7.2)/2.8)
        x=.84-.65*k;y=.83-.35*k;grip=1
    elif t>=10:
        var k:=smoothstep(0,1,(t-10)/2)
        x=.19+.31*k;y=.48-.13*k;grip=1-k
    set_pose(x,y,z,grip)

func apply_machine_presentation(state:String,progress:float,tick:int)->void:
    # Projection only: no admissions, prize RNG, reservations or inventory mutation.
    match state:
        "PLAYING":
            var t:=clampf(progress,0,1)
            if t<.24:set_pose(lerpf(.5,.82,t/.24),lerpf(.35,.75,t/.24),0,0)
            elif t<.55:set_pose(.82,.75,(t-.24)/.31,0)
            elif t<.65:set_pose(.82,.75,1,(t-.55)/.10)
            elif t<.79:set_pose(.82,.75,1-(t-.65)/.14,1)
            elif t<.94:set_pose(lerpf(.82,.16,(t-.79)/.15),lerpf(.75,.35,(t-.79)/.15),0,1)
            else:set_pose(.16,.35,0,1-(t-.94)/.06)
        "CHANGEOVER","DISABLED","BROKEN":
            set_pose(.5,.35,0,0)
        _:
            set_pose(.5,.35,0,0)
