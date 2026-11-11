## Fire contact sensor. Emits touched_fire every damage_interval while the
## player's feet are in a burning cell. One instance per player (own cooldown).
## Emits a signal instead of coupling Gameplay to health or Simulation internals.
class_name GameplayFireHazard
extends Node

signal touched_fire

@export var enabled: bool = false
@export var damage_interval: float = 1.0
## How far above the bottom of the collider the "feet" sample point sits.
@export var feet_inset: float = 7.0
var _cooldown: float = 0.0


func tick(delta: float, bridge: GameplayFireBridge, player: CharacterBody2D) -> void:
	if not enabled or bridge == null:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	if bridge.is_burning_world(_feet_world(player)):
		_cooldown = damage_interval
		touched_fire.emit()


func reset() -> void:
	_cooldown = 0.0


func _feet_world(player: CharacterBody2D) -> Vector2:
	var c := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if c != null and c.shape is RectangleShape2D:
		var half := (c.shape as RectangleShape2D).size.y * absf(c.global_scale.y) * 0.5
		return Vector2(player.global_position.x, c.global_position.y + half - feet_inset)
	return player.global_position + Vector2(0, 13)
