## Small pixel-precise target marker. Purely visual, reusable with any grid.
extends Node2D

@export var show_when_cooling: bool = true
@export var pulse_speed: float = 4.0

@onready var player: GameplayPlayer = get_parent() as GameplayPlayer
@onready var emitter: GameplaySparkEmitter = get_parent().get_node("SparkEmitter")

var _clock: float = 0.0
var _redraw_time: float = 0.0


func _process(delta: float) -> void:
	_clock += delta
	_redraw_time += delta
	if _redraw_time >= 0.05:
		_redraw_time = 0.0
		queue_redraw()


func target_world_position() -> Vector2:
	if player == null or emitter == null:
		return global_position
	return player.global_position + Vector2(float(player.facing) * emitter.reach, 0.0)


func _draw() -> void:
	if player == null or emitter == null:
		return
	if not show_when_cooling and not emitter.is_ready():
		return
	var target := Vector2(float(player.facing) * emitter.reach, 0.0)
	var glow: float = 0.68 + 0.17 * sin(_clock * pulse_speed)
	var alpha := glow if emitter.is_ready() else 0.25
	var color := Color(player.tint.r, player.tint.g, player.tint.b, alpha)
	# Open center keeps the target visible against small pixel textures.
	draw_rect(Rect2(target - Vector2(5, 5), Vector2(10, 10)), Color(0.06, 0.10, 0.14, alpha * 0.7), false, 1.0)
	for offset: Vector2 in [Vector2(-7, 0), Vector2(7, 0), Vector2(0, -7), Vector2(0, 7)]:
		draw_rect(Rect2((target + offset).round(), Vector2(2, 2)), color)
	draw_line(Vector2(float(player.facing) * 18, -3), Vector2(float(player.facing) * 23, -3), color, 1.0)
