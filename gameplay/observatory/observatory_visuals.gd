extends Node2D
const BACKDROP: Texture2D = preload("res://gameplay/observatory/observatory_background.png")

func _draw() -> void:
    draw_texture(BACKDROP, Vector2.ZERO)
