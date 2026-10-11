## 家电状态：空调减速和风扇吹力反馈，状态只来自 GameplayMotor，不改物理。
## 中文维护：移动速度实际取决于 MSD Controller 写入的 motor.speed_scale。
extends Node2D

@onready var room: Node2D = get_parent()
@onready var p1: GameplayPlayer = room.get_node("Player1")
@onready var p2: GameplayPlayer = room.get_node("Player2")
var _clock := 0.0


func get_condition(player: GameplayPlayer) -> String:
	if player.motor.speed_scale < 0.99:
		return "SLOW"
	if absf(player.motor.environment_acceleration_x) > 0.1:
		return "WIND"
	return ""


func _process(delta: float) -> void:
	_clock += delta
	if Engine.get_process_frames() % 5 == 0:
		queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for player: GameplayPlayer in [p1, p2]:
		var condition := get_condition(player)
		if condition.is_empty():
			continue
		var cool := condition == "SLOW"
		var color := Color("a7e9ff") if cool else Color("f5c391")
		var point := player.global_position + Vector2(-17, -84)
		draw_rect(Rect2(point + Vector2(-3, -4), Vector2(49, 17)), Color("14283b", 0.87))
		draw_rect(Rect2(point + Vector2(-3, -4), Vector2(49, 17)), color, false, 1.0)
		draw_string(font, point + Vector2(2, 9), condition, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
		# 空调下方飘动的冷色像素，视觉上和橙色火焰形成区分。
		if cool:
			for j in 3:
				var dx := -17.0 + j * 15.0
				var dy := 4.0 + fmod(_clock * 15.0 + j * 13.0, 24.0)
				draw_rect(Rect2((player.global_position + Vector2(dx, -30 - dy)).round(), Vector2(2, 3)), Color("8adcf6", 0.70))
