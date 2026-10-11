## Optional, self-contained interaction prototype; not approved Simulation mechanics.
class_name GameplayAppliance
extends Node2D

enum Device { FRIDGE, FAN, AC, COMPUTER }
signal state_changed(device: int, state: bool, player_index: int)

@export var device: Device = Device.FRIDGE
@export var interaction_radius: float = 78.0
@export var effect_radius: float = 122.0
@export var wind_acceleration: float = -420.0
@export_range(0.25, 1.0, 0.05) var cold_speed_scale: float = 0.60

var switched_on: bool = false
var charred: bool = false
var _clock: float = 0.0


func can_interact(player: GameplayPlayer) -> bool:
	return not charred and global_position.distance_to(player.global_position) <= interaction_radius


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
	if switched_on and device == Device.FAN:
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
			# Floor-accessible control for the wall-mounted air conditioner.
			draw_rect(Rect2(-14, -24, 28, 22), Color("9aa7a6"))
			draw_rect(Rect2(-10, -19, 20, 12), Color("394d55"))
			draw_rect(Rect2(5, -16, 4, 4), Color("82c9d4") if switched_on else Color("bd796b"))
			if switched_on:
				for i in range(3):
					draw_line(Vector2(-12+i*9, -30), Vector2(-15+i*9, -39), Color("89c7df", 0.76), 2.0)
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
