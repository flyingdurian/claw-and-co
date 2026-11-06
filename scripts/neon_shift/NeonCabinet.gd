extends Node2D
## Source-registered cabinet skin around the accepted M01 presentation component.
## Non-M01 cabinets reuse the illustrated cabinet family; transaction identity stays distinct.
var machine_id := "M01"
var view: MachineView
var color_index := 0
var sign_layer: Node2D
const COLORS := [Color("ff6fa9"),Color("6fe3ff"),Color("ffc777"),Color("bb9dff")]
func _ready() -> void:
    view = preload("res://scenes/machines/M01_Machine.tscn").instantiate() as MachineView
    add_child(view)
    view.get_node("Status").hide()
    view.get_node("SelectButton").hide()
    view.get_node("GlowLight").hide()
    view.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if color_index > 0:
        var shader := Shader.new()
        shader.code = "shader_type canvas_item; uniform vec4 accent : source_color = vec4(1.0); void fragment(){ vec4 c=texture(TEXTURE,UV); float pink=smoothstep(0.08,0.32,c.r-max(c.g,c.b*0.65)); float bright=max(c.r,max(c.g,c.b)); c.rgb=mix(c.rgb,accent.rgb*bright,pink*0.76); COLOR=c;}"
        var material := ShaderMaterial.new()
        material.shader=shader
        material.set_shader_parameter("accent",COLORS[color_index])
        view.artwork.material=material
        view.m01_chamber_backdrop.material=material
    if machine_id == "M02":
        view.m01_v31_rig.get_node("MovingXTrolley/SixPartClaw/RearPivot").hide()
    sign_layer = Node2D.new()
    sign_layer.z_index=12
    sign_layer.draw.connect(_draw_sign)
    add_child(sign_layer)
func _draw_sign() -> void:
    if machine_id=="M01": return
    var font: Font = preload("res://art/neon_shift/fonts/Interface-Bold.ttf")
    var poly := PackedVector2Array([Vector2(73,49),Vector2(221,69),Vector2(220,103),Vector2(73,83)])
    sign_layer.draw_colored_polygon(poly,Color("281e38"))
    var edge:=poly.duplicate();edge.append(poly[0])
    sign_layer.draw_polyline(edge,COLORS[color_index],1.4,true)
    sign_layer.draw_set_transform(Vector2(83,64),.13)
    sign_layer.draw_string(font,Vector2(0,11),machine_id+"  /  "+["MOCHI","LUCKY UFO","PRIZE LAB","PANDA"][color_index],HORIZONTAL_ALIGNMENT_LEFT,126,11,COLORS[color_index])
    sign_layer.draw_string(font,Vector2(0,26),["PLUSH CLUB","TWIN ARM","CHANCE PLAY","PLUSH CLUB"][color_index],HORIZONTAL_ALIGNMENT_LEFT,126,7,Color("fff6e6"))
    sign_layer.draw_set_transform(Vector2.ZERO)

func apply(snapshot: Dictionary, sessions: Dictionary) -> void:
    var local_snapshot: Dictionary = snapshot
    if machine_id != "M01":
        local_snapshot = snapshot.duplicate(false)
        local_snapshot["machines"] = snapshot.get("machines",{}).duplicate(true)
        local_snapshot["machines"]["machines"]["M01"] = snapshot.get("machines",{}).get("machines",{}).get(machine_id,{})
    view.apply_snapshot(local_snapshot,sessions)
