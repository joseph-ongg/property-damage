## Low-cost background embers/mist inspired by atmospheric pixel staging.
## Entirely decorative; deterministic and disabled when the tree is paused.
extends Node2D

@export_range(8, 120, 1) var mote_count: int = 44
@export var drift: float = 10.0

var _motes: Array[Vector2] = []
var _phases: Array[float] = []
var _time: float = 0.0
var _redraw_timer: float = 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 86421
	for i in mote_count:
		_motes.append(Vector2(rng.randf_range(36, 925), rng.randf_range(216, 485)))
		_phases.append(rng.randf_range(0, TAU))
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_redraw_timer += delta
	if _redraw_timer >= 1.0 / 24.0:
		_redraw_timer = 0.0
		queue_redraw()


func _draw() -> void:
	for i in _motes.size():
		var pos := _motes[i]
		var drift_x := sin(_phases[i] + _time * 0.65) * 10.0
		var y := fposmod(pos.y - _time * (drift + float(i % 4) * 4.0) - 210.0, 285.0) + 210.0
		var brightness := 0.27 + 0.22 * sin(_time * 1.7 + _phases[i])
		draw_rect(Rect2(Vector2(pos.x + drift_x, y).round(), Vector2(2, 2)), Color(1.0, 0.78, 0.42, brightness))
