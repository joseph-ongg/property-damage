## Optional dash: independent cooldown and impulse; collision stays in Motor.
class_name GameplayDash
extends Node

@export var dash_speed: float = 510.0
@export var dash_duration: float = 0.15
@export var cooldown: float = 0.8

var time_left: float = 0.0
var cooldown_left: float = 0.0


func begin() -> bool:
	if cooldown_left > 0.0:
		return false
	time_left = dash_duration
	cooldown_left = cooldown
	return true


func tick(delta: float) -> void:
	time_left = maxf(0.0, time_left - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)


func active() -> bool:
	return time_left > 0.0


func ready() -> bool:
	return cooldown_left <= 0.0


func reset() -> void:
	time_left = 0.0
	cooldown_left = 0.0
