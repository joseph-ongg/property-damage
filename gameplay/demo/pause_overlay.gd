## Isolated pause menu that remains interactive when SceneTree.paused is true.
extends CanvasLayer

var is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Backdrop.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	# Prefer physical controls, but support synthetic/accessibility key events.
	var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key in [KEY_P, KEY_ESCAPE]:
		set_paused(not is_paused)
		get_viewport().set_input_as_handled()
	elif is_paused and key == KEY_R:
		set_paused(false)
		get_tree().reload_current_scene()
		get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
	is_paused = paused
	$Backdrop.visible = paused
	get_tree().paused = paused


func _exit_tree() -> void:
	if is_paused:
		get_tree().paused = false
