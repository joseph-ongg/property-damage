## Gameplay subteam MSD: move, jump, face the target, ignite and collide.
## This is a test harness, NOT a fabricated score, property-damage or win loop.
extends Node2D

@onready var status_text: Label = $HUD/SparkStatus

var sparks_p1: int = 0
var sparks_p2: int = 0
var _last_status_age: float = 0.0


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		get_window().content_scale_size = Vector2i(960, 540)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	$Player1.sparked.connect(_on_sparked)
	$Player2.sparked.connect(_on_sparked)


func _process(delta: float) -> void:
	if _last_status_age <= 0.0:
		return
	_last_status_age = maxf(0.0, _last_status_age - delta)
	if _last_status_age <= 0.0:
		status_text.text = "F / ENTER  •  SPARK"


func _on_sparked(player_index: int, target: Vector2, accepted: bool) -> void:
	var cell: Vector2i = $FireBridge.world_to_cell(target)
	if not accepted:
		status_text.text = "P%d  •  NO FIRE GRID AT TARGET" % player_index
	else:
		if player_index == 1:
			sparks_p1 += 1
		else:
			sparks_p2 += 1
		if $FireBridge.is_burning_world(target):
			status_text.text = "P%d  •  CELL %s IGNITED" % [player_index, str(cell)]
		else:
			status_text.text = "P%d  •  SPARK SENT (SIM PENDING)" % player_index
	_last_status_age = 2.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key == KEY_R and not get_tree().paused:
		get_tree().reload_current_scene()
