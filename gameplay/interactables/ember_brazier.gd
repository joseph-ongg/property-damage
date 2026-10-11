## An optional demo objective activated by a directional spark near its flame cup.
## Fully separated from burn_box and its fire propagation simulation.
class_name GameplayEmberBrazier
extends Node2D

signal lit_by(player_index: int)

@export var ignition_radius: float = 44.0
var lit: bool = false
var _clock: float = 0.0


func _process(delta: float) -> void:
	if not lit:
		return
	_clock += delta
	$Glow.modulate.a = 0.68 + 0.17 * sin(_clock * 4.0)
	$Glow.scale = Vector2.ONE * (0.73 + 0.04 * sin(_clock * 3.0))


func try_ignite(world_target: Vector2, player_index: int) -> bool:
	if lit or world_target.distance_to(global_position + Vector2(0.0, -18.0)) > ignition_radius:
		return false
	lit = true
	$Sprite2D.texture = preload("res://gameplay/art/brazier_lit.png")
	$Glow.visible = true
	lit_by.emit(player_index)
	return true
