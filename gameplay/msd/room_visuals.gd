## Original pixel-painted backdrop for Property Damage's living room test.
## No collision dependencies: floor, walls, furniture platforms are separate.
extends Node2D

const ROOM_ART: Texture2D = preload("res://gameplay/msd/art/living_room_pixel.png")


func _draw() -> void:
	draw_texture(ROOM_ART, Vector2.ZERO)
