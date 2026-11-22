## Original pixel-painted backdrop for Property Damage's living room test.
## No collision dependencies: floor, walls, furniture platforms are separate.
extends Node2D

const ROOM_ART: Texture2D = preload("res://gameplay/msd/art/living_room_pixel.png")


func _draw() -> void:
	draw_texture(ROOM_ART, Vector2.ZERO)
	# The source room baked its wall clock into the wallpaper. Cover that
	# original tile with an adjacent strip of the same wall so the movable
	# clock in WorldItems can actually leave the wall when picked up.
	draw_texture_rect_region(ROOM_ART, Rect2(786, 92, 98, 98), Rect2(578, 92, 98, 98))
