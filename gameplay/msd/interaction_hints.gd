## 仅在玩家接近物品时显示简短操作提示；与真正的目标选择共用控制器 API。
## 中文维护：提示绝不决定可否交互，它只读取 get_interaction_offer()。
extends Node2D

@onready var room: Node2D = get_parent()
@onready var p1: GameplayPlayer = room.get_node("Player1")
@onready var p2: GameplayPlayer = room.get_node("Player2")

var _redraw_clock: float = 0.0


func _process(delta: float) -> void:
	_redraw_clock += delta
	if _redraw_clock >= 0.08:
		_redraw_clock = 0.0
		queue_redraw()


func hint_for(player: GameplayPlayer) -> String:
	var offer: Dictionary = room.get_interaction_offer(player)
	if offer.is_empty():
		return ""
	var input_key := "E" if player.player_index == 1 else "SHIFT"
	return input_key + "  " + str(offer["action"])


func _anchor_for(player: GameplayPlayer, offer: Dictionary) -> Vector2:
	var target: Node2D = offer["target"]
	if offer["kind"] == "throw":
		return player.global_position + Vector2(0, -73)
	if offer["kind"] == "pick":
		return target.global_position + Vector2(0, -65)
	var device := target as GameplayAppliance
	match device.device:
		GameplayAppliance.Device.FRIDGE:
			return device.global_position + Vector2(0, -151)
		GameplayAppliance.Device.AC:
			return device.global_position + Vector2(0, -191)
		GameplayAppliance.Device.FAN:
			return device.global_position + Vector2(0, -66)
		GameplayAppliance.Device.COMPUTER:
			return device.global_position + Vector2(0, -90)
	return target.global_position + Vector2(0, -60)


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	for player: GameplayPlayer in [p1, p2]:
		var offer: Dictionary = room.get_interaction_offer(player)
		if offer.is_empty():
			continue
		var content := hint_for(player)
		var accent := Color("69e5c9") if player.player_index == 1 else Color("ffb476")
		var width: float = font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 18.0
		var location := _anchor_for(player, offer)
		var x := clampf(location.x - width * 0.5, 12.0, 948.0 - width)
		var y := clampf(location.y - (30.0 if player.player_index == 1 else 0.0), 73.0, 471.0)
		# 小型实心底板让文字在像素背景上保持可读。
		draw_rect(Rect2(x, y, width, 23), Color("142231", 0.93))
		draw_rect(Rect2(x, y, width, 23), accent, false, 1.0)
		draw_string(font, Vector2(x + 9, y + 16), content, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e4eef0"))
		draw_rect(Rect2(x + 2, y + 3, 3, 17), accent)
