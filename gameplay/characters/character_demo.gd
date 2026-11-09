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


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if P1_CHOICES.has(event.keycode):
		player1_character = P1_CHOICES[event.keycode]
		get_node("Main/GameplayMSD/Player1").set_character_kind(player1_character)
	elif P2_CHOICES.has(event.keycode):
		player2_character = P2_CHOICES[event.keycode]
		get_node("Main/GameplayMSD/Player2").set_character_kind(player2_character)
