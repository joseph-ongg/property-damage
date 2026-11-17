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
var _last_target_offset: Vector2 = Vector2.ZERO ## Stores the latest aim offset for drawing


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	var was_flashing := _flash_remaining > 0.0
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	if was_flashing:
		queue_redraw()  # Clear the final flash frame when it expires.


func is_ready() -> bool:
	return _cooldown_remaining <= 0.0


func cooldown_ratio() -> float:
	if cooldown <= 0.0:
		return 0.0
	return clampf(_cooldown_remaining / cooldown, 0.0, 1.0)


func cast_spark(world_center: Vector2, facing: int, bridge: GameplayFireBridge, tint: Color, target_override: Vector2 = Vector2.INF) -> bool:
	if not is_ready():
		return false
	_direction = 1 if facing >= 0 else -1
	_tint = tint
	_cooldown_remaining = cooldown
	_flash_remaining = flash_duration
	
	# Use target_override if provided, otherwise default to horizontal reach
	var target: Vector2
	if target_override != Vector2.INF:
		target = target_override
		_last_target_offset = target - world_center
	else:
		_last_target_offset = Vector2(float(_direction) * reach, 0)
		target = world_center + _last_target_offset
		
	var accepted := bridge != null and bridge.ignite_world(target)
	spark_cast.emit(target, accepted)
	queue_redraw()
	return accepted


func _draw() -> void:
	if _flash_remaining <= 0.0:
		return
	# The Art Team's room and magic bolts are hard-edge pixel art. Avoid the
	# previous antialiased line/circle glow so Spark uses the same visual scale.
	var alpha := _flash_remaining / flash_duration
	var pixel_color := Color(_tint.r, _tint.g, _tint.b, alpha)
	
	# Draw particles interpolating toward the target offset
	for i in range(6):
		var t := float(i) / 5.0
		var center := (_last_target_offset * t).round()
		draw_rect(Rect2(center + Vector2(-2, -2), Vector2(4, 4)), pixel_color)
		
	var tip := _last_target_offset.round()
	draw_rect(Rect2(tip + Vector2(-5, -3), Vector2(10, 6)), Color(1.0, 0.52, 0.19, alpha))
	draw_rect(Rect2(tip + Vector2(-2, -1), Vector2(4, 3)), Color(1.0, 0.98, 0.77, alpha))
