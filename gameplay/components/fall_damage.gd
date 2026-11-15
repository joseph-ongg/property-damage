## Emits hard_landing(damage) when the player lands after falling farther than safe_distance.
class_name GameplayFallDamage
extends Node

signal hard_landing(damage: int)

@export var enabled: bool = true
## Falls shorter than this (in pixels) are free. A normal jump is roughly 100 px.
@export var safe_distance: float = 220.0
## Damage per pixel beyond safe_distance. 0.15 means a 400 px fall deals about 27 damage.
@export var damage_per_pixel: float = 0.15
@export var min_damage: int = 1

var _airborne: bool = false
var _peak_y: float = 0.0


func reset(body: CharacterBody2D) -> void:
	_airborne = false
	_peak_y = body.global_position.y


## Call once per physics frame, AFTER motor.step() (which runs move_and_slide).
func tick(body: CharacterBody2D) -> void:
	if not enabled:
		return
	if body.is_on_floor():
		if _airborne:
			var distance := body.global_position.y - _peak_y
			if distance > safe_distance:
				var dmg := int((distance - safe_distance) * damage_per_pixel)
				hard_landing.emit(maxi(min_damage, dmg))
		_airborne = false
		_peak_y = body.global_position.y
	else:
		if not _airborne:
			_airborne = true
			_peak_y = body.global_position.y
		else:
			_peak_y = minf(_peak_y, body.global_position.y)
