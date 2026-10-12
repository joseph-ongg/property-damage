## Separate pixel-art atmosphere and foreground plates. No physics, no UI,
## no new environment mechanics: these only add 2D spatial layering.
extends Node2D

@export var foreground: bool = false

const LIGHTING: Texture2D = preload("res://gameplay/msd/art/living_room_lighting.png")
const FOREGROUND: Texture2D = preload("res://gameplay/msd/art/living_room_foreground.png")


func _draw() -> void:
	draw_texture(FOREGROUND if foreground else LIGHTING, Vector2.ZERO)
