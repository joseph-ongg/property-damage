## Reusable HP component. Add as a child of any character.
class_name Health
extends Node

signal changed(hp: int, max_hp: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_hp: int = 3
## Brief immunity after a hit so one hazard doesn't drain every heart in a frame.
@export var invulnerable_time: float = 0.8

var hp: int = 3
var _invuln_left: float = 0.0


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	_invuln_left = maxf(0.0, _invuln_left - delta)


func reset() -> void:
	hp = max_hp
	_invuln_left = 0.0
	changed.emit(hp, max_hp)


func is_alive() -> bool:
	return hp > 0


func is_invulnerable() -> bool:
	return _invuln_left > 0.0


## Returns true if the damage was actually applied.
func take_damage(amount: int = 1) -> bool:
	if not is_alive() or is_invulnerable() or amount <= 0:
		return false
	hp = maxi(0, hp - amount)
	_invuln_left = invulnerable_time
	damaged.emit(amount)
	changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()
	return true


func heal(amount: int = 1) -> void:
	if not is_alive() or amount <= 0:
		return
	var before := hp
	hp = mini(max_hp, hp + amount)
	if hp != before:
		healed.emit(hp - before)
		changed.emit(hp, max_hp)
