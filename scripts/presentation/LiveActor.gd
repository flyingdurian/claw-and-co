class_name LiveActor
extends Node2D
## Presentation-only sprite puppet. All phase, footsteps and poses depend on authoritative ticks.
## No random timers, player avatar, or simulation-side mutations; optional 2D layered NPC rig.
const PROPS := {
    "plush_mochi": "res://art/living/plush_mochi.png",
    "plush_panda": "res://art/living/plush_panda.png",
    "figure_fox": "res://art/prizes/figure_fox.png",
    "figure_star": "res://art/prizes/figure_star.png"
}
var person_id: String = ""
var body: Sprite2D
var shadow: Sprite2D
var carried: Sprite2D
var mood_label: Label
var patience_back: TextureProgressBar
var pose: String = "BROWSE"
var last_pose: String = ""
var base_scale: float = 0.60
var actor_width: float = 100.0
var actor_height: float = 200.0
var original_texture: Texture2D
var source_index: int = 1
var last_animation_key: String = ""
var seed_index: int = 0
var tick: int = 0
var foot_point: Vector2 = Vector2.ZERO
var articulated: ArticulatedCustomerRig = null
var previous_foot: Vector2 = Vector2.ZERO
var last_facing: float = 1.0

func configure(id: String, texture: Texture2D, index: int, scale_factor: float = 0.60) -> void:
    person_id = id
    seed_index = index
    base_scale = scale_factor
    original_texture = texture
    var basename: String = texture.resource_path.get_file()
    source_index = int(basename.trim_prefix("actor_").trim_suffix(".png"))
    var rig_dir: String = "res://art/performers/actor_%02d" % source_index
    # Reuse complete artist-made rigs by character design, not visit ID.
    if ArticulatedCustomerRig.art_complete(rig_dir):
        articulated = ArticulatedCustomerRig.new()
        add_child(articulated)
        articulated.setup(rig_dir)
    actor_width = float(texture.get_width())
    actor_height = float(texture.get_height())
    body = Sprite2D.new()
    body.name = "LivingBody"
    body.texture = texture
    body.centered = true
    body.position = Vector2(0.0, -actor_height * 0.50)
    add_child(body)
    shadow = Sprite2D.new()
    shadow.name = "FootShadow"
    shadow.texture = load("res://art/living/foot_shadow.png") as Texture2D
    shadow.z_index = -1
    add_child(shadow)
    carried = Sprite2D.new()
    carried.name = "WonPrizeProp"
    carried.visible = false
    carried.position = Vector2(28, -actor_height * .39)
    carried.scale = Vector2(.66,.66)
    add_child(carried)
    mood_label = Label.new()
    mood_label.name = "Expression"
    mood_label.position = Vector2(-55, -actor_height-34)
    mood_label.size = Vector2(110, 27)
    mood_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mood_label.add_theme_font_size_override("font_size", 22)
    mood_label.add_theme_color_override("font_color", Color(1,.95,.72))
    mood_label.add_theme_color_override("font_shadow_color", Color(.16,.07,.23))
    mood_label.add_theme_constant_override("shadow_offset_x", 2)
    mood_label.add_theme_constant_override("shadow_offset_y", 2)
    add_child(mood_label)
    patience_back = TextureProgressBar.new()
    patience_back.name = "PatienceMeter"
    patience_back.position = Vector2(-32, -actor_height-43)
    patience_back.size = Vector2(64, 5)
    patience_back.min_value = 0
    patience_back.max_value = 100
    patience_back.value = 100
    patience_back.texture_under = load("res://art/living/patience_track.png") as Texture2D
    patience_back.texture_progress = load("res://art/living/patience_fill.png") as Texture2D
    add_child(patience_back)

