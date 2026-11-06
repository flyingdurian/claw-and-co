class_name NeonCanvas
extends Control
const REGULAR = preload("res://art/neon_shift/fonts/Interface.ttf")
const BOLD = preload("res://art/neon_shift/fonts/Interface-Bold.ttf")
const INK := Color("1a1630")
const CREAM := Color("fff6e6")
const MUTED := Color("bdb2cc")
const PINK := Color("ff79ad")
const MINT := Color("79f0d5")
const GOLD := Color("ffc774")
func box(r: Rect2, color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, width: int = 1) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color=color
    style.corner_radius_top_left=radius
    style.corner_radius_top_right=radius
    style.corner_radius_bottom_left=radius
    style.corner_radius_bottom_right=radius
    style.border_color=border
    style.set_border_width_all(width)
    draw_style_box(style,r)
func txt(at: Vector2, text: String, size_px: int = 16, color: Color = CREAM, bold: bool = false, max_width: float = -1) -> void:
    draw_string(BOLD if bold else REGULAR,at,text,HORIZONTAL_ALIGNMENT_LEFT,max_width,size_px,color)
func centered(r: Rect2, text: String, size_px: int = 16, color: Color = CREAM, bold: bool = false) -> void:
    var font: Font=BOLD if bold else REGULAR
    var text_size:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px)
    txt(Vector2(r.position.x+(r.size.x-text_size.x)/2,r.position.y+(r.size.y+text_size.y*.60)/2),text,size_px,color,bold,r.size.x)
func fitted(texture: Texture2D, r: Rect2, tint: Color = Color.WHITE) -> void:
    if texture == null: return
    var s:=texture.get_size()
    var factor:=minf(r.size.x/s.x,r.size.y/s.y)
    var dims:=s*factor
    draw_texture_rect(texture,Rect2(r.position+(r.size-dims)*.5,dims),false,tint)
func line_bar(r: Rect2, value: float, color: Color) -> void:
    box(r,Color("41364e"),roundi(r.size.y*.5))
    if value > 0: box(Rect2(r.position,Vector2(r.size.x*clampf(value,0,1),r.size.y)),color,roundi(r.size.y*.5))
