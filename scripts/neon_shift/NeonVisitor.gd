extends Node2D
## Registered illustrated poses. State changes come from authoritative visit/machine data.
const ORDER := [0,1,2,3,4,3,2,1]
static var banks: Dictionary={}
static var registration: Dictionary={}
var design := "mika"
var target := Vector2.ZERO
var origin := Vector2(700,374)
var feet := Vector2.ZERO
var elapsed := 0.0
var walking := true
var departing := false
var height := 170.0
var phase := 0
var sprite: Sprite2D
var reaction := "idle"
var selected := false
var bank: Dictionary={}

static func _atlas_cell(texture: Texture2D,index: int,columns: int,rows: int) -> Texture2D:
    if registration.is_empty():
        registration=JSON.parse_string(FileAccess.get_file_as_string("res://art/neon_shift/registration.json"))
    if registration.has(texture.resource_path):
        var r: Array=registration[texture.resource_path].regions[index]
        var registered:=AtlasTexture.new();registered.atlas=texture
        registered.region=Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
        return registered
    var size:=texture.get_size()/Vector2(columns,rows)
    var x0:=floori((index%columns)*size.x)
    var y0:=floori((index/columns)*size.y)
    var x1:=floori(((index%columns)+1)*size.x)
    var y1:=floori(((index/columns)+1)*size.y)
    var cell:=Rect2i(x0,y0,x1-x0,y1-y0)
    var source:=texture.get_image().get_region(cell)
    var used:=source.get_used_rect()
    var atlas:=AtlasTexture.new()
    atlas.atlas=texture
    atlas.region=Rect2(Vector2(cell.position+used.position),Vector2(used.size))
    return atlas

static func load_bank(kind: String) -> Dictionary:
    if banks.has(kind): return banks[kind]
    var data: Dictionary={"walk":[],"poses":{}}
    if kind=="mika":
        for i in 5:
            var tex:=load("res://art/neon_shift/walk/pose_%02d.png" % i) as Texture2D
            data.walk.append(_atlas_cell(tex,0,1,1))
        data.poses.idle=_atlas_cell(load("res://art/neon_shift/actor01_identity.png") as Texture2D,0,1,1)
        var sheet:=load("res://art/neon_shift/sources/mika_reactions.png") as Texture2D
        var keys: Array[String]=["play","anticipation","cheer","miss","hold","card"]
        for i in 6: data.poses[keys[i]]=_atlas_cell(sheet,i,3,2)
    else:
        var path: String="res://art/neon_shift/sources/"+kind+"_poses.png"
        if not ResourceLoader.exists(path): return load_bank("mika")
        var sheet:=load(path) as Texture2D
        data.poses.idle=_atlas_cell(sheet,0,4,2)
        for i in [1,2,3,4]: data.walk.append(_atlas_cell(sheet,i,4,2))
        data.poses.play=_atlas_cell(sheet,5,4,2)
        data.poses.anticipation=data.poses.play
        data.poses.cheer=_atlas_cell(sheet,6,4,2)
        data.poses.hold=_atlas_cell(sheet,7,4,2)
        data.poses.miss=data.poses.idle
        data.poses.card=data.poses.idle
    banks[kind]=data
    return data

func _ready() -> void:
    bank=load_bank(design)
    sprite=Sprite2D.new();sprite.centered=false
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(sprite)
    feet=origin

func present(seconds: float, is_departing: bool = false, state: String = "idle") -> void:
    elapsed=seconds;departing=is_departing;reaction=state
    # Guests stop to acknowledge a completed service before walking out.
    var walk_time:=maxf(0,seconds-1.3) if departing else seconds
    var u:=clampf(walk_time/2.7,0,1)
    walking=(u<1.0 and not departing) or (departing and seconds>1.3)
    feet=origin.lerp(target,smoothstep(0,1,u))
    if departing: feet=target.lerp(Vector2(1030,550),smoothstep(0,1,u))
    position=feet
    var depth:=lerpf(.56,1.0,smoothstep(0,1,u)) if not departing else 1.0
    var texture: Texture2D=bank.poses.get(state,bank.poses.idle)
    if walking:
        var frames: Array=bank.walk
        var idx: int=ORDER[(int(walk_time*11.0)+phase)%ORDER.size()] if frames.size()==5 else (int(walk_time*8.0)+phase)%frames.size()
        texture=frames[idx]
    sprite.texture=texture
    var s:=height*depth/texture.get_height()
    sprite.scale=Vector2.ONE*s
    sprite.position=Vector2(-texture.get_width()*s*.5,-texture.get_height()*s)
    sprite.flip_h=target.x<origin.x and not departing and walking
    modulate.a=1.0-clampf((walk_time-1.8)/.9,0,1) if departing else 1.0
    queue_redraw()

func _draw() -> void:
    draw_set_transform(Vector2.ZERO,0,Vector2(1,.24))
    draw_circle(Vector2(0,-7),30,Color(0.04,0.02,0.08,.30))
    if selected: draw_arc(Vector2(0,-7),33,0,TAU,36,Color(.47,.94,.83,.85),2,true)
    draw_set_transform(Vector2.ZERO)
