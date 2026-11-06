extends NeonCanvas
var game: Control
func _draw() -> void:
    if game != null: game.render_hud(self)
