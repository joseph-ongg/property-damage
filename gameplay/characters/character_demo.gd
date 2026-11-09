## Character showcase, using the real Gameplay arena, players, and controls.
## The art and player classes are also reusable in other team's scenes.
extends Node2D

@export_enum("mage", "ninja", "werewolf") var player1_character: String = "ninja"
@export_enum("mage", "ninja", "werewolf") var player2_character: String = "werewolf"

const P1_CHOICES: Dictionary = {KEY_1: "mage", KEY_2: "ninja", KEY_3: "werewolf"}
const P2_CHOICES: Dictionary = {KEY_7: "mage", KEY_8: "ninja", KEY_9: "werewolf"}


func _ready() -> void:
	get_node("Main/GameplayMSD/Player1").set_character_kind(player1_character)
	get_node("Main/GameplayMSD/Player2").set_character_kind(player2_character)


func _input(event: InputEvent) -> void:
	# Demo selection keys are handled before child HUD/GUI input can consume
	# them. Keep the menu and normal P1/P2 gameplay bindings unchanged.
	if get_tree().paused:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if P1_CHOICES.has(key):
		player1_character = P1_CHOICES[key]
		get_node("Main/GameplayMSD/Player1").set_character_kind(player1_character)
		get_viewport().set_input_as_handled()
	elif P2_CHOICES.has(key):
		player2_character = P2_CHOICES[key]
		get_node("Main/GameplayMSD/Player2").set_character_kind(player2_character)
		get_viewport().set_input_as_handled()
