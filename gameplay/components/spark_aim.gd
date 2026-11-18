## EvaJiangdy b5543ff: reticle and independent vertical Spark aiming.
## Gameplay integration: use each player's own mapped jump/down keys, ignore
## repeats and ordinary crouch/drop, and share the *exact* target with cast.
extends Node2D

@export var show_when_cooling: bool = true
@export var pulse_speed: float = 4.0
@export var max_vertical_reach: float = 48.0
@export var double_tap_window: float = 0.30

@onready var player: GameplayPlayer = get_parent() as GameplayPlayer
@onready var emitter: GameplaySparkEmitter = get_parent().get_node("SparkEmitter")

var _clock: float = 0.0
var _redraw_time: float = 0.0
var _aim_mode: int = 0 # 1 = diagonal up, 0 = forward, -1 = diagonal down
var _last_jump_tap_msec: int = -1
var _last_down_tap_msec: int = -1


func _process(delta: float) -> void:
    _clock += delta
    _redraw_time += delta
    if _redraw_time >= 0.05:
        _redraw_time = 0.0
        queue_redraw()


func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key: InputEventKey = event as InputEventKey
    if not key.pressed or key.echo or player == null:
        return
    if player.input_locked or get_tree().paused:
        return

    # Eva's double-tap up is now scoped to p1_jump (W) or p2_jump (Up).
    # Down is also double-tap so a single S/Down still crouches normally.
    # S+W / Down+Up still drops through one-way platforms without aiming.
    var prefix := "p%d_" % player.player_index
    if key.is_action_pressed(prefix + "jump"):
        if not Input.is_action_pressed(prefix + "down"):
            _tap_direction(1, Time.get_ticks_msec())
    elif key.is_action_pressed(prefix + "down"):
        if not Input.is_action_pressed(prefix + "jump"):
            _tap_direction(-1, Time.get_ticks_msec())


func _tap_direction(direction: int, now_msec: int) -> void:
    var previous := _last_jump_tap_msec if direction > 0 else _last_down_tap_msec
    var within_window := previous >= 0 and now_msec - previous <= int(double_tap_window * 1000.0)
    if direction > 0:
        _last_jump_tap_msec = -1 if within_window else now_msec
    else:
        _last_down_tap_msec = -1 if within_window else now_msec
    if not within_window:
        return
    # Double-tap same direction toggles back to horizontal; switching
    # direction changes aim without needing an intermediate reset.
    _aim_mode = 0 if _aim_mode == direction else direction
    queue_redraw()


func reset_aim() -> void:
    _aim_mode = 0
    _last_jump_tap_msec = -1
    _last_down_tap_msec = -1
    queue_redraw()


func aim_mode() -> int:
    return _aim_mode


func _get_current_target() -> Vector2:
    if player == null or emitter == null:
        return Vector2.ZERO
    return Vector2(float(player.facing) * emitter.reach,
        float(-_aim_mode) * max_vertical_reach)


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
    var glow := 0.68 + 0.17 * sin(_clock * pulse_speed)
    var alpha := glow if emitter.is_ready() else 0.25
    var color := Color(player.tint.r, player.tint.g, player.tint.b, alpha)
    draw_rect(Rect2(target - Vector2(5, 5), Vector2(10, 10)),
        Color(0.06, 0.10, 0.14, alpha * 0.7), false, 1.0)
    for offset: Vector2 in [Vector2(-7, 0), Vector2(7, 0), Vector2(0, -7), Vector2(0, 7)]:
        draw_rect(Rect2((target + offset).round(), Vector2(2, 2)), color)
    var line_y := -3.0 - 12.0 * float(_aim_mode)
    draw_line(Vector2(float(player.facing) * 18.0, line_y),
        Vector2(float(player.facing) * 23.0, line_y), color, 1.0)
