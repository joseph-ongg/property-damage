## Reusable CharacterBody2D movement: ordinary or two-jump fixed-arc platforming.
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
@export_range(0.15, 1.0, 0.05) var jump_cut_multiplier: float = 0.48
@export var fixed_jump_height: bool = false
@export_range(1, 3, 1) var max_jumps: int = 1
@export var preserve_air_momentum: bool = false

# Optional environmental effects, written by the test arena once per frame.
var speed_scale: float = 1.0
var environment_acceleration_x: float = 0.0
var _jumps_used: int = 0
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0


func reset() -> void:
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_jumps_used = 0
	speed_scale = 1.0
	environment_acceleration_x = 0.0


func jumps_remaining() -> int:
	return maxi(0, max_jumps - _jumps_used)


func step(body: CharacterBody2D, delta: float, horizontal: float, jumping: bool, forced_x: float = INF, jump_released: bool = false, force_airborne: bool = false) -> void:
	# 中文：主动下穿单向平台的几帧按空中处理，避免重新把下落速度清零。
	var grounded := body.is_on_floor() and not force_airborne
	if grounded:
		_coyote_left = coyote_time
		_jumps_used = 0
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		# Walking off a ledge spends the first jump after coyote time expires.
		if _coyote_left <= 0.0:
			_jumps_used = maxi(_jumps_used, 1)

	if jumping:
		_jump_buffer_left = jump_buffer_time
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	var first_jump_allowed := grounded or (_jumps_used == 0 and _coyote_left > 0.0)
	var extra_jump_allowed := _jumps_used > 0 and _jumps_used < max_jumps
	var launch := _jump_buffer_left > 0.0 and (first_jump_allowed or extra_jump_allowed)
	if launch:
		body.velocity.y = -jump_speed
		_jumps_used += 1
		_coyote_left = 0.0
		_jump_buffer_left = 0.0
	elif not fixed_jump_height and jump_released and body.velocity.y < -55.0:
		body.velocity.y *= jump_cut_multiplier
	elif grounded:
		if body.velocity.y > 0.0:
			body.velocity.y = 0.0
	else:
		body.velocity.y = minf(body.velocity.y + gravity * delta, max_fall_speed)

	var target_speed := horizontal * speed * speed_scale
	var acceleration := ground_acceleration if grounded else air_acceleration
	# 中文：只在空中松方向键时保留惯性，地面仍会正常减速。
	if is_zero_approx(horizontal) and not grounded and preserve_air_momentum:
		acceleration = 0.0  # No horizontal braking just because the key was released.
	if is_inf(forced_x):
		body.velocity.x = move_toward(body.velocity.x, target_speed, acceleration * delta)
	else:
		body.velocity.x = forced_x
	body.velocity.x += environment_acceleration_x * delta
	body.move_and_slide()
	if body.is_on_floor():
		_jumps_used = 0
