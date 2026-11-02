extends SceneTree
## Genuine Godot frames from production V3.1 geometry; NOT browser composites.
const OUT := "res://ci/output/m01v31/screenshots/"
var scene: Node2D
func _initialize()->void:call_deferred("capture")
func capture()->void:
    root.size=Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    scene=(load("res://scenes/r5/M01V31Proof.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    for i in 6:await process_frame
    scene.run_demo=false
    if not scene.assets_loaded:printerr("M01V31_CAPTURE_ART_MISSING");quit(1);return
    scene.set_capture_zoom(false)
    scene.set_pose(.5,.35,0,0)
    if not await shot("01_owner_rest_fullcabinet"):quit(1);return
    scene.set_pose(0,.35,0,0)
    if not await shot("02_x_far_left"):quit(1);return
    scene.set_pose(1,.35,0,0)
    if not await shot("03_x_far_right"):quit(1);return
    scene.set_pose(.5,0,0,0)
    if not await shot("04_y_back"):quit(1);return
    scene.set_pose(.5,1,0,0)
    if not await shot("05_y_front"):quit(1);return
    scene.set_pose(.5,.35,1,0.6)
    if not await shot("06_z_fully_lowered"):quit(1);return
    scene.set_capture_zoom(true)
    scene.set_pose(.5,.35,0,0)
    if not await shot("07_rest_roof_both_masks_closeup"):quit(1);return
    scene.set_pose(.0,.0,0,0)
    if not await shot("08_left_pillar_mask_xy_extreme"):quit(1);return
    scene.set_pose(1,1,0,0)
    if not await shot("09_chain_termination_xy_extreme"):quit(1);return
    scene.set_pose(.5,.35,1,1)
    if not await shot("10_claw_closed_full_descent"):quit(1);return
    scene.set_pose(1,0,0,0)
    if not await shot("11_chain_far_right_back_under_roof"):quit(1);return
    scene.set_pose(0,1,0,0)
    if not await shot("12_new_left_travel_stop_y_front"):quit(1);return
    scene.set_pose(1,1,0,0)
    if not await shot("13_right_guide_clearance_and_pillar"):quit(1);return
    scene.set_capture_zoom(true)
    scene.set_demo_tick(180)
    if not await shot("14_at_3_seconds_y_forward_left_rail"):quit(1);return
    scene.set_pose(1.0,1.0,0.0,0.0)
    if not await shot("15_front_y_right_chain_vs_light"):quit(1);return
    scene.set_pose(.5,.35,0,0)
    if not await shot("16_rest_chain_vs_light"):quit(1);return
    scene.set_pose(.72,.40,0,0)
    if not await shot("17_chain_visible_over_interior_light_mid_pose"):quit(1);return
    print("M01_V31_ACTUAL_GODOT_CAPTURES=17")
    quit(0)

func shot(label:String)->bool:
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
    var im:Image=root.get_texture().get_image()
    if im.get_size()!=Vector2i(1280,720):
        printerr("M01V31_CAPTURE_BAD_SIZE",im.get_size());return false
    if im.save_png(ProjectSettings.globalize_path(OUT+label+".png"))!=OK:
        printerr("M01V31_CAPTURE_SAVE_FAIL",label);return false
    print("M01V31_ACTUAL_GODOT_FRAME",label)
    return true
