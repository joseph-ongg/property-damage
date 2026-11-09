## Draws one heart per max HP above a character's head.
class_name HeartsDisplay
extends Node2D

@export var health: Health
@export var heart_size: float = 5.0
@export var spacing: float = 14.0
@export var full_color: Color = Color(0.9, 0.15, 0.2)
@export var empty_color: Color = Color(0.2, 0.2, 0.25, 0.6)

var _hp: int = 0
var _max_hp: int = 0


func _ready() -> void:
	if health == null:
		push_warning("HeartsDisplay: assign a Health node.")
		return
	health.changed.connect(_on_changed)
	health.damaged.connect(_on_damaged)
	# Deferred so Health has finished its own _ready regardless of node order.
	_on_changed.call_deferred(health.hp, health.max_hp)


func _on_changed(hp: int, max_hp: int) -> void:
	_hp = hp
	_max_hp = max_hp
	queue_redraw()


func _on_damaged(_amount: int) -> void:
	# Small shake so hits feel readable.
	var tween := create_tween()
	var base := position
	tween.tween_property(self, "position", base + Vector2(3, 0), 0.04)
	tween.tween_property(self, "position", base - Vector2(3, 0), 0.04)
	tween.tween_property(self, "position", base, 0.04)


func _draw() -> void:
	var total_width := spacing * (_max_hp - 1)
	for i in _max_hp:
		var center := Vector2(i * spacing - total_width * 0.5, 0.0)
		_draw_heart(center, full_color if i < _hp else empty_color)


func _draw_heart(c: Vector2, color: Color) -> void:
	var s := heart_size
	draw_circle(c + Vector2(-s * 0.5, -s * 0.3), s * 0.55, color)
	draw_circle(c + Vector2(s * 0.5, -s * 0.3), s * 0.55, color)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 1.0, -s * 0.1),
		c + Vector2(s * 1.0, -s * 0.1),
		c + Vector2(0.0, s * 1.1),
	]), color)
