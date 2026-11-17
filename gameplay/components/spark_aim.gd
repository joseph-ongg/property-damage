## Target marker with double-tap W to toggle aim up, and S for aim down.
extends Node2D

@export var show_when_cooling: bool = true
@export var pulse_speed: float = 4.0
@export var max_vertical_reach: float = 48.0
@export var double_tap_window: float = 0.3 ## Time window in seconds to register a double-press.

@onready var player: GameplayPlayer = get_parent() as GameplayPlayer
@onready var emitter: GameplaySparkEmitter = get_parent().get_node("SparkEmitter")

var _clock: float = 0.0
var _redraw_time: float = 0.0

# Double-tap tracking variables
var _last_w_press_time: float = -1.0
var _aim_mode: int = 0 ## 0 = Normal/Forward, 1 = Aim Up, -1 = Aim Down


func _process(delta: float) -> void:
	_clock += delta
	_redraw_time += delta

	# Check for double-press on the W key (or use "aim_up" if you mapped it)
	if Input.is_key_pressed(KEY_W) and Input.is_action_just_pressed("ui_up"): # Or check "aim_up" if you prefer
		pass

	# Cleaner approach: Detect just-pressed events for W and S keys directly
	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		# Let's check specifically for W key press event
		pass

	if _redraw_time >= 0.05:
		_redraw_time = 0.0
		queue_redraw()


# Let's use Godot's input event method for reliable double-tap detection:
func _input(event: InputEvent) -> void:
	# Check if the W key (or 'aim_up' action) was pressed
	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		var current_time := Time.get_ticks_msec() / 1000.0
		if current_time - _last_w_press_time <= double_tap_window:
			# Double press detected! Toggle aim up
			if _aim_mode == 1:
				_aim_mode = 0 # Reset to normal
			else:
				_aim_mode = 1 # Aim up
			_last_w_press_time = -1.0
		else:
			_last_w_press_time = current_time

	# S key or down action handles aiming down
	if event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		if _aim_mode == -1:
			_aim_mode = 0 # Reset to normal
		else:
			_aim_mode = -1 # Aim down


func _get_current_target() -> Vector2:
	if player == null or emitter == null:
		return Vector2.ZERO

	var h_dir := float(player.facing)
	var vertical_offset := 0.0

	if _aim_mode == 1:
		vertical_offset = -max_vertical_reach
	elif _aim_mode == -1:
		vertical_offset = max_vertical_reach

	return Vector2(h_dir * emitter.reach, vertical_offset)


func target_world_position() -> Vector2:
	if player == null or emitter == null:
		return global_position
	return player.global_position + _get_current_target()


func _draw() -> void:
	if player == null or emitter == null:
		return
	if not show_when_cooling and not emitter.is_ready():
		return

	var target := _get_current_target()
	var glow: float = 0.68 + 0.17 * sin(_clock * pulse_speed)
	var alpha := glow if emitter.is_ready() else 0.25
	var color := Color(player.tint.r, player.tint.g, player.tint.b, alpha)

	# Open center keeps the target visible against small pixel textures.
	draw_rect(Rect2(target - Vector2(5, 5), Vector2(10, 10)), Color(0.06, 0.10, 0.14, alpha * 0.7), false, 1.0)
	for offset: Vector2 in [Vector2(-7, 0), Vector2(7, 0), Vector2(0, -7), Vector2(0, 7)]:
		draw_rect(Rect2((target + offset).round(), Vector2(2, 2)), color)

	# Adjust accent line based on current aim mode
	var h_dir := float(player.facing)
	var line_y_offset := 0.0
	if _aim_mode == 1:
		line_y_offset = -12.0
	elif _aim_mode == -1:
		line_y_offset = 12.0

	draw_line(
		Vector2(h_dir * 18, -3 + line_y_offset),
		Vector2(h_dir * 23, -3 + line_y_offset),
		color, 1.0
	)
