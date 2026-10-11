## Self-contained playable MSD demo bootstrap (no modifications to Sim scenes).
extends Node2D

const InputActions = preload("res://gameplay/input_actions.gd")

@onready var status_text: Label = $HUD/Status


func _enter_tree() -> void:
	InputActions.register_actions()


func _ready() -> void:
	# Resize only the launched game window, never the editor or test runner.
	if DisplayServer.get_name() != "headless":
		get_window().content_scale_size = Vector2i(960, 540)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	$Player1.sparked.connect(_on_sparked)
	$Player2.sparked.connect(_on_sparked)


func _on_sparked(player_index: int, target: Vector2, accepted: bool) -> void:
	if accepted:
		status_text.text = "P%d IGNITED CELL AT %s" % [player_index, str($FireBridge.world_to_cell(target))]
	else:
		status_text.text = "P%d SPARK OUT OF RANGE" % player_index