func render_at(authoritative_tick: int, at_foot: Vector2, action: String, reaction: String = "", prop_id: String = "", patience_percent: float = -1.0, perspective_scale: float = -1.0) -> void:
    tick = authoritative_tick
    pose = action
    foot_point = at_foot
    position = at_foot
    var direction: float = signf(at_foot.x-previous_foot.x)
    if is_zero_approx(direction): direction = last_facing
    last_facing = direction
    previous_foot = at_foot
    z_index = clampi(int(at_foot.y), 0, 4095)
    var group: String = "chat"
    match pose:
        "WALK", "ARRIVE", "LEAVE": group = "walk"
        "PLAY", "CONCENTRATE", "TRY_AGAIN": group = "play"
        "WIN", "CHEER", "CELEBRATE": group = "cheer"
        "MISS", "SAD", "FRUSTRATED": group = "miss"
        "WATCH", "ANTICIPATE", "QUEUE": group = "watch"
        "COLLECT", "HOLD_PRIZE": group = "hold"
    var frame: int = int((tick + seed_index * 7) / 7) % 4
    var key: String = "actor_%02d_%s_%d.png" % [source_index,group,frame]
    if key != last_animation_key:
        body.texture = load("res://art/living/"+key) as Texture2D
        last_animation_key = key
    var phase: float = float(tick + seed_index * 41)
    var gait: float = phase * 0.31
    var bob: float = 0.0
    var lean: float = 0.0
    var squash: float = 1.0
    var side: float = 0.0
    var energy: float = 0.0
    var mood: String = ""
    match pose:
        "WALK", "ARRIVE", "LEAVE":
            bob = absf(sin(gait)) * 7.0
            side = sin(gait * .5) * 2.8
            lean = .06 * sin(gait)
            squash = 1.0 - .016 * absf(sin(gait))
            mood = "♪" if tick % 120 < 24 else ""
        "CHAT":
            bob = 2.8 * sin(phase * .12)
            lean = .045 * sin(phase * .05)
            mood = "…" if tick % 105 < 35 else "♫"
        "WATCH":
            lean = -.05 + .018 * sin(phase * .07)
            bob = 2.0 * sin(phase * .07)
            mood = "👀" if tick % 100 < 42 else ""
        "QUEUE", "ANTICIPATE":
            bob = 2.0 * sin(phase*.10)
            lean = .028 * sin(phase*.08)
            mood = "!" if tick % 140 < 30 else ""
        "REQUEST":
            bob = absf(sin(phase * .16)) * 4.0
            lean = -.055 * sin(phase * .14)
            mood = "?" if tick % 90 < 58 else "!"
        "PLAY", "CONCENTRATE":
            bob = sin(phase * .20) * 1.8
            lean = -.10 + .035 * sin(phase*.11)
            squash = .98 + .025 * sin(phase*.15)
            mood = "✦" if tick % 80 < 18 else ""
        "FRUSTRATED":
            side = sin(phase*.38) * 4.5
            lean = .08 * sin(phase*.38)
            mood = "!!"
        "SAD", "MISS":
            bob = -4.0
            lean = .10 + .014 * sin(phase*.07)
            squash = .95
            mood = "…"
        "WIN", "CHEER", "CELEBRATE":
            bob = absf(sin(phase*.23)) * 15.0
            lean = .14 * sin(phase*.23)
            squash = 1.04
            mood = "★ ✦ ★"
        "COLLECT", "HOLD_PRIZE":
            bob = 2.0 * sin(phase*.08)
            lean = -.06
            mood = "♥"
        "TRY_AGAIN":
            bob = 2.5 * sin(phase*.12)
            lean = -.06 + .03 * sin(phase*.18)
            mood = "!"
        "REST":
            bob = sin(phase*.06)
            mood = ""
        _:
            bob = sin(phase*.07) * 1.8
    var active_reaction: String = reaction
    if not active_reaction.is_empty():
        match active_reaction:
            "STUCK": mood = "!?"
            "MISS_RELEASED": mood = "…"
            "OUTPUT_HELD", "SELF_COLLECTED": mood = "★ ✦ ★"
    var visual_scale: float = perspective_scale if perspective_scale > 0.0 else base_scale
    # Real independent motion: 2-D sprite translation, sway, squash, footstep, leap and prop animation.
    if articulated != null and articulated.rig_valid:
        body.visible = false
        articulated.visible = true
        articulated.scale = Vector2(visual_scale,visual_scale)
        # R4-A rig uses foot-contact coordinates anchored at actor's origin.
        # The former -height offset detached modular feet from the aisle floor.
        articulated.position = Vector2.ZERO
        articulated.sample(tick,action,direction)
    body.scale = Vector2(visual_scale*(1.0 + lean*.36), visual_scale*squash)
    body.position = Vector2(side*visual_scale, (-actor_height*.5 - bob)*visual_scale)
    body.rotation = lean
    shadow.position = Vector2(0, -2)
    shadow.scale = Vector2(.54 * visual_scale, .28 * visual_scale) * (1.0 - clampf(bob/75.0,0.0,.25))
    var prize_path: String = str(PROPS.get(prop_id, ""))
    carried.visible = not prize_path.is_empty()
    if carried.visible:
        if carried.texture == null or carried.get_meta("item_id", "") != prop_id:
            carried.texture = load(prize_path) as Texture2D
            carried.set_meta("item_id", prop_id)
        carried.position = Vector2(30, -actor_height*.38 - bob*.55) * visual_scale
        carried.rotation = -.07 + .06 * sin(phase*.17)
        carried.scale = Vector2(.64,.64) * visual_scale
    mood_label.text = mood
    mood_label.position = Vector2(-55,-actor_height*.93)*visual_scale + Vector2(0,-24-bob*.75)
    mood_label.scale = Vector2.ONE * maxf(.85,visual_scale)
    patience_back.visible = patience_percent >= 0.0
    if patience_back.visible:
        patience_back.value = clampf(patience_percent,0.0,100.0)
        patience_back.position = mood_label.position + Vector2(23,31)
        patience_back.scale = Vector2.ONE * maxf(.85,visual_scale)
