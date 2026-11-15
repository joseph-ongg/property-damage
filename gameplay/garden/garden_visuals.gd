## Source Piskel stage reconstruction: exact 2x integer pixel scale, preserving
## art's original aspect and source colors with separate breakable plant layers.
extends Node2D

const STAGE: Texture2D = preload("res://gameplay/garden/art_generated/garden_stage_background.png")

func _draw() -> void:
    draw_texture(STAGE, Vector2.ZERO)
