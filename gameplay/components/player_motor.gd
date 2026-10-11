## Independent, reusable platforming physics for a CharacterBody2D.
## Coyote time and jump buffering make platform jumps more forgiving.
class_name GameplayMotor
extends Node

@export var speed: float = 245.0
@export var ground_acceleration: float = 1500.0
@export var air_acceleration: float = 1000.0
@export var jump_speed: float = 460.0
@export var gravity: float = 1050.0
@export var max_fall_speed: float = 750.0
@export_range(0.0, 0.3, 0.01) var coyote_time: float = 0.10
@export_range(0.0, 0.3, 0.01) var jump_buffer_time: float = 0.12

var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0


func reset() -> void:
	_coyote_left = 0.0
	_jump_buffer_left = 0.0


func step(body: CharacterBody2D, delta: float, horizontal: float, jumping: bool, forced_x: float = INF) -> void:
	var grounded := body.is_on_floor()
	if grounded:
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)

	if jumping:
		_jump_buffer_left = jump_buffer_time
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	var launch := _jump_buffer_left > 0.0 and _coyote_left > 0.0
	if launch:
		body.velocity.y = -jump_speed
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
	elif grounded:
		if body.velocity.y > 0.0:
			body.velocity.y = 0.0
	else:
		body.velocity.y = minf(body.velocity.y + gravity * delta, max_fall_speed)

	var acceleration := ground_acceleration if grounded else air_acceleration
	if is_inf(forced_x):
		body.velocity.x = move_toward(body.velocity.x, horizontal * speed, acceleration * delta)
	else:
		body.velocity.x = forced_x
	body.move_and_slide()
