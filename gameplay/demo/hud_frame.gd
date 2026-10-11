## Decorative HUD frame and progress strips. Rendering-only, no game rules.
extends Control

var _shards: int = 0
var _braziers: int = 0


func set_progress(shards: int, braziers: int) -> void:
	if shards == _shards and braziers == _braziers:
		return
	_shards = clampi(shards, 0, 5)
	_braziers = clampi(braziers, 0, 3)
	queue_redraw()


func _draw() -> void:
	# Left-aligned, low-contrast HUD protects legibility without hiding the moon.
	var main := Rect2(14, 12, 507, 132)
	_draw_panel(main)
	draw_rect(Rect2(22, 18, 3, 26), Color("deb579"))
	draw_rect(Rect2(22, 46, 492, 1), Color("8d806f", 0.45))
	draw_rect(Rect2(22, 68, 492, 1), Color("8d806f", 0.30))
	# Quest progress strips give persistent feedback without huge text.
	_draw_meter(Rect2(25, 135, 230, 6), _shards, 5, Color("f9d694"))
	_draw_meter(Rect2(271, 135, 231, 6), _braziers, 3, Color("f18e57"))
	# Bottom caption.
	draw_rect(Rect2(14, 506, 931, 27), Color(0.035, 0.05, 0.09, 0.81))
	draw_rect(Rect2(14, 506, 931, 1), Color("c6a97a", 0.48))


func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, Color(0.034, 0.058, 0.106, 0.85))
	draw_rect(rect, Color("ac9276", 0.58), false, 1.0)
	for corner: Vector2 in [rect.position, rect.position + Vector2(rect.size.x - 10, 0), rect.position + Vector2(0, rect.size.y - 10), rect.end - Vector2(10, 10)]:
		draw_rect(Rect2(corner, Vector2(10, 2)), Color("dfbd87"))


func _draw_meter(rect: Rect2, value: int, maximum: int, accent: Color) -> void:
	draw_rect(rect, Color("172439"))
	var inner := rect.grow(-1)
	var fraction := float(value) / float(maximum)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * fraction, inner.size.y)), accent)
	draw_rect(rect, Color("768da5", 0.6), false, 1.0)
