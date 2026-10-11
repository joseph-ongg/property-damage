## Facing-dependent spark, with visible feedback even before Simulation storage ships.
class_name GameplaySparkEmitter
extends Node2D

signal spark_cast(target: Vector2, accepted: bool)

@export var reach: float = 34.0
@export var cooldown: float = 0.22
@export var flash_duration: float = 0.16

var _cooldown_remaining: float = 0.0
var _flash_remaining: float = 0.0
var _direction: int = 1
var _tint: Color = Color.ORANGE


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	var was_flashing := _flash_remaining > 0.0
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	if was_flashing:
		queue_redraw()  # Clear the final flash frame when it expires.


func cast_spark(world_center: Vector2, facing: int, bridge: GameplayFireBridge, tint: Color) -> bool:
	if _cooldown_remaining > 0.0:
		return false
	_direction = 1 if facing >= 0 else -1
	_tint = tint
	_cooldown_remaining = cooldown
	_flash_remaining = flash_duration
	var target := world_center + Vector2(float(_direction) * reach, 0)
	var accepted := bridge != null and bridge.ignite_world(target)
	spark_cast.emit(target, accepted)
	queue_redraw()
	return accepted


func _draw() -> void:
	if _flash_remaining <= 0.0:
		return
	var alpha := _flash_remaining / flash_duration
	var start := Vector2(float(_direction) * 13.0, 0.0)
	var end := Vector2(float(_direction) * reach, 0.0)
	var glow := Color(_tint.r, _tint.g, _tint.b, alpha)
	draw_line(start, end, glow, 5.0, true)
	draw_circle(end, 7.0, glow)
	draw_circle(end, 3.0, Color(1.0, 0.98, 0.75, alpha))
