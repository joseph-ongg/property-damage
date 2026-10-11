## Lightweight landing dust, decor only, independent from physics and art assets.
extends Node2D

@export var lifetime: float = 0.27
var _remaining: float = 0.0


func trigger() -> void:
	_remaining = lifetime
	queue_redraw()


func is_active() -> bool:
	return _remaining > 0.0


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining = maxf(0.0, _remaining - delta)
	queue_redraw()


func _draw() -> void:
	if not is_active():
		return
	var progress := 1.0 - _remaining / lifetime
	var smoke := Color(0.85, 0.73, 0.56, (1.0 - progress) * 0.55)
	for i in 4:
		var side := -1.0 if i < 2 else 1.0
		var outward := (5.0 + float(i % 2) * 5.0) + progress * 17.0
		var y := -3.0 - progress * (4.0 + float(i % 2) * 6.0)
		draw_rect(Rect2(Vector2(side * outward, y).round(), Vector2(3, 3)), smoke)
