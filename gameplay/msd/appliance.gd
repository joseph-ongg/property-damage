## Optional, self-contained interaction prototype; not approved Simulation mechanics.
class_name GameplayAppliance
extends Node2D

enum Device { FRIDGE, FAN, AC, COMPUTER }
signal state_changed(device: int, state: bool, player_index: int)

@export var device: Device = Device.FRIDGE
@export var interaction_radius: float = 78.0
@export var effect_radius: float = 130.0
@export var wind_acceleration: float = -420.0
@export_range(0.25, 1.0, 0.05) var cold_speed_scale: float = 0.45  # 开启后区域内速度约为 45%。 / While the AC is on, nearby movement targets 45% of normal speed.

var switched_on: bool = false
var charred: bool = false
var _clock: float = 0.0


# The fan is drawn on the table; its node origin is above a standing player's
# interaction height. Use the base/control point, not the artwork's origin.
func interaction_point() -> Vector2:
	if device == Device.FAN:
		return global_position + Vector2(0.0, 24.0)
	return global_position


func can_interact(player: GameplayPlayer) -> bool:
	return not charred and interaction_point().distance_to(player.global_position) <= interaction_radius


func interact(player: GameplayPlayer) -> bool:
	if not can_interact(player):
		return false
	switched_on = not switched_on
	state_changed.emit(int(device), switched_on, player.player_index)
	queue_redraw()
	return true


func receive_spark(target: Vector2, player_index: int) -> bool:
	if device != Device.COMPUTER or charred or target.distance_to(global_position) > 49.0:
		return false
	charred = true
	switched_on = false
	state_changed.emit(int(device), false, player_index)
	queue_redraw()
	return true


func applies_to(player: GameplayPlayer) -> bool:
	return switched_on and not charred and global_position.distance_to(player.global_position) <= effect_radius


func device_name() -> String:
	match device:
		Device.FRIDGE: return "FRIDGE"
		Device.FAN: return "FAN"
		Device.AC: return "AIR CONDITIONER"
		Device.COMPUTER: return "COMPUTER"
	return "APPLIANCE"


func _process(delta: float) -> void:
	_clock += delta
	if switched_on and device in [Device.FAN, Device.AC]:
		queue_redraw()


func _draw() -> void:
	var gold := Color("e8ba79") if switched_on else Color("8f8985")
	match device:
		Device.FRIDGE:
			# The base fridge lives in the pixel room art. Toggle only the door.
			if switched_on:
				draw_rect(Rect2(-55, -108, 92, 92), Color("26333e"))
				draw_rect(Rect2(-54, -107, 90, 6), Color("909ca2"))
				draw_rect(Rect2(-51, -98, 82, 5), Color("6c7a80"))
				# 打开的冰箱用两层货架和小容器强调这是内部空间，不是一块黑洞。
				# Use shelves and containers to make an open fridge read as an interior.
				for shelf_y in [-69.0, -41.0]:
					draw_rect(Rect2(-45, shelf_y, 70, 3), Color("667882"))
					draw_rect(Rect2(-45, shelf_y - 3, 70, 2), Color("b4c4c0", 0.6))
				draw_rect(Rect2(-38, -84, 15, 13), Color("b5d7c3"))
				draw_rect(Rect2(-16, -82, 11, 11), Color("dfad83"))
				draw_rect(Rect2(0, -52, 21, 11), Color("b4c1d5"))
				draw_rect(Rect2(-38, -29, 22, 10), Color("759fb2"))
				draw_rect(Rect2(35, -108, 18, 94), Color("c5c5b9"))
				draw_rect(Rect2(38, -84, 3, 25), Color("737d83"))
			else:
				draw_rect(Rect2(33, -81, 4, 22), Color("626d78"))
		Device.FAN:
			draw_rect(Rect2(-2, 1, 4, 19), Color("aab1a6"))
			draw_rect(Rect2(-17, 18, 34, 4), Color("a1a29b"))
			draw_arc(Vector2(0, -8), 17, 0, TAU, 30, Color("b8b0a1"), 2.0)
			for i in range(3):
				var angle := (TAU * i / 3.0) + (_clock * 13.0 if switched_on else 0.0)
				var blade := Vector2(cos(angle), sin(angle)) * 12.0
				draw_line(Vector2(0, -8), Vector2(0, -8) + blade, Color("99c7cb") if switched_on else Color("778b96"), 4.0)
			draw_circle(Vector2(0, -8), 3, gold)
		Device.AC:
			# 空调本体挂在墙上，交互开关仍在地面玩家伸手可及的位置。
			# Wall-mount the AC while keeping its control accessible to floor-level players.
			# 用独立大轮廓避免误看成桌旁插座。
			# Use a distinct silhouette so it does not resemble a wall socket.
			var housing := Rect2(-45, -147, 90, 35)
			draw_rect(Rect2(-49, -151, 98, 42), Color("414e5b"))
			draw_rect(housing, Color("b5c0bd"))
			draw_rect(Rect2(-42, -144, 84, 8), Color("d1d1bc"))
			draw_rect(Rect2(-41, -131, 82, 13), Color("60737e"))
			for i in 9:
				draw_rect(Rect2(-37 + i * 9, -126, 5, 3), Color("324a59"))
			draw_rect(Rect2(33, -142, 5, 5), Color("6be4db") if switched_on else Color("c28e67"))
			# 墙壁开关与作用范围独立标记，玩家走近时才显示互动键。
			# Keep the switch and area indicator separate; show interaction keys only nearby.
			draw_rect(Rect2(-12, -19, 24, 21), Color("63737d"))
			draw_rect(Rect2(-9, -16, 18, 15), Color("283c4a"))
			draw_rect(Rect2(3, -13, 4, 4), Color("82e4ed") if switched_on else Color("b36b63"))
			if switched_on:
				# 细冷气像素粒子，提示开关已生效，不盖住整个地图。
				# Subtle cold-air pixels show AC status without covering the scene.
				for i in 7:
					var drift := fmod(_clock * 27.0 + float(i * 23), 76.0)
					var x := -35.0 + float(i * 11) + sin(_clock * 1.5 + i) * 4.0
					draw_rect(Rect2(Vector2(x, -102 + drift).round(), Vector2(3, 5)), Color(0.56, 0.88, 0.97, 0.34))
				# 将范围提示压在地板边缘，不再让半圆弧横穿桌面、遮挡角色。
				# Move range markers to the floor instead of covering the desk with an arc.
				for i in range(-6, 7):
					var offset := float(i) * 18.0
					if absf(offset) <= effect_radius:
						draw_rect(Rect2(offset - 5.0, 21.0, 10.0, 2.0), Color(0.50, 0.87, 1.0, 0.29))
		Device.COMPUTER:
			draw_rect(Rect2(-22, -35, 44, 30), Color("4e525b"))
			draw_rect(Rect2(-19, -32, 38, 24), Color("2e343b") if charred else Color("2a5673") if switched_on else Color("57707c"))
			draw_rect(Rect2(-3, -4, 6, 8), Color("7f8180"))
			draw_rect(Rect2(-15, 3, 30, 4), Color("b2a69b"))
			if charred:
				for i in range(4):
					draw_rect(Rect2(-16+i*9, -24-(i%2)*5, 3, 3), Color("463c43"))
			elif switched_on:
				draw_rect(Rect2(-15, -27, 28, 3), Color("87dad1"))
	# Colored notch signals interactivity without an extra giant HUD.
	draw_rect(Rect2(-4, 24, 8, 3), gold)
