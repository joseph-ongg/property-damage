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
# 来源：Austin / chouhuaidan，a529274 player.gd 的 jumps_left 计数方案。
# EN: Source: Austin (chouhuaidan), commit a529274, player jump counter.
# 中文：直接按剩余次数管理双跳；下方额外保留本地土狼时间、预输入和空中惯性。
# EN: Count remaining jumps while retaining local coyote time, jump buffering and air momentum.
var _jumps_left: int = 1
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0


func reset() -> void:
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_jumps_left = max_jumps
	speed_scale = 1.0
	environment_acceleration_x = 0.0


func jumps_remaining() -> int:
	return maxi(0, _jumps_left)


func step(body: CharacterBody2D, delta: float, horizontal: float, jumping: bool, forced_x: float = INF, jump_released: bool = false, force_airborne: bool = false) -> void:
	# 中文：主动下穿单向平台的几帧按空中处理，避免重新把下落速度清零。
	# EN: Treat deliberate drop-through as airborne to preserve downward velocity.
	var grounded := body.is_on_floor() and not force_airborne
	if grounded:
		_coyote_left = coyote_time
		_jumps_left = max_jumps
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		# Walking off a ledge spends the first jump after coyote time expires.
		if _coyote_left <= 0.0:
			_jumps_left = mini(_jumps_left, max_jumps - 1)

	if jumping:
		_jump_buffer_left = jump_buffer_time
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	# Austin 上游逻辑：有 jumps_left 才能跳，起跳后减一。
	# EN: Austin approach: permit a jump while jumps_left is positive, then decrement it.
	# 中文：走出边缘后在 coyote 时间内仍可用第一次跳。
	# EN: The first jump remains available briefly after walking off a ledge.
	var first_jump_allowed := grounded or (_jumps_left == max_jumps and _coyote_left > 0.0)
	var extra_jump_allowed := _jumps_left > 0 and _jumps_left < max_jumps
	var launch := _jump_buffer_left > 0.0 and (first_jump_allowed or extra_jump_allowed)
	if launch:
		body.velocity.y = -jump_speed
		_jumps_left -= 1
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
	# EN: Keep horizontal momentum when releasing direction midair; brake normally on the ground.
	if is_zero_approx(horizontal) and not grounded and preserve_air_momentum:
		acceleration = 0.0  # No horizontal braking just because the key was released.
	if is_inf(forced_x):
		body.velocity.x = move_toward(body.velocity.x, target_speed, acceleration * delta)
	else:
		body.velocity.x = forced_x
	body.velocity.x += environment_acceleration_x * delta
	# 中文：空调是外部减速效果；即使玩家在空中松开方向键保留惯性，
	# EN: Air conditioning applies external slowdown even if horizontal air momentum is retained.
	# 进入冷气区也应逐渐降到减速后的上限，离开后不再施加这段阻力。
	# EN: Slow to the chilled speed cap in the AC zone; stop applying drag outside it.
	if speed_scale < 0.99 and absf(body.velocity.x) > speed * speed_scale:
		var limit := signf(body.velocity.x) * speed * speed_scale
		body.velocity.x = move_toward(body.velocity.x, limit, ground_acceleration * delta * 0.7)
	body.move_and_slide()
	if body.is_on_floor():
		_jumps_left = max_jumps
