## Native Art Team Garden pixels scaled by nearest filtering to our battle viewport.
extends Node2D
const IMAGE: Texture2D = preload("res://gameplay/art_team/exported/garden.png")

func _draw() -> void:
    draw_texture_rect(IMAGE, Rect2(0, 0, 960, 540), false)
