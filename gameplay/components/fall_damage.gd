## Emits hard_landing(damage) when the body lands after a long fall.
## Design rule: no damage if the fall is shorter than 2 character heights;
## otherwise damage = (distance fell - 2 * character height) / 10.
## "Distance fell" is measured from the last spot the body stood on, so a normal
## jump (up and back down to the same level) is free, and so is the rise of a
## double jump or a coyote-time jump.
class_name GameplayFallDamage
extends Node

signal hard_landing(damage: int)

@export var enabled: bool = true
## Character height in pixels. 0 = read it from the body's CollisionShape2D.
@export var character_height: float = 0.0
@export var fallback_height: float = 40.0
@export var safe_heights: float = 2.0
@export var damage_divisor: float = 10.0
## A one-frame vertical jump bigger than this is a teleport (respawn), not a fall.
@export var teleport_threshold: float = 150.0

var _airborne: bool = false
var _ground_y: float = 0.0
var _last_y: float = 0.0
var _initialised: bool = false


func reset(body: CharacterBody2D) -> void:
	_airborne = false
	_ground_y = body.global_position.y
	_last_y = body.global_position.y
	_initialised = true


func height_of(body: CharacterBody2D) -> float:
	if character_height > 0.0:
		return character_height
	var c := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if c != null:
		if c.shape is RectangleShape2D:
			return (c.shape as RectangleShape2D).size.y * absf(c.global_scale.y)
		if c.shape is CapsuleShape2D:
			return (c.shape as CapsuleShape2D).height * absf(c.global_scale.y)
	return fallback_height


## Call once per physics frame, AFTER move_and_slide().
func tick(body: CharacterBody2D) -> void:
	if not enabled:
		return
	var y := body.global_position.y
	if not _initialised or absf(y - _last_y) > teleport_threshold:
		reset(body)  # first frame or respawn: don't count it as a fall
		return
	_last_y = y
	if body.is_on_floor():
		if _airborne:
			var distance := y - _ground_y
			var safe := safe_heights * height_of(body)
			if distance > safe:
				var dmg := int((distance - safe) / damage_divisor)
				if dmg > 0:
					hard_landing.emit(dmg)
		_airborne = false
		_ground_y = y
	else:
		_airborne = true
