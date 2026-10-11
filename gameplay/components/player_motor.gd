## Independent, reusable platforming physics for a CharacterBody2D.
class_name GameplayMotor
extends Node

@export var speed: float = 245.0
@export var ground_acceleration: float = 1500.0
@export var air_acceleration: float = 1000.0
@export var jump_speed: float = 460.0
@export var gravity: float = 1050.0
@export var max_fall_speed: float = 750.0


func step(body: CharacterBody2D, delta: float, horizontal: float, jumping: bool) -> void:
	if body.is_on_floor():
		if jumping:
			body.velocity.y = -jump_speed
		elif body.velocity.y > 0.0:
			body.velocity.y = 0.0
	else:
		body.velocity.y = minf(body.velocity.y + gravity * delta, max_fall_speed)
	var acceleration := ground_acceleration if body.is_on_floor() else air_acceleration
	body.velocity.x = move_toward(body.velocity.x, horizontal * speed, acceleration * delta)
	body.move_and_slide()
