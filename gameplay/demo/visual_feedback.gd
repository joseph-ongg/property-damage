## Ephemeral visual event feedback; callers provide position/text/color only.
extends Node2D

var _bursts: Array[Dictionary] = []
const LIFETIME := 1.05


func emit(world_pos: Vector2, message: String, color: Color = Color("f5d495")) -> void:
	_bursts.append({"position": world_pos, "label": message, "color": color, "age": 0.0})
	queue_redraw()


func active_count() -> int:
	return _bursts.size()


func _process(delta: float) -> void:
	if _bursts.is_empty():
		return
	for index in range(_bursts.size() - 1, -1, -1):
		_bursts[index]["age"] += delta
		if _bursts[index]["age"] >= LIFETIME:
			_bursts.remove_at(index)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for burst: Dictionary in _bursts:
		var age: float = burst["age"]
		var progress: float = age / LIFETIME
		var origin: Vector2 = burst["position"] + Vector2(0, -24 - age * 32)
		var base: Color = burst["color"]
		var tint := Color(base.r, base.g, base.b, 1.0 - progress)
		var message: String = burst["label"]
		draw_string_outline(font, origin + Vector2(1, 0), message, HORIZONTAL_ALIGNMENT_CENTER, 150.0, 13, 3, Color(0.03, 0.05, 0.09, tint.a))
		draw_string(font, origin + Vector2(1, 0), message, HORIZONTAL_ALIGNMENT_CENTER, 150.0, 13, tint)
		for i in 6:
			var angle := TAU * float(i) / 6.0 + age * 1.8
			var radius := 7 + 22 * progress
			var point := origin + Vector2(cos(angle), sin(angle)) * radius
			draw_rect(Rect2(point.round(), Vector2(3, 3)), Color(tint.r, tint.g, tint.b, tint.a * 0.72))
