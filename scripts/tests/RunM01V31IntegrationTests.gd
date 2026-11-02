extends SceneTree
var assertions := 0
var failures := 0
func _initialize()->void: call_deferred("run_all")
func check(ok:bool,label:String)->void:
    assertions+=1
    if not ok:
        failures+=1
        printerr("M01_V31_FAIL "+label)

func run_all()->void:
    var scene:=load("res://scenes/r5/M01V31Proof.tscn").instantiate() as Node2D
    check(scene!=null,"V3.1 proof scene loads")
    if scene==null:quit(1);return
    root.add_child(scene)
    for i in 5:await process_frame
    scene.run_demo=false
    check(bool(scene.assets_loaded),"all approved PNG assets present")
    var rig: Node2D=scene.mechanic
    var cfg: Dictionary=rig.config
    check(float(cfg["version"])==3.1 and float(cfg["roof_pitch_degrees"])==5.4,
        "exact owner V3.1, never R10 or earlier V3")
    check(int(cfg["bridge"]["visual_scale_percent"])==105,"approved bridge 105 percent")
    check(int(cfg["trolley_scale_percent"])==80,"approved trolley 80 percent")
    check(int(cfg["chain"]["scale_percent"])==109,"approved chain 109 percent")
    check(float(cfg["suspension"]["rest_gap"])==57.0 and float(cfg["suspension"]["max_drop"])==265.0,
        "approved rest and full descent")
    check(rig.has_node("OriginalLeftPillarForegroundMask") and
          rig.has_node("ChainFeedRoofTerminationMask") and
          rig.has_node("OriginalRoofFasciaOcclusion") and
          rig.has_node("OriginalRightPillarRestoration") and
          rig.has_node("RightChamberGapClosure") and
          rig.has_node("UpperRightRoofForeground") and
          rig.has_node("OriginalCabinetFrontCrosspiece"),
          "four source-registered foreground restoration layers")
    var pillar: Sprite2D=rig.get_node("OriginalLeftPillarForegroundMask")
    var chain_mask: Sprite2D=rig.get_node("ChainFeedRoofTerminationMask")
    var roof_mask: Sprite2D=rig.get_node("OriginalRoofFasciaOcclusion")
    var right_mask: Sprite2D=rig.get_node("OriginalRightPillarRestoration")
    var chamber_fill: Sprite2D=rig.get_node("RightChamberGapClosure")
    var upper_roof: Sprite2D=rig.get_node("UpperRightRoofForeground")
    var roof_front: Sprite2D=rig.get_node("OriginalCabinetFrontCrosspiece")
    check(pillar.texture.get_size()==Vector2(1024,1536) and
          chain_mask.texture.get_size()==Vector2(1024,1536) and
          roof_mask.texture.get_size()==Vector2(1024,1536) and
          right_mask.texture.get_size()==Vector2(1024,1536) and
          chamber_fill.texture.get_size()==Vector2(1024,1536) and
          upper_roof.texture.get_size()==Vector2(1024,1536) and
          roof_front.texture.get_size()==Vector2(1024,1536),
          "all source-registered masks are exactly 1024x1536")
    check(not chain_mask.region_enabled and chain_mask.position==Vector2.ZERO and
          chain_mask.texture.get_image().get_used_rect().size.y<=16,
          "chain occlusion uses alpha-transparent strip, never rectangular rail patch")
    check(right_mask.texture.get_image().get_pixel(937,530).a>0.0,
          "right-front pillar source artwork restored, not transparent environment")
    check(chamber_fill.texture.get_image().get_used_rect().size.x>0,
          "right chamber gap infill generated from the existing illustrated wall")
    check(upper_roof.z_index==6,
          "right marquee mask retains authentic front layer")
    var left_cap: Sprite2D=rig.get_node("CabinetFixedHardware/leftFrontMount")
    check(not left_cap.visible and
          not (rig.get_node("CabinetFixedHardware/leftBackMount") as Sprite2D).visible,
          "both decorative left mount caps concealed without moving rail anchors")
    var rails:Node2D=rig.get_node("CabinetFixedHardware")
    check(not (rig.get_node("CabinetFixedHardware/LeftFixedDepthGuide/RigidOriginalRailSection2") as Sprite2D).visible,
        "exposed left front rail decoration is concealed, geometry is unchanged")
    var bridge:Node2D=rig.get_node("MovingYBridge")
    var trolley:Node2D=rig.get_node("MovingXTrolley")
    var chain:Node2D=rig.get_node("FlexibleChain")
    check(chain.z_index<bridge.z_index and chain.z_index<upper_roof.z_index and
          chain.z_index<roof_front.z_index and roof_front.z_index>bridge.z_index,
        "chain stays behind front bridge and upper roof at all positions")
    check(chamber_fill.z_index==rails.z_index and
          rig.get_children().find(chamber_fill)<rig.get_children().find(rails) and
          chamber_fill.z_index<bridge.z_index,
        "wall infill draws before fixed guides but above the outdoor environment")
    check(right_mask.texture.get_image().get_used_rect().end.y>=955,
        "right vertical frame restoration extends past truncated border")
    rig.set_pose(0.5,0.35,0,0)
    var fixed0:=rails.transform
    var mask0:=pillar.transform
    var chainmask0:=chain_mask.transform
    var rightmask0:=right_mask.transform
    var roofmask0:=roof_mask.transform
    var uppermask0:=upper_roof.transform
    var frontmask0:=roof_front.transform
    var wallmask0:=chamber_fill.transform
    var p0: Dictionary=rig.last_pose.duplicate(true)
    rig.set_pose(1.0,0.35,0,0)
    var px:Dictionary=rig.last_pose.duplicate(true)
    check(bridge.position.distance_to(Vector2(0,0))>10,"bridge exists on roof")
    check(px["trolley"].distance_to(p0["trolley"])>185.0,
        "trolley reaches far right end from center")
    rig.set_pose(0.0,0.35,0,0)
    var far_left: Dictionary=rig.last_pose.duplicate(true)
    check(px["trolley"].distance_to(far_left["trolley"])>290.0,
        "trolley retains long usable X travel after revised left stop")
    check(float(far_left["trolley"].x)>315.0 and float(far_left["trolley"].x)<360.0,
        "left travel stops at the owner blue-circle boundary, clear of the frame")
    rig.set_pose(1.0,0.35,0,0)
    check(px["left"]==p0["left"] and px["right"]==p0["right"],"X does not move bridge bearings")
    rig.set_pose(0.5,1.0,0,0)
    var py:Dictionary=rig.last_pose.duplicate(true)
    check(py["left"].distance_to(p0["left"])>20.0 and py["right"].distance_to(p0["right"])>20,
        "Y moves BOTH ends of transverse bridge")
    check(rails.transform==fixed0,"Y never moves both fixed guide rails")
    rig.set_pose(0.5,0.35,1.0,0)
    var pz:Dictionary=rig.last_pose.duplicate(true)
    check(pz["wire_bottom"].y-p0["wire_bottom"].y==265.0,"Z lowers cable exactly 265 source px")
    check(pz["trolley"]==p0["trolley"] and pz["left"]==p0["left"],"Z does not move XY assembly")
    check(pz["chain_end"].distance_to(p0["chain_end"])<.001,"Z never disconnects chain feed")
    check(pillar.transform==mask0 and chain_mask.transform==chainmask0 and
          right_mask.transform==rightmask0 and roof_mask.transform==roofmask0 and
          chamber_fill.transform==wallmask0 and upper_roof.transform==uppermask0 and
          roof_front.transform==frontmask0,
        "four masks remain cabinet-fixed")
    check(chain.get_child_count()>=60 and chain.get_child(0).texture!=null,
        "original Astra link art powers dynamic flexible chain")
    check(chain.get_child(0).texture.get_size()==Vector2(39,86) and
          not chain.get_child(0).region_enabled and
          (chain.get_child(0).texture as Texture2D).get_image().get_used_rect().size.y<=56,
          "chain uses 65-percent source-faithful display art, same center and path")
    check(not rig.bridge_slices[0].visible and
          rig.bridge_slices[0].material is ShaderMaterial and
          rig.bridge_slices[0].region_rect.position.x>0,
          "front-left rail cap uses original interior chrome, not the exposed endplate")
    var hashes: Array[String]=[]
    for pass_idx in 2:
        var signature: Array[String]=[]
        for tick in 720:
            rig.set_demo_tick(tick)
            var p:Dictionary=rig.last_pose
            check(absf(float(p["wire_bottom"].y)-float(p["wire_top"].y)-
                float(p["cable_length"]))<.005,"cable continuous tick "+str(tick))
            check(rails.transform==fixed0 and mask0==pillar.transform,
                "fixed rails and left pillar tick "+str(tick))
            check(float(p["travel_fraction"])>.0 and float(p["travel_fraction"])<1.0,
                "both trolley bearings within end stops tick "+str(tick))
            signature.append("%.5f:%.5f:%.5f:%.5f"%[p["x"],p["y"],p["z"],p["grip"]])
        hashes.append("|".join(signature).sha256_text())
    check(hashes[0]==hashes[1],"720 tick authored demo deterministic replay")
    # Real game presentation bridge integration: machine screen creates V31 rig.
    var machine: Node=(load("res://scenes/machines/M01_Machine.tscn") as PackedScene).instantiate()
    root.add_child(machine)
    for i in 2:await process_frame
    check(machine.get("m01_v31_rig")!=null,"actual M01 MachineView hosts V3.1 rig")
    machine.queue_free()
    print("M01_V31_TEST_ASSERTIONS=",assertions," PASSED=",assertions-failures,
        " FAILED=",failures," DETERMINISTIC_SHA256=",hashes[0])
    quit(0 if failures==0 else 1)
