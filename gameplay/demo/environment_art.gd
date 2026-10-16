## Painted, original, static backgrounds and foreground glows; no gameplay logic.
extends Node2D

const SKY: Texture2D = preload("res://gameplay/art/moonlit_ruins.png")
const LIGHT: Texture2D = preload("res://gameplay/art/warm_glow.png")


func _draw() -> void:
	draw_texture(SKY, Vector2.ZERO)
	# Warm interior lantern light against cold moonlit hills.
	for world_pos: Vector2 in [Vector2(117, 258), Vector2(478, 206), Vector2(845, 260)]:
		draw_texture_rect(LIGHT, Rect2(world_pos - Vector2(92, 92), Vector2(184, 184)), false, Color(1, 0.8, 0.67, 0.5))
		# Hand-built ornamental lantern mount, gently framed in dark metal.
		draw_line(world_pos + Vector2(0,-28), world_pos + Vector2(0,-6), Color("3f3e49"), 3.0)
		draw_rect(Rect2(world_pos - Vector2(7, 5), Vector2(14, 17)), Color("443b46"))
		draw_rect(Rect2(world_pos - Vector2(4, 2), Vector2(8, 11)), Color("f8c27a"))
		draw_rect(Rect2(world_pos - Vector2(2, 2), Vector2(4, 8)), Color("ffe5a5"))
