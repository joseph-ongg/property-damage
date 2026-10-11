## Optional fire contact sensor for later integration; disabled in the MSD demo.
## Emits contact damage instead of coupling Gameplay to health or Simulation internals.
class_name GameplayFireHazard
extends Node

signal touched_fire

@export var enabled: bool = false
@export var damage_interval: float = 1.0
var _cooldown: float = 0.0


func tick(delta: float, bridge: GameplayFireBridge, player: CharacterBody2D) -> void:
	if not enabled or bridge == null:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	var feet := player.global_position + Vector2(0, 13)
	if bridge.is_burning_world(feet):
		_cooldown = damage_interval
		touched_fire.emit()
