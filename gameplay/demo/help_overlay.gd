## Optional on-demand control guide. H toggles it without changing any input mappings.
## Pauses the demo world while open and cooperates with the P/Esc pause overlay.
extends CanvasLayer

var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key != KEY_H:
		return
	if not is_open and (get_parent().get_node("PauseOverlay").is_paused or get_parent().get_node("VictoryOverlay").visible):
		return
	set_open(not is_open)
	get_viewport().set_input_as_handled()


func set_open(open: bool) -> void:
	if open and (get_parent().get_node("PauseOverlay").is_paused or get_parent().get_node("VictoryOverlay").visible):
		return
	is_open = open
	visible = open
	get_tree().paused = open


func _exit_tree() -> void:
	if is_open:
		get_tree().paused = false
